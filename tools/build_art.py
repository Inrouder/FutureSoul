"""Reproducible original low-resolution pixel artwork for FutureSoul (requires Pillow)."""
from PIL import Image, ImageDraw
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parents[1] / 'assets'
(ROOT/'tiles').mkdir(parents=True, exist_ok=True)
(ROOT/'units').mkdir(parents=True, exist_ok=True)

C = {'void':'#0d101a','floor':'#323945','edge':'#212734','shine':'#4d5661',
     'teal':'#2ce5cd','red':'#fa476e','gold':'#f4b75d','blue':'#668cda'}

def new():
    im=Image.new('RGBA',(32,32),'#00000000'); return im,ImageDraw.Draw(im)

def rect(d, xy, color): d.rectangle(xy, fill=color)

def save_tile(name,fn):
    im,d=new();fn(im,d);im.save(ROOT/'tiles'/f'{name}.png')

def floor_variation(seed):
    rng=random.Random(seed)
    def painter(im,d):
        rect(d,(0,0,31,31),'#303743' if seed%2==0 else '#353b47')
        d.line((0,0,31,0),fill='#454c56')
        d.line((0,0,0,31),fill='#414956')
        d.line((31,0,31,31),fill='#242a35')
        d.line((0,31,31,31),fill='#232934')
        for _ in range(16):
            x,y=rng.randint(2,29),rng.randint(2,29)
            rect(d,(x,y,x+rng.randint(0,2),y+rng.randint(0,1)),rng.choice(['#3d4550','#292f3b','#55545a','#373f4a']))
        if seed%3==0:
            d.line((6,7,9,7,12,10),fill='#474a53')
    return painter
for i in range(5): save_tile('floor_'+str(i),floor_variation(i))

def wall(im,d):
    rect(d,(0,0,31,31),'#161d29');rect(d,(0,0,31,5),'#77808c');
    rect(d,(0,6,31,9),'#3f4e5c');rect(d,(0,10,31,28),'#2c3645')
    rect(d,(3,13,28,16),'#4b5764');rect(d,(3,20,28,21),'#586472')
    rect(d,(0,29,31,31),'#101723');
    for x in [4,25]:rect(d,(x,3,x+2,5),'#d0a45e');rect(d,(x,23,x+2,25),'#1b2634')
    rect(d,(11,10,18,13),'#67e1d0');rect(d,(11,14,18,15),'#244d59')
save_tile('wall',wall)

def cover(im,d):
    rect(d,(5,7,29,29),'#16171d');rect(d,(2,3,27,25),'#775337')
    rect(d,(4,5,25,8),'#b18553');rect(d,(4,18,25,23),'#5a3b2e')
    for x in [6,21]:rect(d,(x,9,x+2,17),'#966a42')
    rect(d,(11,10,18,13),'#b58748');rect(d,(3,3,27,5),'#eeb75b')
    rect(d,(3,6,27,7),'#402d29');rect(d,(5,24,25,25),'#442f27')
save_tile('crate',cover)

def console(im,d):
    rect(d,(4,6,30,30),'#141925');rect(d,(2,3,28,25),'#455366')
    rect(d,(5,5,25,17),'#142b3c');rect(d,(7,7,23,15),'#3dbfac')
    rect(d,(9,9,21,11),'#bdf8d7');rect(d,(4,20,26,22),'#121b27')
    for x,cl in [(7,'#ed4f74'),(13,'#d4be60'),(20,'#73eadb')]:rect(d,(x,20,x+3,22),cl)
    rect(d,(8,25,11,30),'#273243');rect(d,(21,25,24,30),'#273243')
save_tile('console',console)

def neon(im,d):
    rect(d,(8,2,24,31),'#172030');rect(d,(10,0,22,26),'#354054')
    rect(d,(12,2,20,23),'#2de2cc');rect(d,(13,3,19,20),'#c5fff1')
    rect(d,(14,23,18,31),'#1a2634')
save_tile('neon',neon)

def floor_hazard(im,d):
    floor_variation(8)(im,d)
    for x in [-13,3,19]:
        d.polygon([(x,31),(x+10,31),(x+30,0),(x+21,0)],fill='#af8542')
        d.line([(x,31),(x+21,0)],fill='#46382f',width=2)
save_tile('hazard',floor_hazard)

