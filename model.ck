public class Model {
    // a specific instantiation of a GAN model

    // latent spaces
    Latent @ latents[0];

    // latents yet to be processed by the backend
    Latent @ makeLatentStack[0];

    int id;

    1::second / 24.0 => dur framerate;

    // osc stuff
    "localhost" => string hostname;

    5005 => int sendPort;
    5006 => int recvPort;

    OscIn in;
    OscSend out;
    // There is a bug w/ bundling where the message sometime doesn't get sent at startup I think.
    // This is for messages that need a response and can stall the program if you don't get one.
    OscOut outUnbundled;
    OscMsg msg;

    recvPort => in.port;
    out.setHost(hostname, sendPort);
    outUnbundled.dest(hostname, sendPort);

    Event modelLoad;

    // just load the default model
    fun void init() {
        init("");
    }

    fun void init(string model_name) {
        spork~ oscListener();
        out.openBundle(now);
        spork~ driveFrames();

        outUnbundled.start("/load/PGAN/send");
        model_name => outUnbundled.add;
        outUnbundled.send();

        modelLoad => now;

        <<< "loaded model" >>>;
    }

    fun OscIn makeOscIn() {
        OscIn newIn;
        recvPort => in.port;
        return newIn;
    }

    // Bundles all messages on a per-frame basis. This improves
    // performance & responsiveness with the python osc server.
    fun void driveFrames() {
        while (true) {
            framerate => now;
	    // <<< "driving frame" >>>;
            // ensure that the bundle is closed after any messages on the frame are set
            me.yield();
            out.closeBundle();

            out.openBundle(now);
        }
    }

    // listen for all osc messages from python backend and process
    fun void oscListener() {
    	in.listenAll();

	while(true) {
	    in => now;
	    while(in.recv(msg)) {

                <<< "got message from", msg.address >>>;
	        if (RegEx.match("/load/.*/receive", msg.address)) {
		   modelLoad.broadcast();
		}

		if (msg.address == "/make_latent/receive") {
                   msg.getInt(0) => int id;

                   makeLatentStack[makeLatentStack.size()-1] @=> Latent l;
                   makeLatentStack.popBack();
                   id => l.id;
                   l.loaded.broadcast();
		}

		if (msg.address == "/latent/load/receive") {
                   msg.getString(0) => string filepath;
                   msg.getInt(1) => int id;

                   id => latents[filepath].id;
                   latents[filepath].loaded.broadcast();
		}
	    }
	}
    }

    fun Latent@ makeLatent() {
        <<< "[makeLatent]" >>>;

        outUnbundled.start("/make_latent/send").send();

        Latent l;
        makeLatentStack << l;

        <<< "[makeLatent] waiting for l.loaded..." >>>;
        l.loaded => now;
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
    fun void sinOsc(Latent source, Latent point1, float phase, float amp) {
        out.startMsg("/sin_osc, i i f f");
        source.id => out.addInt;
        point1.id => out.addInt;
        phase => out.addFloat;
        amp => out.addFloat;
    }

    fun void add(Latent source, Latent point1, Latent point2) {
        out.startMsg("/add, i i i");
        source.id => out.addInt;
        point1.id => out.addInt;
        point2.id => out.addInt;
    }

    fun void sub(Latent source, Latent point1, Latent point2) {
        out.startMsg("/sub, i i i");
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

    fun void div(Latent source, Latent point1, float scalar) {
        out.startMsg("/div, i i f");
        source.id => out.addInt;
        point1.id => out.addInt;
        scalar => out.addFloat;
    }

    fun Latent@ loadLatent(string filepath) {
        <<< "about to start message" >>>;
        outUnbundled.start("/latent/load/send");
        filepath => outUnbundled.add;
        outUnbundled.send();

        Latent l;
        l @=> latents[filepath];

        l.loaded => now;
        <<< "latent", filepath, "loaded" >>>;

        latents.erase(filepath);
        return l;
    }

    fun void saveLatent(Latent l, string filepath) {
        out.startMsg("/latent/save, i s");
        l.id => out.addInt;
        filepath => out.addString;
    }

    fun void rotate(int angle) {
        out.startMsg("/rotate, i");
        angle => out.addInt;
    }
}
