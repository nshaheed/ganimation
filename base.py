import torch
import matplotlib.pyplot as plt
import torchvision
import time

from pythonosc import dispatcher
from pythonosc import osc_server

use_gpu = True if torch.cuda.is_available() else False

def print_volume_handler(unused_addr, args, volume):
      print("[{0}] ~ {1}".format(args[0], volume))

ip = "127.0.0.1"
port = 5005

dispatcher = dispatcher.Dispatcher()
dispatcher.map("/volume", print_volume_handler, "Volume")

server = osc_server.ThreadingOSCUDPServer(
    (ip, port), dispatcher)
print("Serving on {}".format(server.server_address))
server.serve_forever()

# trained on high-quality celebrity faces "celebA" dataset
# this model outputs 512 x 512 pixel images
model = torch.hub.load('facebookresearch/pytorch_GAN_zoo:hub',
                       'PGAN', model_name='celebAHQ-512',
                       pretrained=True, useGPU=use_gpu)

figure, ax = plt.subplots()

plt.ion()

num_images = 1

while True:
    noise, _ = model.buildNoiseData(num_images)

    with torch.no_grad():
        generated_images = model.test(noise)
    
        # let's plot these images using torchvision and matplotlib
        grid = torchvision.utils.make_grid(generated_images.clamp(min=-1, max=1), scale_each=True, normalize=True)
        plt.imshow(grid.permute(1, 2, 0).cpu().numpy())
        plt.show()

        figure.canvas.draw()
        figure.canvas.flush_events()
        
        time.sleep(0.042) # 24 fps



