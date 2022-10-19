// Hello GAN! This is the simplest thing you can do 
// in GANimator: declare a model and tell it to display
// an image.

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
