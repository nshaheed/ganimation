// basic example of latent space oscillation

// seed
// Math.srandom(0);

(1/24.0)::second => dur framerate; // 24 fps

Model m;
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
// while( true )
// {
//     m.face(right);
//     // frequency
//     while (s.freq() == prevFreq) {
//         Std.mtof( 33 + Math.random2(0,3) * 12 +
//           hi[Math.random2(0,hi.size()-1)] ) => s.freq;
//     }
//     s.freq() => prevFreq;  

//     // harmonics
//     Math.random2( 1, 5 ) => s.harmonics;
    
//     Math.randomf() => float chance;
//     if (chance > 0.25) {
//         120::ms => now;
//     } else {
//         // updateSide();
//         240::ms => now;
//     }
// }

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
        m.sinOsc(osc, left, right, s.last(), scale * (amp.last()+1.01));
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

        // while (pos >= 0) {
        //     m.interpolate(intp, left, right, pos);
        //     delta -=> pos;
        //     framerate => now;
        // }
}
