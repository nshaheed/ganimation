public class StyleGAN extends Model {
    false => int loaded;

    // load up a .pkl file (local or url)
    fun void init(string pkl_address) {
        if (headless) {
           spork~ oscReceiver();
        }
        spork~ oscListener();
        out.openBundle(now);
        spork~ driveFrames();

        // in the case of headless mode, need to set up
        // the receiver before trying to do any osc calls
        me.yield();

        outUnbundled.start("/load/StyleGAN/send");
        pkl_address => outUnbundled.add;
        outUnbundled.send();

        modelLoad => now;

        <<< "loaded StyleGAN" >>>;
    }
}