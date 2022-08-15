public class StyleGAN extends Model {
    false => int loaded;

    // load up a .pkl file (local or url)
    fun void init(string pkl_address) {
        spork~ oscListener();
        out.openBundle(now);
        spork~ driveFrames();

        outUnbundled.start("/load/StyleGAN/send");
        pkl_address => outUnbundled.add;
        outUnbundled.send();

        modelLoad => now;

        <<< "loaded StyleGAN" >>>;
    }
}