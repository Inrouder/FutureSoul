extends Node2D
# FUTURESOUL realtime playable prototype for Godot 4.3+
const SIZE := Vector2(1280,720)
const WORLD := Rect2(36,75,1068,580)
const SPEED := 195.0
const TEAMS := ["MAELSTROM","EDGERUNNERS","KOBANTEC"]
const JOBS := [["Gunner","Punk Bruiser","Shooty"],["The Big","Snipeout","Cyberpsycho","Netrunner"],["First Warrior","The Rocky","Raven"]]
const COLORS := [Color("#ff465b"),Color("#33d9e7"),Color("#e5c45a")]
var faction := 1
var job := 0
var suit := 0
var mode := 0
var palette := [Color("#20d9ec"),Color("#f24e70"),Color("#eeca62"),Color("#b48bff"),Color("#a4f079")]
var phase := "menu"
var player := {}
var enemies: Array = []
var allies: Array = []
var bullets: Array = []
var particles: Array = []
var covers: Array = []
var decor: Array = []
var terminals := [Vector2(250,230),Vector2(855,505)]
var hacked := [false,false]
var hostage := Vector2(924,340)
var hostage_free := false
var time := 0.0
var elapsed := 0.0
var flash := 0.0
var shake := 0.0
var score := 0
var message := "WELCOME TO FUTURESOUL"
var game_result := ""
var ui_font: Font
var rng := RandomNumberGenerator.new()
var net_note := "OFFLINE DEMO / MULTIPLAYER IN DEVELOPMENT"
func _ready() -> void:
 rng.seed=397441
 ui_font=ThemeDB.fallback_font
 _build_map()
func _build_map() -> void:
 covers.clear()
 decor.clear()
 for i in range(12):
  var x := float(190+(i%6)*140)
  var y := float(173+int(i/6)*315)
  if i==2 or i==9: continue
  covers.append(Rect2(x,y,62,27))
 for i in range(22):
  var p := Vector2(72+i*47.0,105+float((i*97)%495))
  decor.append(p)
func _start() -> void:
 _build_map()
 player=_actor(Vector2(155,350),0,faction,job)
 player.color=suit
 enemies.clear()
 allies.clear()
 bullets.clear()
 particles.clear()
 for i in range(6):
  enemies.append(_actor(Vector2(730+(i%3)*92,220+int(i/3)*150),1,0,i%3))
 for i in range(2):
  allies.append(_actor(Vector2(120,265+i*169),0,faction,(i+1)%JOBS[faction].size()))
 hacked=[false,false]
 hostage_free=false
 hostage=Vector2(924,340)
 score=0
 elapsed=0
 game_result=""
 message="LIVE OPERATION // "+["HOSTAGE RESCUE","BASE ASSAULT","BREACH EXTRACTION"][mode]
 phase="play"
func _actor(pos: Vector2,team: int,fac: int,klass: int) -> Dictionary:
 return {"pos":pos,"team":team,"fac":fac,"klass":klass,"hp":120.0 if JOBS[fac][klass] in ["The Rocky","Gunner"] else 100.0,"max":120.0 if JOBS[fac][klass] in ["The Rocky","Gunner"] else 100.0,"cool":0.0,"ability":0.0,"color":fac,"aim":Vector2.RIGHT,"invisible":0.0,"slow":0.0,"shield":0.0}
func _process(dt: float) -> void:
 time+=dt
 flash=maxf(0.0,flash-dt)
 shake=maxf(0.0,shake-dt)
 if phase=="play":
  elapsed+=dt
  _tick_player(dt)
  _tick_ai(dt)
  _tick_bullets(dt)
  _tick_effects(dt)
  _objectives()
 queue_redraw()
