from PIL import Image

def generate_padded_icon(input_path, target_size, content_ratio=0.85):
    """
    Pads and resizes an image so the content takes up `content_ratio` of the target canvas.
    - For Desktop / Favicons: content_ratio ~ 0.88 (large, prominent, crisp)
    - For Mobile Maskable: content_ratio ~ 0.72 (fits inside Android safe-zone circle, no cutoff)
    """
    img = Image.open(input_path).convert("RGBA")
    
    target_width, target_height = target_size
    content_w = int(target_width * content_ratio)
    content_h = int(target_height * content_ratio)
    
    img_resized = img.resize((content_w, content_h), Image.Resampling.LANCZOS)
    
    canvas = Image.new("RGBA", target_size, (0, 0, 0, 0))
    
    paste_x = (target_width - content_w) // 2
    paste_y = (target_height - content_h) // 2
    canvas.paste(img_resized, (paste_x, paste_y), img_resized)
    
    return canvas

# 1. Desktop Favicon and Standard Icons (88% scale - prominent on desktop)
generate_padded_icon("assets/Goldenpawicon.png", (512, 512), content_ratio=0.88).save("web/favicon.png")
generate_padded_icon("assets/Goldenpawicon.png", (192, 192), content_ratio=0.88).save("web/icons/Icon-192.png")
generate_padded_icon("assets/Goldenpawicon.png", (512, 512), content_ratio=0.88).save("web/icons/Icon-512.png")

# 2. Mobile Maskable Icons (72% scale - perfectly fits Android safe-zone circle without cutting toes)
generate_padded_icon("assets/Goldenpawicon.png", (192, 192), content_ratio=0.72).save("web/icons/Icon-maskable-192.png")
generate_padded_icon("assets/Goldenpawicon.png", (512, 512), content_ratio=0.72).save("web/icons/Icon-maskable-512.png")

print("All Desktop and Mobile icons generated successfully!")
