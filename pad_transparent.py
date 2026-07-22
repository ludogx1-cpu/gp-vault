import sys
import os
from PIL import Image

def create_padded_icon(src_path, dest_path, final_size, scale_factor=0.65, bg_color=(0, 0, 0, 255)):
    # Open the original image (which has transparency)
    try:
        img = Image.open(src_path).convert("RGBA")
    except Exception as e:
        print(f"Error opening {src_path}: {e}")
        return

    # Calculate new size for the actual content
    content_size = int(final_size * scale_factor)
    
    # Resize the original image using LANCZOS (high quality)
    img = img.resize((content_size, content_size), Image.Resampling.LANCZOS)
    
    # Create a new solid background image of the final size
    new_img = Image.new("RGBA", (final_size, final_size), bg_color)
    
    # Calculate position to paste the resized image in the center
    offset = (final_size - content_size) // 2
    
    # Paste the resized image using itself as a mask to preserve transparency of the paw over the black background
    new_img.paste(img, (offset, offset), img)
    
    # Save the result
    new_img.save(dest_path, "PNG")
    print(f"Saved {dest_path} (size: {final_size}x{final_size}, content scaled to {scale_factor*100}%)")

if __name__ == "__main__":
    src_icon = "assets/Goldenpawicon.png"
    if not os.path.exists(src_icon):
        print(f"Source icon not found: {src_icon}")
        sys.exit(1)
        
    print("Creating padded icons with BLACK background...")
    
    # Create standard icons
    create_padded_icon(src_icon, "web/icons/Icon-192.png", 192, 0.65)
    create_padded_icon(src_icon, "web/icons/Icon-512.png", 512, 0.65)
    
    # Create maskable icons
    create_padded_icon(src_icon, "web/icons/Icon-maskable-192.png", 192, 0.65)
    create_padded_icon(src_icon, "web/icons/Icon-maskable-512.png", 512, 0.65)

