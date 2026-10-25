class_name MegaWeapons
extends Node3D
## Match-local salvage. Neither inventory nor the online protocol is modified.
var battle: BattleMatch
var pickups: Array[Dictionary]=[]
var loadouts: Dictionary={}
var elapsed:=0.0
var status:="B: MEGA WEAPON / find glowing relics in space"
const LABELS=["SOLAR LANCE","GRAVITY NOVA"]
func _ready() -> void:
 for i in range(6):
  var root:=Node3D.new();root.position=Vector3(cos(i*TAU/6)*380,(i%3-1)*95,sin(i*TAU/6)*380);add_child(root)
  var shape:=PrismMesh.new();shape.size=Vector3(12,22,12)
  SpaceModelFactory.mesh(root,shape,Vector3.ZERO,Color(1,.65,.15) if i%2==0 else Color(.6,.3,1),"RelicCore",true)
  var ring:=SpaceModelFactory.ring(root,Vector3.ZERO,18,.5,Color(.3,.85,1),"RelicOrbit",true);ring.rotation.x=PI/2
  var label:=Label3D.new();label.text=LABELS[i%2]+"\nAPPROACH 32m / 3 CHARGES";label.position.y=26;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.font_size=42;label.pixel_size=.12;label.visibility_range_end=1400;root.add_child(label)
  pickups.append({"actor":root,"kind":i%2,"ready":0.0})
func tick(delta: float) -> void:
 if battle.finished:return
 elapsed+=delta
 for pickup in pickups:
  var actor: Node3D=pickup.actor
  actor.visible=elapsed>=float(pickup.ready)
  if not actor.visible:continue
  actor.rotate_y(delta*.4)
  for ship in battle.ships:
   if ship.alive and not loadouts.has(ship.get_instance_id()) and ship.position.distance_squared_to(actor.position)<32*32:
    grant(ship,int(pickup.kind));pickup.ready=elapsed+90;actor.visible=false;break
 for ship in battle.ships:
  if not ship.alive:loadouts.erase(ship.get_instance_id());continue
  if not ship.player_controlled and loadouts.has(ship.get_instance_id()):
   var target:=ship.targeting.target
   if not is_instance_valid(target) or not target.alive:continue
   var offset:=target.position-ship.position
   if loadouts[ship.get_instance_id()].kind==0:
    var along:=offset.dot(-ship.global_basis.z)
    if along>0 and along<900 and (offset+ship.global_basis.z*along).length()<12:fire(ship)
   elif offset.length()<140:fire(ship)
func grant(ship: CombatShip,kind: int) -> void:
 loadouts[ship.get_instance_id()]={"kind":clampi(kind,0,1),"charges":3,"ready":elapsed}
 if ship.player_controlled:status=LABELS[kind]+" ACQUIRED / B TO FIRE / 3 CHARGES"
func fire(ship: CombatShip) -> bool:
 if battle.finished or not ship.alive:return false
 var id:=ship.get_instance_id()
 if not loadouts.has(id):
  if ship.player_controlled:status="NO MEGA WEAPON / approach a glowing relic within 32m"
  return false
 var data: Dictionary=loadouts[id]
 if elapsed<float(data.ready):
  if ship.player_controlled:status="MEGA WEAPON RECHARGING / %.1fs"%(float(data.ready)-elapsed)
  return false
 var kind: int=data.kind
 var victims: Array[CombatShip]=[]
 var forward: Vector3=-ship.global_basis.z
 for target in battle.ships:
  if not target.alive or target.team==ship.team:continue
  var offset:=target.global_position-ship.global_position
  if kind==0:
   var along:=offset.dot(forward)
   if along<0 or along>1100 or (offset-forward*along).length()>16:continue
  elif offset.length()>140:continue
  var query:=PhysicsRayQueryParameters3D.create(ship.global_position,target.global_position,2)
  if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():continue
  victims.append(target)
 for target in victims:
  target.health.damage(130 if kind==0 else 80,ship,"solar lance" if kind==0 else "gravity nova")
  ship.hits+=1
  if kind==1 and target.alive:target.movement.apply_gravity_slow(3)
 if kind==0:
  var beam:=Node3D.new();battle.add_child(beam);beam.global_transform=ship.global_transform
  var shape:=BoxMesh.new();shape.size=Vector3(2,2,1100)
  SpaceModelFactory.mesh(beam,shape,Vector3(0,0,-550),Color(1,.8,.25),"SolarBeam",true)
  get_tree().create_timer(.25,false).timeout.connect(beam.queue_free)
 else:SpaceEffects.burst(battle,ship.global_position,Color(.65,.3,1),140)
 ship.shots+=1;data.charges-=1;data.ready=elapsed+12
 if ship.player_controlled:
  SpaceAudio.play("missile");status="%s / %d HITS / %d CHARGES"%[LABELS[kind],victims.size(),data.charges]
 if data.charges<=0:loadouts.erase(id)
 return true
func _unhandled_input(event: InputEvent) -> void:
 if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and event.is_action_pressed("mega_weapon"):
  fire(battle.pilot.ship);get_viewport().set_input_as_handled()

func description(ship: CombatShip) -> String:
 if not is_instance_valid(ship) or not loadouts.has(ship.get_instance_id()):return "B: MEGA WEAPON / find glowing relics in space"
 var data: Dictionary=loadouts[ship.get_instance_id()]
 return "B: %s / %d CHARGES / %s"%[LABELS[data.kind],data.charges,"READY" if elapsed>=float(data.ready) else "%.1fs"%(float(data.ready)-elapsed)]
