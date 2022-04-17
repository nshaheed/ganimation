// Randomly generate faces to the beat of blit

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
.5 => s.gain;
.05 => r.mix;

// an array
[ 0, 2, 4, 7, 9, 11 ] @=> int hi[];


// infinite time loop
while( true )
{
    // start the message...
    xmit.start( "/face" );
    
    // add int argument
    // Math.random2( 30, 80 ) => xmit.add;
    // add float argument
    // Math.random2f( .1, .5 ) => xmit.add;
    
    // send it
    xmit.send();
    <<< "sent" >>>;

    // frequency
    Std.mtof( 33 + Math.random2(0,3) * 12 +
        hi[Math.random2(0,hi.size()-1)] ) => s.freq;

    // harmonics
    Math.random2( 1, 5 ) => s.harmonics;
    
    Math.randomf() => float chance;
    
    if (chance > 0.95) {
        360::ms => now;
    }
    else if (chance > 0.25) {
        120::ms => now;
    } else {
        240::ms => now;
    }
}
