import os

def process_file(path):
    with open(path, 'r') as f:
        content = f.read()

    new_content = content.replace('SafeArea(bottom: true, child:', 'SafeArea(top: false, bottom: true, child:')
    
    if new_content != content:
        with open(path, 'w') as f:
            f.write(new_content)
        print("Updated:", path)

for root, dirs, files in os.walk('/home/trace/Desktop/lab/Onmint-v1/user_app/lib/screens'):
    for f in files:
        if f.endswith('.dart'):
            process_file(os.path.join(root, f))
