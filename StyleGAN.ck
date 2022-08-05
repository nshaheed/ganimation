public class StyleGAN extends Model {
    false => int loaded;

    // load up a .pkl file (local or url)
    fun void init(string pkl_address) {
        out.start("/load/StyleGAN/send");
        out.add(pkl_address);
        out.send();

        in.addAddress("/load/StyleGAN/receive, i");

	      OscMsg load;

	      <<< "waiting for load...", now >>>;
	      in => now;
	      // while (!m.in.recv(load)) { };

        <<< "loaded StyleGAN" >>>;
    }
}