class_name AlienVisual
extends Node3D
var definition: CollectibleDefinition
var blink_time := 0.0
var eyes: Array[Node3D] = []
var wings: Array[Node] = []
var comet_tail: Node3D
var orbit_pivots: Array[Node3D] = []

func _ready() -> void:
 if definition == null: return
 eyes = SpaceModelFactory.companion(self, definition)
 comet_tail = find_child("CometTail",true,false)
 for node in get_children():
  if node.has_meta("wing_side"): wings.append(node)
  if node.has_meta("orbit_speed"): orbit_pivots.append(node)

func _process(delta: float) -> void:
 blink_time += delta
 for orbit in orbit_pivots: orbit.rotate_object_local(Vector3.UP,float(orbit.get_meta("orbit_speed"))*delta)
 var blink := 0.035 if fmod(blink_time,4.2) > 4.05 else 0.25
 for eye in eyes: eye.scale.y = 0.035 if blink < 0.1 else float(eye.get_meta("open_scale_y",0.25))
 for wing in wings:
  var rest: Vector3 = wing.get_meta("rest_rotation",Vector3.ZERO)
  wing.rotation = rest + Vector3(0,sin(blink_time*3.2)*0.16*float(wing.get_meta("wing_side",1)),0)

 if is_instance_valid(comet_tail):
  var rest: Vector3 = comet_tail.get_meta("rest_rotation",Vector3.ZERO)
  comet_tail.rotation = rest + Vector3(0,0,sin(blink_time*4.2)*0.14)
