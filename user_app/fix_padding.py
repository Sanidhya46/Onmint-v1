import os

def process_file(path):
    with open(path, 'r') as f:
        content = f.read()

    idx = content.find('bottomNavigationBar: Container(')
    if idx == -1: return

    # find the matching closing bracket for this Container
    start_idx = idx + len('bottomNavigationBar: Container(') - 1
    depth = 0
    end_idx = -1
    for i in range(start_idx, len(content)):
        if content[i] == '(':
            depth += 1
        elif content[i] == ')':
            depth -= 1
            if depth == 0:
                end_idx = i
                break
    
    if end_idx != -1:
        # replace
        new_content = content[:idx] + 'bottomNavigationBar: SafeArea(\nchild: Container(' + content[start_idx+1:end_idx] + ')\n)' + content[end_idx+1:]
        with open(path, 'w') as f:
            f.write(new_content)
        print("Updated", path)

for root, dirs, files in os.walk('/home/trace/Desktop/lab/Onmint-v1/user_app/lib/screens'):
    for f in files:
        if f.endswith('.dart'):
            # Some files might have multiple occurrences
            # so we could run process_file multiple times if needed, but usually it's once per file.
            # Let's loop until not found
            while True:
                with open(os.path.join(root, f), 'r') as file:
                    if 'bottomNavigationBar: Container(' in file.read():
                        process_file(os.path.join(root, f))
                    else:
                        break
