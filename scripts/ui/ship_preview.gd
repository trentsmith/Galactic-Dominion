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
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 add_child(viewport)
 scene = Node3D.new()
 viewport.add_child(scene)
 var env_node := WorldEnvironment.new()
 var env := Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color(0.018, 0.03, 0.065)
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color(0.6, 0.7, 1)
 env.ambient_light_energy = 0.8
 env_node.environment = env
 scene.add_child(env_node)
 var light := DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-35, -25, 0)
 scene.add_child(light)
 var camera := Camera3D.new()
 scene.add_child(camera)
 camera.position = Vector3(11, 7, 15)
 camera.look_at(Vector3.ZERO)
 camera.current = true

func show_stats(stats: ShipStats) -> void:
 if not is_node_ready():
  await ready
 if is_instance_valid(ship):
  scene.remove_child(ship)
  ship.queue_free()
 ship = CombatShip.new()
 ship.stats = stats
 ship.set_physics_process(false)
 scene.add_child(ship)
 ship.remove_from_group("ships")
 ship.collision_layer = 0
 ship.collision_mask = 0

func _process(delta: float) -> void:
 if is_instance_valid(ship):
  ship.rotate_y(delta * 0.3)
