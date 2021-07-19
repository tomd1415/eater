import sys
from PIL import Image

infile = "max4.png"

#for infile in sys.argv[1:]:
   # try:
with Image.open(infile) as im:
    print("Orgional = ", im.mode, im.size)
   # except OSError:
print("Error")
pass