func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_ESCAPE:
   phase="menu"
  if event.keycode==KEY_R and phase=="dead":
   _start()
  if event.keycode==KEY_E and phase=="play":
   _interact()
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and phase=="menu":
  var m := get_global_mouse_position()
  if m.x>=64 and m.x<430:
   if m.y>=225 and m.y<345:
    mode=clampi(int((m.y-225)/40),0,2)
   elif m.y>=380 and m.y<500:
    faction=clampi(int((m.y-380)/40),0,2)
    job=0
  if m.x>=465 and m.x<855 and m.y>=225 and m.y<490:
   job=clampi(int((m.y-225)/40),0,JOBS[faction].size()-1)
  if m.x>=470 and m.x<700 and m.y>=535 and m.y<570:
   suit=clampi(int((m.x-470)/48),0,4)
  if m.y>=605 and m.y<676 and m.x>=445 and m.x<828:
   _start()
func _tick_player(dt: float) -> void:
 if player.is_empty(): return
 var v := Vector2.ZERO
 if Input.is_key_pressed(KEY_A): v.x-=1
 if Input.is_key_pressed(KEY_D): v.x+=1
 if Input.is_key_pressed(KEY_W): v.y-=1
 if Input.is_key_pressed(KEY_S): v.y+=1
 var job_name: String=JOBS[int(player.fac)][int(player.klass)]
 var multiplier := 1.35 if job_name=="Cyberpsycho" else 1.0
 _move(player,v.normalized()*SPEED*multiplier*dt)
 player.aim=(get_global_mouse_position()-player.pos).normalized()
 player.cool=maxf(0.0,float(player.cool)-dt)
 player.ability=maxf(0.0,float(player.ability)-dt)
 player.invisible=maxf(0.0,float(player.invisible)-dt)
 player.shield=maxf(0.0,float(player.shield)-dt)
 if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and float(player.cool)<=0:
  _fire(player,true)
 if Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
  if float(player.ability)<=0:
   _special()
func _move(actor: Dictionary,delta: Vector2) -> void:
 var old: Vector2=actor.pos
 var next := old+Vector2(delta.x,0)
 if _walkable(next): actor.pos=next
 old=actor.pos
 next=old+Vector2(0,delta.y)
 if _walkable(next): actor.pos=next
func _walkable(p: Vector2) -> bool:
 if not WORLD.grow(-18).has_point(p): return false
 for r in covers:
  if r.grow(13).has_point(p): return false
 return true
func _fire(actor: Dictionary,owned: bool) -> void:
 var name_v: String=JOBS[int(actor.fac)][int(actor.klass)]
 var spread := 0.08 if name_v=="Snipeout" else 0.15
 var dir: Vector2=actor.aim.rotated(rng.randf_range(-spread,spread))
 var power := 21.0
 var interval := 0.19
 if name_v=="The Big": power=42.0; interval=0.48
 if name_v=="Gunner": power=14.0; interval=0.09
 if name_v=="Snipeout": power=58.0; interval=0.85
 if name_v=="Punk Bruiser": power=28.0; interval=0.28
 bullets.append({"pos":actor.pos+dir*19,"velocity":dir*850,"life":1.0,"damage":power,"team":int(actor.team),"pierce":name_v=="Snipeout"})
 actor.cool=interval
 for i in range(5):
  _spark(actor.pos+dir*23,dir.rotated(rng.randf_range(-1.5,1.5))*rng.randf_range(35,105),Color("#ffd375"))
func _special() -> void:
 var name_v: String=JOBS[int(player.fac)][int(player.klass)]
 player.ability=7.0
 match name_v:
  "First Warrior":
   player.invisible=3.5
   message="OPTICAL CAMOUFLAGE"
  "The Rocky":
   player.shield=4.5
   _area_damage(player.pos,64,46,1)
   message="SHIELD BASH"
  "Raven":
   _area_damage(get_global_mouse_position(),145,45,1)
   message="CHAIN LIGHTNING"
  "Netrunner":
   for e in enemies:
    if e.hp>0 and e.pos.distance_to(player.pos)<280: e.slow=4.0
   message="QUICKHACK / EMP"
  "Cyberpsycho","Punk Bruiser":
   _area_damage(player.pos,95,65,1)
   message="MANTIS OVERDRIVE"
  "Snipeout","The Big","Gunner","Shooty":
   for i in range(4):
    player.cool=0
    _fire(player,true)
   message="WEAPON OVERCHARGE"
