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

Envelope masterLeft => dac.left;
Envelope masterRight => dac.right;
1.0 => masterLeft.value => masterRight.value;
10::ms => masterLeft.duration => masterRight.duration;

BlitSquare s => JCRev r => masterLeft;
r => masterRight;
// Blit b => Envelope e1 => Pan2 bPan => Envelope e => GVerb g => master;
Blit b => Envelope e1 => Pan2 bPan;
GVerb g;
g.chan(0) => masterLeft;
g.chan(1) => masterRight;
Envelope eLeft => g.chan(0);
Envelope eRight => g.chan(1);
bPan.left => eLeft;
bPan.right => eRight;

Blit b2 => Envelope e2 => eLeft;
e2 => eRight;

// 0 => r.gain => e1.gain => e2.gain;

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
3::second => eLeft.duration => eRight.duration;

0 => int envDir;
0.9 => float minPos;
1.0 => float maxPos;

// an array of scale degrees
[ 0, 2, 4, 7, 9, 11 ] @=> int hi[];

-1.0 => float prevFreq;
-1.0 => float prevFreqB;
// infinite time loop

BandedWG bwg => Gain gain => Pan2 pan => JCRev rev => master;

BandedWG bwg2 => gain;

1 => gain.gain;
0.8 => bwg.gain;
0.2 => bwg2.gain;

0.3 => rev.mix;

1.0 => float pos; // interpolate pos

m.face(right);

0.99 => float maxOct;
0 => int minOct;

0 => int pluckStage;

1.0 => float doubleTime;

// manage track recordings
// if (rec) {
//     s   => WvOut2 blitSquare => blackhole;
//     e   => WvOut2 blits      => blackhole;
//     pan => WvOut2 perc       => blackhole;

//     // auto adds datetime to filename
//     "special:auto" => blitSquare.wavFilename => blits.wavFilename => perc.wavFilename;

//     // prefix filename with stem name
//     "blitSquare" => blitSquare.autoPrefix;
//     "blits" => blits.autoPrefix;
//     "perc" => perc.autoPrefix;

//     // needed to close file atm
//     null @=> blitSquare => blits => perc;
// }

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
        if (pluckStage == 2) {
            if (chance > 0.9) {
                spork~ auxPercSeq();
            }

            120::ms => now;
        } else {
            120::ms => now;
        }

        if (pluckStage == 1 || pluckStage == 2) {
            bwg.pluck(1.0);
        }

        if (pluckStage == 2) {
            spork~ auxPerc();
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
                spork~ auxPerc();
                m.face(right);
                120::ms => now;
                Math.random2f( .7, .9 ) => bwg2.pluck;
                Math.random2f( .7, 1 ) => bwg.pluck;
                spork~ auxPerc();
            } else {
                240*doubleTime::ms => now;
                Math.random2f( .7, 1 ) => bwg.pluck;
            }

        } else {
            240*doubleTime::ms => now;
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

            if (e1Flag & eLeft.value() != 0.0) {
                currPos - 1 => currPos;
            }

            m.interpolate(intp, left, right, currPos);
            delta +=> pos;
            m.framerate => now;
        }

        0.01::second => now;

        while (pos >= 0.0) {
            scale(0, 1, minPos, maxPos, pos) => float currPos;

            if (e1Flag && eLeft.value() != 0.0) {
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
                if (eLeft.value() == 0.0) {
                    eLeft.keyOn();
                    eRight.keyOn();
                }

                if (eLeft.value() == 1.0) {
                    eLeft.keyOff();
                    eRight.keyOff();
                }
            }

            if (msg.data2 == 42 && msg.data3 > 0) { // go into double time (TODO map to button)
                if (doubleTime == 1.0) {
                   0.5 => doubleTime;
                } else {
                   1.0 => doubleTime;
                }
            }

            if (msg.data2 == 77) { // adjust volume of global beat
                scale(0, 127, 0.0, 1.0, msg.data3) => master.target;
                master.keyOn();
            }
        }
    }
}

fun void auxPerc() {
    if (doubleTime == 1.0) return;

    ModalBar bar => LPF lpf => Pan2 barPan => GVerb gverb;
    gverb.chan(0) => eLeft;
    gverb.chan(1) => eRight;
    
    800 * 4 => lpf.freq;
    Math.random2f(0.4, 0.8) => barPan.pan;
    // 1 => barPan.pan;
    // e => dac;

    if (Math.randomf() > 0.5) {
        -1.0 * barPan.pan() => barPan.pan;
    }
    
    // ModalBar bar => gain;

    [1, 2, 3, 5] @=> int presets[];
    presets[Math.random2(0,presets.size()-1)] => bar.preset;
    3 => bar.preset;

    Math.random2f( 0, 0.2 ) => bar.stickHardness;
    Math.random2f( 0, 0.2 ) => bar.strikePosition;
    Math.random2f( 0, 1 ) => bar.vibratoGain;
    Math.random2f( 0, 60 ) => bar.vibratoFreq;
    Math.random2f( 0, 1 ) => bar.volume;
    Math.random2f( .5, 1 ) => bar.directGain;
    // Math.random2f( .3, 0.6 ) => bar.masterGain;
    Math.random2f( .7, 1.0 ) => bar.masterGain;

    0.8 => bar.gain;

    // set freq
    // scale[Math.random2(0,scale.size()-1)] => int winner;
    // 57 + Math.random2(0,2)*12 + winner => Std.mtof => bar.freq;

    (Math.floor(maxOct)) $ int => int maxOctFloor;
    (Math.floor(scale(0, 1, 0, hi.size(), maxOct - maxOctFloor))) $ int => int scaleDeg;


    int currDeg;
    hi[Math.random2(0,scaleDeg)] => currDeg;
    // if (currOct >= 1 && currOct == maxOctFloor) {
    //     // limit scale degree options if it's the top octave
    //     hi[Math.random2(0,scaleDeg)] => currDeg;
    // } else {
    //     hi[Math.random2(0,hi.size()-1)] => currDeg;
    // }

    // 33 + scaleDeg => Std.mtof => bar.freq;
    33 + 36 + currDeg => Std.mtof => bar.freq;
    <<< "freq", bar.freq() >>>;
    // 20 => bar.freq;
    // go
    .8 => bar.noteOn;

    // advance time
    .5::second => now;
}

fun void auxPercSeq() {
     for (0 => int i; i < Math.random2(3,8); i++) {
        spork~ auxPerc();
        120::ms => now;
    }
}