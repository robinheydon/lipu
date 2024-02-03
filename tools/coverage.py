import sys
import pathlib
import json

dot = pathlib.Path (".")
absolute_dot = dot.absolute ()

path = pathlib.Path (sys.argv[1]) / "coverage.json"

fp = open (path, "rb")
content = fp.read ()
fp.close ()

data = json.loads (content)
files = data['files']
files = sorted (files, key = lambda x: x['file'])

output = []
output.append ("-"*79)
for f in files:
    filename = pathlib.Path (f['file'])
    local = filename.relative_to (absolute_dot)
    output.append (f"{str(local):<57} {f['percent_covered']}% ({f['covered_lines']}/{f['total_lines']})")
output.append ("="*79)
output.append (f"{'Total:':<57} {data['percent_covered']}% ({data['covered_lines']}/{data['total_lines']})")
output.append ("-"*79)

fp = open (sys.argv[2], "w")
fp.write ('\n'.join (output))
fp.close ()
