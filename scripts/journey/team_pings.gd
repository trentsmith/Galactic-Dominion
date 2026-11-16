class_name TeamPings
extends Node3D
## Host derives the position from the controlled ship, never from client coordinates.
const TYPES=["LOOK HERE","DANGER","REGROUP"]
var battle: FreeRoamMatch
var records: Array[Dictionary]=[]
var cooldowns: Dictionary={}
var visuals: Dictionary={}
var clock:=0.0
var serial:=0
var hint: Label
func _ready() -> void:
 if battle.network_role=="server":return
 var layer:=CanvasLayer.new();layer.layer=6;add_child(layer)
 hint=Label.new();hint.position=Vector2(390,110);hint.size=Vector2(500,60);hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.add_theme_font_size_override("font_size",14);hint.add_theme_constant_override("outline_size",5);layer.add_child(hint)
func request(kind: int=0) -> void:
 if battle.network_role=="client":
  var session:=battle.get_parent() as OnlineSession
  if session!=null:session.ship_event.rpc_id(1,"ping",kind)
 else:add_ping(1,battle.pilot.ship,kind)
func add_ping(owner: int,ship: CombatShip,kind: int) -> bool:
 if battle.network_role=="client" or not is_instance_valid(ship) or not ship.alive or kind not in range(3) or float(cooldowns.get(owner,-10))>clock-2:return false
 cooldowns[owner]=clock;serial+=1
 var direction: Vector3=-ship.global_basis.z
 var at: Vector3=ship.global_position+direction*600
 var query:=PhysicsRayQueryParameters3D.create(ship.global_position+direction*6,ship.global_position+direction*2000,3);query.exclude=[ship.get_rid()]
 var hit:=get_world_3d().direct_space_state.intersect_ray(query)
 if not hit.is_empty():at=hit.position
 var target:=ship.targeting.target
 if is_instance_valid(target) and target.alive and ship.position.distance_to(target.position)<1400 and direction.dot(ship.position.direction_to(target.position))>.85:at=target.position
 var owned: Array[Dictionary]=[]
 for record in records:
  if int(record.owner)==owner:owned.append(record)
 while owned.size()>=3:
  var old: Dictionary=owned.pop_front();records.erase(old)
 records.append({"id":serial,"owner":owner,"team":ship.team,"name":ship.callsign.left(32),"kind":kind,"at":JourneyState.pack(at),"remaining":45.0})
 if records.size()>18:records.pop_front()
 return true
func _physics_process(delta: float) -> void:
 clock+=delta
 if battle.network_role!="client":
  for record in records:record.remaining-=delta
  records=records.filter(func(record):return record.remaining>0)
 if battle.network_role=="server":return
 render_markers()
func snapshot(team: int) -> Array:
 return records.filter(func(record):return int(record.team)==team).duplicate(true)
func forget_owner(owner: int) -> void:
 cooldowns.erase(owner)
func apply_snapshot(data: Array) -> void:
 if battle.network_role!="client":return
 records.clear()
 for value in data:
  if records.size()>=18:break
  if not value is Dictionary or not value.get("kind") in range(3):continue
  var at:=JourneyState.coordinates(value.get("at"))
  if at.is_empty():continue
  records.append({"id":int(JourneyState.number(value.get("id",0),0,999999999)),"owner":int(JourneyState.number(value.get("owner",0),0,2147483647)),"team":int(JourneyState.number(value.get("team",0),0,4)),"name":str(value.get("name","Pilot")).left(32),"kind":int(value.kind),"at":at,"remaining":JourneyState.number(value.get("remaining",0),0,45)})
func render_markers() -> void:
 if not is_instance_valid(battle.pilot.ship):return
 var live: Dictionary={};var nearest: Dictionary={};var distance:=INF
 for record in records:
  var id:=int(record.id);live[id]=true
  if not visuals.has(id):
   var root:=Node3D.new();add_child(root);visuals[id]=root
   var color: Color=[Color(.45,.85,1),Color(1,.4,.2),Color(.5,1,.65)][int(record.kind)]
   SpaceModelFactory.ring(root,Vector3.ZERO,6,.2,color,"TeamPing",true)
   var label:=Label3D.new();label.name="Caption";label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=true;label.position.y=12;label.pixel_size=.04;label.modulate=color;root.add_child(label)
  var actor: Node3D=visuals[id];actor.position=JourneyState.vector(record.at);actor.visible=not battle.scenic_hud
  (actor.get_node("Caption") as Label3D).text=TYPES[int(record.kind)]+" / "+str(record.name)
  var range_value:=actor.position.distance_to(battle.pilot.ship.position)
  if range_value<distance:distance=range_value;nearest=record
 for id in visuals.keys():
  if not live.has(id):visuals[id].queue_free();visuals.erase(id)
 hint.visible=not battle.scenic_hud and not battle.map_panel.visible
 hint.text=""
 if not nearest.is_empty():
  var direction: Vector3=battle.camera.global_basis.inverse()*(JourneyState.vector(nearest.at)-battle.pilot.ship.position).normalized()
  hint.text="TEAM / %s · %s · %dm · %s"%[TYPES[int(nearest.kind)],nearest.name,int(distance),"BEHIND" if direction.z>0 else "LEFT" if direction.x<-.2 else "RIGHT" if direction.x>.2 else "AHEAD"]
