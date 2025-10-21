import os
import sys
from pathlib import Path

def convert_line_endings_to_lf(file_path):
    with open(file_path, 'rb') as file:
        content = file.read()

    # Convert CRLF to LF
    content = content.replace(b'\r\n', b'\n')

    with open(file_path, 'wb') as file:
        file.write(content)

def process_directory(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.ts'):
                file_path = Path(root) / file
                print(f"Converting file: {file_path}")
                convert_line_endings_to_lf(file_path)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <directory_path>")
        sys.exit(1)

    directory_path = sys.argv[1]
    process_directory(directory_path)

    print("Conversion completed.")
