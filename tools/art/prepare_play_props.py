#!/usr/bin/env python3
"""Read-only PNG analysis for the v0.4 prop atlas. Requires Pillow, numpy, scipy.

Regenerates atlas JSON only; source RGBA artwork stays intact. Two-pixel padding
preserves edge antialiasing. Review the resulting regions in actual Godot.
"""
from pathlib import Path
import json
from PIL import Image
import numpy as np
from scipy import ndimage
ROOT=Path(__file__).resolve().parents[2]/'game/assets/production'
SETS=[('play_props.png',4,4,96,'mushroom spring crate question checkpoint goal log_step island cloud_platform lily cracked spring_compressed hud_panel sign cloud bush'.split()),('play_interactions.png',4,2,64,'bowl thorn spikes roller ice_spikes mace saw torch'.split())]
layout={}
for filename,cols,rows,threshold,names in SETS:
    with Image.open(ROOT/filename) as image:
        alpha=np.asarray(image.convert('RGBA'))[:,:,3];height,width=alpha.shape
    for i,name in enumerate(names):
        x0=round((i%cols)*width/cols);x1=round((i%cols+1)*width/cols)
        y0=round((i//cols)*height/rows);y1=round((i//cols+1)*height/rows)
        labels,_=ndimage.label(alpha[y0:y1,x0:x1]>=threshold)
        counts=np.bincount(labels.ravel());counts[0]=0
        assert counts.max()>0,name
        ys,xs=np.where(labels==counts.argmax())
        left=max(x0,x0+int(xs.min())-2);right=min(x1,x0+int(xs.max())+3)
        top=max(y0,y0+int(ys.min())-2);bottom=min(y1,y0+int(ys.max())+3)
        layout[name]=[left,top,right-left,bottom-top]
        if filename!='play_props.png':layout[name].append(filename)
(ROOT/'playful_layout.json').write_text(json.dumps(layout,indent=2)+'\n')
print('Prepared',len(layout),'prop regions; PNG sources unchanged')
