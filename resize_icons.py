from PIL import Image
import sys
import os

def zoom_image(img_path, zoom_factor=2.5):
    try:
        if not os.path.exists(img_path):
            print(f'File not found: {img_path}')
            return
            
        img = Image.open(img_path)
        img = img.convert('RGBA')
        width, height = img.size
        
        new_width = width / zoom_factor
        new_height = height / zoom_factor
        
        left = (width - new_width) / 2
        top = (height - new_height) / 2
        right = (width + new_width) / 2
        bottom = (height + new_height) / 2
        
        cropped_img = img.crop((left, top, right, bottom))
        resized_img = cropped_img.resize((width, height), Image.LANCZOS)
        
        resized_img.save(img_path)
        print(f'Successfully zoomed {img_path}')
    except Exception as e:
        print(f'Error processing {img_path}: {e}')

zoom_image(r'c:\Users\a\Desktop\Updated_Onmint\New_Onmint\user_app\assets\images\user_app_logo.png')
zoom_image(r'c:\Users\a\Desktop\Updated_Onmint\New_Onmint\vendor_app\assets\images\vendor_app_logo.png')
