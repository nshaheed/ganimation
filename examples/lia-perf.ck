// basic example of interpolating between two faces

StyleGAN m;
m.init(me.dir() + "../../lia_models/Face-Hands_Lia-Coleman.pkl");

// init latents
m.makeLatent() @=> Latent draw;
m.makeLatent() @=> Latent left;
m.makeLatent() @=> Latent right;
m.makeLatent() @=> Latent intp;
m.makeLatent() @=> Latent noise;

m.makeLatent() @=> Latent rightNoise;

m.draw(draw);

(1/15.0)::second => dur framerate; // 24 fps

BlitSquare s => JCRev r => dac;
Blit b => Envelope e => r;
// .5 => s.gain;
.2 => s.gain;
// 0 => s.gain;
.4 => r.mix;

0.1 => b.gain;
3::second => e.duration;

0 => int envDir;

// an array of scale degrees
[ 0, 2, 4, 7, 9, 11 ] @=> int hi[];

-1.0 => float prevFreq;
// infinite time loop

BandedWG bwg => Pan2 pan => JCRev rev => dac;
3 => bwg.gain;

1.0 => float pos; // interpolate pos

m.face(left);
m.face(right);

// 2::second => now;

// m.add(draw, left, right);
// 2::second => now;

// m.add(draw, draw, left);
// 1::week => now;

0 => int maxOct;
0 => int minOct;

0 => int pluckStage;

spork~ rotate();
spork~ interpolate();
spork~ addNoise();
spork~ score();
// spork~ setRightNoise();
// 1::week => now;
while( true )
{
    m.face(right);

    if (pluckStage == 2) {
        if (pos < 0.1) {
            3 => minOct;
            3 => maxOct;
        } else if (pos < 0.33) {
            2 => minOct;
            3 => maxOct;
        } else if (pos < 0.5) {
            1 => minOct;
            3 => maxOct;
        }

        else if (pos < 0.66) {
            0 => minOct;
            3 => maxOct;
        } else {
            0 => minOct;
            2 => maxOct;
        }
    }

    
    // frequency
    while (s.freq() == prevFreq) {
        Std.mtof( 33 + Math.random2(minOct,maxOct) * 12 +
          hi[Math.random2(0,hi.size()-1)] ) => s.freq;
    }
    s.freq() => prevFreq;

    if (pluckStage == 2 && minOct == 3) {
        e.keyOn();
        Std.mtof( 33 + Math.random2(minOct,maxOct) * 12 +
        hi[Math.random2(0,hi.size()-1)] ) => b.freq;

        // harmonics
        // Math.random2( 1, 5 ) => b.harmonics;
    } else if (minOct == 1) {
        if (envDir == 0) {
            e.keyOn();
        } else {
            e.keyOff();
        }
    }

    // harmonics
    Math.random2( 1, 5 ) => s.harmonics;
    
    Math.randomf() => float chance;
    if (chance > 0.25) {
        120::ms => now;
        if (pluckStage == 1) {
            bwg.pluck(1.0);
        }
    } else {
        // updateSide();
        if (pluckStage == 2) {
            if (Math.randomf() >= 0.5) {
                120::ms => now;
                bwg.pluck(1.0);
                120::ms => now;
                bwg.pluck(1.0);
            } else {
                240::ms => now;
                bwg.pluck(1.0);
            }
        } else {
            240::ms => now;
        }

        if (pluckStage == 0) {
            bwg.pluck(1.0);
        }
    }
}

fun void score() {
    <<< "enter score" >>>;
    // 20::second => now;
    // 1 => maxOct;

    // 20::second => now;
    // 2 => maxOct;
    // 1 => pluckStage;

    // 20::second => now;
    // 3 => maxOct;
    2 => pluckStage;
}

fun void setRightNoise() {
    while(true) {
        m.face(right);
        // 1::second => now;
    }
    // 0.01 => float amt;
    // while(true) {
    //     m.face(rightNoise);
    //     m.mul(rightNoise, rightNoise, amt);

    //     m.add(right, right, rightNoise);
    //     3 * m.framerate => now;

    //     0.01 +=> amt;
    //     <<< amt >>>;
    // }
}

fun void updateSide() {
    m.face(left);
    m.face(right);
}

fun void rotate() {
    SinOsc s => blackhole;
    SinOsc amp => blackhole;

    36.0*0.12 => s.freq;
    0.25 => amp.freq;
    1 => amp.gain;
    2 => float scale;

    m.makeLatent() @=> Latent osc;

    0 => int counter;
    while (true) {
        if (counter % 2 == 0) {
            m.sinOsc(osc, left, s.last(), scale * (amp.last()+1.01));
        }
        m.add(draw, intp, osc);
        m.add(draw, draw, noise);
        1 +=> counter;
        m.framerate => now;
    }
}

fun void interpolate() {
    m.framerate / 15::second => float delta;
    
    while (true) {

        while (pos <= 1) {
            // <<< "pos", pos >>>;
            m.interpolate(intp, left, right, pos);
            delta +=> pos;
            m.framerate => now;
        }

        while (pos >= 0) {
            // <<< "pos", pos >>>;
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
        // m.add(draw, draw, noise);
        
        // 3 * m.framerate => now;
        120::ms => now;
    }
}
