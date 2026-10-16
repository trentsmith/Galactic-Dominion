class_name ShipPreview
extends SubViewportContainer

var viewport: SubViewport
var scene: Node3D
var ship: CombatShip

func _ready() -> void:
 stretch = true
 custom_minimum_size = Vector2(400, 260)
 viewport = SubViewport.new()
 viewport.size = Vector2i(480, 300)
 viewport.own_world_3d = true
 viewport.msaa_3d = Viewport.MSAA_4X
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 add_child(viewport)
 scene = Node3D.new()
 viewport.add_child(scene)
 scene.add_child(SpaceEnvironmentArt.environment())
 var light := DirectionalLight3D.new()
 light.light_energy = 1.35
 light.light_color = Color(1,.91,.78)
 light.rotation_degrees = Vector3(-32, 140, 0)
 scene.add_child(light)
 var fill := DirectionalLight3D.new()
 fill.name="CoolRimLight"
 fill.rotation_degrees=Vector3(-12,-35,0)
 fill.light_color=Color(.35,.62,1)
 fill.light_energy=.65
 scene.add_child(fill)
 var camera := Camera3D.new()
 scene.add_child(camera)
 camera.position = Vector3(9, 6, -13)
 camera.look_at(Vector3.ZERO)
 camera.current = true

func show_stats(stats: ShipStats) -> void:
 if not is_node_ready():
  await ready
 if is_instance_valid(ship):
  scene.remove_child(ship)
  ship.queue_free()
 var env := scene.get_child(0) as WorldEnvironment
 var lunar := stats.variant_style == "moon_moth" or stats.crew_id == "crew_lunaflutter"
 env.environment.sky.sky_material.set_shader_parameter("moon_palette",1.0 if lunar else 0.0)
 env.environment.sky.sky_material.set_shader_parameter("comet_palette",1.0 if stats.variant_style == "comet_pup" or stats.crew_id == "crew_cinderbit" else 0.0)
 ship = CombatShip.new()
 ship.stats = stats
 ship.set_physics_process(false)
 scene.add_child(ship)
 ship.set_physics_process(false)
 ship.remove_from_group("ships")
 ship.collision_layer = 0
 ship.collision_mask = 0

func _process(delta: float) -> void:
 if is_instance_valid(ship):
  ship.rotate_y(delta * 0.3)
