import urllib.request
import json

url = "https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ8Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpbCiVodG1sXzAwMDY1NmVlYjYwYzkwYzkwMzM4NWI4OTcyMGIxNGI5EgsSBxD17s3KjBQYAZIBJAoKcHJvamVjdF9pZBIWQhQxMTY2MTcyNDk5MTU0MDY1MDc1Ng&filename=&opi=89354086"
try:
    response = urllib.request.urlopen(url)
    html = response.read().decode('utf-8')
    print("Download Success! Length:", len(html))
    print(html[:500])
except Exception as e:
    print("Download Error:", e)
