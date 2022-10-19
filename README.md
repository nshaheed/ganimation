[toc]

TODO: embed video of mirror with caption

# What is GANimator?
# Installing
## Requirements
- Windows 10/11
- The latest version of the [ChucK programming language](https://chuck.stanford.edu/)
- A newish, CUDA-compatible GPU (i.e. nvidia GTX 1000-series or later). Running GANs is computationally expensive and hardware acceleration on the newer nvidia chips helps a lot.
## Installation Instructions
- Go to the Releases page and click on the provided link in the description (NOT the zip of the source code). It will be in the format `ganimator-X.X.X.zip'.
- Unzip this a known location.

## Installing for Development
- make sure conda/anaconda is installed
- install cuda toolkit
- make a new conda environment
- activate conda environment
- git clone
- cd to dir
- conda call to install pip environment
- run `python ganimator.py`

### installing PyOpenGL (for windows at least)
- don't install the one on conda/pip
- download the relevant binary linked to [here](https://stackoverflow.com/questions/59725675/need-to-install-pyopengl-windows) (i.e. 39 is version 3.9) (note: the acclerate version doesn't seem to have GLUT?)
- run `pip install PyOpenGL-3.1.6---.whl`

# Using GANimator
GANimator has two parts: the ChucK library where you load models and interact with them, and the backend where the animation is
rendered and displayed.

## Launching the Backend
In order to run GANimator, you first launch the backend, and then run your chuck code. 
The backend is found in the downloaded release directory from the [Installation Instructions](#installation-instructions).
To run, launch `<downloaded dir>/ganimator.exe`. This will launch the backend, displaying this window:

![image](https://user-images.githubusercontent.com/6963603/196762448-2a2c46c0-0a57-496a-8f95-e1489da2d671.png)

The different options are described in [Backend-Options](#backend-options). Click `Start` and you will see 
the message `Waiting for model load` in the text console. Loading the model and interacting with it is done
in chuck, as described in [Hello GAN](#hello-gan) and [Example](#examples). For even more info about what you can do,
check out the documentation below, and look at the examples found in `<downloaded dir>/chuck/examples/`.

## Importing Files in ChucK
## Examples
### Hello GAN
### Randomization
### Interpolation
### Arithmetic
### Oscillation
## Supported GAN frameworks
### PGan
### StyleGAN2 & StyleGAN3
## Methods
## Backend Options
