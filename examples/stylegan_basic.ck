// Randomly generate faces to the beat of blit

// Load default celebAHQ-512 model
StyleGAN m;
// m.init(me.dir() + "../local_models/stylegan3-r-afhqv2-512x512.pkl");
m.init(me.dir() + "../local_models/lia1.pkl");

<<< "model initialized" >>>;

m.makeLatent() @=> Latent @ l;
m.draw(l);

// Blit s => JCRev r => dac;
// .5 => s.gain;
// .05 => r.mix;

// // an array
// [ 0, 2, 4, 7, 9, 11 ] @=> int hi[];


// // infinite time loop
// while( true )
// {
//     m.face(l);

//     // frequency
//     Std.mtof( 33 + Math.random2(0,3) * 12 +
//         hi[Math.random2(0,hi.size()-1)] ) => s.freq;

//     // harmonics
//     Math.random2( 1, 5 ) => s.harmonics;
    
//     Math.randomf() => float chance;

//     if (chance > 0.95) {
//         360::ms => now;
//     }
//     else if (chance > 0.25) {
//         120::ms => now;
//     } else {
//         240::ms => now;
//     }
// }
