import sys
import os
from PIL import Image

def shift_image_down(path, base_shift_pixels=3, base_size=192):
    if not os.path.exists(path):
        print(f"File not found: {path}")
        return
    try:
        img = Image.open(path).convert("RGBA")
        width, height = img.size
        # Calculate shift based on image height relative to base_size
        shift = int(round((height / base_size) * base_shift_pixels))
        if shift == 0:
            shift = 1 # min shift

        # Create new image with transparent background
        new_img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
        # Paste original image shifted down by 'shift' pixels
        new_img.paste(img, (0, shift))
        new_img.save(path)
        print(f"Shifted {path} down by {shift} pixels.")
    except Exception as e:
        print(f"Error processing {path}: {e}")

if __name__ == "__main__":
    paths = [
        'web/icons/Icon-192.png',
        'web/icons/Icon-512.png',
        'web/icons/Icon-maskable-192.png',
        'web/icons/Icon-maskable-512.png',
        'web/favicon.png',
        'assets/Goldenpawicon.png'
    ]
    for p in paths:
        shift_image_down(p, base_shift_pixels=11, base_size=192)
