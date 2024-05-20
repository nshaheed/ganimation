// basic example of interpolating between two latent points

StableDiffusion m;
// m.init();

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


0 => float intp;
0.1 => float speed;

//eon => now;
//30::second => now; // loading...
// infinite time loop
while( true )
{
    //m.face(draw);
    <<< "draw" >>>;
    //1::second => now;
    //continue;

    // frequency
    while (s.freq() == prevFreq) {
        Std.mtof( 33 + Math.random2(0,3) * 12 +
          hi[Math.random2(0,hi.size()-1)] ) => s.freq;
    }
    s.freq() => prevFreq;  

    // harmonics
    Math.random2( 1, 5 ) => s.harmonics;
    
    Math.randomf() => float chance;


    m.interpolate(draw, left, right, intp);

    speed +=> intp;

    if (Math.fabs(intp) > 1) {
        -1 *=> speed;
    }

    10::second => now;
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
