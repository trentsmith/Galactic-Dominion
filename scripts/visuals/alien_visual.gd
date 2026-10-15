class_name AlienVisual
extends Node3D
var definition: CollectibleDefinition
var blink_time := 0.0
var eyes: Array[Node3D] = []

func _ready() -> void:
 if definition == null: return
 eyes = SpaceModelFactory.companion(self, definition)

func _process(delta: float) -> void:
 blink_time += delta
 var blink := 0.035 if fmod(blink_time,4.2) > 4.05 else 0.25
 for eye in eyes: eye.scale.y = blink
