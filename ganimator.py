import argparse
import torch
import time
import logging
import asyncio

from gooey import Gooey

from pythonosc import dispatcher, osc_server
from pythonosc.osc_server import AsyncIOOSCUDPServer
from pythonosc.udp_client import SimpleUDPClient

import glfw
from OpenGL.GL import *
import OpenGL.GL.shaders
import numpy as np

import model.model

def log_osc(func):
    def printlog(*args, **kwargs):
        log_str = f'addr={args[0]}'

        method_args = args[2:]

        if len(method_args) > 0:
            for idx, arg_name in enumerate(args[1]):
                log_str += f', {arg_name}={method_args[idx]}'

        logging.debug(log_str)
        func(*args, **kwargs)

    return printlog

@log_osc
def draw(addr: str, args, id: int) -> None:
    curr_model.set_draw(id)

@log_osc
def load(addr: str, args, model_name: str) -> None:
    global curr_model

    match addr.split('/')[2]:
        case 'StyleGAN':
            curr_model = model.model.StyleGAN3()
            curr_model.load(model_name)
        case 'PGAN':
            curr_model = model.model.Model()

            if model_name == '':
                curr_model.load()
            else:
                curr_model.load(model_name)
        case 'StableDiffusion':
            curr_model = model.model.StableDiffusion()
            curr_model.load()        
        case _:
            logging.error('model type not found')
            
    # pythonosc requires an attached value
    return_addr = '/'.join(addr.split('/')[:-1] + ['receive'])

    logging.debug(f'{return_addr} calling back to client')
    client.send_message(return_addr, 0)    

@log_osc
def random_face(addr: str, args, id: int) -> None:
    curr_model.replace_latent(id)

@log_osc
def make_latent(addr: str, *args) -> None:
    id = curr_model.make_latent()

    client.send_message('/make_latent/receive', id)

@log_osc
def interpolate(addr: str, args, source_id: int, left_id: int, right_id: int, interp: float) -> None:
    curr_model.interpolate(source_id, left_id, right_id, interp)

@log_osc
def sin_osc(addr: str, args, source_id: int, point1_id: int, phase: float, amp: float) -> None:
    curr_model.sin_osc(source_id, point1_id, phase, amp)

@log_osc
def add(addr: str, args, source_id: int, point1_id: int, point2_id: int) -> None:
    curr_model.add(source_id, point1_id, point2_id)

@log_osc
def sub(addr: str, args, source_id: int, point1_id: int, point2_id: int) -> None:
    curr_model.sub(source_id, point1_id, point2_id)

@log_osc
def mul(addr: str, args, source_id: int, point1_id: int, scalar: float) -> None:
    curr_model.mul(source_id, point1_id, scalar)

@log_osc
def div(addr: str, args, source_id: int, point1_id: int, point2_id: int) -> None:
    curr_model.div(source_id, point1_id, point2_id)

@log_osc
def save_latent(addr: str, args, source_id: id, filepath: str) -> None:
    curr_model.save_latent(source_id, filepath)

@log_osc
def load_latent(addr: str, args, filepath: str) -> None:
    id = curr_model.load_latent(filepath)

    logging.info(f'latent id = {id}')
    client.send_message('/latent/load/receive', [filepath, id])

@log_osc
def rotate(addr: str, args, angle: int) -> None:
    angle = angle % 360

    if angle % 90 != 0:
        logging.error('wrong angle, must be one of {0, 90, 180, 270}')

    curr_model.rotate = angle

num_images = 1

ip = "127.0.0.1"
port = 5005

curr_model = None
latent = None

