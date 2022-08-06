

import model.model

print(dir(model.model))

new_model = model.model.StyleGAN3()

new_model.load('./local_models/stylegan3-r-afhqv2-512x512.pkl')

assert new_model.size() == (512,512)

noise = new_model.generate_noise()

img = new_model.make_image(0)

assert img.shape == (512,512,3)

old_id = new_model.make_latent()

new_model.save_latent(old_id, 'test.npy')
new_id = new_model.load_latent('test.npy')

assert new_model.latent[old_id].equal(new_model.latent[new_id])

print('worked')
