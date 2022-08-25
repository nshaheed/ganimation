// basic example of latent space oscillation

// seed
// Math.srandom(0);

(1/24.0)::second => dur framerate; // 24 fps

Model m;
m.init();

m.makeLatent() @=> Latent draw;
m.makeLatent() @=> Latent left;
m.makeLatent() @=> Latent right;
m.makeLatent() @=> Latent intp;

m.draw(draw);

m.face(left);
m.face(right);

spork~ rotate();
spork~ interpolate();
1::week => now;

fun void updateSide() {
    m.face(left);
    m.face(right);
}

fun void rotate() {
    SinOsc s => blackhole;
    SinOsc amp => blackhole;
    2.5 => s.freq;
    // 36.0*0.12 => s.freq;
    0.25 => amp.freq;
    0 => amp.gain;
    2 => float scale;
    // 0 => s.gain;
    // 1.0 => float scale;

    m.makeLatent() @=> Latent osc;
    m.makeLatent() @=> Latent sum;

    // draw @=> osc;
    now + 10::second => time then;
    while (now < then) {
        m.sinOsc(osc, left, s.last(), scale * (amp.last()+1.01));
        m.add(draw, intp, osc);
        // m.draw(osc);
        framerate => now;
    }
}

fun void interpolate() {
    0.0 => float pos;
    framerate / 10::second => float delta;
    

        while (pos <= 1) {
            m.interpolate(intp, left, right, pos);
            delta +=> pos;
            framerate => now;
        }
}
