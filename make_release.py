import os
import subprocess
import shutil


cwd = os.getcwd()
ganimator_path = os.path.join(cwd, 'ganimator.py')

# build the exe
subprocess.call(f'pyinstaller --windowed --noconfirm --add-data *.ck;./chuck/ --add-data examples/*.ck;./chuck/examples/ {ganimator_path}')
dist_dir = os.path.join(cwd, 'dist', 'ganimator')

# copy the glfw dlls over because the ones that are installed don't work for some reason
glfw_path = os.path.join(os.environ['CONDA_PREFIX'], 'Lib', 'site-packages', 'glfw')

glfw_dll = os.path.join(glfw_path, 'glfw3.dll')
msvcr_dll = os.path.join(glfw_path, 'msvcr110.dll')

shutil.copy(glfw_dll, dist_dir)
shutil.copy(msvcr_dll, dist_dir)

# zip it up!
shutil.make_archive('ganimator', 'zip', dist_dir)
