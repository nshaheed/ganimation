import torch
import matplotlib.pyplot as plt
import torchvision
import time
import threading

from pythonosc import dispatcher
from pythonosc import osc_server

use_gpu = True if torch.cuda.is_available() else False

def random_face(addr: str, *args) -> None:
    print("[{0}] ~ {1}".format(addr, args))

    noise, _ = model.buildNoiseData(num_images)

    with torch.no_grad():
        generated_images = model.test(noise)

        # let's plot these images using torchvision and matplotlib
        grid = torchvision.utils.make_grid(generated_images.clamp(min=-1, max=1), scale_each=True, normalize=True)
        ax.imshow(grid.permute(1, 2, 0).cpu().numpy())

        figure.canvas.draw()
        figure.canvas.flush_events()
        plt.draw()

    print("done")

def run_server(dispatch):
    server = osc_server.ThreadingOSCUDPServer(
        (ip, port), dispatch)
    print("Serving on {}".format(server.server_address))
    server.serve_forever()


figure, ax = plt.subplots()
print("ax", ax)

plt.ion()
plt.show()

num_images = 1

# trained on high-quality celebrity faces "celebA" dataset
# this model outputs 512 x 512 pixel images
model = torch.hub.load('facebookresearch/pytorch_GAN_zoo:hub',
                       'PGAN', model_name='celebAHQ-512',
                       pretrained=True, useGPU=use_gpu)

ip = "127.0.0.1"
port = 5005


dispatcher = dispatcher.Dispatcher()
dispatcher.map("/face", random_face)

x = threading.Thread(target=run_server, args=[dispatcher])
x.start()
print("past server start")

# matplotlib draw loop
while True:
    plt.show()

    figure.canvas.draw()
    figure.canvas.flush_events()
        
    time.sleep(0.042) # 24 fps

