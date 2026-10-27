extends Node2D
# FUTURESOUL — tactical prototype (Godot 4.x)
const CELL := 48
const O := Vector2(88, 116)
const W := 22
const H := 11
const CYAN := Color("#29e5e0")
const HOT := Color("#f34e74")
const GOLD := Color("#f8df55")
const BG := Color("#080e1c")
const FACTIONS := ["MAELSTROM", "EDGERUNNERS", "KOBANTEC"]
const CLASSES := [
 ["Gunner","Punk Bruiser","Shooty"],
 ["The Big","Snipeout","Cyberpsycho","Netrunner"],
 ["First Warrior","The Rocky","Raven"]
]
var mode := 0
var faction := 1
var class_idx := 0
var tint_idx := 0
var palette := [Color("#24d8e3"),Color("#ff5b88"),Color("#ffce54"),Color("#ad86ff"),Color("#8ffa8a")]
var page := "menu"
var status := "CHOOSE YOUR OPERATION"
var units: Array = []
var blocks: Array = []
var effects: Array = []
var consoles := [Vector2i(4,3), Vector2i(17,7)]
var bases := [Vector2i(2,5), Vector2i(19,5)]
var hostage := Vector2i(17,5)
var extraction := Vector2i(1,5)
var acquired := [false,false]
var breach := false
var hack_pos := -1
var hack_path: Array = []
var hack_sequence: Array = []
var hack_matrix: Array = []
var active_team := 0
var selected := -1
var action := "move"
var round_no := 1
var game_over := false
var offline := true
var net_role := "offline"
var bot_busy := false
var ip_text := "127.0.0.1"
var ip_focus := false
var noise := FastNoiseLite.new()
var rng := RandomNumberGenerator.new()
var tick := 0.0

func _ready() -> void:
 rng.seed = 246824
 noise.seed = 7707
 noise.frequency = 0.15
 set_process(true)
 queue_redraw()
 multiplayer.peer_connected.connect(_on_peer_connected)
 multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _process(delta: float) -> void:
 tick += delta
 queue_redraw()

func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,Vector2(1280,720)), BG)
 _background()
 if page == "menu":
  _menu()
 else:
  _world()
  _hud()
  if page == "hack":
   _hacking()
  if game_over:
   _panel(Rect2(345,230,590,220),Color("#121c2d"),HOT)
   _txt(Vector2(391,300),"OPERATION COMPLETE",31,GOLD)
   _txt(Vector2(391,352),status,18,CYAN)
   _txt(Vector2(391,399),"ESC  /  RETURN TO HQ",16,Color.WHITE)

func _background() -> void:
 for i in range(45):
  var x := float((i * 179 + 21) % 1280)
  var y := float((i * 83 + 19) % 720)
  draw_rect(Rect2(x,y,2,2),Color("#183346"))
 draw_rect(Rect2(0,0,1280,6),CYAN.darkened(0.6))
 draw_rect(Rect2(0,709,1280,11),Color("#101d32"))

func _panel(rect: Rect2, fill: Color, edge: Color) -> void:
 draw_rect(rect,fill)
 draw_rect(rect,edge,false,2)
 draw_line(rect.position+Vector2(0,16),rect.position+Vector2(16,0),edge,2)

