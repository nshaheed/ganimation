

import model.model

print(dir(model.model))

new_model = model.model.StyleGAN3()

new_model.load('./local_models/stylegan3-r-afhqv2-512x512.pkl')

assert new_model.size() == (512,512)

noise = new_model.generate_noise()

img = new_model.make_image(0)

assert img.shape == (512,512,3)

print('worked')