func _area_damage(center: Vector2,radius: float,damage: float,target_team: int) -> void:
 for e in enemies:
  if int(e.team)==target_team and e.pos.distance_to(center)<radius:
   e.hp=maxf(0.0,float(e.hp)-damage)
 for i in range(30):
  _spark(center,Vector2.RIGHT.rotated(rng.randf_range(-PI,PI))*rng.randf_range(50,200),Color("#32e8fa"))
func _tick_ai(dt: float) -> void:
 for e in enemies:
  if e.hp<=0: continue
  e.cool=maxf(0.0,float(e.cool)-dt)
  e.slow=maxf(0.0,float(e.slow)-dt)
  var target: Vector2=player.pos
  if player.invisible>0 and not allies.is_empty(): target=allies[0].pos
  var diff: Vector2=target-e.pos
  e.aim=diff.normalized()
  if diff.length()>195:
   _move(e,e.aim*dt*(42 if e.slow>0 else 85))
  elif diff.length()<115:
   _move(e,-e.aim*dt*55)
  if diff.length()<560 and e.cool<=0 and _sight(e.pos,target):
   _fire(e,false)
 for a in allies:
  if a.hp<=0: continue
  a.cool=maxf(0.0,float(a.cool)-dt)
  var closest: Dictionary={}
  var dist := INF
  for e in enemies:
   if e.hp>0 and a.pos.distance_to(e.pos)<dist:
    dist=a.pos.distance_to(e.pos)
    closest=e
  if not closest.is_empty():
   a.aim=(closest.pos-a.pos).normalized()
   if dist>235: _move(a,a.aim*dt*98)
   if dist<560 and a.cool<=0 and _sight(a.pos,closest.pos): _fire(a,true)
func _sight(a: Vector2,b: Vector2) -> bool:
 for r in covers:
  if r.intersects_segment(a,b)!=null: return false
 return true
func _tick_bullets(dt: float) -> void:
 for i in range(bullets.size()-1,-1,-1):
  var b: Dictionary=bullets[i]
  var old: Vector2=b.pos
  b.pos+=b.velocity*dt
  b.life-=dt
  var hit := false
  if not WORLD.has_point(b.pos): hit=true
  for c in covers:
   if c.intersects_segment(old,b.pos)!=null and not b.pierce: hit=true
  var victims: Array=enemies if int(b.team)==0 else [player]
  if int(b.team)==1:
   victims=[player]
   victims.append_array(allies)
  for v in victims:
   if float(v.hp)>0 and v.pos.distance_to(b.pos)<17:
    var damage: float=b.damage
    if v.has("shield") and float(v.shield)>0: damage*=0.35
    v.hp=maxf(0.0,float(v.hp)-damage)
    if int(b.team)==1 and v==player: flash=0.13
    if float(v.hp)<=0:
     score+=1
     message="TARGET ELIMINATED"
    hit=true
    break
  if hit or b.life<=0:
   for j in range(4):
    _spark(b.pos,Vector2.RIGHT.rotated(rng.randf_range(-PI,PI))*rng.randf_range(20,110),Color("#ff7455"))
   bullets.remove_at(i)
func _spark(p: Vector2,v: Vector2,c: Color) -> void:
 particles.append({"pos":p,"vel":v,"life":0.35,"col":c})
func _tick_effects(dt: float) -> void:
 for i in range(particles.size()-1,-1,-1):
  var p: Dictionary=particles[i]
  p.pos+=p.vel*dt
  p.vel*=0.91
  p.life-=dt
  if p.life<=0: particles.remove_at(i)
func _interact() -> void:
 if mode==0:
  if player.pos.distance_to(hostage)<60:
   hostage_free=true
   message="HOSTAGE SECURED / REACH EXTRACTION"
 elif mode==2:
  for i in range(2):
   if not hacked[i] and player.pos.distance_to(terminals[i])<68:
    hacked[i]=true
    message="DATA EXTRACTED "+str(int(hacked[0])+int(hacked[1]))+"/2"
  if hacked[0] and hacked[1] and player.pos.distance_to(Vector2(954,310))<75:
   _win("MAINFRAME BREACHED")
