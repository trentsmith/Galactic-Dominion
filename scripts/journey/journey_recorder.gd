class_name JourneyRecorder
extends Node
## Solo resumes at a serviced station; NPC battles are session-local.
var battle: FreeRoamMatch
var region:=0
var clock:=0.0
var message:=""
var restoring:=false
var status: Label
var status_time:=0.0
var rumor_pending:=false
func _ready() -> void:
 if battle.network_role!="offline" or battle.profile==null:set_physics_process(false);return
 region=0
 var layer:=CanvasLayer.new();layer.layer=6;add_child(layer)
 status=Label.new();status.position=Vector2(28,325);status.size=Vector2(315,70);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.add_theme_font_size_override("font_size",13);status.add_theme_constant_override("outline_size",4);layer.add_child(status)
func _physics_process(delta: float) -> void:
 if rumor_pending:
  var director:=battle.frontier
  for child in battle.get_children():
   if child is ComponentSalvage and not child.placement_pending and director.active.get("kind","")=="rumor":
    var index:=int(director.active.cache)
    if index in range(child.caches.size()):director.active.at=child.caches[index].position;director.point.position=director.active.at
    rumor_pending=false
 clock+=delta
 status_time=maxf(0,status_time-delta)
 status.visible=not battle.scenic_hud and not battle.map_panel.visible and status_time>0
 if clock>=12:
  clock=0;save_checkpoint()
func job_snapshot() -> Dictionary:
 var director:=battle.frontier
 if director.active.is_empty():return {}
 var result:=director.snapshot();result.elapsed=director.elapsed
 if is_instance_valid(director.boss):
  result.anchors=director.boss.snapshot();result.hull_ratio=director.enemy.health.hull/director.enemy.health.max_hull;result.shield_ratio=director.enemy.health.shield/director.enemy.health.max_shield if director.enemy.health.max_shield>0 else 0.0
 return JourneyState.sanitize_job(result)
func save_checkpoint(force: bool=false) -> bool:
 if battle.network_role!="offline" or battle.profile==null or restoring:return false
 var value:={"region":region,"peaceful":battle.peaceful,"saved_at":int(Time.get_unix_time_from_system()),"job":job_snapshot()}
 var previous: Dictionary=battle.profile.journey.resume
 if not force and battle.profile.save_error.is_empty() and not previous.is_empty() and int(previous.region)==region and bool(previous.peaceful)==battle.peaceful and previous.job==value.job:return true
 var saved:=JourneyState.transaction(battle.profile,func():battle.profile.journey.resume=value)
 message="JOURNEY SAVED / Continue at "+FreeRoamWorld.NAMES[region] if saved else "AUTOSAVE FAILED / "+battle.profile.save_error+" / retry from the Frontier log"
 if status!=null:status.text=message;status_time=5 if saved else 1000000;status.add_theme_color_override("font_color",Color(.6,.95,.8) if saved else Color(1,.6,.4))
 return saved
func docked(index: int) -> void:
 region=clampi(index,0,6);clock=0;save_checkpoint()
func restore(value: Dictionary) -> void:
 var clean: Dictionary=JourneyState.sanitize({"resume":value}).resume
 if clean.is_empty():return
 restoring=true;region=int(clean.region)
 var origin: Vector3=FreeRoamWorld.CENTERS[region]
 for ship in battle.fleet.ships:
  ship.position=origin+Vector3((ship.fleet_slot-1)*35,0,160);ship.velocity=Vector3.ZERO;ship.health.configure(ship.stats);ship.movement.boost_energy=ship.stats.boost_capacity
  ship.brain.roam_center=origin+Vector3(0,0,-800)
 battle.pilot.take_control(battle.fleet.ships[0])
 var stored: Dictionary=clean.job
 var state: Dictionary=battle.profile.frontier
 if not stored.is_empty() and int(stored.active.generation)==int(state.generation) and not int(stored.active.slot) in state.done:
  var data: Dictionary=stored.active.duplicate(true);data.at=JourneyState.vector(data.at)
  var director:=battle.frontier;director.start(data)
  director.elapsed=stored.elapsed;director.progress=stored.progress;director.integrity=stored.integrity;director.escort=stored.escort;director.completed=stored.completed
  if data.kind=="escort" and is_instance_valid(director.goal):director.point.position=(data.at as Vector3).lerp(director.goal.position,director.escort)
  if data.kind=="boss" and is_instance_valid(director.boss):
   var values: Array=stored.get("anchors",[40,40,40])
   for i in range(3):director.boss.points[i].health=values[i]
   director.boss.refresh();director.enemy.health.hull=director.enemy.health.max_hull*stored.hull_ratio;director.enemy.health.shield=director.enemy.health.max_shield*stored.shield_ratio
  if data.kind=="rumor" and data.has("cache"):
   director.active.cache=data.cache;director.active.cache_generation=data.cache_generation
   for child in battle.get_children():
    if child is ComponentSalvage and int(data.cache) in range(child.caches.size()):director.active.at=child.caches[int(data.cache)].position;director.point.position=director.active.at
   rumor_pending=true
 battle.log_label.text="CONTINUED / "+FreeRoamWorld.NAMES[region]+" safe dock. Job timers resume; NPC fleets start a new session."
 restoring=false;clock=0
