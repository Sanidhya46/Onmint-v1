import os
import re

directory = 'vendor_app/lib/screens'

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original_content = content

    def repl_all(match):
        pre = match.group(1)
        val = match.group(2)
        return pre + f'padding: const EdgeInsets.only(left: {val}, right: {val}, top: {val}, bottom: 100)'

    content = re.sub(
        r'(SingleChildScrollView\s*\(\s*(?:physics:[^,]+,)?\s*)padding:\s*const\s*EdgeInsets\.all\(([\d\.]+)\)',
        repl_all,
        content
    )
    
    def repl_sym(match):
        pre = match.group(1)
        h = match.group(2)
        v = match.group(3)
        return pre + f'padding: const EdgeInsets.only(left: {h}, right: {h}, top: {v}, bottom: 100)'

    content = re.sub(
        r'(SingleChildScrollView\s*\(\s*(?:physics:[^,]+,)?\s*)padding:\s*const\s*EdgeInsets\.symmetric\(horizontal:\s*([\d\.]+),\s*vertical:\s*([\d\.]+)\)',
        repl_sym,
        content
    )

    content = re.sub(
        r'SingleChildScrollView\(\s*child:',
        r'SingleChildScrollView(\n        padding: const EdgeInsets.only(bottom: 100),\n        child:',
        content
    )
    
    content = re.sub(
        r'SingleChildScrollView\(\s*physics:([^,]+),\s*child:',
        r'SingleChildScrollView(\n        physics:\1,\n        padding: const EdgeInsets.only(bottom: 100),\n        child:',
        content
    )

    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