func _objectives() -> void:
 if player.hp<=0:
  game_result="FLATLINED // PRESS R TO RESTART"
  phase="dead"
  return
 if mode==0 and hostage_free:
  hostage=hostage.lerp(player.pos+Vector2(28,26),minf(1.0,get_process_delta_time()*2))
  if player.pos.distance_to(Vector2(95,350))<65: _win("HOSTAGE EXTRACTED")
 if mode==1:
  var alive := 0
  for e in enemies:
   if e.hp>0: alive+=1
  if alive==0: _win("ENEMY BASE CLEARED")
func _win(text_v: String) -> void:
 game_result=text_v+" // PRESS R TO REPLAY"
 phase="dead"
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,SIZE),Color("#050b16"))
 _ambient()
 if phase=="menu":
  _menu_draw()
 else:
  _map_draw()
  for a in allies:
   if a.hp>0: _sprite(a)
  for e in enemies:
   if e.hp>0: _sprite(e)
  if player.hp>0: _sprite(player)
  for b in bullets:
   draw_line(b.pos-b.velocity.normalized()*19,b.pos,b_team_color(b.team),3.0)
  for p in particles:
   draw_circle(p.pos,3.0*p.life/0.35,p.col)
  _hud()
  if phase=="dead":
   draw_rect(Rect2(330,255,670,135),Color("#080f1f"))
   draw_rect(Rect2(330,255,670,135),Color("#ff4b6d"),false,2)
   _text(Vector2(361,305),"OPERATION TERMINATED",30,Color("#ffce55"))
   _text(Vector2(361,352),game_result,16,Color("#33e3ee"))
 if flash>0:
  draw_rect(Rect2(Vector2.ZERO,SIZE),Color(1,0.12,0.1,flash*1.9))
func b_team_color(team: int) -> Color:
 return Color("#5df3ff") if team==0 else Color("#ff6880")
func _ambient() -> void:
 for i in range(38):
  var p := Vector2(float((i*163)%1280),float((i*83)%720))
  draw_circle(p,1.5,Color(0.13,0.6,0.7,0.25))
func _text(pos: Vector2,t: String,size: int=17,c: Color=Color.WHITE) -> void:
 draw_string(ui_font,pos,t,HORIZONTAL_ALIGNMENT_LEFT,-1,size,c)
func _rect(r: Rect2,fill: Color,border: Color) -> void:
 draw_rect(r,fill)
 draw_rect(r,border,false,2.0)
func _menu_draw() -> void:
 _text(Vector2(68,107),"FUTURESOUL",65,Color("#38e2f3"))
 _text(Vector2(72,145),"REALTIME CYBERPUNK // LIVE FIRE EDITION",18,Color("#ecca62"))
 _rect(Rect2(53,180,835,505),Color("#0d1929"),Color("#2b5868"))
 _text(Vector2(74,212),"MISSION TYPE",20,Color("#fbd864"))
 for i in range(3):
  _option(Vector2(77,225+i*40),["01   MAELSTROM KIDNAP","02   FACTION WAR","03   HACK THE BASE"][i],mode==i)
 _text(Vector2(74,367),"CHOOSE YOUR FACTION",20,Color("#fbd864"))
 for i in range(3):
  _option(Vector2(77,380+i*40),TEAMS[i],faction==i)
 _text(Vector2(468,211),"CLASS & CYBERWARE",20,Color("#fbd864"))
 for i in range(JOBS[faction].size()):
  _option(Vector2(466,225+i*40),JOBS[faction][i].to_upper(),job==i)
 _text(Vector2(467,521),"ARMOR TINT",16,Color("#fbd864"))
 for i in range(palette.size()):
  draw_rect(Rect2(470+i*48,539,33,33),palette[i])
  if suit==i: draw_rect(Rect2(467+i*48,536,39,39),Color.WHITE,false,2)
 _rect(Rect2(446,605,380,71),Color("#13626c"),Color("#4ff8ed"))
 _text(Vector2(482,648),"DEPLOY / PLAY OFFLINE",24,Color.WHITE)
 _rect(Rect2(917,180,300,505),Color("#101b29"),Color("#2b5868"))
 _text(Vector2(942,216),"OPERATIVE PREVIEW",19,Color("#fbd864"))
 var dummy := _actor(Vector2(1061,360),0,faction,job)
 dummy.color=suit
 _sprite(dummy,4.1)
 _text(Vector2(945,494),JOBS[faction][job].to_upper(),22,Color("#30ebf3"))
 _text(Vector2(945,526),TEAMS[faction],16,Color("#eaca59"))
 _text(Vector2(944,575),"WASD / MOVE",16)
 _text(Vector2(944,602),"MOUSE / SHOOT",16)
 _text(Vector2(944,629),"SPACE / SKILL",16)
 _text(Vector2(944,656),"E / OBJECTIVE",16)
 _text(Vector2(68,709),net_note,14,Color("#91acb7"))
