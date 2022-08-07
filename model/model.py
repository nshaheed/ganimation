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

## TODO abstract this to allow for subclasses for different models (stylegan, pgan, w/e)
class Model:
    model = None
    use_gpu = None
    device = None

    id_counter = 0
    latent = None

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
        result = result.rot90(1,[0,1])          # image needs to be rotated for some reason
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

    def sin_osc(self, source_id: int, point1_id: int, point2_id: int, phase: float = 0, amp: float = 1):
        n = self.latent[point1_id]
        n = amp * math.cos(phase) * n
        self.latent[source_id] = n

    def add(self, source_id: int, point1_id: int, point2_id: int):
        self.latent[source_id] = self.latent[point1_id] + self.latent[point2_id]

    def mul(self, source_id: int, point1_id: int, scalar: float):
        self.latent[source_id] = scalar * self.latent[point1_id]

    # save latent to file
    def save_latent(self, source_id: int, filepath: str):
        latent = self.latent[source_id].numpy()
        np.save(filepath, latent)

    # load latent from file
    def load_latent(self, filepath: str) -> int:
        loaded_latent = np.load(filepath)
        loaded_latent = torch.from_numpy(loaded_latent).to(self.device)
        return self.make_latent(arr=loaded_latent)


class StyleGAN3(Model):

    # latent = None
    model = None
    # device = None
    pkl = None
    render_obj = None
    render_args = None

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

        result = result.image.rot90(1,[0,1]).rot90(1,[0,1]) # image needs to be rotated for some reason
        result = np.asarray(result)

        return result
