"""Generate an illustrated concept preview from actual in-repository original sprites.
Not a Godot screenshot. Runtime HUD is drawn by scripts/main.gd.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pathlib import Path
import random
R=Path(__file__).resolve().parents[1]
T=R/'assets/tiles'; U=R/'assets/units';W,H=1440,900
random.seed(4)
im=Image.new('RGB',(W,H),'#0b101c');d=ImageDraw.Draw(im)
for x in range(0,W,32):d.line((x,0,x,H),fill='#101a29')
for y in range(0,H,32):d.line((0,y,W,y),fill='#101a29')
font='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
bold='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
F=lambda s:ImageFont.truetype(font,s)
B=lambda s:ImageFont.truetype(bold,s)
def txt(s,x,y,sz=18,c='#e6eefa',bold_=False):d.text((x,y),s,font=B(sz) if bold_ else F(sz),fill=c)
def panel(x,y,w,h,border='#43dccc'):
 d.rectangle((x,y,x+w,y+h),fill='#111c2c',outline=border,width=2)
 d.rectangle((x+1,y+1,x+w-1,y+5),fill=border)
def box(x,y,w,h,label,col='#44dccc',filled=False):
 d.rectangle((x,y,x+w,y+h),fill=col if filled else '#192a3c',outline=col,width=2)
 txt(label,x+13,y+11,15,'#0b101b' if filled else '#dfe9f5',True)
d.rectangle((0,0,W,7),fill='#49e0ce')
panel(36,22,1368,70)
txt('F/S',56,35,30,'#48eedc',True);txt('MAELSTROM KIDNAP / BLACKGRID',135,38,24,'#e8ebf3',True)
txt('EXTRACTION CONTRACT // TURN-BASED TACTICAL SHOOTER',138,68,12,'#8094a8')
# map
W0,H0=28,19
special={}
for x in range(W0):
 for y in range(H0):
  if x in [0,W0-1] or y in [0,H0-1]:special[(x,y)]='wall'
for y in range(2,8):
 if y!=5:special[(8,y)]='wall'
for x in range(10,16):
 if x!=13:special[(x,4)]='wall'
for y in range(11,17):
 if y!=14:special[(19,y)]='wall'
for x in range(11,18):
 if x!=14:special[(x,13)]='wall'
for y in range(3,8):
 if y!=6:special[(20,y)]='wall'
for x in range(21,26):
 if x!=23:special[(x,12)]='wall'
for cell in [(5,5),(6,12),(10,9),(14,8),(16,10),(11,16),(22,4),(24,14),(23,16)]:special[cell]='crate'
for cell in [(10,3),(17,6),(22,15)]:special[cell]='console'
for cell in [(3,3),(25,3),(18,3),(9,16)]:special[cell]='neon'
for cell in [(7,16),(15,5),(25,10),(12,10)]:special[cell]='puddle'
for x in range(2,5):
 for y in range(8,12):special[(x,y)]='extract'
for x in range(21,25):special[(x,8)]='hazard'
X,Y=38,112
floor_cache={name:Image.open(T/f'{name}.png').convert('RGBA') for name in {f'floor_{i}' for i in range(5)}|set(special.values())|{'hostage'}}
for y in range(H0):
 for x in range(W0):
  kind=special.get((x,y),f'floor_{(x*19+y*37+x*y*3)%5}')
  im.paste(floor_cache[kind],(X+x*32,Y+y*32),floor_cache[kind])
# softened colored tile bloom simulated ONLY IN CONCEPT PREVIEW
light=Image.new('RGBA',(W,H));dl=ImageDraw.Draw(light)
for c,col in [((3,3),(20,236,218,70)),((25,3),(20,236,218,80)),((18,3),(20,236,218,80)),((9,16),(20,236,218,70)),((22,9),(243,80,96,40))]:
 cx,cy=X+c[0]*32+16,Y+c[1]*32+16;dl.ellipse((cx-95,cy-95,cx+95,cy+95),fill=col)
light=light.filter(ImageFilter.GaussianBlur(48)); im=Image.alpha_composite(im.convert('RGBA'),light)
d=ImageDraw.Draw(im)
# sprites
for kind,num,c,team,name in [('runner',0,(3,14),'edge','GHOST'),('netrunner',1,(4,15),'edge','NULL'),('punk',3,(24,4),'punk','SKULL'),('punk',3,(24,6),'punk','HEX'),('heavy',2,(7,9),'edge','CIPHER')]:
 x,y=cx,cy=X+c[0]*32+16,Y+c[1]*32+16
 col='#45eed9' if team=='edge' else '#f64d72'
 d.ellipse((x-19,y-19,x+19,y+19),outline=col,width=2)
 sprite=Image.open(U/f'{kind}_{num}.png').convert('RGBA');im.paste(sprite,(x-16,y-18),sprite)
 d.rectangle((x-16,y-23,x+16,y-19),fill='#0c1723');d.rectangle((x-15,y-22,x+12,y-21),fill='#6ce6b5')
 txt(name,x-21,y-40,10,'#ffffff')
im.paste(floor_cache['hostage'],(X+22*32,Y+9*32),floor_cache['hostage'])
d.rectangle((X-1,Y-1,X+W0*32+1,Y+H0*32+1),outline='#3ecfbe',width=3)
# LoS overlay ray
l0=(X+7*32+16,Y+9*32+16);l1=(X+24*32+16,Y+6*32+16)
d.line((l0,l1),fill='#f85378',width=3)
# sidebar
panel(958,112,446,608)
txt('MISSION // 001',976,132,16,'#e8b66b',True)
txt('GEISELRETTUNG',976,171,27,'#f0f3ff',True)
for i,line in enumerate(['EDGERUNNERS: Geisel holen, zur','grünen Zone bringen.','MAELSTROM: 12 Runden abwehren.']):txt(line,977,226+i*25,16,'#8597ad')
txt('ROUND 03 / 12',976,314,20,'#efb66d',True)
txt('ACTIVE // GHOST',976,359,20,'#45e9db',True)
txt('AP: 2    |    HP: 95    |    RIFLE',976,393,16,'#e2eaf6')
txt('YOU // GHOST / HP 95',976,439,16,'#45e9db')
txt('ACTIONS // YOUR TURN',976,481,17,'#efb66d',True)
box(975,519,199,46,'1 / BEWEGEN','#48eedc',True)
box(1187,519,199,46,'2 / SCHIESSEN','#f04c75')
box(975,576,199,46,'3 / GEISEL','#e8b66b')
box(1187,576,199,46,'4 / OVERWATCH','#48eedc')
box(975,635,411,46,'ZUG BEENDEN   [SPACE]','#e8b66b')
txt('LINK: ONLINE  |  UNIT #1',979,692,13,'#93a8bd')
panel(38,737,1366,98,'#e8b66b')
txt('FIELD LOG //',56,751,14,'#e8b66b',True)
txt('GHOST // Relocated',56,785,20,'#ebeffa',True)
txt('[LINKSKLICK] ZIELFELD    [1-4] AKTION    [SPACE] ENDE',844,791,12,'#93a1b5')
txt('BUILD 0.1.0  //  FUTURESOUL PROTOCOL',40,860,12,'#93a3b7')
txt('CONCEPT PREVIEW // GENERATED FROM ORIGINAL GAME ASSETS',796,860,12,'#43dccc')
(R/'docs').mkdir(exist_ok=True)
im.convert('RGB').save(R/'docs/preview.png',optimize=True)
print(R/'docs/preview.png')
