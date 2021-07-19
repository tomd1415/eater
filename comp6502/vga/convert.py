from PIL import Image
import io


image = Image.open("sarah1.png", mode="r")
pixels = image.load()

out_file = open("sarah1.bin", "wb")

for y in range(256):
  for x in range(128):
    try:
      out_file.write(chr(pixels[x, y]))
    except:
      out_file.write(chr(0))
out_file.close()
image.close()