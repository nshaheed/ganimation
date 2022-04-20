public class Model {
		// a specific instantiation of a GAN model

		// latent spaces
		Latent @ latents[0];

		int id;
		
		// osc stuff
		"localhost" => string hostname;
		
		5005 => int sendPort;
		5006 => int recvPort;

		OscIn oin;
		OscOut oout;
		OscMsg msg;

		recvPort => oin.port;
		oout.dest(hostname, sendPort);

		fun Latent@ makeLatent() {

				oin.addAddress("/make_latent/receive, i");
				oout.start( "/make_latent/send" );
				oout.send();

				<<< "waiting for response" >>>;
				oin => now;

				int id;
				while(oin.recv(msg)) {
						msg.getInt(0) => id;
						<<< "got left id", id >>>;
				}

				Latent l;
				id => l.id;
				latents << l;

				return new Latent;
		}

		fun void face(Latent @l) {
				oout.start("/face");
				l.id => oout.add;
				oout.send();
		}
}