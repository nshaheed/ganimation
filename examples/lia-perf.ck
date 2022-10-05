// perf of face-hands with lia coleman's model

// set up args
false => int rec;
for (int i; i < me.args(); i++) {
    if (me.arg(i) == "rec") {
        true => rec;
    }
}

// set up latents
StyleGAN m;
true => m.headless;
m.init(me.dir() + "../../lia_models/Face-Hands_Lia-Coleman.pkl");
m.rotate(180);

// init latents
m.makeLatent() @=> Latent draw;
m.loadLatent(me.dir() + "/points/hands_covering_face.npy") @=> Latent left;
// m.makeLatent() @=> Latent left;
m.makeLatent() @=> Latent right;
m.makeLatent() @=> Latent intp;
m.makeLatent() @=> Latent noise;

m.makeLatent() @=> Latent rightNoise;

m.draw(draw);

(1/15.0)::second => dur framerate; // 24 fps

// set up signal graph
Envelope master => dac;
1.0 => master.value;
10::ms => master.duration;

BlitSquare s => JCRev r => master;
Blit b => Envelope e1 => Pan2 bPan => Envelope e => GVerb g => master;
Blit b2 => Envelope e2 => e;

64 => Std.mtof => b.freq => b2.freq;

3 => b2.harmonics;

0 => e1.value;
1 => e2.value;

5::second => e1.duration => e2.duration;


// .5 => s.gain;
.2 => s.gain;
// 0 => s.gain;
.4 => r.mix;

0.2 => b.gain;
0.1 => b2.gain;
3::second => e.duration;

0 => int envDir;
0.9 => float minPos;
1.0 => float maxPos;

// an array of scale degrees
[ 0, 2, 4, 7, 9, 11 ] @=> int hi[];

-1.0 => float prevFreq;
-1.0 => float prevFreqB;
// infinite time loop

BandedWG bwg => Gain gain => Pan2 pan => JCRev rev => master;
1 => gain.gain;
1 => bwg.gain;
0.3 => rev.mix;

1.0 => float pos; // interpolate pos

m.face(right);

0.99 => float maxOct;
0 => int minOct;

0 => int pluckStage;

// manage track recordings
if (rec) {
    s   => WvOut2 blitSquare => blackhole;
    e   => WvOut2 blits      => blackhole;
    pan => WvOut2 perc       => blackhole;

    // auto adds datetime to filename
    "special:auto" => blitSquare.wavFilename => blits.wavFilename => perc.wavFilename;

    // prefix filename with stem name
    "blitSquare" => blitSquare.autoPrefix;
    "blits" => blits.autoPrefix;
    "perc" => perc.autoPrefix;

    // needed to close file atm
    null @=> blitSquare => blits => perc;
}

spork~ rotate();
spork~ interpolate();
spork~ addNoise();
spork~ manageMidi();

