// basic example of interpolating between two faces

StyleGAN m;
m.init(me.dir() + "../local_models/stylegan3-r-afhqv2-512x512.pkl");
// m.init(me.dir() + "../local_models/lia1.pkl");
// m.init(me.dir() + "../../lia_models/Face-Hands_Lia-Coleman.pkl");

m.makeLatent() @=> Latent draw;
m.makeLatent() @=> Latent left;
m.makeLatent() @=> Latent right;

m.draw(draw);

Blit s => JCRev r => dac;
// .5 => s.gain;
.5 => s.gain;
.05 => r.mix;

// an array of scale degrees
[ 0, 2, 4, 7, 9, 11 ] @=> int hi[];

-1.0 => float prevFreq;


0.1 => float increment;
0 => float intp;
// infinite time loop
while( true )
{
    // m.face(draw);

    // frequency
    while (s.freq() == prevFreq) {
        Std.mtof( 33 + Math.random2(0,3) * 12 +
          hi[Math.random2(0,hi.size()-1)] ) => s.freq;
    }
    s.freq() => prevFreq;

    // harmonics
    Math.random2( 1, 5 ) => s.harmonics;

    Math.randomf() => float chance;
    if (chance > 0.95) {
        // updateSide();
        // interpolate_step(5200::ms, s.harmonics());
    } else if (chance > 0.25) {
        120::ms => now;
    } else {
        // updateSide();
        // interpolate_step(2400::ms, s.harmonics());
        // (2400-180)::ms => now;
    }

    m.interpolate(draw, left, right, intp);
    increment +=> intp;
    5::second => now;
}

fun void updateSide() {
    m.face(left);
    m.face(right);
}

fun void interpolate_step(dur d, int nharms) {
    (1/24.0)::second => dur framerate; // 24 fps

    d / framerate => float frames;

    0.7 + (nharms * 0.2) => float magnitude;

    now + d => time later;
    0 => float count;
    while (now < later) {
        (count / frames) * magnitude => float intp;

        m.interpolate(draw, left, right, intp);

        if (intp < 0.1) {
            2 +=> count;
            2*framerate => now;
            // framerate => now;
        } else {
            1 +=> count;
            // 2*framerate => now;
            framerate => now;
        }
    }
}
