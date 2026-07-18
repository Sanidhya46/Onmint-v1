import os

def wrap_body_with_safearea(path):
    with open(path, 'r') as f:
        text = f.read()

    new_text = ""
    idx = 0
    modified = False

    while True:
        pos = text.find('body: ', idx)
        if pos == -1:
            new_text += text[idx:]
            break

        new_text += text[idx:pos + 6]
        idx = pos + 6

        # Skip whitespace
        while idx < len(text) and text[idx] in ' \n\t':
            new_text += text[idx]
            idx += 1

        if text[idx:idx+8] == 'SafeArea' or text[idx:idx+4] == 'null':
            continue
            
        # Check if it is a TabBarView - we might want to wrap its children instead, 
        # but SafeArea around TabBarView is also fine.
        
        new_text += 'SafeArea(bottom: true, child: '
        modified = True

        depth_paren = 0
        depth_brace = 0
        depth_bracket = 0
        in_string = False
        string_char = ''
        escaped = False

        while idx < len(text):
            c = text[idx]
            if in_string:
                if escaped:
                    escaped = False
                elif c == '\\':
                    escaped = True
                elif c == string_char:
                    in_string = False
                new_text += c
                idx += 1
                continue

            if c in '"\'':
                in_string = True
                string_char = c
                new_text += c
                idx += 1
                continue

            if c == '(': depth_paren += 1
            elif c == ')': depth_paren -= 1
            elif c == '{': depth_brace += 1
            elif c == '}': depth_brace -= 1
            elif c == '[': depth_bracket += 1
            elif c == ']': depth_bracket -= 1

            if depth_paren == 0 and depth_brace == 0 and depth_bracket == 0:
                if c == ',' or c == '}':
                    new_text += ')'
                    break
            elif depth_paren < 0 or depth_brace < 0 or depth_bracket < 0:
                new_text += ')'
                break

            new_text += c
            idx += 1

    if modified:
        with open(path, 'w') as f:
            f.write(new_text)
        print("Wrapped body with SafeArea in:", path)

for root, dirs, files in os.walk('/home/trace/Desktop/lab/Onmint-v1/user_app/lib/screens'):
    for f in files:
        if f.endswith('.dart'):
            wrap_body_with_safearea(os.path.join(root, f))
