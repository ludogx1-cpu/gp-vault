from PIL import Image

def pad_image(input_path, output_path, padding_ratio=0.2):
    try:
        img = Image.open(input_path).convert("RGBA")
        old_size = img.size
        # We want the original image to take up 50% of the new canvas
        new_size = (int(old_size[0] / 0.5), int(old_size[1] / 0.5))
        
        # Create a new black image
        new_img = Image.new("RGBA", new_size, (0, 0, 0, 255))
        
        # Paste the original image into the center
        paste_x = (new_size[0] - old_size[0]) // 2
        paste_y = (new_size[1] - old_size[1]) // 2
        new_img.paste(img, (paste_x, paste_y), img)
        
        new_img.save(output_path)
        print(f"Successfully padded {input_path} and saved to {output_path}")
    except Exception as e:
        print(f"Error padding {input_path}: {e}")

# Pad the favicon
pad_image("assets/Goldenpawicon.png", "web/favicon_padded.png")

# Now resize it to 192 and 512
img = Image.open("web/favicon_padded.png").convert("RGBA")
img.resize((192, 192), Image.Resampling.LANCZOS).save("web/icons/Icon-192.png")
img.resize((512, 512), Image.Resampling.LANCZOS).save("web/icons/Icon-512.png")
img.resize((512, 512), Image.Resampling.LANCZOS).save("web/favicon.png")
print("Icons generated!")
