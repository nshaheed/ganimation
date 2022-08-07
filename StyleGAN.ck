public class StyleGAN extends Model {
    false => int loaded;

    // load up a .pkl file (local or url)
    fun void init(string pkl_address) {
        spork~ oscListener();
        out.openBundle(now);
        spork~ driveFrames();

        out.startMsg("/load/StyleGAN/send, s");
        pkl_address => out.addString;

        modelLoad => now;

        <<< "loaded StyleGAN" >>>;
    }
}