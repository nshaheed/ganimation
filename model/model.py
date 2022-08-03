import torch
import logging

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

    vi = None
    vj = None

    draw = None # which latent to draw

    def __init__(self):
        self.use_gpu = True if torch.cuda.is_available() else False
        self.latent = {}

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
        # result = torchvision.transforms.functional.resize(result, (512,512))

        # print(f'{result = }, {result.shape = }')
        return result

    def interpolate(self, source_id: int, left_id: int, right_id: int, interp: float) -> None:
        """ Linear interpolation between left and right latents. """
        self.latent[source_id] = self.latent[left_id] * interp + self.latent[right_id] * (1.0 - interp)

    def set_draw(self, source_id: int) -> None:
        """ Set which latent from the model to draw. """
        self.draw = source_id

    def sin_osc(self, source_id: int, point1_id: int, point2_id: int, phase: float = 0, amp: float = 1):
        # get angle vector
        n = self.latent[point2_id] - self.latent[point1_id]
        # TODO: make this a class method for model
        n = torch.squeeze(n[:,:3])
        n = torch.nn.functional.normalize(n, dim=0) # normalize

        # TODO generalize this and make additive
        if self.vi is None or self.vj is None:
            self.vi = torch.randn(3, device=self.device)
            self.vj = torch.cross(n, self.vi, dim=0)


        # do the rotation and scale properly
        result = amp * (math.cos(phase)*self.vi + math.sin(phase)*self.vj)
        result = torch.cat((result, torch.zeros(512-3, device=self.device)))
        result = torch.unsqueeze(result, 0)

        self.latent[source_id] = result

    def add(self, source_id: int, point1_id: int, point2_id: int):
        self.latent[source_id] = self.latent[point1_id] + self.latent[point2_id]

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
        result = self.render_obj.render(**self.render_args)

        return result.image
