import json, subprocess, sys, glob
js = glob.glob('_build/js/**/parity/font/dump/dump.js', recursive=True)[0]
f, t = sys.argv[1], sys.argv[2]
a = subprocess.run(['node', 'parity/font/typr_dump.mjs', f, t], capture_output=True, text=True)
b = subprocess.run(['node', js, f, t], capture_output=True, text=True)
la = (a.stdout.strip().splitlines() or [''])[-1]
lb = (b.stdout.strip().splitlines() or [''])[-1]
try: A = json.loads(la)
except Exception: print('typr failed:', (a.stderr or la)[-300:]); sys.exit()
try: B = json.loads(lb)
except Exception: print('mbt failed:', lb[:300]); sys.exit()
for k in ['upem', 'asc', 'desc']:
  if A[k] != B[k]: print(k, A[k], B[k])
for i, (ga, gb) in enumerate(zip(A['glyphs'], B['glyphs'])):
  for k in ['g', 'ax', 'cmds']:
    if ga[k] != gb[k]: print(i, k, str(ga[k])[:80], '|', str(gb[k])[:80])
  if ga['crds'] != gb['crds']: print(i, 'crds', ga['crds'][:10], gb['crds'][:10])
