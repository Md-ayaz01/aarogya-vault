import json
import os
import urllib.request

output_text_path = r"C:\Users\patha\.gemini\antigravity-ide\brain\669e603c-ff87-4c13-a681-08cfcdd85e42\.system_generated\steps\234\output.txt"
dest_dir = r"c:\Users\patha\Downloads\aarogya-vault\stitch_designs\doctor"

os.makedirs(dest_dir, exist_ok=True)

with open(output_text_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

screens = data.get('screens', [])
downloaded_count = 0

for screen in screens:
    title = screen.get('title', 'Untitled')
    if not title.startswith("Doctor App"):
        continue
    
    html_info = screen.get('htmlCode')
    if not html_info or 'downloadUrl' not in html_info:
        print(f"Skipping {title} (no HTML code info)")
        continue
        
    download_url = html_info['downloadUrl']
    
    # Clean title to filename
    safe_title = title.replace("Doctor App | ", "").replace(" & ", "_").replace(" ", "_").lower()
    filename = f"{safe_title}.html"
    filepath = os.path.join(dest_dir, filename)
    
    print(f"Downloading {title} to {filename}...")
    try:
        urllib.request.urlretrieve(download_url, filepath)
        downloaded_count += 1
    except Exception as e:
        print(f"Error downloading {title}: {e}")

print(f"Successfully downloaded {downloaded_count} doctor app screens.")
