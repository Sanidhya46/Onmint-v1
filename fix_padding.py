import os
import re

directory = 'vendor_app/lib/screens'

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original_content = content
    
    # Simple regex to replace padding in waiting_for_patient_screen.dart
    content = re.sub(
        r'padding:\s*const EdgeInsets\.symmetric\(horizontal:\s*20,\s*vertical:\s*24\),',
        r'padding: const EdgeInsets.only(left: 20, right: 20, top: 24, bottom: 100),',
        content
    )
    
    # If there is a SingleChildScrollView without padding, add it
    # We will look for SingleChildScrollView( and if it doesn't have padding immediately after, we add it.
    # It's easier to just find the end of the children list in Column and add a SizedBox(height: 100).
    # Let's find: `// Green Safety Priority Bar\n            Container(...),\n          ],\n        ),`
    # and change to `// Green Safety Priority Bar\n            Container(...),\n            const SizedBox(height: 100),\n          ],\n        ),`

    # Actually, adding const SizedBox(height: 100) before the last ] of the Column inside SingleChildScrollView is safest.
    # Let's just find "Green Safety Priority Bar" and append SizedBox after it?
    # No, we want it for ALL screens.
    
    # Let's use the SafeArea + padding approach.
    
    # We can replace `SingleChildScrollView(` with `SafeArea(top: false, bottom: true, child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: 100),`
    # BUT we need to close the `SafeArea)`. This requires balanced parenthesis matching.
    
    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, _, files in os.walk(directory):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
