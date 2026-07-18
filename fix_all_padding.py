import os
import re

directory = 'vendor_app/lib/screens'

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original_content = content
    
    # 1. Handle SingleChildScrollView( child: ... )
    # We want to replace it with SingleChildScrollView( padding: const EdgeInsets.only(bottom: 100), child: ... )
    content = re.sub(
        r'SingleChildScrollView\(\s*child:',
        r'SingleChildScrollView(\n        padding: const EdgeInsets.only(bottom: 100),\n        child:',
        content
    )
    
    # 2. Handle SingleChildScrollView( physics: ... child: ...)
    # Wait, sometimes physics is there.
    content = re.sub(
        r'SingleChildScrollView\(\s*physics:([^,]+),\s*child:',
        r'SingleChildScrollView(\n        physics:\1,\n        padding: const EdgeInsets.only(bottom: 100),\n        child:',
        content
    )
    
    # 3. Handle cases where padding already exists but it's EdgeInsets.all(16)
    # e.g., padding: const EdgeInsets.all(16),
    # Change to padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
    content = re.sub(
        r'padding:\s*const EdgeInsets\.all\(([\d\.]+)\),',
        r'padding: EdgeInsets.only(left: \1, right: \1, top: \1, bottom: 100),',
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
