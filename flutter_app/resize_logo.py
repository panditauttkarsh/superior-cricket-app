
from PIL import Image
import os

def add_padding(image_path, output_path, padding_percent=0.3):
    img = Image.open(image_path)
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    width, height = img.size
    new_width = int(width * (1 + 2 * padding_percent))
    new_height = int(height * (1 + 2 * padding_percent))
    
    # Create a new transparent image
    new_img = Image.new('RGBA', (new_width, new_height), (0, 0, 0, 0))
    
    # Calculate position to center the original image
    offset = (int(width * padding_percent), int(height * padding_percent))
    
    new_img.paste(img, offset)
    new_img.save(output_path)
    print(f"Resized image saved to {output_path}")

if __name__ == "__main__":
    base_path = "/Users/apple/Desktop/fresh-project/superior-cricket-app/flutter_app/assets/images/"
    input_logo = os.path.join(base_path, "app_logo.png")
    output_logo = os.path.join(base_path, "app_logo_padded.png")
    add_padding(input_logo, output_logo)
