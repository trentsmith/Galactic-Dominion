class_name AlienVisual
extends Node3D
var definition: CollectibleDefinition
var blink_time := 0.0
var eyes: Array[Node3D] = []
var wings: Array[Node] = []

func _ready() -> void:
 if definition == null: return
 eyes = SpaceModelFactory.companion(self, definition)
 for node in get_children():
  if node.has_meta("wing_side"): wings.append(node)

func _process(delta: float) -> void:
 blink_time += delta
 var blink := 0.035 if fmod(blink_time,4.2) > 4.05 else 0.25
 for eye in eyes: eye.scale.y = 0.035 if blink < 0.1 else float(eye.get_meta("open_scale_y",0.25))
 for wing in wings:
  var rest: Vector3 = wing.get_meta("rest_rotation",Vector3.ZERO)
  wing.rotation = rest + Vector3(0,sin(blink_time*3.2)*0.16*float(wing.get_meta("wing_side",1)),0)
