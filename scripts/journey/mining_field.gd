class_name MiningField
extends Node3D
var battle: FreeRoamMatch
var profile: PlayerProfile
var veins: Array[MineralVein]=[]
var generation:=-1
var placing:=true
var progress:=0.0
var selected:=-1
var hint: Label
var message:=""
var message_time:=0.0
func sensor_range() -> float:return JourneySensors.range_for(profile,battle.pilot.ship)
func _ready() -> void:
 profile=battle.profile
 if battle.network_role!="offline" or profile==null:set_physics_process(false);return
 var layer:=CanvasLayer.new();layer.layer=7;add_child(layer)
 hint=Label.new();hint.position=Vector2(390,380);hint.size=Vector2(500,75);hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.add_theme_font_size_override("font_size",15);hint.add_theme_constant_override("outline_size",5);layer.add_child(hint);refresh()
func refresh() -> void:
 for vein in veins:vein.queue_free()
 veins.clear();generation=int(profile.journey.mining.generation)
 var rng:=RandomNumberGenerator.new();rng.seed=int(profile.frontier.seed)+generation*65599
 for slot in range(12):
  var vein:=MineralVein.new();vein.field=self;vein.slot=slot;vein.generation=generation;vein.material_id=["ore","crystal","alloy"][slot%3]
  var region:=slot%7
  vein.position=FreeRoamWorld.CENTERS[region]+Vector3(rng.randf_range(-550,550),rng.randf_range(150,400),rng.randf_range(-650,-250))
  if slot==0:vein.position=Vector3(150,35,-120)
  add_child(vein);veins.append(vein);vein.visible=not slot in profile.journey.mining.opened
  if not vein.visible:vein.collision_layer=0
 placing=true
func settle() -> void:
 var query:=PhysicsShapeQueryParameters3D.new();var sphere:=SphereShape3D.new();sphere.radius=10;query.shape=sphere;query.collision_mask=2
 var excluded: Array[RID]=[]
 for vein in veins:excluded.append(vein.get_rid())
 query.exclude=excluded
 for vein in veins:
  for attempt in range(24):
   query.transform=Transform3D(Basis.IDENTITY,vein.global_position)
   if get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():break
   vein.position.y+=35
func _physics_process(delta: float) -> void:
 if placing:placing=false;settle()
 if generation!=int(profile.journey.mining.generation):refresh()
 tick(delta,Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and Input.is_action_pressed("frontier_use"))
func tick(delta: float,held: bool) -> void:
 if battle.network_role!="offline" or not battle.pilot.ship.alive:return
 var ship:=battle.pilot.ship;var next:=-1;var distance:=130.0
 for i in range(veins.size()):
  if not veins[i].visible:continue
  var range_value:=ship.position.distance_to(veins[i].position)
  if range_value<distance:distance=range_value;next=i
 if next!=selected:selected=next;progress=0
 message_time=maxf(0,message_time-delta)
 hint.visible=not battle.scenic_hud and not battle.map_panel.visible and (next>=0 or message_time>0)
 if next<0:hint.text=message if message_time>0 else "";return
 var vein:=veins[next]
 if vein.health<=0 and distance<=75 and held:
  var ray:=PhysicsRayQueryParameters3D.create(ship.global_position,vein.global_position,2);ray.exclude=[vein.get_rid()]
  if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():progress+=delta
  else:progress=0;message="MINING BLOCKED / move around the obstacle";message_time=2
  if progress>=1:collect(vein);progress=0
 else:progress=0
 hint.text=message if message_time>0 else "%s / %dm\n%s"%[vein.title(),int(distance),"Hold F to tractor materials · %d%%"%int(progress*100) if vein.health<=0 and distance<=75 else "Approach within 75m to collect" if vein.health<=0 else "Fire lasers at the glowing seam to fracture it"]
func collect(vein: MineralVein) -> bool:
 if battle.network_role!="offline" or not is_instance_valid(vein) or vein.generation!=int(profile.journey.mining.generation) or vein.slot in profile.journey.mining.opened or vein.health>0:return false
 if battle.pilot.ship.position.distance_to(vein.position)>75:return false
 var amount:=4 if vein.material_id=="ore" else 2
 if int(profile.sanctuary.materials[vein.material_id])+amount>99999:message="MATERIAL STORAGE FULL / use materials in your home workshop";message_time=5;return false
 var saved:=JourneyState.transaction(profile,func():
  profile.sanctuary.materials[vein.material_id]+=amount;profile.journey.mining.opened.append(vein.slot);profile.journey.mining.total+=1
  if profile.journey.mining.opened.size()==12:profile.journey.mining.generation+=1;profile.journey.mining.opened.clear())
 if not saved:message="MINING NOT SAVED / vein retained; retry F. "+profile.save_error;message_time=6;return false
 vein.hide();vein.set_deferred("collision_layer",0);message="MATERIALS SAVED / +%d %s / available in your home workshop"%[amount,vein.material_id];message_time=7;SpaceAudio.play("click");SpaceEffects.burst(self,vein.position,vein.tint,8);return true
