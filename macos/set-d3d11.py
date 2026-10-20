#!/usr/bin/env python3
# Pin Nitrous to Direct3D 11.0 in 3dsMax.ini (UTF-16). 3ds Max writes WARP back after a failed
# graphics init, and then keeps using its software path (Nitrous DX11 SW) on later launches.
import re, sys
p = sys.argv[1]
raw = open(p, 'rb').read()
bom = raw.startswith(b'\xff\xfe')
text = raw.decode('utf-16')
new = re.sub(r'(?m)^GFXDirect3DVersion=.*$', 'GFXDirect3DVersion=11.0', text)
if new != text:
    open(p, 'wb').write((b'\xff\xfe' if bom else b'') + new.encode('utf-16-le'))
    print('3dsMax.ini: GFXDirect3DVersion=11.0')
