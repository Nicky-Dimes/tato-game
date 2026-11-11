#!/usr/bin/env python3
"""Reproducible play routes added only into free cells; original IDs/geometry retained.

Run after build_levels.py. Baseline text files beside this script make reruns idempotent.
"""
from pathlib import Path
import json,re,collections
root=Path(__file__).resolve().parents[1]
source=root/'game/data/levels';baseline=root/'tools/level_baseline';baseline.mkdir(exist_ok=True)
report=[]
for path in sorted(source.glob('W*-*.txt')):
    if path.stem.endswith('-B'):continue
    original=baseline/path.name
    if not original.exists() or 'play_routes = 0.4' not in path.read_text():
        original.write_text(path.read_text())
    text=original.read_text();head,maptext=text.split('[map]\n',1)
    lines=maptext.rstrip('\n').splitlines();width=max(map(len,lines));height=len(lines)
    grid=[list(line.ljust(width)) for line in lines]
    world=int(path.stem[1]);used=set(''.join(lines))|set('@ECo hH*nkL?BS^v#%= /\\~i')
    used|={m[0] for m in re.findall(r'^(.+) = ',head,re.M)}
    pool=iter(c for c in 'VYUXOJIAQRTWFGKZfjluz!' if c not in used)
    definitions=[]
    def symbol(value):
        char=next(pool);definitions.append(f'{char} = {value}');return char
    flyer=symbol(['bee_buzzer','bee_buzzer','balloon_jelly','crow_swooper','crow_swooper','pie_bat'][world-1]+' up=0.0 range=3')
    ground=symbol(['mushroom_hopper','apple_chomper','candy_imp','ice_puffin','pepper_goblin','onion_knight'][world-1])
    pad=symbol('shroom' if world==1 else 'spring')
    ferry=symbol('platform w=4 dx=3 dy=-1 t=2.8 thin')
    step=symbol('platform w=3 dx=0 dy=0 t=3 thin')
    boosts=symbol('pickup wings')
    barrier=symbol('crate h=2 holds=coins:6')
    counts=collections.Counter()
    def clear(x,y,w=1):return 0<=y<height and x>=0 and x+w<=width and all(grid[y][u]==' ' for u in range(x,x+w))
    def put(x,y,char):
        if clear(x,y):grid[y][x]=char;return True
        return False
    # Tiny isolated stepping columns become three-cell landings, without filling wide pits.
    for y in range(height-3,height):
        x=1
        while x<width-1:
            if grid[y][x]=='#':
                start=x
                while x<width and grid[y][x]=='#':x+=1
                if x-start<3:
                    for u in [start-1,x]:
                        if 0<u<width-1 and grid[y][u]==' ':grid[y][u]='#';counts['widened_ground_cells']+=1
            else:x+=1
    for y in range(height-3):
        x=1
        while x<width-1:
            if grid[y][x]=='=':
                start=x
                while x<width and grid[y][x]=='=':x+=1
                if x-start<3:
                    for u in range(max(1,start-1),min(width-1,start+3)):
                        if grid[y][u]==' ':grid[y][u]='=';counts['widened_platform_cells']+=1
            else:x+=1
    modules=0
    for x in range(10,width-18,18):
        floor=height-3
        if not all(grid[floor][u] in '#%i' for u in range(x,min(width,x+15))):continue
        modules+=1
        # An optional, genuinely reachable high road. One-way surfaces never wall off the ground route.
        for px,py,w in [(x+3,floor-3,4),(x+10,floor-5,4)]:
            if clear(px,py,w):
                grid[py][px:px+w]=['=']*w;counts['new_platforms']+=1
                for u in [px,px+2]:
                    if put(u,py-1,'o'):counts['new_coins']+=1
        if modules%2==1 and put(x+1,floor-1,pad):counts['new_bounce_pads']+=1
        if put(x+8,floor-2,flyer):counts['new_flyers']+=1
        if modules%2==0 and put(x+10,floor-1,barrier):counts['new_crate_obstacles']+=1
        if modules%2==0 and put(x+14,floor-1,ground):counts['new_ground_enemies']+=1
        if modules%4==0 and put(x+5,floor-2,ferry):counts['new_moving_platforms']+=1
        elif modules%3==0 and put(x+6,floor-1,step):counts['new_log_steps']+=1
        if modules%3==0 and put(x+11,floor-6,boosts):counts['new_wing_rewards']+=1
        if modules%2==0 and put(x+16,floor-1,'h'):counts['new_hearts']+=1
    head=head.replace('[legend]\n','[legend]\n'+'\n'.join(definitions)+'\n')
    head=head.replace('[meta]\n','[meta]\nplay_routes = 0.4\n')
    path.write_text(head+'[map]\n'+'\n'.join(''.join(line).rstrip() for line in grid)+'\n')
    report.append({'stage':path.stem,'width':width,'modules':modules,**counts})
(root/'tools/play_routes_manifest.json').write_text(json.dumps(report,indent=2)+'\n')
print('PLAY ROUTES:',len(report),'stages;',dict(sum((collections.Counter({k:v for k,v in x.items() if k not in ['stage','width','modules']}) for x in report),collections.Counter())))
