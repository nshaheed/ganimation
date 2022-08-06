// This example demonstrate saving a point in latent space an .npy file.
// See load.py for how to load and display points.

StyleGAN m;
m.init(me.dir() + "../../local_models/stylegan3-r-afhqv2-512x512.pkl");

m.makeLatent() @=> Latent l;

me.dir() + "here.npy" => string path;
m.saveLatent(l, path);

<<< "saved latent to", path >>>;

1::second => now; // need to drive at least 1 frame