true => int e1Flag;
while( true )
{
    m.face(right);

    if (maxOct > 3.17) {
        3 => minOct;
        2 => pluckStage;
    } else if (maxOct > 2.17) {
        0 => minOct;
        1 => pluckStage;
    } else {
        0 => minOct;
        0 => pluckStage;
    }

    (Math.floor(maxOct)) $ int => int maxOctFloor;
    (Math.floor(scale(0, 1, 0, hi.size(), maxOct - maxOctFloor))) $ int => int scaleDeg;

    // frequency
    while (s.freq() == prevFreq) {
        Math.random2(minOct,maxOctFloor) => int currOct;

        int currDeg;
        if (currOct >= 1 && currOct == maxOctFloor) {
            // limit scale degree options if it's the top octave
            hi[Math.random2(0,scaleDeg)] => currDeg;
        } else {
            hi[Math.random2(0,hi.size()-1)] => currDeg;
        }

        Std.mtof( 33 + currOct * 12 + currDeg ) => s.freq;
        
    }
    s.freq() => prevFreq;

    if (pluckStage == 2 && minOct == 3) {
        true => e1Flag;
        1::second => e1.duration => e2.duration;
        e1.keyOn();
        while (b.freq() == prevFreqB) {
            Std.mtof( 33 + Math.random2(minOct,maxOctFloor) * 12 +
            hi[Math.random2(0,hi.size()-1)] ) => b.freq;
            (b.freq() / 2.0) + 0.1 => b2.freq;

            // harmonics
            0 => b.harmonics;
            Math.random2f(-0.5, 0.5) => bPan.pan;
        }
        b.freq() => prevFreqB;
    } else {
        if (e1Flag) {
            5::second => e1.duration => e2.duration;
            <<< "hit e1 flag" >>>;
            e1.keyOff();
            e2.keyOn();

            false => e1Flag;
        }
    }

    // harmonics
    Math.random2( 1, 5 ) => s.harmonics;

    3 => gain.gain;
    
    Math.randomf() => float chance;
    if (chance > 0.25) {
        120::ms => now;
        if (pluckStage == 1) {
            bwg.pluck(1.0);
        }
    } else {
        if (pluckStage == 2) {
            float odds;
            if (e1Flag) {
                1 => odds;
                9 => gain.gain;
            } else {
                Math.randomf() => odds;
            }
            
            if (odds >= 0.5) {
                120::ms => now;
                Math.random2f( .7, 1 ) => bwg.pluck;
                m.face(right);
                120::ms => now;
                Math.random2f( .7, 1 ) => bwg.pluck;
            } else {
                240::ms => now;
                Math.random2f( .7, 1 ) => bwg.pluck;
            }
        } else {
            240::ms => now;
        }

        if (pluckStage == 0) {
            Math.random2f( .7, 1 ) => bwg.pluck;
        }
    }
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
            scale(0, 1, minPos, maxPos, pos) => float currPos;

            if (e1Flag & e.value() != 0.0) {
                currPos - 1 => currPos;
            }

            m.interpolate(intp, left, right, currPos);
            delta +=> pos;
            m.framerate => now;
        }

        0.01::second => now;

        while (pos >= 0.0) {
            scale(0, 1, minPos, maxPos, pos) => float currPos;

            if (e1Flag && e.value() != 0.0) {
                currPos - 1 => currPos;
            }
            m.interpolate(intp, left, right, currPos);

            delta -=> pos;
            m.framerate => now;
        }
    }
}

fun void addNoise() {
    while (true) {
        m.face(noise);
        m.mul(noise, noise, 0.05);
        120::ms => now;
    }
}

fun float scale(float inMin, float inMax, float outMin, float outMax, float val) {
    (val - inMin) / (inMax - inMin) => float inProportion;
    ((outMax - outMin) * inProportion) + outMin => float outVal;

    return outVal;
}

fun void manageMidi() {
    MidiIn in;
    "Launch Control XL" => string device;

    // open midi receiver, exit on fail
    if ( !in.open(device) ) {
        <<< "Failed to open MIDI device" >>>;
        me.exit();
    }

    MidiMsg msg;

    while(true) {
        in => now;

        // receive midimsg(s)
        while( in.recv( msg ) )
        {
            // print content
            <<< msg.data1, msg.data2, msg.data3 >>>;

            if (msg.data2 == 13) { // control range of s
                scale(0, 127, 0.99, 3.99, msg.data3) => maxOct;

                scale(0, 127, 1.0, 0.4, msg.data3) => maxPos;
                scale(0, 127, 0.9, 0.0, msg.data3) => minPos;
            }

            if (msg.data2 == 41 && msg.data3 > 0) { // hit the blit env
                if (e.value() == 0.0) {
                    e.keyOn();
                }

                if (e.value() == 1.0) {
                    e.keyOff();
                }
            }

            if (msg.data2 == 77) { // adjust volume of global beat
                scale(0, 127, 0.0, 1.0, msg.data3) => master.target;
                master.keyOn();
            }
        }
    }
}
