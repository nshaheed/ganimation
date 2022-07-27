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
    OscOut out;
    OscMsg msg;

    recvPort => in.port;
    out.dest(hostname, sendPort);

    // just load the default model
    fun static Model make() {
        return make("");
    }

    fun static Model make(string model_name) {
        Model m;

        m.out.start("/load/send");
        m.out.add(model_name);
        m.out.send();

        m.in.addAddress("/load/receive, i");

	OscMsg load;
	// m.in => now;
	while (!m.in.recv(load)) { };

        <<< "loaded model" >>>;

        return m;
    }

    fun Latent@ makeLatent() {

        in.addAddress("/make_latent/receive, i");
        out.start("/make_latent/send");
        out.send();

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
        out.start("/face");
        l.id => out.add;
        out.send();
    }

    fun void interpolate(Latent l, Latent left, Latent right, float scale) {
        out.start("/interpolate");
        l.id => out.add;
        left.id => out.add;
        right.id => out.add;
        scale => out.add;
        out.send();
    }

    fun void draw(Latent l) {
        out.start("/draw");
        l.id => out.add;
        out.send();
    }

    // control the sinosc lfo piecemeal
    fun void sinOsc(Latent source, Latent point1, Latent point2, float phase, float amp) {
        out.start("/sin_osc");
        source.id => out.add;
        point1.id => out.add;
        point2.id => out.add;
        phase => out.add;
        amp => out.add;
        out.send();
    }

    fun void add(Latent source, Latent point1, Latent point2) {
        out.start("/add");
        source.id => out.add;
        point1.id => out.add;
        point2.id => out.add;
        out.send();
    }
}