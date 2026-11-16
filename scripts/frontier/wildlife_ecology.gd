class_name WildlifeEcology
extends Node3D
## Small bounded ambient simulation, kept away from the player's capture encounter.
var expedition: PlanetExpedition
var clock:=0.0
var tracks: Array[Node3D]=[]
var tracked_id:=0
var last_stamp:=Vector3.INF
var prey: SurfaceFauna
var predator: SurfaceFauna
var trail_label: Label3D
func _ready() -> void:
 trail_label=Label3D.new();trail_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;trail_label.pixel_size=.012;trail_label.font_size=24;trail_label.modulate=Color(.95,.8,.5);add_child(trail_label);trail_label.hide()
func _physics_process(delta: float) -> void:
 clock-=delta
 if clock>0 or expedition.finished:return
 clock=2.0
 var target:=expedition.tracked_animal()
 if is_instance_valid(target):
  if tracked_id!=target.get_instance_id():
   tracked_id=target.get_instance_id();last_stamp=Vector3.INF
   for old in tracks:old.queue_free()
   tracks.clear()
  if not last_stamp.is_finite() or target.position.distance_to(last_stamp)>3:
   stamp(target)
  trail_label.visible=expedition.bot.position.distance_to(last_stamp)<15
  trail_label.position=last_stamp+Vector3.UP*1.5;trail_label.text=target.definition.display_name+" / fresh tracks\nT: change tracked species · follow the amber trail"
 if is_instance_valid(prey) and is_instance_valid(predator):
  if not prey.alive or not predator.alive or prey==target or predator==target or expedition.bot.position.distance_to(prey.position)<45 or expedition.bot.position.distance_to(predator.position)<45:release_pair()
  else:
   prey.set_meta("ambient_flee",predator.get_instance_id());predator.set_meta("ambient_prey",prey.get_instance_id());return
 # At most one ambient hunt and one pass through loaded fauna every two seconds.
 for animal in expedition.fauna:
  if not is_instance_valid(animal) or not animal.alive or animal==target or animal.definition.damage<=0 or expedition.bot.position.distance_to(animal.position)<65:continue
  for candidate in expedition.fauna:
   if not is_instance_valid(candidate) or not candidate.alive or candidate==target or candidate.definition.damage>0 or candidate.position.distance_to(animal.position)>28 or expedition.bot.position.distance_to(candidate.position)<65:continue
   predator=animal;prey=candidate;return
func stamp(animal: SurfaceFauna) -> void:
 last_stamp=animal.position
 var mark:=Node3D.new();mark.position=animal.position;mark.position.y=SurfaceWorld.height_at(mark.position.x,mark.position.z)+.08;add_child(mark);tracks.append(mark)
 for side in [-1,1]:
  var mesh:=SphereMesh.new();mesh.radius=.12;mesh.height=.05
  SpaceModelFactory.mesh(mark,mesh,Vector3(side*.22,0,0),Color(.75,.53,.24),"WildlifeTrack")
 if tracks.size()>16:tracks.pop_front().queue_free()
func release_pair() -> void:
 if is_instance_valid(predator):predator.remove_meta("ambient_prey")
 if is_instance_valid(prey):prey.remove_meta("ambient_flee")
 predator=null;prey=null
