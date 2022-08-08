// Explore the latent space && save interesting points to .npy files

StyleGAN m;

// choose a model to load up
// m.init(me.dir() + "../local_models/stylegan3-r-afhqv2-512x512.pkl");
m.init(me.dir() + "../../lia_models/Face-Hands_Lia-Coleman.pkl");


// basic goals
// - button to randomize latent
// - button to save point
// - prompt to give name to point to be saved
// - store in directory

// stretch
// buttons to control phase of lfo (left/right keys)


Hid hi;
HidMsg msg;

// which keyboard
0 => int device;

if( !hi.openKeyboard( device ) ) me.exit();
<<< "keyboard '" + hi.name() + "' ready", "" >>>;

1::second => now;

m.makeLatent() @=> Latent @ l; // the latent to be randomized
m.draw(l);

while (true) {
      // 1::second => now;
      hi => now;
      
      m.face(l);
}


