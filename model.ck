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
    fun void init() {
        init("");
    }

    fun void init(string model_name) {
        out.start("/load/PGAN/send");
        out.add(model_name);
        out.send();

        in.addAddress("/load/PGAN/receive, i");

	      OscMsg load;
	      in => now;
	      // while (!in.recv(load)) { };

        <<< "loaded model" >>>;
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

    fun void mul(Latent source, Latent point1, float scalar) {
        out.start("/mul");
        source.id => out.add;
        point1.id => out.add;
        scalar => out.add;
        out.send();
    }    
}