def floor_extract(im,d):
    floor_variation(12)(im,d)
    rect(d,(2,2,29,29),'#1c726b');rect(d,(4,4,27,27),'#204b4c')
    rect(d,(6,6,25,8),'#4cf9dc');rect(d,(6,23,25,25),'#4cf9dc')
    rect(d,(6,8,8,23),'#4cf9dc');rect(d,(23,8,25,23),'#4cf9dc')
    d.polygon([(16,10),(23,16),(17,16),(17,21),(11,16),(16,16)],fill='#81ffdf')
save_tile('extract',floor_extract)

def puddle(im,d):
    floor_variation(3)(im,d)
    d.ellipse((3,12,29,26),fill='#174b4d');d.ellipse((8,15,24,23),fill='#1b7370')
    rect(d,(12,17,18,18),'#58a19b');rect(d,(5,22,9,22),'#44cabb')
save_tile('puddle',puddle)

def hostage(im,d):
    # top-down hostage with bound wrists and bright jacket
    d.ellipse((5,26,28,31),fill='#0c1623')
    rect(d,(10,20,14,29),'#383e4a');rect(d,(19,20,23,29),'#383e4a')
    rect(d,(8,12,25,24),'#c7a451');rect(d,(10,14,23,21),'#d8b96e')
    rect(d,(4,15,9,21),'#aa8c57');rect(d,(25,15,29,21),'#aa8c57')
    rect(d,(12,5,23,14),'#a27a63');rect(d,(11,3,23,8),'#31242d')
    rect(d,(14,10,21,11),'#292431');rect(d,(8,18,27,19),'#fa476e')
save_tile('hostage',hostage)

palettes=['#44e3d0','#bb7dff','#f7b75e','#ff5b81']
# character sprites stand upright in tile view, forward toward top. Facing is rotational in-game.
# Separate files per class + armor accent. All art original, shaded pixel-by-pixel.
for role in ('runner','netrunner','heavy','punk'):
    for ci,ac in enumerate(palettes):
        im,d=new()
        # ground shadow
        d.ellipse((5,25,29,31),fill=(2,8,17,145))
        # boots
        rect(d,(9,22,14,28),'#101622');rect(d,(20,22,25,28),'#101622')
        rect(d,(10,24,13,26),'#546073');rect(d,(21,24,24,26),'#546073')
        # armored shoulders / torso
        main='#313b56' if role!='punk' else '#4a2634'
        rect(d,(8,11,26,23),'#0e1522');rect(d,(10,13,24,22),main)
        rect(d,(6,12,10,20),'#647187' if role!='punk' else '#9e5261')
        rect(d,(24,12,29,20),'#647187' if role!='punk' else '#9e5261')
        rect(d,(12,15,22,17),ac)
        rect(d,(13,18,20,21),'#1b2633');rect(d,(15,19,18,19),ac)
        # neck and helmet (small cute chunky pixel character)
        rect(d,(12,6,23,14),'#ba8d78')
        rect(d,(10,3,24,8),'#171d2e')
        rect(d,(9,5,12,12),'#1c2638');rect(d,(23,5,26,12),'#1c2638')
        rect(d,(12,9,22,12),'#122b35')
        rect(d,(14,9,21,10),ac)
        rect(d,(12,4,22,5),ac)
        rect(d,(16,2,21,3),'#59667f')
        if role=='runner':
            rect(d,(6,17,10,20),'#c6c7cf');rect(d,(8,18,9,19),ac)
            rect(d,(24,17,29,20),'#1a2e40')
        elif role=='netrunner':
            rect(d,(8,10,10,16),'#4ef6da');rect(d,(23,8,25,13),'#4ef6da')
            rect(d,(12,19,21,21),'#265c68')
        elif role=='heavy':
            rect(d,(5,11,10,18),'#788193');rect(d,(25,11,30,18),'#788193')
            rect(d,(14,2,21,5),'#8999ad');rect(d,(10,21,24,24),'#8893a3')
        elif role=='punk':
            rect(d,(12,0,15,5),'#f54c70');rect(d,(16,1,20,4),'#a63350')
            rect(d,(14,9,21,10),'#fa4366')
            rect(d,(8,16,10,19),'#f54c70')
        # weapon: black + silver muzzle tilted forward
        rect(d,(24,15,30,18),'#0d1420');rect(d,(27,14,31,15),'#758b9a')
        rect(d,(29,13,31,14),'#a6c3cf')
        im.save(ROOT/'units'/f'{role}_{ci}.png')
print('Generated',len(list(ROOT.rglob('*.png'))),'original PNG assets')