###### OpenGL stuff ######
async def draw_loop(test, framerate, **kwargs) -> None:
    # initialize glfw
    if not glfw.init():
        return

    logging.info("Waiting for model load...")
    while curr_model is None:
        await asyncio.sleep(1.0/24)
    logging.info("Model loaded!")

    breakpoint()

    # stall the render loop if in test mode
    while test:
        await asyncio.sleep(1.0)

    size = curr_model.size()
    # window = glfw.create_window(size[0], size[1], "My OpenGL window", None, None)
    window = glfw.create_window(512, 512, "GANimator", None, None)

    if not window:
        glfw.terminate()
        return

    glfw.make_context_current(window)

    indices = [0, 1, 2,
               2, 3, 0]

    indices = np.array(indices, dtype= np.uint32)

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

    glUseProgram(shader)

    glClearColor(1, 1, 1, 1.0)

    EBO = glGenBuffers(1)
    VBO = glGenBuffers(1)
    texture = glGenTextures(1)

    frameCount = 0
    lastTime = glfw.get_time()

    while not glfw.window_should_close(window):
        await asyncio.sleep(0) # this needs to be before poll events

        if framerate:
            currentTime = glfw.get_time()
            frameCount += 1

            if (currentTime - lastTime >= 1.0):
                ctime = currentTime - lastTime # time delta in seconds
                logging.info(f'{1000.0 * ctime/frameCount:.3f} ms/frame ({frameCount/ctime:.1f} fps)')
                frameCount = 0
                lastTime = currentTime

        # temp fix until proper latent selection is added
        if curr_model.draw is None:
            continue
        with torch.no_grad():
            id = curr_model.draw
            generated_image = curr_model.make_image(id)

        await asyncio.sleep(0)

        quad = curr_model.get_quad()
        glBindBuffer(GL_ARRAY_BUFFER, VBO)
        glBufferData(GL_ARRAY_BUFFER, quad.itemsize * len(quad), quad, GL_STATIC_DRAW)

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

        glBindTexture(GL_TEXTURE_2D, texture)
        #texture wrapping params
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
        #texture filtering params
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, size[0], size[1], 0, GL_RGB, GL_FLOAT, generated_image)

        glClear(GL_COLOR_BUFFER_BIT)
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, None)

        glfw.swap_buffers(window)

        await asyncio.sleep(0) # this needs to be before poll events

        glfw.poll_events()

    glfw.terminate()

client = None

# init_main sets up all the osc/opengl coroutines and closes things properly
@Gooey(
    program_name='GANimator'
)
async def main() -> None:
    parser = argparse.ArgumentParser(description='image renering server for GANimator')
    parser.add_argument('-d', '--debug', help='print debug logging', action='store_true')
    parser.add_argument('-f', '--framerate', help='print frame info', action='store_true')
    parser.add_argument('-t', '--test', help='testing mode, don\'t render images', action='store_true')

    args = parser.parse_args()

    # set up logging
    if args.debug:
        level = logging.DEBUG
    else:
        level = logging.INFO
    fmt = '[%(levelname)s] %(asctime)s - %(message)s'
    logging.basicConfig(level=level, format=fmt)

    # set up model (TODO handle multiple models)
    global curr_model

    global client
    client = SimpleUDPClient(ip, port+1)  # Create client

    dispatch = dispatcher.Dispatcher()
    dispatch.map('/draw', draw, 'id')
    dispatch.map('/face', random_face, 'id')
    dispatch.map('/sin_osc', sin_osc, 'source_id' , 'point2_id', 'phase', 'amp')
    dispatch.map('/add', add, 'source_id', 'point1_id', 'point2_id')
    dispatch.map('/sub', sub, 'source_id', 'point1_id', 'point2_id')
    dispatch.map('/mul', mul, 'source_id', 'point1_id', 'scalar')
    dispatch.map('/div', div, 'source_id', 'point1_id', 'scalar')
    dispatch.map('/interpolate', interpolate, 'source_id', 'left_id', 'right_id', 'interp')
    dispatch.map('/make_latent/send', make_latent)
    dispatch.map('/load/*/send', load, 'model_name')
    dispatch.map('/latent/load/send', load_latent, 'filepath')
    dispatch.map('/latent/save', save_latent, 'source_id', 'filepath')
    dispatch.map('/rotate', rotate, 'angle')

    server = osc_server.AsyncIOOSCUDPServer(
        (ip, port), dispatch, asyncio.get_event_loop())
    transport, protocol = await server.create_serve_endpoint()

    logging.info('OSC server is loaded')

    await draw_loop(**vars(args))

    transport.close()
    print('shutting down...')

if __name__ == '__main__':
    asyncio.run(main())
