#!/usr/bin/env python3
"""Read source art; write tight atlas regions/anchors, never modify a PNG.

Authoring-only dependencies: Pillow, numpy, scipy. Runtime/CI validator is stdlib.
Run after replacing any production character sheet, then review AnimationAudit.
"""
from pathlib import Path
from PIL import Image
from scipy import ndimage
import numpy as np
import hashlib, json, statistics, base64, gzip

root=Path(__file__).resolve().parents[2]/'game/assets/production'
layout=json.loads((root/'animation_layout.json').read_text())
for name,spec in layout.items():
    path=root/name
    pixels=np.asarray(Image.open(path).convert('RGBA'))
    h,w=pixels.shape[:2]
    labels,count=ndimage.label(pixels[:,:,3]>128)
    sizes=np.bincount(labels.ravel()); sizes[0]=0
    objects=ndimage.find_objects(labels)
    spec.update(size=[w,h],sha256=hashlib.sha256(path.read_bytes()).hexdigest(),row_metrics=[],frame_sha256=[],frames=[])
    rows=spec['rows']
    for row in range(rows):
        group=[]
        for col in range(4):
            candidates=[]
            for ident,box in enumerate(objects,1):
                if box is None or sizes[ident]<100:continue
                ys,xs=box
                cx,cy=(xs.start+xs.stop)*.5,(ys.start+ys.stop)*.5
                if col*w/4<=cx<(col+1)*w/4 and row*h/rows<=cy<(row+1)*h/rows:
                    candidates.append((int(sizes[ident]),ident,box))
            assert candidates,(name,row,col,'missing main character component')
            _,ident,(ys,xs)=max(candidates,key=lambda c:c[0])
            x0,x1=max(0,xs.start-2),min(w,xs.stop+2)
            y0,y1=max(0,ys.start-2),min(h,ys.stop+2)
            anchor_x=(col+.5)*w/4-x0
            if not 0<=anchor_x<=x1-x0:anchor_x=(x1-x0)*.5
            silhouette=ndimage.binary_dilation(labels[y0:y1,x0:x1]==ident,iterations=2)
            mask=base64.b64encode(gzip.compress(np.where(silhouette,255,0).astype(np.uint8).tobytes(),mtime=0)).decode()
            group.append({'mask_gzip':mask, 'region':[x0,y0,x1-x0,y1-y0], 'anchor':[anchor_x,ys.stop-y0], 'body_height':ys.stop-ys.start, 'ink_height':ys.stop-ys.start})
        reference_height=statistics.median(c['body_height'] for c in group)
        spec['row_metrics'].append({'anchor':[w/8,h/rows*.9],'body_height':reference_height})
        for cel in group:cel['body_height']=reference_height
        spec['frames'].append(group)
        spec['frame_sha256'].append([hashlib.sha256(pixels[c['region'][1]:c['region'][1]+c['region'][3],c['region'][0]:c['region'][0]+c['region'][2]].tobytes()).hexdigest() for c in group])
        assert len(set(spec['frame_sha256'][-1]))==4,(name,row,'duplicate new frames')
(root/'animation_layout.json').write_text(json.dumps(layout,indent=2)+'\n')
print('Analysed production atlases; updated tight regions, foot anchors and frame hashes. PNGs unchanged.')
