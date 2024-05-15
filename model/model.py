import logging
import math
import torch

# styleGAN-specific
import pickle
import dnnlib
import numpy as np
from viz import renderer

import sys
import legacy

# Stable Diffusion Specific
from transformers import CLIPTextModel, CLIPTokenizer
from diffusers import StableDiffusionPipeline

from PIL import Image


## TODO abstract this to allow for subclasses for different models (stylegan, pgan, w/e)
class Model:
    model = None
    use_gpu = None
    device = None

    id_counter = 0
    latent = None

    rotate = 0

    draw = None # which latent to draw

    def __init__(self):
        self.use_gpu = True if torch.cuda.is_available() else False
        self.latent = {}
        self.setDevice()

    def setDevice(self) -> None:
        self.device = 'cuda' if self.use_gpu else 'cpu'

    def load(self, model_name='celebAHQ-512'):
        """ load a specific model (needs more vars). """
        self.model = torch.hub.load('facebookresearch/pytorch_GAN_zoo:hub',
                               'PGAN', model_name=model_name,
                               pretrained=True, useGPU=self.use_gpu)

    def size(self) -> (int, int):
        """ return the height and width of the model. """
        if self.model is None:
            logging.error('attempted to get shape when no model is loaded')
            return None

        return self.model.getSize() # TODO: PGAN-specific, need to make a virtual method

    def generate_noise(self):
        noise, _ = self.model.buildNoiseData(1)
        return noise

    def make_latent(self, arr=None) -> int:
        """ Make a random latent and add to latent collection. """
        id = self.id_counter

        if arr is not None:
            self.latent[id] = arr
        else:
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
        result = result[0].clamp(min=-1, max=1) # chop off any vals not in (-1,1)
        result = result.transpose(0, 2)         # the channel dim should be last
        result = torch.add(result, 1)           # scale the image: (-1,1) -> (0,1)
        result = torch.div(result, 2)
        result = np.asarray(result)             # convert to numpy array to feed to texture

        return result

    def interpolate(self, source_id: int, left_id: int, right_id: int, interp: float) -> None:
        """ Linear interpolation between left and right latents. """
        self.latent[source_id] = self.latent[left_id] * interp + self.latent[right_id] * (1.0 - interp)

    def set_draw(self, source_id: int) -> None:
        """ Set which latent from the model to draw. """
        self.draw = source_id

    def sin_osc(self, source_id: int, point1_id: int, phase: float = 0, amp: float = 1):
        n = self.latent[point1_id]
        n = amp * math.cos(phase) * n
        self.latent[source_id] = n

    def add(self, source_id: int, point1_id: int, point2_id: int):
        self.latent[source_id] = self.latent[point1_id] + self.latent[point2_id]

    def sub(self, source_id: int, point1_id: int, point2_id: int):
        self.latent[source_id] = self.latent[point1_id] - self.latent[point2_id]

    def mul(self, source_id: int, point1_id: int, scalar: float):
        self.latent[source_id] = scalar * self.latent[point1_id]

    def div(self, source_id: int, point1_id: int, scalar: float):
        self.latent[source_id] = self.latent[point1_id] / scalar

    # save latent to file
    def save_latent(self, source_id: int, filepath: str):
        latent = self.latent[source_id].numpy()
        np.save(filepath, latent)

    # load latent from file
    def load_latent(self, filepath: str) -> int:
        loaded_latent = np.load(filepath)
        loaded_latent = torch.from_numpy(loaded_latent).to(self.device)
        return self.make_latent(arr=loaded_latent)

    def get_quad(self):
        """ Different models need to be rotated in different ways. Modify the positions values of quads to achieve this. """
        quad = None
        match self.rotate:
            case 0:
                #           positions    colors          texture coords
                quad = [    1,  1, 0.0,  1.0, 1.0, 1.0,  0.0, 0.0,
                            1, -1, 0.0,  1.0, 1.0, 1.0,  1.0, 0.0,
                           -1, -1, 0.0,  1.0, 1.0, 1.0,  1.0, 1.0,
                           -1,  1, 0.0,  1.0, 1.0, 1.0,  0.0, 1.0]
            case 90:
                #           positions    colors          texture coords
                quad = [    1, -1, 0.0,  1.0, 1.0, 1.0,  0.0, 0.0,
                           -1, -1, 0.0,  1.0, 1.0, 1.0,  1.0, 0.0,
                           -1,  1, 0.0,  1.0, 1.0, 1.0,  1.0, 1.0,
                            1,  1, 0.0,  1.0, 1.0, 1.0,  0.0, 1.0]
            case 180:
                #           positions    colors          texture coords
                quad = [   -1, -1, 0.0,  1.0, 1.0, 1.0,  0.0, 0.0,
                           -1,  1, 0.0,  1.0, 1.0, 1.0,  1.0, 0.0,
                            1,  1, 0.0,  1.0, 1.0, 1.0,  1.0, 1.0,
                            1, -1, 0.0,  1.0, 1.0, 1.0,  0.0, 1.0]
            case 270:
                #           positions    colors          texture coords
                quad = [   -1,  1, 0.0,  1.0, 1.0, 1.0,  0.0, 0.0,
                            1,  1, 0.0,  1.0, 1.0, 1.0,  1.0, 0.0,
                            1, -1, 0.0,  1.0, 1.0, 1.0,  1.0, 1.0,
                           -1, -1, 0.0,  1.0, 1.0, 1.0,  0.0, 1.0]
            case _:
                logging.error('wrong angle, must be one of {0, 90, 180, 270}')

        quad = np.array(quad, dtype = np.float32)
        return quad


class StyleGAN3(Model):

    # latent = None
    model = None
    # device = None
    pkl = None
    render_obj = None
    render_args = None

    rotate = 270

    def __init__(self):
        self.latent = {}
        self.setDevice()

    def load(self, pkl_address) -> None:
        self.render_args = dnnlib.EasyDict(
            pkl = pkl_address
        )
    
        self.render_obj = renderer.Renderer()
    
        # pre-load network
        self.model = self.render_obj.get_network(pkl_address, 'G_ema')
        self.make_image(self.make_latent())

    def size(self) -> (int, int):
        res = self.model.img_resolution
        return (res, res)

    # TODO currently only does the z latent space, need more
    # fine-grained control of this in w space
    def generate_noise(self):

        # TODO make setting seed an option
        # noise = torch.from_numpy(np.random.RandomState(seed).randn(1, self.model.z_dim)).to(device)
        noise = torch.from_numpy(np.random.RandomState().randn(1, self.model.z_dim)).to(self.device)
        return noise

    def make_image(self, id):
        self.render_args['latent'] = self.latent[id]
        result = self.render_obj.render(**self.render_args)

        result = result.image
        result = np.asarray(result)

        return result

class StableDiffusion(Model):

    model = None

    rotate = 0

    def __init__(self):
        self.use_gpu = True if torch.cuda.is_available() else False
        self.latent = {}
        self.setDevice()

    def load(self, model_address=''):
        self.model = StableDiffusionPipeline.from_pretrained('CompVis/stable-diffusion-v1-4')
        self.model.to(self.device)

    def size(self) -> (int, int):
        return (512,512) # this probably isn't guaranteed, will deal with later

    def generate_noise(self):
        pass

    def make_image(self, id):
        prompt = ['A cozy campfire'] 
        guidance_scale = 12.5
        with torch.autocast("cuda"):
            image = self.model(prompt, guidance_scale = guidance_scale, num_inference_steps = 1).images[0]

        pix = np.array(image)
        return pix
