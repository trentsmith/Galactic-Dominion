class_name AlienVisual
extends Node3D
var definition: CollectibleDefinition
var blink_time := 0.0
var eyes: Array[Node3D] = []

func _ready() -> void:
 if definition == null: return
 var color := definition.color.lightened(0.2)
 var accent := definition.accent
 CartoonStyle.ball(self, Vector3.ZERO, Vector3(0.8, 0.78, 0.7), color)
 CartoonStyle.ball(self, Vector3(0, -0.6, 0.08), Vector3(0.62, 0.5, 0.55), color.lightened(0.13))
 for side in [-1, 1]:
  CartoonStyle.ball(self, Vector3(side * 0.43, -0.88, -0.1), Vector3(0.26, 0.19, 0.3), accent)
  CartoonStyle.ball(self, Vector3(side * 0.74, -0.28, 0), Vector3(0.22, 0.36, 0.22), color)
  CartoonStyle.ball(self, Vector3(side * 0.53, -0.05, -0.56), Vector3(0.14, 0.09, 0.04), Color(1, 0.48, 0.65))
  var eye := CartoonStyle.ball(self, Vector3(side * 0.29, 0.22, -0.61), Vector3(0.2, 0.26, 0.09), Color(0.045, 0.065, 0.14))
  eyes.append(eye)
  CartoonStyle.ball(eye, Vector3(-0.25, 0.3, -0.8), Vector3(0.3, 0.25, 0.18), Color.WHITE, true)
 var smile := TorusMesh.new()
 smile.inner_radius = 0.11
 smile.outer_radius = 0.145
 var mouth := MeshInstance3D.new()
 mouth.mesh = smile
 mouth.position = Vector3(0, -0.18, -0.68)
 mouth.rotation.x = PI / 2
 mouth.scale.y = 0.6
 mouth.material_override = CartoonStyle.material(Color(0.15, 0.1, 0.22))
 add_child(mouth)
 if definition.species == "Vesperi":
  for side in [-1, 1]:
   CartoonStyle.ball(self, Vector3(side * 0.44, 0.97, 0), Vector3(0.13, 0.45, 0.13), color)
   CartoonStyle.ball(self, Vector3(side * 0.47, 1.33, 0), Vector3.ONE * 0.2, accent, true)
 elif definition.species == "Auralith":
  for side in [-1, 1]:
   CartoonStyle.ball(self, Vector3(side * 0.75, 0.7, 0), Vector3(0.28, 0.57, 0.2), color.lightened(0.2)).rotation.z = side * -0.6
  CartoonStyle.ball(self, Vector3(0, 0.76, -0.14), Vector3.ONE * 0.17, accent, true)
 else:
  for side in [-1, 1]:
   CartoonStyle.ball(self, Vector3(side * 0.6, 0.68, 0), Vector3(0.25, 0.46, 0.25), Color(1, 0.85, 0.58)).rotation.z = side * -0.5
  if definition.species == "Drakari":
   for side in [-1, 1]:
    CartoonStyle.ball(self, Vector3(side * 0.82, 0.02, 0.5), Vector3(0.55, 0.18, 0.45), color.darkened(0.12))
 if definition.rarity in ["legendary", "mythic"]:
  var halo := MeshInstance3D.new()
  var shape := TorusMesh.new()
  shape.inner_radius = 1.05
  shape.outer_radius = 1.1
  halo.mesh = shape
  halo.position.y = 0.25
  halo.material_override = CartoonStyle.material(definition.rarity_color(), true)
  add_child(halo)

func _process(delta: float) -> void:
 blink_time += delta
 var blink := 0.08 if fmod(blink_time, 4.2) > 4.05 else 0.26
 for eye in eyes: eye.scale.y = blink
