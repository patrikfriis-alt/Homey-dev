"""
Generate icon-192.png and icon-512.png from icon.svg
Run: python generate_icons.py
Requires: pip install cairosvg  (or use the fallback below)
"""
import struct, zlib, math

def make_png(size):
    """Create a simple orange rounded-rect PNG with white H letter using pure Python."""
    w = h = size
    scale = size / 512

    def to_bytes(n, length=1):
        return n.to_bytes(length, 'big')

    def pack_chunk(chunk_type, data):
        c = chunk_type + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)

    # Draw pixel by pixel
    pixels = []
    r_outer = int(112 * scale)  # corner radius

    # H letter parameters (scaled)
    cx = w // 2
    cy = h // 2
    bar_w = int(40 * scale)
    bar_h = int(220 * scale)
    cross_h = int(40 * scale)
    cross_w = int(100 * scale)

    def in_rounded_rect(x, y):
        if x < r_outer and y < r_outer:
            return math.hypot(x - r_outer, y - r_outer) <= r_outer
        if x > w - r_outer and y < r_outer:
            return math.hypot(x - (w - r_outer), y - r_outer) <= r_outer
        if x < r_outer and y > h - r_outer:
            return math.hypot(x - r_outer, y - (h - r_outer)) <= r_outer
        if x > w - r_outer and y > h - r_outer:
            return math.hypot(x - (w - r_outer), y - (h - r_outer)) <= r_outer
        return True

    def in_h(x, y):
        left_bar = abs(x - (cx - cross_w//2)) <= bar_w//2 and abs(y - cy) <= bar_h//2
        right_bar = abs(x - (cx + cross_w//2)) <= bar_w//2 and abs(y - cy) <= bar_h//2
        crossbar = abs(y - cy) <= cross_h//2 and abs(x - cx) <= cross_w//2 + bar_w//2
        return left_bar or right_bar or crossbar

    rows = []
    for y in range(h):
        row = bytearray([0])  # filter byte
        for x in range(w):
            if not in_rounded_rect(x, y):
                row += bytearray([0, 0, 0, 0])  # transparent
            elif in_h(x, y):
                row += bytearray([255, 255, 255, 255])  # white
            else:
                row += bytearray([245, 156, 0, 255])  # #F59C00
        rows.append(bytes(row))

    raw = zlib.compress(b''.join(rows), 9)

    png = (
        b'\x89PNG\r\n\x1a\n'
        + pack_chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0))
        + pack_chunk(b'IDAT', raw)
        + pack_chunk(b'IEND', b'')
    )
    return png

for size, name in [(192, 'icon-192.png'), (512, 'icon-512.png')]:
    data = make_png(size)
    with open(name, 'wb') as f:
        f.write(data)
    print(f'Created {name} ({size}x{size})')