func _option(pos: Vector2,t: String,on: bool) -> void:
 _rect(Rect2(pos,Vector2(365 if pos.x<430 else 373,35)),Color("#1a5863") if on else Color("#142236"),Color("#3ce9e4") if on else Color("#355264"))
 _text(pos+Vector2(10,24),t,16,Color("#ffe37b") if on else Color("#b5cbda"))
func _map_draw() -> void:
 draw_rect(WORLD,Color("#162b36"))
 for x in range(24):
  var px := WORLD.position.x+x*46.0
  draw_line(Vector2(px,WORLD.position.y),Vector2(px,WORLD.end.y),Color("#1c3a43"),1)
 for y in range(14):
  var py := WORLD.position.y+y*46.0
  draw_line(Vector2(WORLD.position.x,py),Vector2(WORLD.end.x,py),Color("#1c3a43"),1)
 for i in range(50):
  var x := WORLD.position.x+float((i*117)%1040)
  var y := WORLD.position.y+float((i*191)%530)
  draw_rect(Rect2(x,y,10+(i%3)*6,2),Color("#25545e"))
  if i%4==0:
   draw_circle(Vector2(x,y),2,Color("#12b8c3"))
 for c in covers:
  draw_rect(c.grow(9),Color(0.0,0.0,0.0,0.36))
  draw_rect(c,Color("#314455"))
  draw_rect(Rect2(c.position,Vector2(c.size.x,6)),Color("#667b8e"))
  draw_rect(Rect2(c.position+Vector2(5,12),Vector2(c.size.x-10,4)),Color("#142835"))
  draw_rect(c,Color("#080e1e"),false,2)
 for d in decor:
  draw_circle(d,4,Color("#2d6368"))
 for i in range(2):
  var p: Vector2=terminals[i]
  draw_rect(Rect2(p-Vector2(20,23),Vector2(40,42)),Color("#19232e"))
  draw_rect(Rect2(p-Vector2(14,18),Vector2(28,23)),Color("#24bfe0") if hacked[i] else Color("#ecce4b"))
  _text(p+Vector2(-19,37),"DATA",13,Color("#ffdd70"))
 if mode==0:
  draw_circle(hostage,15,Color("#f7cf65"))
  _text(hostage+Vector2(-13,5),"VIP",13,Color("#111a23"))
  draw_arc(Vector2(95,350),42,0,TAU,32,Color("#2fecdc"),3)
 if mode==2:
  draw_rect(Rect2(922,283,68,55),Color("#16252b"))
  draw_rect(Rect2(927,291,58,34),Color("#f36b78") if hacked[0] and hacked[1] else Color("#496274"))
  _text(Vector2(932,347),"CORE",13,Color("#f4db66"))
 draw_rect(WORLD,Color("#31707b"),false,3)
