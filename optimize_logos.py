from PIL import Image
import os

def trim_transparency(img_path, padding_percent=0.10):
    try:
        if not os.path.exists(img_path):
            print(f'File not found: {img_path}')
            return
            
        img = Image.open(img_path)
        img = img.convert('RGBA')
        
        # Get bounding box of non-transparent pixels
        bbox = img.getbbox()
        if bbox is None:
            print(f'Image {img_path} is completely transparent!')
            return
            
        # Crop to the bounding box (removes all excess transparency)
        cropped_img = img.crop(bbox)
        
        # Calculate new size with padding
        width, height = cropped_img.size
        # Add padding based on the longest side to keep it square if it was square
        max_side = max(width, height)
        padding = int(max_side * padding_percent)
        
        new_size = max_side + (padding * 2)
        
        # Create a new transparent image with the new padded size
        final_img = Image.new('RGBA', (new_size, new_size), (0, 0, 0, 0))
        
        # Paste the cropped image in the center
        paste_x = (new_size - width) // 2
        paste_y = (new_size - height) // 2
        final_img.paste(cropped_img, (paste_x, paste_y))
        
        # Save back to the same path
        final_img.save(img_path)
        print(f'Successfully trimmed and optimized padding for {img_path}')
        
    except Exception as e:
        print(f'Error processing {img_path}: {e}')

# Paths to the logos
user_logo = r'c:\Users\a\Desktop\Updated_Onmint\New_Onmint\user_app\assets\images\user_app_logo.png'
vendor_logo = r'c:\Users\a\Desktop\Updated_Onmint\New_Onmint\vendor_app\assets\images\vendor_app_logo.png'

print("Optimizing User App Logo...")
trim_transparency(user_logo, padding_percent=0.10)

print("Optimizing Vendor App Logo...")
trim_transparency(vendor_logo, padding_percent=0.10)
