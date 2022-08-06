// basic example of interpolating between two faces

StyleGAN m;
// m.init(me.dir() + "../local_models/stylegan3-r-afhqv2-512x512.pkl");
// m.init(me.dir() + "../local_models/lia1.pkl");
m.init(me.dir() + "../../lia_models/Face-Hands_Lia-Coleman.pkl");

// 1::second / 15.0 => m.framerate;

m.makeLatent() @=> Latent draw;
m.makeLatent() @=> Latent left;
m.makeLatent() @=> Latent right;
m.makeLatent() @=> Latent intp;
m.makeLatent() @=> Latent noise;

m.draw(draw);

(1/15.0)::second => dur framerate; // 24 fps

Blit s => JCRev r => dac;
// .5 => s.gain;
.5 => s.gain;
// 0 => s.gain;
.05 => r.mix;

// an array of scale degrees
[ 0, 2, 4, 7, 9, 11 ] @=> int hi[];

-1.0 => float prevFreq;
// infinite time loop

m.face(left);
m.face(right);

// 2::second => now;

// m.add(draw, left, right);
// 2::second => now;

// m.add(draw, draw, left);
// 1::week => now;

spork~ rotate();
spork~ interpolate();
spork~ addNoise();
// 1::week => now;
while( true )
{
    m.face(right);
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
        // updateSide();
        240::ms => now;
    }
}

fun void updateSide() {
    m.face(left);
    m.face(right);
}

fun void rotate() {
    SinOsc s => blackhole;
    SinOsc amp => blackhole;
    // 2.5 => s.freq;
    36.0*0.12 => s.freq;
    0.25 => amp.freq;
    1 => amp.gain;
    2 => float scale;
    // 1.0 => float scale;

    m.makeLatent() @=> Latent osc;
    m.makeLatent() @=> Latent sum;

    // draw @=> osc;

    0 => int counter;
    while (true) {
        if (counter % 2 == 0) {
            m.sinOsc(osc, left, right, s.last(), scale * (amp.last()+1.01));
        }
        m.add(draw, intp, osc);
        // m.draw(osc);
        1 +=> counter;
        m.framerate => now;
    }
}

fun void interpolate() {
    0.0 => float pos;
    m.framerate / 10::second => float delta;
    

    while(true) {
        while (pos <= 1) {
            m.interpolate(intp, left, right, pos);
            delta +=> pos;
            m.framerate => now;
        }

        while (pos >= 0) {
            m.interpolate(intp, left, right, pos);
            delta -=> pos;
            m.framerate => now;
        }
    }
}

fun void addNoise() {
    while (true) {
        m.face(noise);
        m.mul(noise, noise, 0.05);
        m.add(draw, draw, noise);
        
        1 * m.framerate => now;
    }
}