func _sprite(a: Dictionary,mult: float=1.0) -> void:
 var pos: Vector2=a.pos
 var angle: float=a.aim.angle()+PI/2
 var team: int=a.team
 var primary: Color=palette[int(a.color)] if team==0 else Color("#e74e72")
 if float(a.invisible)>0: primary.a=0.36
 draw_set_transform(pos,angle,Vector2(mult,mult))
 draw_circle(Vector2(0,5),18,Color(0,0,0,0.35))
 draw_rect(Rect2(-11,-10,22,25),Color("#060a13"))
 draw_rect(Rect2(-9,-8,18,19),primary)
 draw_rect(Rect2(-6,-18,12,12),Color("#b69a86"))
 draw_rect(Rect2(-9,-19,18,6),Color("#152c36"))
 draw_rect(Rect2(-7,-17,14,4),primary.darkened(0.3))
 draw_rect(Rect2(-7,-13,5,3),Color("#48f8f5"))
 draw_rect(Rect2(2,-13,5,3),Color("#48f8f5"))
 draw_rect(Rect2(-15,-5,6,17),Color("#6a7489"))
 draw_rect(Rect2(9,-5,6,17),Color("#6a7489"))
 draw_rect(Rect2(-9,12,7,10),Color("#121b29"))
 draw_rect(Rect2(2,12,7,10),Color("#121b29"))
 draw_rect(Rect2(8,-7,7,21),Color("#111e2b"))
 draw_rect(Rect2(9,-20,5,24),Color("#f6db75"))
 draw_rect(Rect2(-6,-2,12,5),Color("#142432"))
 draw_set_transform(Vector2.ZERO)
 if mult==1.0:
  draw_rect(Rect2(pos+Vector2(-19,-30),Vector2(38,4)),Color("#0c1623"))
  draw_rect(Rect2(pos+Vector2(-18,-29),Vector2(36.0*float(a.hp)/float(a.max),2)),Color("#47e4ed") if team==0 else Color("#fd617e"))
  if float(a.shield)>0: draw_arc(pos,22,0,TAU,26,Color("#7bdfff"),2)
func _hud() -> void:
 draw_rect(Rect2(0,0,1280,64),Color("#0b1221"))
 _text(Vector2(42,37),"FUTURESOUL  /  "+["HOSTAGE RESCUE","FACTION WAR","HACK THE BASE"][mode],22,Color("#f0d96c"))
 _text(Vector2(925,37),"LIVE  "+str(snappedf(elapsed,0.1))+"s",17,Color("#43f5f0"))
 draw_rect(Rect2(1107,80,163,562),Color("#0b1523"))
 _text(Vector2(1122,110),"OPERATIVE",15,Color("#ecd66b"))
 _text(Vector2(1122,144),JOBS[faction][job],17,Color("#40ddea"))
 _text(Vector2(1122,181),"HP "+str(ceili(player.hp))+"/"+str(ceili(player.max)),15)
 _text(Vector2(1122,225),"KILLS "+str(score),15,Color("#eeca62"))
 _text(Vector2(1122,275),"WASD MOVE",14)
 _text(Vector2(1122,306),"LMB SHOOT",14)
 _text(Vector2(1122,338),"SPACE SKILL",14)
 _text(Vector2(1122,370),"E INTERACT",14)
 _text(Vector2(1122,411),"ESC MENU",14)
 _text(Vector2(1122,458),"MISSION",15,Color("#ecca62"))
 if mode==2:
  _text(Vector2(1122,489),str(int(hacked[0])+int(hacked[1]))+"/2 DATA",16,Color("#37e8ea"))
 if mode==0:
  _text(Vector2(1122,489),"VIP SECURED" if hostage_free else "LOCATE VIP",13,Color("#37e8ea"))
 _text(Vector2(40,692),message,17,Color("#ffd66a"))
 var cross := get_global_mouse_position()
 draw_arc(cross,10,0,TAU,22,Color("#d3f5f7"),1.5)
 draw_line(cross+Vector2(-16,0),cross+Vector2(-5,0),Color.WHITE,1)
 draw_line(cross+Vector2(5,0),cross+Vector2(16,0),Color.WHITE,1)
