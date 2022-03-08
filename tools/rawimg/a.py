import os
import sys
import tempfile

import imageio

WIDTH  = 1280
HEIGHT = 1024

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 a.py <image_file>")
        sys.exit(1)

    image_file = sys.argv[1]
    out_file = os.path.join(tempfile.gettempdir(), f"{os.path.basename(image_file)}.raw")

    im = imageio.imread(image_file)
    height, width, _ = im.shape
    if width != WIDTH or height != HEIGHT:
        print(f"Image must be {WIDTH}x{HEIGHT}")
        print(f"Your image is {width}x{height}")
        sys.exit(1)
    with open(out_file, 'wb') as f:
        f.write(im.tobytes())
    print(f"{out_file}")

if __name__ == '__main__':
    main()