func _txt(pos: Vector2, value: String, size: int = 16, color: Color = Color.WHITE) -> void:
 draw_string(ThemeDB.fallback_font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func _button(rect: Rect2, title: String, on: bool = false) -> void:
 _panel(rect,Color("#26364a") if on else Color("#101d2e"),CYAN if on else Color("#486073"))
 _txt(rect.position+Vector2(13,rect.size.y*0.67),title,17,GOLD if on else Color("#d5e5f3"))

func _menu() -> void:
 _txt(Vector2(76,94),"F U T U R E S O U L",48,CYAN)
 _txt(Vector2(81,126),"NEON TACTICS  //  PROTOCOL 2077",15,GOLD)
 _panel(Rect2(70,162,730,453),Color("#0f1b2c"),Color("#385c69"))
 _txt(Vector2(96,197),"01  OPERATION",19,GOLD)
 for i in range(3):
  _button(Rect2(96+i*225,212,212,49),["MAELSTROM KIDNAP","FACTION WAR","HACK THE BASE"][i],mode == i)
 _txt(Vector2(96,302),"02  FACTION",19,GOLD)
 for i in range(3):
  _button(Rect2(96+i*225,317,212,46),FACTIONS[i],faction == i)
 _txt(Vector2(96,403),"03  OPERATIVE / CYBERWARE",19,GOLD)
 for i in range(CLASSES[faction].size()):
  var x := 96 + (i % 3) * 225
  var y := 421 + int(i / 3) * 53
  _button(Rect2(x,y,212,43),CLASSES[faction][i].to_upper(),class_idx == i)
 _txt(Vector2(96,558),"ARMOUR COLOR",16,GOLD)
 for i in range(palette.size()):
  draw_rect(Rect2(260+i*42,541,29,29),palette[i])
  if i == tint_idx:
   draw_rect(Rect2(257+i*42,538,35,35),Color.WHITE,false,2)
 _button(Rect2(96,636,212,49),"SOLO / VS BOTS",false)
 _button(Rect2(321,636,215,49),"HOST LAN",false)
 _button(Rect2(549,636,208,49),"JOIN LAN",false)
 _panel(Rect2(826,162,378,453),Color("#10192a"),CYAN.darkened(0.5))
 _txt(Vector2(849,196),"OPERATIVE DOSSIER",19,GOLD)
 _portrait(Vector2(974,322),3.5,palette[tint_idx],faction)
 _txt(Vector2(850,453),CLASSES[faction][class_idx].to_upper(),22,CYAN)
 _txt(Vector2(850,482),FACTIONS[faction],15,GOLD)
 _txt(Vector2(850,523),"TACTICAL // TURN BASED",16)
 _txt(Vector2(850,553),"NEON CITY  -  DISTRICT 07",14,Color("#8aaec1"))
 _txt(Vector2(90,706),"LAN IP: "+ip_text+"   (CLICK IP / TYPE ADDRESS / ENTER)",13,Color("#8fa8b8"))

func _portrait(pos: Vector2, scale_v: float, tint: Color, team: int) -> void:
 draw_set_transform(pos,0,Vector2(scale_v,scale_v))
 draw_rect(Rect2(-10,-9,20,18),Color("#08101d"))
 draw_rect(Rect2(-7,-10,14,7),Color("#29364b"))
 draw_rect(Rect2(-6,-8,12,7),Color("#b98c80"))
 draw_rect(Rect2(-8,-12,16,5),tint.darkened(0.2))
 draw_rect(Rect2(-7,-2,14,14),tint)
 draw_rect(Rect2(-4,0,8,9),Color("#182335"))
 draw_rect(Rect2(-10,0,4,10),Color("#76879a"))
 draw_rect(Rect2(6,0,4,10),Color("#76879a"))
 draw_rect(Rect2(-6,11,5,8),Color("#263047"))
 draw_rect(Rect2(1,11,5,8),Color("#263047"))
 draw_rect(Rect2(-5,-5,4,2),CYAN if team != 0 else HOT)
 draw_rect(Rect2(2,-5,4,2),CYAN if team != 0 else HOT)
 draw_rect(Rect2(9,3,9,3),GOLD)
 draw_set_transform(Vector2.ZERO)

func _init_game(is_offline: bool) -> void:
 offline = is_offline
 page = "battle"
 units.clear()
 blocks.clear()
 effects.clear()
 acquired = [false,false]
 breach = false
 game_over = false
 active_team = 0
 selected = -1
 round_no = 1
 action = "move"
 status = "SELECT YOUR OPERATIVE"
 for x in range(W):
  for y in range(H):
   if x == 0 or y == 0 or x == W-1 or y == H-1:
    blocks.append(Vector2i(x,y))
 for p in [Vector2i(7,2),Vector2i(7,3),Vector2i(7,7),Vector2i(7,8),Vector2i(14,2),Vector2i(14,3),Vector2i(14,7),Vector2i(14,8),Vector2i(10,5),Vector2i(11,5),Vector2i(10,6),Vector2i(11,4)]:
  blocks.append(p)
 for i in range(3):
  _spawn(0,Vector2i(3,4+i),faction if faction != 0 else 0,class_idx if i == 0 else i % CLASSES[faction].size(),i == 0)
  _spawn(1,Vector2i(18,4+i),0 if faction != 0 else 1,i % 3,false)
 selected = _team_unit(0)
 _broadcast()

func _spawn(team: int,pos: Vector2i,fac: int,klass: int,custom: bool) -> void:
 units.append({"team":team,"pos":pos,"fac":fac,"klass":klass,"hp":125 if CLASSES[fac][klass] in ["Gunner","The Rocky"] else 100,"max_hp":125 if CLASSES[fac][klass] in ["Gunner","The Rocky"] else 100,"ap":2,"color":tint_idx if custom else (2 if team == 1 else 0),"shield":false,"stun":0,"hidden":false})

func _tile(pos: Vector2i) -> Vector2:
 return O + Vector2(pos.x*CELL,pos.y*CELL)

func _world() -> void:
 draw_rect(Rect2(64,94,1100,555),Color("#07111b"))
 for y in range(H):
  for x in range(W):
   var p := _tile(Vector2i(x,y))
   var n := noise.get_noise_2d(float(x),float(y))
   var floor_c := Color("#152535") if n > -0.1 else Color("#1b2d3c")
   draw_rect(Rect2(p,Vector2(CELL-1,CELL-1)),floor_c)
   if (x+y*3)%7 == 0:
    draw_rect(Rect2(p+Vector2(5,7),Vector2(21,2)),Color("#295469"))
   if (x*3+y)%11 == 0:
    draw_rect(Rect2(p+Vector2(34,34),Vector2(4,4)),CYAN.darkened(0.6))
   if Vector2i(x,y) in blocks:
    draw_rect(Rect2(p,Vector2(CELL-1,CELL-1)),Color("#0b1422"))
    draw_rect(Rect2(p+Vector2(3,3),Vector2(CELL-7,9)),Color("#405769"))
    draw_rect(Rect2(p+Vector2(5,15),Vector2(4,25)),Color("#30485c"))
    draw_rect(Rect2(p+Vector2(37,15),Vector2(4,25)),Color("#30485c"))
    draw_rect(Rect2(p,Vector2(CELL,CELL)),Color("#294558"),false,2)
 for i in range(2):
  var c := _tile(consoles[i])
  draw_rect(Rect2(c+Vector2(8,6),Vector2(32,32)),GOLD.darkened(0.2))
  draw_rect(Rect2(c+Vector2(12,10),Vector2(24,19)),CYAN if acquired[i] else Color("#314459"))
  _txt(c+Vector2(11,44),"DATA",10,GOLD)
 for i in range(2):
  var b := _tile(bases[i])
  draw_rect(Rect2(b+Vector2(1,1),Vector2(46,46)),HOT if i==1 else CYAN,false,3)
 if mode == 0:
  var h := _tile(hostage)
  draw_circle(h+Vector2(24,21),13,GOLD)
  _txt(h+Vector2(7,46),"VIP",12,Color.BLACK)
 if mode == 2:
  var pc := _tile(Vector2i(19,3))
  draw_rect(Rect2(pc+Vector2(7,7),Vector2(34,34)),HOT)
  _txt(pc+Vector2(8,29),"CORE",11,Color.BLACK)
 if selected >= 0 and selected < units.size() and int(units[selected].team) == active_team and not game_over:
  var u: Dictionary = units[selected]
  for x in range(1,W-1):
   for y in range(1,H-1):
    var gp := Vector2i(x,y)
    if gp in blocks or _occupied(gp) != -1:
     continue
    if action == "move" and int(u.ap)>0 and _distance(u.pos,gp)<=4:
     draw_rect(Rect2(_tile(gp)+Vector2(3,3),Vector2(42,42)),Color(0.1,0.85,0.78,0.12))
 for i in range(units.size()):
  var u: Dictionary = units[i]
  if int(u.hp)<=0:
   continue
  var at := _tile(u.pos)+Vector2(24,25)
  draw_circle(at+Vector2(0,15),16,Color(0,0,0,0.55))
  if i == selected:
   draw_arc(at,21,0,TAU,24,GOLD,3)
  _portrait(at,1.1,palette[int(u.color)] if int(u.team)==0 else HOT,int(u.fac))
  draw_rect(Rect2(at+Vector2(-21,-33),Vector2(42,5)),Color("#10151e"))
  draw_rect(Rect2(at+Vector2(-20,-32),Vector2(40.0*float(u.hp)/float(u.max_hp),3)),CYAN if int(u.team)==0 else HOT)
  if bool(u.shield):
   draw_arc(at,18,0,TAU,24,CYAN,2)
  if int(u.stun)>0:
   _txt(at+Vector2(-9,-39),"EMP",10,GOLD)
 for fx in effects:
  var fp := _tile(fx)+Vector2(24,24)
  draw_circle(fp,17,Color(1,0.7,0.25,0.28))
 _txt(Vector2(81,80),"NEON DISTRICT 07   //   "+["EXTRACTION","FACTION WAR","BREACH PROTOCOL"][mode],17,GOLD)

func _hud() -> void:
 _panel(Rect2(75,655,1100,57),Color("#0d1829"),Color("#365e6a"))
 _txt(Vector2(94,677),"ROUND %02d" % round_no,16,GOLD)
 _txt(Vector2(94,698),"TEAM "+str(active_team+1),13,CYAN if active_team==0 else HOT)
 for i in range(4):
  _button(Rect2(265+i*137,663,128,40),["1 MOVE","2 SHOOT","3 SKILL","4 USE"][i],action==["move","shoot","skill","use"][i])
 _button(Rect2(851,663,143,40),"END TURN",false)
 _txt(Vector2(1008,681),"AP: "+str(units[selected].ap) if selected>=0 and selected < units.size() else "AP: --",15,GOLD)
 _txt(Vector2(1008,701),"TAB = NEXT",12,Color("#9eb4c3"))
 _txt(Vector2(1179,130),"STATUS",13,GOLD)
 var lines := status.split(" ",false,4)
 var sy := 160
 for t in lines:
  _txt(Vector2(1170,sy),t,13,CYAN)
  sy += 21
 _txt(Vector2(1170,280),"UNITS",13,GOLD)
 for i in range(units.size()):
  var u: Dictionary = units[i]
  _txt(Vector2(1170,307+i*42),("A" if int(u.team)==0 else "B")+" "+str(i+1),13,CYAN if int(u.team)==0 else HOT)
  _txt(Vector2(1170,322+i*42),str(u.hp)+" HP",12,GOLD)
 _txt(Vector2(1170,594),"TWO DATA",12,GOLD)
 _txt(Vector2(1170,614),str(int(acquired[0]))+" / "+str(int(acquired[1])),15,CYAN)

func _distance(a: Vector2i,b: Vector2i) -> int:
 return abs(a.x-b.x)+abs(a.y-b.y)

func _occupied(p: Vector2i) -> int:
 for i in range(units.size()):
  if int(units[i].hp)>0 and units[i].pos==p:
   return i
 return -1

func _team_unit(team: int) -> int:
 for i in range(units.size()):
  if int(units[i].team)==team and int(units[i].hp)>0:
   return i
 return -1

func _cycle() -> void:
 if selected < 0:
  selected = _team_unit(active_team)
  return
 for offset in range(1,units.size()+1):
  var i := (selected+offset)%units.size()
  if int(units[i].team)==active_team and int(units[i].hp)>0:
   selected=i
   return

func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  var k: int = event.keycode
  if page=="menu":
   if ip_focus and k==KEY_BACKSPACE and ip_text.length()>0:
    ip_text=ip_text.substr(0,ip_text.length()-1)
   elif k==KEY_ENTER:
    ip_focus=false
   elif ip_focus and event.unicode>=32 and event.unicode<=126 and ip_text.length()<40:
    ip_text+=char(event.unicode)
  elif k==KEY_ESCAPE:
   if page=="hack":
    page="battle"
   else:
    page="menu"
    multiplayer.multiplayer_peer=OfflineMultiplayerPeer.new()
  elif page=="battle" and not game_over:
   if k==KEY_1: action="move"
   if k==KEY_2: action="shoot"
   if k==KEY_3: action="skill"
   if k==KEY_4: action="use"
   if k==KEY_TAB: _cycle()
   if k==KEY_SPACE: _submit({"type":"end"})
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  var m := get_global_mouse_position()
  if page=="menu":
   _menu_click(m)
  elif page=="hack":
   _hack_click(m)
  elif page=="battle" and not game_over:
   if m.y>660:
    if m.x>=851 and m.x<997:
     _submit({"type":"end"})
    elif m.x>=265 and m.x<813:
     var ai := int((m.x-265)/137)
     action=["move","shoot","skill","use"][clampi(ai,0,3)]
   else:
    var p := Vector2i(floori((m.x-O.x)/CELL),floori((m.y-O.y)/CELL))
    if p.x>0 and p.x<W-1 and p.y>0 and p.y<H-1:
     var who := _occupied(p)
     if who>=0 and int(units[who].team)==active_team:
      selected=who
     else:
      _submit({"type":action,"pos":[p.x,p.y],"unit":selected})

func _menu_click(m: Vector2) -> void:
 if m.y>=212 and m.y<261 and m.x>=96 and m.x<758:
  mode=clampi(int((m.x-96)/225),0,2)
 elif m.y>=317 and m.y<363 and m.x>=96 and m.x<758:
  faction=clampi(int((m.x-96)/225),0,2)
  class_idx=0
 elif m.y>=421 and m.y<525 and m.x>=96 and m.x<758:
  var ix := clampi(int((m.x-96)/225),0,2)+3*int((m.y-421)/53)
  if ix < CLASSES[faction].size(): class_idx=ix
 elif m.y>=537 and m.y<580 and m.x>=260 and m.x<469:
  tint_idx=clampi(int((m.x-260)/42),0,4)
 elif m.y>=635 and m.y<688:
  if m.x>=96 and m.x<309:
   net_role="offline"
   _init_game(true)
  elif m.x>=321 and m.x<536:
   var peer := ENetMultiplayerPeer.new()
   if peer.create_server(7777,2)==OK:
    multiplayer.multiplayer_peer=peer
    net_role="host"
    _init_game(false)
    status="HOST  UDP 7777"
   else: status="NETWORK PORT ERROR"
  elif m.x>=549 and m.x<757:
   var peer := ENetMultiplayerPeer.new()
   if peer.create_client(ip_text,7777)==OK:
    multiplayer.multiplayer_peer=peer
    net_role="client"
    offline=false
    page="battle"
    status="CONNECTING TO HOST..."
   else: status="COULD NOT CONNECT"
 elif m.y>=691:
  ip_focus=true
  ip_text=""

func _submit(cmd: Dictionary) -> void:
 if net_role=="client":
  _remote_action.rpc_id(1,cmd)
 else:
  _apply(cmd,0)
  _broadcast()

@rpc("any_peer","reliable")
func _remote_action(cmd: Dictionary) -> void:
 if not multiplayer.is_server(): return
 var from := multiplayer.get_remote_sender_id()
 _apply(cmd,1 if from!=1 else 0)
 _broadcast()

func _apply(cmd: Dictionary,team: int) -> void:
 if game_over or page=="hack": return
 if active_team!=team:
  status="WAIT FOR YOUR TURN"
  return
 if cmd.type=="end":
  _end_turn()
  return
 var index := int(cmd.get("unit",-1))
 if index<0 or index>=units.size(): return
 var u: Dictionary=units[index]
 if int(u.team)!=team or int(u.hp)<=0 or int(u.ap)<=0: return
 var ar: Array=cmd.get("pos",[0,0])
 var p := Vector2i(int(ar[0]),int(ar[1]))
 if p.x<1 or p.x>=W-1 or p.y<1 or p.y>=H-1: return
 var dist := _distance(u.pos,p)
 match str(cmd.type):
  "move":
   if dist>4 or p in blocks or _occupied(p)>=0 or not _path_clear(u.pos,p):
    status="MOVEMENT BLOCKED"
    return
   u.pos=p
   u.ap-=1
   status="MOVED INTO COVER"
  "shoot":
   var victim := _occupied(p)
   if victim<0 or int(units[victim].team)==team or dist>8: return
   if not _line_clear(u.pos,p):
    status="LINE OF SIGHT BLOCKED"
    return
   var damage := 32
   if CLASSES[int(u.fac)][int(u.klass)]=="The Big": damage=48
   if CLASSES[int(u.fac)][int(u.klass)]=="Gunner": damage=39
   units[victim].hp=maxi(0,int(units[victim].hp)-damage)
   u.ap-=1
   effects=[p]
   status="DIRECT HIT  -"+str(damage)
  "skill":
   _skill(index,p)
  "use":
   if dist>1: return
   if mode==0 and p==hostage and team==0:
    breach=true
    u.ap-=1
    status="VIP FREED. ESCORT TO EVAC."
   elif mode==0 and breach and u.pos==extraction:
    _victory(team)
   elif mode==2:
    for ci in range(2):
     if p==consoles[ci] and not acquired[ci]:
      hack_pos=ci
      selected=index
      _begin_hack()
      return
    if p==Vector2i(19,3) and acquired[0] and acquired[1]:
     _victory(team)
   else:
    status="NO INTERACTION AVAILABLE"
 units[index]=u
 _check_victory()

func _path_clear(a: Vector2i,b: Vector2i) -> bool:
 var current := a
 while current.x!=b.x:
  current.x+=1 if b.x>current.x else -1
  if current in blocks or (_occupied(current)>=0 and current!=b): return false
 while current.y!=b.y:
  current.y+=1 if b.y>current.y else -1
  if current in blocks or (_occupied(current)>=0 and current!=b): return false
 return true

func _line_clear(a: Vector2i,b: Vector2i) -> bool:
 var steps := maxi(abs(a.x-b.x),abs(a.y-b.y))*3
 for i in range(1,steps):
  var t := float(i)/float(steps)
  var p := Vector2i(roundi(lerpf(a.x,b.x,t)),roundi(lerpf(a.y,b.y,t)))
  if p in blocks: return false
 return true

func _skill(index: int,p: Vector2i) -> void:
 var u: Dictionary=units[index]
 var name_v: String=CLASSES[int(u.fac)][int(u.klass)]
 var dist := _distance(u.pos,p)
 match name_v:
  "Gunner","Shooty","The Big","Snipeout":
   var target := _occupied(p)
   if target<0 or int(units[target].team)==int(u.team) or dist>10: return
   if name_v!="Snipeout" and not _line_clear(u.pos,p): return
   units[target].hp=maxi(0,int(units[target].hp)-(55 if name_v=="Snipeout" else 44))
   status="POWER SHOT"
  "Punk Bruiser","Cyberpsycho","First Warrior","The Rocky":
   if name_v=="First Warrior":
    u.hidden=true
    status="OPTICAL CAMOUFLAGE"
   else:
    if dist>2: return
    for i in range(units.size()):
     if int(units[i].team)!=int(u.team) and _distance(units[i].pos,p)<=1:
      units[i].hp=maxi(0,int(units[i].hp)-38)
    status="MELEE OVERLOAD"
  "Netrunner":
   var target := _occupied(p)
   if target<0 or dist>7 or int(units[target].team)==int(u.team): return
   units[target].stun=1
   status="WEAPONS DISABLED / EMP"
  "Raven":
   for i in range(units.size()):
    if int(units[i].team)!=int(u.team) and _distance(units[i].pos,p)<=2:
     units[i].hp=maxi(0,int(units[i].hp)-27)
   status="CHAIN LIGHTNING"
 u.ap-=1
 units[index]=u

func _end_turn() -> void:
 active_team=1-active_team
 if active_team==0: round_no+=1
 for i in range(units.size()):
  if int(units[i].team)==active_team:
   units[i].ap=0 if int(units[i].stun)>0 else 2
   units[i].stun=maxi(0,int(units[i].stun)-1)
   units[i].hidden=false
 selected=_team_unit(active_team)
 status="TEAM "+str(active_team+1)+"  //  YOUR TURN"
 if offline and active_team==1:
  _bot_turn()

func _bot_turn() -> void:
 for i in range(units.size()):
  var u: Dictionary=units[i]
  if int(u.team)!=1 or int(u.hp)<=0: continue
  var enemy := _team_unit(0)
  var best := 999
  for j in range(units.size()):
   if int(units[j].team)!=0 or int(units[j].hp)<=0: continue
   var d := _distance(u.pos,units[j].pos)
   if d<best:
    best=d
    enemy=j
  if enemy<0: break
  if best<=8 and _line_clear(u.pos,units[enemy].pos):
   units[enemy].hp=maxi(0,int(units[enemy].hp)-28)
   effects=[units[enemy].pos]
  else:
   var p: Vector2i=u.pos
   var e: Vector2i=units[enemy].pos
   var options := [Vector2i(signi(e.x-p.x),0),Vector2i(0,signi(e.y-p.y))]
   for direction in options:
    var step: Vector2i=p+direction
    if step not in blocks and _occupied(step)<0:
     units[i].pos=step
     break
 _check_victory()
 if not game_over:
  _end_turn()

func _check_victory() -> void:
 var a := 0
 var b := 0
 for u in units:
  if int(u.hp)>0:
   if int(u.team)==0: a+=1
   else: b+=1
 if a==0: _victory(1)
 elif b==0: _victory(0)
 elif mode==0 and breach:
  for u in units:
   if int(u.team)==0 and u.pos==extraction: _victory(0)

func _victory(team: int) -> void:
 game_over=true
 status=("EDGERUNNERS / TEAM 1" if team==0 else "DEFENDERS / TEAM 2")+" WIN"

func _begin_hack() -> void:
 hack_path.clear()
 hack_matrix.clear()
 var codes := ["1C","55","BD","E9","7A"]
 for row in range(5):
  var line: Array=[]
  for col in range(5):
   line.append(codes[rng.randi_range(0,4)])
  hack_matrix.append(line)
 hack_sequence=[hack_matrix[0][2],hack_matrix[3][2],hack_matrix[3][4]]
 page="hack"
 status="BREACH SEQUENCE REQUIRED"

func _hacking() -> void:
 draw_rect(Rect2(Vector2.ZERO,Vector2(1280,720)),Color(0,0,0,0.88))
 _panel(Rect2(105,65,1070,581),Color("#0b100e"),GOLD)
 _txt(Vector2(142,111),"FUTURESOUL // BREACH PROTOCOL",27,GOLD)
 _txt(Vector2(142,145),"CODE MATRIX  /  ROW-COLUMN ALTERNATION",16,CYAN)
 for row in range(5):
  for col in range(5):
   var r := Rect2(150+col*105,190+row*75,90,58)
   _panel(r,Color("#1d2616"),GOLD.darkened(0.5))
   _txt(r.position+Vector2(25,38),str(hack_matrix[row][col]),23,GOLD)
 _panel(Rect2(735,185,388,318),Color("#141c16"),GOLD)
 _txt(Vector2(765,224),"SEQUENCE REQUIRED",21,CYAN)
 for j in range(hack_sequence.size()):
  _button(Rect2(766+j*113,251,96,49),str(hack_sequence[j]),j<hack_path.size())
 _txt(Vector2(764,363),"BUFFER  "+str(hack_path.size())+"/3",20,GOLD)
 _txt(Vector2(764,399),"Start: top row",15)
 _txt(Vector2(764,430),"Then: same column / row",15)
 _txt(Vector2(765,472),"ESC TO ABORT",16,HOT)

func _hack_click(m: Vector2) -> void:
 var col := int((m.x-150)/105)
 var row := int((m.y-190)/75)
 if m.x<150 or m.y<190 or col<0 or col>=5 or row<0 or row>=5: return
 var choice := Vector2i(col,row)
 if hack_path.has(choice): return
 if hack_path.is_empty():
  if row!=0: return
 else:
  var last: Vector2i=hack_path[-1]
  if hack_path.size()%2==1 and col!=last.x: return
  if hack_path.size()%2==0 and row!=last.y: return
 hack_path.append(choice)
 var value: String=hack_matrix[row][col]
 if value!=str(hack_sequence[hack_path.size()-1]):
  status="BREACH FAILED. RETRY."
  _begin_hack()
  return
 if hack_path.size()==3:
  acquired[hack_pos]=true
  page="battle"
  if selected>=0: units[selected].ap=maxi(0,int(units[selected].ap)-1)
  status="DATA SHARD EXTRACTED "+str(int(acquired[0]))+"/2"
  _broadcast()

func _on_peer_connected(_id: int) -> void:
 if multiplayer.is_server(): _send_state.rpc_id(_id,_snapshot())

func _on_peer_disconnected(_id: int) -> void:
 status="NETWORK PLAYER DISCONNECTED"

func _snapshot() -> Dictionary:
 var serialized: Array=[]
 for u in units:
  var c: Dictionary=u.duplicate()
  var p: Vector2i=c.pos
  c.pos=[p.x,p.y]
  serialized.append(c)
 return {"units":serialized,"active_team":active_team,"round":round_no,"status":status,"acquired":acquired,"breach":breach,"over":game_over,"mode":mode}

func _broadcast() -> void:
 if net_role=="host" and multiplayer.is_server():
  _send_state.rpc(_snapshot())

@rpc("authority","call_remote","reliable")
func _send_state(s: Dictionary) -> void:
 if net_role!="client": return
 units=s.units
 for i in range(units.size()):
  var p: Array=units[i].pos
  units[i].pos=Vector2i(int(p[0]),int(p[1]))
 active_team=int(s.active_team)
 round_no=int(s.round)
 status=str(s.status)
 acquired=s.acquired
 breach=bool(s.breach)
 game_over=bool(s.over)
 mode=int(s.mode)
 page="battle"
 if selected<0: selected=_team_unit(1)
