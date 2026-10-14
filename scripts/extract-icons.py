#!/usr/bin/env python3
"""Write an exe's first icon group as hicolor PNGs: <icons>/<N>x<N>/apps/<name>.png
usage: extract-icons.py <exe> <icons dir, e.g. ~/.local/share/icons/hicolor> <name>
Stands in for winemenubuilder, which env.sh disables (it would also create per-language menu entries).
Keeps entries that are PNG or 32-bit DIBs, which is what modern application icons contain."""
import os, struct, sys, zlib

def resources(pe):
    lfanew = struct.unpack_from('<I', pe, 0x3c)[0]
    nsect, optsize = struct.unpack_from('<H12xH', pe, lfanew + 6)
    opt = lfanew + 24
    dirs = opt + (112 if struct.unpack_from('<H', pe, opt)[0] == 0x20b else 96)
    rsrc_rva = struct.unpack_from('<I', pe, dirs + 2 * 8)[0]
    sects = [struct.unpack_from('<8xIIII', pe, opt + optsize + 40 * i) for i in range(nsect)]
    def off(rva):
        for vsize, va, rawsize, raw in sects:
            if va <= rva < va + max(vsize, rawsize):
                return rva - va + raw
        raise ValueError(f'rva {rva:#x} not in any section')
    base = off(rsrc_rva)
    def entries(d):  # [(id or None for named, offset)] in directory order
        named, ids = struct.unpack_from('<12xHH', pe, base + d)
        for i in range(named + ids):
            n, o = struct.unpack_from('<II', pe, base + d + 16 + 8 * i)
            yield (None if n & 0x80000000 else n), o
    def data(o):  # descend to the first language, return the data blob
        while o & 0x80000000:
            o = next(entries(o & 0x7fffffff))[1]
        rva, size = struct.unpack_from('<II', pe, base + o)
        return pe[off(rva):off(rva) + size]
    types = dict(entries(0))
    icons = {n: o for n, o in entries(types[3] & 0x7fffffff)}
    group = data(next(entries(types[14] & 0x7fffffff))[1])
    for i in range(struct.unpack_from('<4xH', group)[0]):
        yield data(icons[struct.unpack_from('<12xH', group, 6 + 14 * i)[0]])

def png(w, h, rgba_rows):
    chunk = lambda t, d: struct.pack('>I', len(d)) + t + d + struct.pack('>I', zlib.crc32(t + d))
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)) +
            chunk(b'IDAT', zlib.compress(b''.join(b'\0' + r for r in rgba_rows), 9)) + chunk(b'IEND', b''))

def to_png(img):  # -> (size, png bytes) or None
    if img[:8] == b'\x89PNG\r\n\x1a\n':
        return struct.unpack_from('>I', img, 16)[0], img
    hdr, w, h2, bpp = struct.unpack_from('<Iii2xH', img)  # BITMAPINFOHEADER; height counts the AND mask too
    if bpp != 32:
        return None
    h = h2 // 2
    px = img[hdr:hdr + w * h * 4]
    stride = (w + 31) // 32 * 4
    mask = img[hdr + w * h * 4:]
    use_mask = not any(px[3::4])  # old-style 32 bpp without alpha: transparency is in the AND mask
    rows = []
    for y in range(h - 1, -1, -1):  # DIBs are bottom-up
        row = bytearray()
        for x in range(w):
            b, g, r, a = px[(y * w + x) * 4:(y * w + x) * 4 + 4]
            if use_mask:
                a = 0 if mask[y * stride + x // 8] & (0x80 >> (x % 8)) else 255
            row += bytes((r, g, b, a))
        rows.append(bytes(row))
    return w, png(w, h, rows)

exe, icons, name = sys.argv[1:4]
with open(exe, 'rb') as f:
    pe = f.read()
best = {}
for img in resources(pe):
    got = to_png(img)
    if got and got[0] not in best:
        best[got[0]] = got[1]
for size, data in sorted(best.items()):
    d = os.path.join(icons, f'{size}x{size}', 'apps')
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, name + '.png'), 'wb') as f:
        f.write(data)
print('icon sizes:', ' '.join(map(str, sorted(best))) or 'none')
