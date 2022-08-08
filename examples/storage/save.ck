// This example demonstrate saving a point in latent space an .npy file.
// See load.py for how to load and display points.

StyleGAN m;
m.init(me.dir() + "../../local_models/stylegan3-r-afhqv2-512x512.pkl");

// need to delay a bit bc of ongoing issues with python-osc
1::second => now;

m.makeLatent() @=> Latent l;
<<< "latent made" >>>;

me.dir() + "here.npy" => string path;
m.saveLatent(l, path);

<<< "saved latent to", path >>>;

0.1::second => now; // need to drive at least 1 frame
