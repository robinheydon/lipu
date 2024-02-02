import sys
import pathlib
import json

dot = pathlib.Path (".")
absolute_dot = dot.absolute ()

path = pathlib.Path (sys.argv[1]) / "coverage.json"
print (path)

fp = open (path, "rb")
content = fp.read ()
fp.close ()

data = json.loads (content)
files = data['files']
files = sorted (files, key = lambda x: x['file'])
print ("-"*79)
for f in files:
    filename = pathlib.Path (f['file'])
    local = filename.relative_to (absolute_dot)
    print (f"{str(local):<57} {f['percent_covered']}% ({f['covered_lines']}/{f['total_lines']})")
print ("="*79)
print (f"{'Total:':<57} {data['percent_covered']}% ({data['covered_lines']}/{data['total_lines']})")
print ("-"*79)
