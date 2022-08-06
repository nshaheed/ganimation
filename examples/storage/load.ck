// This example demonstrate loading a saved point in latent space, saved to an .npy file.
// See save.py for how to save points.

StyleGAN m;
m.init(me.dir() + "../../local_models/stylegan3-r-afhqv2-512x512.pkl");

me.dir() + "here.npy" => string path;
m.loadLatent(path) @=> Latent l;

m.draw(l);

1::week => now;