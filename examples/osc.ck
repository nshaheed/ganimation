// basic example of latent space oscillation

// seed
// Math.srandom(0);

Model m;
m.makeLatent() @=> Latent draw;
m.makeLatent() @=> Latent left;
m.makeLatent() @=> Latent right;

m.draw(draw);

Blit s => JCRev r => dac;
// .5 => s.gain;
// .5 => s.gain;
0 => s.gain;
.05 => r.mix;

// an array of scale degrees
[ 0, 2, 4, 7, 9, 11 ] @=> int hi[];

-1.0 => float prevFreq;
// infinite time loop

spork~ rotate();
1::week => now;
while( true )
{
    m.face(draw);

    // frequency
    while (s.freq() == prevFreq) {
        Std.mtof( 33 + Math.random2(0,3) * 12 +
          hi[Math.random2(0,hi.size()-1)] ) => s.freq;
    }
    s.freq() => prevFreq;  

    // harmonics
    Math.random2( 1, 5 ) => s.harmonics;
    
    Math.randomf() => float chance;
    if (chance > 0.25) {
        120::ms => now;
    } else {
        (240-180)::ms => now;
    }
}

fun void rotate() {
    (1/24.0)::second => dur framerate; // 24 fps

    SinOsc s => blackhole;
    SinOsc amp => blackhole;
    3 => s.freq;
    0.1 => amp.freq;
    0.00005 => float scale;


    while (true) {
        m.sinOsc(draw, left, right, s.last(), scale * (amp.last()+1.01));
        framerate => now;
    }
}
