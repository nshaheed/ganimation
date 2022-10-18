# What is GANimator?
# Installing
## Requirements
- Windows 10/11
- The latest version of the [ChucK programming language](https://chuck.stanford.edu/)
- A newish, CUDA-compatible GPU (i.e. NVIDIA 1000-series or later)
## Installation Instructions
- go to the releases page and click on the provided link (it will be in the format `ganimator-X.X.X.zip')
- download source code zip as well
- unzip both of these to a known directory

## Installing for Development
- make sure conda/anaconda is installed
- install cuda toolkit
- make a new conda environment
- activate conda environment
- git clone
- cd to dir
- conda call to install pip environment
- run `python ganimator.py`

## installing PyOpenGL (for windows at least)
- don't install the one on conda/pip
- download the relevant binary linked to [here](https://stackoverflow.com/questions/59725675/need-to-install-pyopengl-windows) (i.e. 39 is version 3.9) (note: the acclerate version doesn't seem to have GLUT?)
- run `pip install PyOpenGL-3.1.6---.whl`

# Using GANimator
GANimator has two parts: the ChucK library where you load models to
manipulate the latent space, and the backend where the animation is
rendered.

The backend is found in the downloaded release directory from the [Installation Instructions](#installation-instructions).
## Hello GAN
## Examples
## Supported GAN frameworks
### PGan
### StyleGAN2 & StyleGAN3
## Methods
