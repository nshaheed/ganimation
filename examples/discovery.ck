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

1::second => now;

// make a ConsoleInput
ConsoleInput in;

fun void savePrompt(Latent l) {
    me.dir() + "/points/" => string filepath;
    
    // prompt
    in.prompt( "enter line of text:" ) => now;

    in.getLine() => string filename;

    if (filename == "") { return; }

    filepath + filename + ".npy" => filepath;

    m.saveLatent(l, filepath);
}

while (true) {

    hi => now;
    <<< "got kbd input"  >>>;

    // get one or more messages
    while( hi.recv( msg ) )
    {
        // check for action type
        if( msg.isButtonDown() )
        {
            <<< "down:", msg.which, "(code)", msg.key, "(usb key)", msg.ascii, "(ascii)" >>>;

            if (msg.which == 57) { // space bar
                m.face(l);
            }
            if (msg.which == 31) { // s key for save
                savePrompt(l);
            }
        }

        else
        {
            //<<< "up:", msg.which, "(code)", msg.key, "(usb key)", msg.ascii, "(ascii)" >>>;
        }
    }
    // 0.1::second => now;
}


