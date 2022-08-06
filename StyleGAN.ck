public class StyleGAN extends Model {
    false => int loaded;

    // load up a .pkl file (local or url)
    fun void init(string pkl_address) {
        out.openBundle(now);
        spork~ driveFrames();

        out.startMsg("/load/StyleGAN/send, s");
        pkl_address => out.addString;

        in.addAddress("/load/StyleGAN/receive, i");

	      OscMsg load;

	      <<< "waiting for load..." >>>;
	      in => now;
	      // while (!m.in.recv(load)) { };

        <<< "loaded StyleGAN" >>>;
    }
}