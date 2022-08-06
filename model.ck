public class Model {
    // a specific instantiation of a GAN model

    // latent spaces
    Latent @ latents[0];

    int id;

    1::second / 24.0 => dur framerate;

    // osc stuff
    "localhost" => string hostname;

    5005 => int sendPort;
    5006 => int recvPort;

    OscIn in;
    OscSend out;
    OscMsg msg;

    recvPort => in.port;
    out.setHost(hostname, sendPort);

    // just load the default model
    fun void init() {
        init("");
    }

    fun void init(string model_name) {
        out.openBundle(now);
        spork~ driveFrames();
        out.startMsg("/load/PGAN/send, s");
        out.addString(model_name);

        in.addAddress("/load/PGAN/receive, i");

	      OscMsg load;
	      in => now;
	      // while (!in.recv(load)) { };

        <<< "loaded model" >>>;
    }

    // Bundles all messages on a per-frame basis. This improves
    // performance & responsiveness with the python osc server.
    fun void driveFrames() {
        while (true) {
            framerate => now;
            // ensure that the bundle is closed after any messages on the frame are set
            me.yield();
            out.closeBundle();

            out.openBundle(now);
        }
    }


    fun Latent@ makeLatent() {
        in.addAddress("/make_latent/receive, i");
        out.startMsg("/make_latent/send");

        <<< "waiting for response" >>>;
        in => now;

        int id;
        while(in.recv(msg)) {
            msg.getInt(0) => id;
            <<< "got id", id >>>;
        }

        Latent l;
        id => l.id;
        latents << l;

        return l;
    }

    fun void face(Latent l) {
        out.startMsg("/face, i");
        l.id => out.addInt;
    }

    fun void interpolate(Latent l, Latent left, Latent right, float scale) {
        out.startMsg("/interpolate, i i i f");
        l.id => out.addInt;
        left.id => out.addInt;
        right.id => out.addInt;
        scale => out.addFloat;
    }

    fun void draw(Latent l) {
        out.startMsg("/draw, i");
        l.id => out.addInt;
    }

    // control the sinosc lfo piecemeal
    fun void sinOsc(Latent source, Latent point1, Latent point2, float phase, float amp) {
        out.startMsg("/sin_osc, i i i f f");
        source.id => out.addInt;
        point1.id => out.addInt;
        point2.id => out.addInt;
        phase => out.addFloat;
        amp => out.addFloat;
    }

    fun void add(Latent source, Latent point1, Latent point2) {
        out.startMsg("/add, i i i");
        source.id => out.addInt;
        point1.id => out.addInt;
        point2.id => out.addInt;
    }

    fun void mul(Latent source, Latent point1, float scalar) {
        out.startMsg("/mul, i i f");
        source.id => out.addInt;
        point1.id => out.addInt;
        scalar => out.addFloat;
    }    
}
