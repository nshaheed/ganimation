import numpy
from tqdm.auto import tqdm

import torch
from torch import autocast
# from torchvision import transforms as tfms

from transformers import CLIPTextModel, CLIPTokenizer
from diffusers import StableDiffusionPipeline

from PIL import Image
from matplotlib import pyplot as plt

import numpy as np

# For video display:
#from IPython.display import HTML
#from base64 import b64encode

# For interactive notebook
#import ipywidgets as widgets#
#from ipywidgets import interact, interact_manual

# Set device - Make sure to set the runtime to GPU in the Kaggle Notebook !
torch_device = "cuda" if torch.cuda.is_available() else "cpu"
print(torch_device)


# Use the scheduler in stableDiff pipeline
# scheduler = LMSDiscreteScheduler(beta_start=0.00085, beta_end=0.012, beta_schedule="scaled_linear", num_train_timesteps=1000)
stable_diff_pipe = StableDiffusionPipeline.from_pretrained('CompVis/stable-diffusion-v1-4')

stable_diff_pipe.to(torch_device)

prompt = ['A cozy campfire']   # Change this and Enjoy !!
guidance_scale = 12.5

# Change the seed parameter to create an original image each time.
generator = torch.manual_seed(69)    # Nice !

# Loop
with autocast("cuda"):
    image = stable_diff_pipe(prompt, guidance_scale = guidance_scale, num_inference_steps = 12).images[0]

# breakpoint()
print(f'{type(image)}')

image.show()

pix = np.array(image)
breakpoint()
