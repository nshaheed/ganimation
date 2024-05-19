public class StableDiffusion extends Model {
    false => int loaded;

    // Sensible defaults
    fun StableDiffusion() {
        if (headless) {
           spork~ oscReceiver();
        }
        spork~ oscListener();
        out.openBundle(now);
        spork~ driveFrames();

        // in the case of headless mode, need to set up
        // the receiver before trying to do any osc calls
        me.yield();

        outUnbundled.start("/load/StableDiffusion/send");
        "" => outUnbundled.add;
        outUnbundled.send();

        // Maybe don't want this in the constructor, but w/e
        modelLoad => now;

        <<< "loaded StableDiffusion" >>>;
    }

    fun void init() {
        if (headless) {
           spork~ oscReceiver();
        }
        spork~ oscListener();
        out.openBundle(now);
        spork~ driveFrames();

        // in the case of headless mode, need to set up
        // the receiver before trying to do any osc calls
        me.yield();

        outUnbundled.start("/load/StableDiffusion/send");
        "" => outUnbundled.add;
        outUnbundled.send();

        modelLoad => now;

        <<< "loaded StableDiffusion" >>>;
    }
}