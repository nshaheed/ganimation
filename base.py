import argparse
import torch
import matplotlib.pyplot as plt
import torchvision
import time
import threading
import logging

from pythonosc import dispatcher, osc_server
from pythonosc.udp_client import SimpleUDPClient

import glfw
from OpenGL.GL import *
import OpenGL.GL.shaders
import numpy as np
from PIL import Image


import time

use_gpu = True if torch.cuda.is_available() else False

def draw(addr: str, args, id: int) -> None:
    logging.debug(f'{addr=}, {id=}')

    global model
    model.set_draw(id)

def random_face(addr: str, args, id: int) -> None:
    logging.debug(f'{addr=}, {id=}')

    global model
    model.replace_latent(id)

def make_latent(addr: str, *args) -> None:
    logging.debug(f'{addr=}')

    global model
    id = model.make_latent()

    client.send_message('/make_latent/receive', id)

# def interpolate(addr: str, fixed_argument: List[Any], *osc_arguments: List[Any]) -> None:
def interpolate(addr: str, args, source_id: int, left_id: int, right_id: int, interp: float) -> None:
    logging.debug(f'{addr=}, {source_id=}, {left_id=}, {right_id=}, {interp=}')

    global model
    model.interpolate(source_id, left_id, right_id, interp)

def run_server(dispatch):
    server = osc_server.ThreadingOSCUDPServer(
        (ip, port), dispatch)
    print("Serving on {}".format(server.server_address))
    server.serve_forever()

num_images = 1

ip = "127.0.0.1"
port = 5005

model = None
latent = None

## TODO abstract this to allow for subclasses for different models (stylegan, pgan, w/e)
class Model:
    model = None
    use_gpu = None

    id_counter = 0
    latent = None

    draw = None # which latent to draw

    def __init__(self):
        self.use_gpu = True if torch.cuda.is_available() else False
        self.latent = {}

        # trained on high-quality celebrity faces "celebA" dataset
        # this model outputs 512 x 512 pixel images
        self.model = torch.hub.load('facebookresearch/pytorch_GAN_zoo:hub',
                               'PGAN', model_name='celebAHQ-512',
                               pretrained=True, useGPU=use_gpu)

    def generate_noise(self):
        noise, _ = self.model.buildNoiseData(1)
        return noise

    def make_latent(self) -> int:
        """ Make a random latent and add to latent collection. """
        id = self.id_counter
        self.latent[id] = self.generate_noise()

        # make sure each id is unique
        self.id_counter += 1
        logging.debug(f'latent shape: {self.latent[id].shape}')

        return id

    def replace_latent(self, id: int, source_id=None) -> None:
        """ Replace latent at id with a new random latent. """
        self.latent[id] = self.generate_noise()

        # TODO: add case for when source_id is not None

    def make_image(self, id):
        """ Use a latent to generate an image. """
        curr_latent = self.latent[id]
        result = self.model.test(curr_latent)
        return result

    def interpolate(self, source_id: int, left_id: int, right_id: int, interp: float) -> None:
        """ Linear interpolation between left and right latents. """
        self.latent[source_id] = self.latent[left_id] * interp + self.latent[right_id] * (1.0 - interp)

    def set_draw(self, source_id: int) -> None:
        """ Set which latent from the model to draw. """
        self.draw = source_id

