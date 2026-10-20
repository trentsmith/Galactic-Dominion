class_name BattleZone
extends Node3D

var start_radius := 600.0
var final_radius := 95.0
var radius := 600.0
var elapsed := 0.0
var rings: Array[MeshInstance3D] = []

func _ready() -> void:
 radius = start_radius
 for axis in range(3):
  var mesh := MeshInstance3D.new()
  var torus := TorusMesh.new()
  torus.inner_radius = 0.997
  torus.outer_radius = 1.003
  torus.rings = 128
  torus.ring_segments = 6
  mesh.mesh = torus
  if axis == 1:
   mesh.rotation.x = PI / 2.0
  if axis == 2:
   mesh.rotation.z = PI / 2.0
  var mat := StandardMaterial3D.new()
  mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  mat.albedo_color = Color(0.12, 0.6, 0.8, 0.25)
  mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  mesh.material_override = mat
  add_child(mesh)
  rings.append(mesh)

func tick(delta: float, ships: Array[CombatShip]) -> void:
 elapsed += delta
 radius = lerpf(start_radius, final_radius, clampf((elapsed - 30.0) / 420.0, 0.0, 1.0))
 # Fleet War ends by elimination: after eight minutes even the centre becomes unsafe.
 if start_radius > 600.0 and elapsed > 480.0:
  radius = maxf(0.0, final_radius * (1.0 - (elapsed - 480.0) / 30.0))
 for ring in rings:
  ring.scale = Vector3.ONE * radius
 for ship in ships:
  if not ship.alive:
   continue
  if ship.global_position.length() > radius or (start_radius > 600.0 and elapsed >= 510.0):
   ship.outside_time += delta
   ship.health.damage((8.0 + ship.outside_time * 2.0) * delta, null)
  else:
   ship.outside_time = 0.0
