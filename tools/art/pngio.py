"""Tiny dependency-free PNG reader/writer (8-bit RGB/RGBA, non-interlaced).

Used by the art tools so the pipeline needs nothing beyond Python 3.
"""
import struct
import zlib


def read_png(path):
    """Return (width, height, pixels) where pixels is a bytearray of RGBA."""
    with open(path, "rb") as f:
        data = f.read()
    assert data[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG: %s" % path
    pos = 8
    width = height = None
    bit_depth = color_type = None
    idat = []
    palette = None
    trns = None
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos:pos + 4])
        ctype = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + length]
        pos += 12 + length
        if ctype == b"IHDR":
            width, height, bit_depth, color_type, _c, _f, interlace = struct.unpack(">IIBBBBB", body)
            assert bit_depth == 8, "only 8-bit PNG supported"
            assert interlace == 0, "interlaced PNG not supported"
        elif ctype == b"PLTE":
            palette = body
        elif ctype == b"tRNS":
            trns = body
        elif ctype == b"IDAT":
            idat.append(body)
        elif ctype == b"IEND":
            break
    raw = zlib.decompress(b"".join(idat))
    channels = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}[color_type]
    stride = width * channels
    out = bytearray(width * height * 4)
    prev = bytearray(stride)
    p = 0
    for y in range(height):
        ftype = raw[p]
        p += 1
        line = bytearray(raw[p:p + stride])
        p += stride
        if ftype == 1:
            for i in range(channels, stride):
                line[i] = (line[i] + line[i - channels]) & 255
        elif ftype == 2:
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 255
        elif ftype == 3:
            for i in range(stride):
                left = line[i - channels] if i >= channels else 0
                line[i] = (line[i] + ((left + prev[i]) >> 1)) & 255
        elif ftype == 4:
            for i in range(stride):
                a = line[i - channels] if i >= channels else 0
                b = prev[i]
                c = prev[i - channels] if i >= channels else 0
                pa = abs(b - c)
                pb = abs(a - c)
                pc = abs(a + b - 2 * c)
                if pa <= pb and pa <= pc:
                    pr = a
                elif pb <= pc:
                    pr = b
                else:
                    pr = c
                line[i] = (line[i] + pr) & 255
        base = y * width * 4
        if color_type == 2:
            out[base:base + width * 4:4] = line[0::3]
            out[base + 1:base + width * 4:4] = line[1::3]
            out[base + 2:base + width * 4:4] = line[2::3]
            out[base + 3:base + width * 4:4] = b"\xff" * width
        elif color_type == 6:
            out[base:base + width * 4] = line
        elif color_type == 0:
            out[base:base + width * 4:4] = line
            out[base + 1:base + width * 4:4] = line
            out[base + 2:base + width * 4:4] = line
            out[base + 3:base + width * 4:4] = b"\xff" * width
        elif color_type == 4:
            out[base:base + width * 4:4] = line[0::2]
            out[base + 1:base + width * 4:4] = line[0::2]
            out[base + 2:base + width * 4:4] = line[0::2]
            out[base + 3:base + width * 4:4] = line[1::2]
        elif color_type == 3:
            for x in range(width):
                idx = line[x]
                out[base + x * 4] = palette[idx * 3]
                out[base + x * 4 + 1] = palette[idx * 3 + 1]
                out[base + x * 4 + 2] = palette[idx * 3 + 2]
                out[base + x * 4 + 3] = trns[idx] if trns and idx < len(trns) else 255
        prev = line
    return width, height, out


def write_png(path, width, height, rgba):
    """Write RGBA bytes (len = w*h*4) as a PNG."""
    assert len(rgba) == width * height * 4
    stride = width * 4
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        raw += rgba[y * stride:(y + 1) * stride]

    def chunk(ctype, body):
        c = struct.pack(">I", len(body)) + ctype + body
        return c + struct.pack(">I", zlib.crc32(ctype + body) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)