###### OpenGL stuff ######
def main() -> None:
    # initialize glfw
    if not glfw.init():
        return

    window = glfw.create_window(512, 512, "My OpenGL window", None, None)

    if not window:
        glfw.terminate()
        return

    glfw.make_context_current(window)
    #           positions    colors          texture coords
    quad = [   -1, -1, 0.0,  1.0, 1.0, 1.0,  0.0, 0.0,
                1, -1, 0.0,  1.0, 1.0, 1.0,  1.0, 0.0,
                1,  1, 0.0,  1.0, 1.0, 1.0,  1.0, 1.0,
               -1,  1, 0.0,  1.0, 1.0, 1.0,  0.0, 1.0]

    quad = np.array(quad, dtype = np.float32)

    indices = [0, 1, 2,
               2, 3, 0]

    indices = np.array(indices, dtype= np.uint32)

    print(quad.itemsize * len(quad))
    print(indices.itemsize * len(indices))
    print(quad.itemsize * 8)

    vertex_shader = """
    #version 330
    in layout(location = 0) vec3 position;
    in layout(location = 1) vec3 color;
    in layout(location = 2) vec2 inTexCoords;

    out vec2 outTexCoords;
    void main()
    {
        gl_Position = vec4(position, 1.0f);
        outTexCoords = inTexCoords;
    }
    """

    fragment_shader = """
    #version 330
    in vec2 outTexCoords;

    out vec4 outColor;
    uniform sampler2D samplerTex;
    void main()
    {
        outColor = texture(samplerTex, outTexCoords);
    }
    """
    shader = OpenGL.GL.shaders.compileProgram(OpenGL.GL.shaders.compileShader(vertex_shader, GL_VERTEX_SHADER),
                                              OpenGL.GL.shaders.compileShader(fragment_shader, GL_FRAGMENT_SHADER))

    VBO = glGenBuffers(1)
    glBindBuffer(GL_ARRAY_BUFFER, VBO)
    glBufferData(GL_ARRAY_BUFFER, quad.itemsize * len(quad), quad, GL_STATIC_DRAW)

    EBO = glGenBuffers(1)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, EBO)
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indices.itemsize * len(indices), indices, GL_STATIC_DRAW)

    #position = glGetAttribLocation(shader, "position")
    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, quad.itemsize * 8, ctypes.c_void_p(0))
    glEnableVertexAttribArray(0)

    #color = glGetAttribLocation(shader, "color")
    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, quad.itemsize * 8, ctypes.c_void_p(12))
    glEnableVertexAttribArray(1)

    #texture_coords = glGetAttribLocation(shader, "inTexCoords")
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, quad.itemsize * 8, ctypes.c_void_p(24))
    glEnableVertexAttribArray(2)

    glUseProgram(shader)

    glClearColor(1, 1, 1, 1.0)

    texture = glGenTextures(1)


    frameCount = 0
    lastTime = glfw.get_time()

    while not glfw.window_should_close(window):
        glfw.poll_events()

        if args.framerate:
            currentTime = glfw.get_time()
            frameCount += 1

            if (currentTime - lastTime >= 1.0):
                ctime = currentTime - lastTime # time delta in seconds
                print(f'{1000.0 * ctime/frameCount:.3f} ms/frame ({frameCount/ctime:.1f} fps)')
                frameCount = 0
                lastTime = currentTime

        # temp fix until proper latent selection is added
        if model.draw is None:
            continue
        with torch.no_grad():
            id = model.draw
            generated_images = model.make_image(id)
            generated_images = generated_images[0].clamp(min=-1, max=1) # chop off any vals not in (-1,1)
            generated_images = generated_images.transpose(0, 2) # the channel dim should be last
            generated_images = generated_images.rot90(1,[0,1]) # image needs to be rotate for some reason
            generated_images = torch.add(generated_images, 1) # scale the image: (-1,1) -> (0,1)
            generated_images = torch.div(generated_images, 2)
            generated_images = np.asarray(generated_images) # convert to numpy array to feed to texture


        glBindTexture(GL_TEXTURE_2D, texture)
        #texture wrapping params
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
        #texture filtering params
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, 512, 512, 0, GL_RGB, GL_FLOAT, generated_images)

        glClear(GL_COLOR_BUFFER_BIT)

        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, None)

        glfw.swap_buffers(window)

    glfw.terminate()

model = Model()

client = None

parser = argparse.ArgumentParser()
parser.add_argument('-d', '--debug', help='print debug logging', action='store_true')
parser.add_argument('-f', '--framerate', help='print frame info', action='store_true')
args = parser.parse_args()

# init_main sets up all the osc/opengl coroutines and closes things properly
def init_main():
    # set up logging
    if args.debug:
        level = logging.DEBUG
    else:
        level = logging.INFO
    fmt = '[%(levelname)s] %(asctime)s - %(message)s'
    logging.basicConfig(level=level, format=fmt)

    # set up model (TODO handle multiple models)
    global model

    global client
    client = SimpleUDPClient(ip, port+1)  # Create client

    dispatch = dispatcher.Dispatcher()
    dispatch.map("/draw", draw, "id")
    dispatch.map("/face", random_face, "id")
    dispatch.map("/interpolate", interpolate, "source_id", "left_id", "right_id", "interp")
    dispatch.map("/make_latent/send", make_latent)

    server = osc_server.ThreadingOSCUDPServer(
        (ip, port), dispatch)
    x = threading.Thread(target=server.serve_forever)
    x.start()

    print("past server start")

    main()

    server.server_close()
    print("shutting down...")

if __name__ == "__main__":
    init_main()
