// basic example of interpolating between two faces

// destination host name
"localhost" => string hostname;
// destination port number
5005 => int port;

// check command line
if( me.args() ) me.arg(0) => hostname;
if( me.args() > 1 ) me.arg(1) => Std.atoi => port;

// sender object
OscOut xmit;

// aim the transmitter at destination
xmit.dest( hostname, port );

Blit s => JCRev r => dac;
// .5 => s.gain;
.1 => s.gain;
.05 => r.mix;

// an array
[ 0, 2, 4, 7, 9, 11 ] @=> int hi[];


xmit.start( "/make_noise" );
xmit.send();
xmit.start( "/make_noise" );
xmit.send();

-1.0 => float prevFreq;
// infinite time loop
while( true )
{
    // start the message...
    xmit.start( "/face" );
    0 => xmit.add;
    // send it
    xmit.send();

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
				updateSide();
				interpolate_step(360::ms);
    }
    else if (chance > 0.25) {
        120::ms => now;
    } else {
				updateSide();
				interpolate_step(180::ms);
        (240-180)::ms => now;
	  }
}

fun void updateSide() {
		// start the message...
		xmit.start( "/face" );
		1 => xmit.add;
		// send it
		xmit.send();
		// start the message...
		xmit.start( "/face" );
		2 => xmit.add;
		// send it
		xmit.send();				
}

fun void interpolate_step(dur d) {
		(1/24.0)::second => dur framerate;

		d / framerate => float frames;

		// Math.random2f(0.75, 3.0) => float magnitude;
		0.5 => float magnitude;

		now + d => time later;
		0 => float count;
		while (now < later) {
				(count / frames) * magnitude => float intp;

				xmit.start( "/interpolate" );
				// add int argument
				0 => xmit.add; // source
				1 => xmit.add; // left
				2 => xmit.add; // right
				// Math.sqrt(intp) => xmit.add;
				intp => xmit.add;

				xmit.send();

				if (intp < 0.1) {
						<<< 2 >>>;
						2 +=> count;
						2*framerate => now;
						// framerate => now;
				} else {
						<<< 1 >>>;
						1 +=> count;
						// 2*framerate => now;
						framerate => now;
				}
		}
}
