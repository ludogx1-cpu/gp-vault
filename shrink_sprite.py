import os
from PIL import Image

input_path = "assets/Baby Corgi sneeze Transparent BG Sprite.webp"
output_path = "assets/Baby Corgi sneeze Optimized.webp"

try:
    print("Opening image...")
    img = Image.open(input_path)
    print(f"Original size: {img.size}")
    
    # Target size for a 10x10 grid where each frame is 200x200 pixels
    target_width = 2000
    target_height = 2000
    
    print(f"Resizing to {target_width}x{target_height}...")
    img_resized = img.resize((target_width, target_height), Image.Resampling.LANCZOS)
    
    print("Saving optimized image...")
    img_resized.save(output_path, "WEBP", lossless=False, quality=80, method=6)
    
    orig_size = os.path.getsize(input_path) / (1024*1024)
    new_size = os.path.getsize(output_path) / (1024*1024)
    print(f"Success! Reduced from {orig_size:.2f} MB to {new_size:.2f} MB")

except Exception as e:
    print(f"Error: {e}")
