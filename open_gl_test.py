from OpenGL.GL import *
from OpenGL.GLUT import *
from OpenGL.GLU import *

import numpy as np
from PIL import Image # pillow

width, height = 800, 600

# def ReadTexture(filename):
#       # PIL can open BMP, EPS, FIG, IM, JPEG, MSP, PCX, PNG, PPM
#       # and other file types.  We convert into a texture using GL.
#       print('trying to open', filename)
#       try:
#           image = Image.open(filename)
#       except IOError as ex:
#           print('IOError: failed to open texture file')
#           message = template.format(type(ex).__name__, ex.args)
#           print(message)
#           return -1
#       print('opened file: size=', image.size, 'format=', image.format)
#       imageData = np.array(list(image.getdata()), np.uint8)

#       textureID = glGenTextures(1)
#       glPixelStorei(GL_UNPACK_ALIGNMENT, 4)
#       glBindTexture(GL_TEXTURE_2D, textureID)
#       glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_NEAREST);
#       glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_NEAREST);
#       glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,GL_CLAMP_TO_EDGE);
#       glTexParameterf(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,GL_CLAMP_TO_EDGE);
#       glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0)
#       glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, 0)
#       glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, image.size[0], image.size[1],
#                    0, GL_RGB, GL_UNSIGNED_BYTE, imageData)

#       image.close()
#       return textureID
                                                    
# texture_id = ReadTexture("img.jpg")

def square():
    # We have to declare the points in this sequence: bottom left, bottom right, top right, top left
    glBegin(GL_QUADS) # Begin the sketch
    glVertex2f(100, 100) # Coordinates for the bottom left point
    glVertex2f(200, 100) # Coordinates for the bottom right point
    glVertex2f(200, 200) # Coordinates for the top right point
    glVertex2f(100, 200) # Coordinates for the top left point
    glEnd() # Mark the end of drawing


def iterate():
    glViewport(0, 0, 500,500)
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    glOrtho(0.0, 500, 0.0, 500, 0.0, 1.0)
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()
    
def draw():
    # glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    glClear(GL_COLOR_BUFFER_BIT)

    glLoadIdentity() # Reset all graphic/shape's position
    # iterate()
    # glColor3f(1.0, 0.0, 3.0) # Set the color to pink
    # square() # Draw a square using our function

    textureID = glGenTextures(1)
    glBindTexture(GL_TEXTURE_2D, textureID)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)

    # glPushClientAttrib(GL_CLIENT_PIXEL_STORE_BIT)
    glPixelStorei(GL_UNPACK_ALIGNMENT, 1)

    image = Image.open("img.png")
    img_data = np.array(list(image.getdata()), np.uint8)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, img_data)
    # glPopClientAttrib()
    
    glutSwapBuffers()


    # glutWireTeapot(0.5)
    # glFlush()

    # glEnable(GL_TEXTURE_2D)
    # glBindTexture(GL_TEXTURE_2D, texture_id)
    # glTexCoord2f(0, 0)
    # glVertex2f(0,0)
    # glTexCoord2f(0, 1)
    # glVertex2f(0,100)
    # glTexCoord2f(1, 1)
    # glVertex2f(100,100)
    # glTexCoord2f(1, 0)
    # glVertex2f(100,0)
    # glEnd()
    # glDisable(GL_TEXTURE_2D)

    # glClear(GL_COLOR_BUFFER_BIT)

    # # draw xy axis with arrows
    # glBegin(GL_LINES)

    # # x
    # glVertex2d(-1, 0)
    # glVertex2d(1, 0)
    # glVertex2d(1, 0)
    # glVertex2d(0.95, 0.05)
    # glVertex2d(1, 0)
    # glVertex2d(0.95, -0.05)

    # # y
    # glVertex2d(0, -1)
    # glVertex2d(0, 1)
    # glVertex2d(0, 1)
    # glVertex2d(0.05, 0.95)
    # glVertex2d(0, 1)
    # glVertex2d(-0.05, 0.95)

    # glEnd()

    # glFlush()

    # texture = glGenTextures(1)
    # glBindTexture(GL_TEXTURE_2D, texture)
    # # texture wrapping params
    # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
    # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
    # # texture filtering params
    # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    # glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)

    # image = Image.open("img.png")
    # img_data = image.convert("RGBA").tobytes()
    # glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 800, 600, 0, GL_RGBA, GL_UNSIGNED_BYTE, img_data)

    # glFlush()

                                            

# initialization
glutInit()
glutInitDisplayMode(GLUT_RGBA)
glutInitWindowSize(width, height)
glutInitWindowPosition(200,200)

window = glutCreateWindow("opengl window")

glutDisplayFunc(draw)
glutIdleFunc(draw)
glutMainLoop()

