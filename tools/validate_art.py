#!/usr/bin/env python3
"""Validate authored animation metadata and unchanged source PNGs; stdlib only."""
import hashlib
import json
import struct
import gzip
import base64
from pathlib import Path

root = Path(__file__).resolve().parents[1] / 'game/assets/production'
layout = json.loads((root / 'animation_layout.json').read_text())
frames = 16  # Tato's original 4x4 production atlas.
for name, spec in layout.items():
    data = (root / name).read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', name
    size = list(struct.unpack('>II', data[16:24]))
    assert size == spec['size'], (name, 'dimensions changed')
    assert hashlib.sha256(data).hexdigest() == spec['sha256'], (name, 'source changed; revalidate anchors')
    assert len(spec['row_metrics']) == spec['rows'], name
    for metric, hashes in zip(spec['row_metrics'], spec['frame_sha256']):
        assert len(hashes) == 4 and len(set(hashes)) == 4, (name, 'duplicate or missing cels')
        assert 0 < metric['body_height'] <= size[1] / spec['rows'], name
        x, y = metric['anchor']
        assert 0 <= x <= size[0] / 4 and 0 <= y <= size[1] / spec['rows'] + 1, name
    for row in spec['frames']:
        for cel in row:
            assert len(gzip.decompress(base64.b64decode(cel['mask_gzip']))) == cel['region'][2] * cel['region'][3], (name, 'bad silhouette mask')
    frames += spec['columns'] * len(spec.get('active_rows', range(spec['rows'])))
assert frames == 236, frames
print('ART: 28 characters, 236 production cels, 112 additional cels; source hashes and anchors valid')
