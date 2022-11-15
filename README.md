


https://user-images.githubusercontent.com/6963603/197025085-78981ae8-6fb4-4599-9ad4-a67fcaa05088.mp4

GANimator being used in a live performance of *mirror* by Lia Coleman & Nick Shaheed. Full video [here](https://vimeo.com/762363875).

# What is GANimator?
GANimator is a tool for ChucK to create live, interactive animation using generative adversarial networks (GANs).
# Installing
## Requirements
- Windows 10/11
- The latest version of the [ChucK programming language](https://chuck.stanford.edu/)
- A newish, CUDA-compatible GPU (i.e. nvidia GTX 1000-series or later). Running GANs is computationally expensive and hardware acceleration on the newer nvidia chips helps a lot.
## Installation Instructions
- Go to the Releases page and click on the provided link in the description (NOT the zip of the source code). It will be in the format `ganimator-X.X.X.zip'.
- Unzip this a known location.

## Installing for Development
These instructions are still a work in progress!

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

## Setting up ChucK
Because chuck is weird about how it imports files, adding the GANimator classes to your chuck program is a bit convoluted.

Because chuck adds classes to the VM at runtime via `Machine.add`, if you try to add the GANimator classes from within your chuck
program, it will complain at compile-time because they haven't been added to the VM namespace yet. In order to make the classes
available you will need to add them in a separate program that you run before running your main script.

The separate chuck file for imports looks like this:

```
Machine.add(me.dir() + "latent.ck");
Machine.add(me.dir() + "model.ck");

# this is only needed if you're using StyleGAN
Machine.add(me.dir() + "StyleGAN.ck");

// Adding your chuck program will then launch your code.
// If you want to continue to modify your code/replace the spork, 
// don't include this line and instead launch the code separately in
// miniAudicle.
Machine.add(me.dir() + "mycode.ck"); 
```

If you're using miniAudicle, add a spork of this file first. It will import all the GANimator classes and add them to the namespace.
You can then launch your chuck code from here and the chuck VM will be able to compile!

Pay careful attention to where your chuck files are relative to the GANimator ones, and use relative imports when needed. An example of
this is in [this launch file](examples/basic_launch.ck).
## Examples
These examples (and more!) can be found in the `<downloaded dir>/chuck/examples/` directory as well as in this [git repo](/examples/).
Dig around for ideas and to get a better sense of how to use the tool
### Hello GAN
See [hello_gan.ck](/examples/hello_gan.ck) and [hello_gan_launch.ck](/examples/hello_gan_launch.ck)

Hello GAN! This is the simplest thing you can do 
in GANimator: declare a model and tell it to display
an image. 

```
// Declare our model and initialize it.
// Because no path to a model is provided,
// it defaults to a model based off of the
// celebAHQ-512 dataset.
Model m;
m.init();

// Initialize a point in latent space and store it in l
m.makeLatent() @=> Latent @ l;
// Draw l in the display window
m.draw(l);

10::second => now;
```
### Randomization

See [basic.ck](/examples/basic.ck) and [basic_launch.ck](/examples/basic_launch.ck).

Randomly generate new faces to a rhythm (with sound!).

[Video of output](https://vimeo.com/699255291/7ca1271ee2)

```

// Load default celebAHQ-512 model
Model m;
m.init();

// Create and draw a latent point
m.makeLatent() @=> Latent @ l;
m.draw(l);

// Make sound!
Blit s => JCRev r => dac;
.5 => s.gain;
.05 => r.mix;

// Our scale
[ 0, 2, 4, 7, 9, 11 ] @=> int hi[];


// infinite loop
while( true )
{
    // random point in l
    m.face(l);

    // frequency
    Std.mtof( 33 + Math.random2(0,3) * 12 +
        hi[Math.random2(0,hi.size()-1)] ) => s.freq;

    // harmonics
    Math.random2( 1, 5 ) => s.harmonics;
    
    // Randomize the rhythm
    Math.randomf() => float chance;
    if (chance > 0.95) {
        360::ms => now;
    }
    else if (chance > 0.25) {
        120::ms => now;
    } else {
        240::ms => now;
    }
}
```
### Interpolation
[Video!](https://vimeo.com/700907651/2978db3e39)

A more involved example of interpolation can be found at [interpolate.ck](/examples/interpolate.ck) and [interpolate_launch.ck](/examples/interpolate_launch.ck).

Smoothly interpolate between two latent points. This is the classic GAN effect that you probably know and love (or hate).

```
// initialize model
Model m;
m.init();

// make our latent points. We are interpolating from left to right.
m.makeLatent() @=> Latent draw;
m.makeLatent() @=> Latent left;
m.makeLatent() @=> Latent right;

// draw is the latent point that will be displayed
m.draw(draw);

0.0 => float intp;

while (intp < 1.0) {
    (1/24.0)::second => dur framerate; // 24 fps
    
    // interpolate by intp between left & right, 
    // storing interpolate value in draw. 
    m.interpolate(draw, left, right, intp);
    0.001 +=> intp;
    framerate => now;
}
```
## Supported GAN frameworks
The currently supported frameworks are StyleGAN2, StyleGAN3, and PGAN. The PGANs available are currently limited to a [few models provided by facebook research](model/model.py#L37-L39), but a StyleGAN model can be loaded from a local file. See the [Methods & Models](#methods--models) section below.
## Methods & Models
### Model
This is parent class `Model` and all of it's class methods. The parent class `Model` supports [these](https://github.com/facebookresearch/pytorch_GAN_zoo#load-a-pretrained-model-with-torchhub) pretrained PGAN models. See [StyleGAN](#stylegan) for differences between the `Model` and `StyleGAN` classes.

#### init
`fun void init()`

Loads the default model (which is `celebAHQ-512`).

`fun void init(string model_name)`

Loads any of [these](https://github.com/facebookresearch/pytorch_GAN_zoo#load-a-pretrained-model-with-torchhub) models.

StyleGAN allows for loading local model files, see [below](#stylegan) for more information.
#### makeLatent
`fun Latent@ makeLatent()`

Create a new Latent associated with the `Model`. What is returned is a reference to a randomized point in latent space.
#### draw
`fun void draw(Latent l)`

Specify which latent `l` to draw to the screen. As `l` is modified the screen will be updated. This is how animation happens.
#### face
`fun void face(Latent l)`

Set `l` to a random point in space. This should really be called `random`, but that hasn't been fixed yet.
#### interpolate
`void interpolate(Latent l, Latent left, Latent right, float scale)`

Linear interpolation between two points in latent space.

`left` and `right` are the two points to interpolate between. `scale` is the point on the interpolation to calculate, where `0` is left, `1` is right, `0.5` is halfway between `left` and `right`, and values outside of `0-1` are extrapolations. The caculated result is stored in `l`.

#### sinOsc
`fun void sinOsc(Latent source, Latent point1, float phase, float amp)`

Oscillated around a point with controllable `phase` and `amp`litude.

The oscillation is calculated around `point1`, and the result is stored in `source`.

See [examples/osc.ck](examples/osc.ck)
#### add
`fun void add(Latent source, Latent point1, Latent point2)`

Add `point1` and `point2`, storing the sum in `source`.
#### sub
`fun void sub(Latent source, Latent point1, Latent point2)`

Subtract `point2` from `point1`, storing the difference in `source`.

#### mul
`fun void mul(Latent source, Latent point1, float scalar)`

Multiply `point1` by a `scalar`, storing the product in `source`.

#### div
`fun void div(Latent source, Latent point1, float scalar)`

Diving `point1` by a `scalar`, storing the quotient in `source`.

#### loadLatent
`fun Latent@ loadLatent(string filepath)`

Load a latent point stored in a file. This should be a `.npy` file.
#### saveLatent
`fun void saveLatent(Latent l, string filepath)`

Save latent point `l` at `filepath`. This should be a `.npy` file.
#### rotate
`fun void rotate(int angle)`

Rotate the outputed image. `angle` can either be `0`, `90`, `180`, or `270`.
### StyleGAN
`StyleGAN` supports the same methods as `Model`. The only difference is when calling `init`, you provide a filepath to a StyleGAN2-ADA or StyleGAN3 model.
i.e. `styleGAN.init("dog_pic_gan.pkl")`

See [examples/stylegan_basic.ck](examples/stylegan_basic.ck) for a more detailed example.
### Latent
A `Latent` is a single point in latent space. This point will be the input to your provided GAN, where it will deterministically output an image. The manipulation of latent points over time is how GANimator creates animation.
## Backend Options
### debug
Enables debug-level logging.
### framerate
Displays the rendered framerate of the animation
### test
Recieve OSC messages from chuck, but do not render an image. This is faster/uses less power.
