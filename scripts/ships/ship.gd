class_name CombatShip
extends CharacterBody3D
signal eliminated(ship, attacker)

var stats: ShipStats
var team := 0
var fleet_slot := 0
var callsign := "Ship"
var alive := true
var player_controlled := false
var movement: ShipMovement
var health: ShipHealth
var weapons: ShipWeapons
var targeting: ShipTargeting
var brain: ShipBrain
var shield_mesh: MeshInstance3D
var engine_mesh: MeshInstance3D
var muzzle_mesh: MeshInstance3D
var ability_remaining := 0.0
var ability_cooldown := 0.0
var muzzle_flash := 0.0
var damage_dealt := 0.0
var kills := 0
var shots := 0
var hits := 0
var outside_time := 0.0
var crew_name := "Unassigned"
var hit_effect_remaining := 0.0
var companion: AlienCompanion

func _ready() -> void:
 add_to_group("ships")
 collision_layer = 1
 collision_mask = 3
 var collision := CollisionShape3D.new()
 var sphere := SphereShape3D.new()
 sphere.radius = 2.6
 collision.shape = sphere
 add_child(collision)
 movement = ShipMovement.new()
 movement.ship = self
 movement.boost_energy = stats.boost_capacity
 add_child(movement)
 health = ShipHealth.new()
 health.configure(stats)
 add_child(health)
 health.destroyed.connect(_destroy)
 health.hit.connect(_hit)
 weapons = ShipWeapons.new()
 weapons.ship = self
 weapons.configure(stats)
 add_child(weapons)
 targeting = ShipTargeting.new()
 targeting.ship = self
 add_child(targeting)
 brain = ShipBrain.new()
 brain.ship = self
 add_child(brain)
 _build_visual()
 var crew := CollectionCatalog.find(stats.crew_id)
 if crew != null and crew.kind == "crew" and crew.species != "Human":
  companion = AlienCompanion.new()
  companion.ship = self
  companion.definition = crew
  add_child(companion)

func _build_visual() -> void:
 var color := stats.color if team == 0 or stats.variant_style != "standard" else Color(0.95, 0.25, 0.20)
 color = color.lightened(0.12)
 var body := CapsuleMesh.new()
 body.radius = 1.5 if stats.ability in ["aegis", "barrage"] else 1.2 if stats.ability in ["overcharge", "repair"] else 0.95
 body.height = 5.4 if stats.ability != "aegis" else 4.4
 _mesh(body, Vector3.ZERO, color).rotation.x = PI / 2
 var wing := CapsuleMesh.new()
 wing.radius = 0.48
 wing.height = 8.6 if stats.ability == "aegis" else 6.8
 _mesh(wing, Vector3(0, -0.1, 0.8), color.darkened(0.18)).rotation.z = PI / 2
 var cockpit := SphereMesh.new()
 cockpit.radius = 0.95
 cockpit.height = 1.9
 _mesh(cockpit, Vector3(0, 0.85, -0.9), Color(0.13, 0.19, 0.36)).scale = Vector3(1.05, 0.75, 1.1)
 CartoonStyle.ball(self, Vector3(-0.35, 1.38, -1.1), Vector3(0.18, 0.06, 0.3), Color(0.82, 0.96, 1), true)
 for side in [-1, 1]:
  CartoonStyle.ball(self, Vector3(side * 2.5, 0, 0.8), Vector3(0.7, 0.6, 1.35), color.lightened(0.16))
  CartoonStyle.ball(self, Vector3(side * 0.65, 0.12, -2.15), Vector3(0.26, 0.17, 0.16), Color(1, 0.88, 0.52), true)
 if stats.ability == "barrage":
  for side in [-1, 1]:
   CartoonStyle.ball(self, Vector3(side * 1.7, -0.3, -0.8), Vector3(0.75, 0.65, 1.8), Color(1, 0.73, 0.52))
 elif stats.ability == "repair":
  CartoonStyle.ball(self, Vector3(0, 1.1, 1.1), Vector3(0.7, 0.28, 0.7), Color(0.71, 1, 0.76))
 var engine := SphereMesh.new()
 engine.radius = 0.55
 engine.height = 1.1
 engine_mesh = _mesh(engine, Vector3(0, 0, 3.0), Color(0.2, 0.85, 1.0), true)
 var muzzle := SphereMesh.new()
 muzzle.radius = 0.45
 muzzle.height = 0.9
 muzzle_mesh = _mesh(muzzle, Vector3(0, 0, -3.3), Color(1, 0.85, 0.3), true)
 muzzle_mesh.visible = false
 var shield := SphereMesh.new()
 shield.radius = 4.5
 shield.height = 9.0
 shield_mesh = _mesh(shield, Vector3.ZERO, Color(0.2, 0.8, 1.0, 0.15), true)
 var material := shield_mesh.material_override as StandardMaterial3D
 material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 material.cull_mode = BaseMaterial3D.CULL_DISABLED
 shield_mesh.visible = false
 _build_component_visuals()
 _build_variant_visual(color)

func _build_component_visuals() -> void:
 if stats.engine_style != "standard":
  for side in [-1.0, 1.0]:
   var pod := CylinderMesh.new()
   pod.top_radius = 0.45
   pod.bottom_radius = 0.6
   pod.height = 2.5
   _mesh(pod, Vector3(side * 2.0, 0, 2.0), Color(0.3, 0.85, 0.7)).rotation.x = PI / 2.0
 if stats.weapon_style != "standard":
  for side in [-1.0, 1.0]:
   var barrel := BoxMesh.new()
   barrel.size = Vector3(0.4, 0.4, 2.6)
   _mesh(barrel, Vector3(side * 2.5, 0, -1.0), Color(1, 0.6, 0.25))
 if stats.shield_style != "standard":
  var capacitor := SphereMesh.new()
  capacitor.radius = 0.6
  capacitor.height = 1.2
  _mesh(capacitor, Vector3(0, 0.8, 1.2), Color(0.2, 0.85, 1), true)
 if stats.utility_style != "standard":
  var antenna := BoxMesh.new()
  antenna.size = Vector3(0.15, 1.4, 0.15)
  _mesh(antenna, Vector3(0, 1.1, 2.0), Color(0.9, 0.65, 1))

func _build_variant_visual(color: Color) -> void:
 if stats.variant_style == "standard":
  return
 var accent := Color(1, 0.25, 0.9) if stats.variant_style == "voidglass" else Color(0.2, 1, 1) if stats.variant_style == "aurora" else Color(1, 0.8, 0.25)
 for side in [-1.0, 1.0]:
  var trim := BoxMesh.new()
  trim.size = Vector3(0.25, 0.4, 5.5)
  _mesh(trim, Vector3(side * 1.2, 0.3, 0), accent, true)
  var fin := BoxMesh.new()
  fin.size = Vector3(0.3, 1.6, 2.5)
  var fin_mesh := _mesh(fin, Vector3(side * 3.0, 0.6, 1.0), color.lightened(0.3))
  fin_mesh.rotation.z = side * 0.45
 if stats.variant_style == "celestial":
  var ring := TorusMesh.new()
  ring.inner_radius = 3.3
  ring.outer_radius = 3.5
  _mesh(ring, Vector3(0, 0, 1.5), accent, true).rotation.x = PI / 2.0
 else:
  for side in [-1.0, 1.0]:
   var ribbon := BoxMesh.new()
   ribbon.size = Vector3(0.12, 0.12, 7.0)
   _mesh(ribbon, Vector3(side * 2.5, 0.3, 3.5), accent, true)

func _mesh(shape: Mesh, position: Vector3, color: Color, unshaded: bool = false) -> MeshInstance3D:
 var mesh := MeshInstance3D.new()
 mesh.mesh = shape
 mesh.position = position
 var material := CartoonStyle.material(color, unshaded)
 mesh.material_override = material
 add_child(mesh)
 return mesh

func _physics_process(delta: float) -> void:
 if not alive:
  return
 hit_effect_remaining = maxf(0.0, hit_effect_remaining - delta)
 health.tick(delta)
 weapons.tick(delta)
 targeting.tick(delta)
 ability_cooldown = maxf(0.0, ability_cooldown - delta)
 ability_remaining = maxf(0.0, ability_remaining - delta)
 movement.ability_multiplier = 1.65 if ability_remaining > 0.0 and stats.ability == "speed" else 1.0
 weapons.overcharge = ability_remaining > 0.0 and stats.ability == "overcharge"
 if not player_controlled:
  brain.tick(delta)
 if ability_remaining > 0.0 and stats.ability == "repair":
  for ally in get_tree().get_nodes_in_group("ships"):
   if ally.alive and ally.team == team and global_position.distance_to(ally.global_position) < 90.0:
    ally.health.hull = minf(ally.health.max_hull, ally.health.hull + 3.0 * delta)
 movement.tick(delta)
 engine_mesh.scale = Vector3(1, 1, 1.0 + velocity.length() / stats.speed)
 muzzle_flash = maxf(0.0, muzzle_flash - delta)
 muzzle_mesh.visible = muzzle_flash > 0.0
 shield_mesh.visible = ability_remaining > 0.0 and stats.ability == "aegis"

func activate_ability() -> bool:
 if ability_cooldown > 0.0 or not alive:
  return false
 ability_remaining = 5.0
 ability_cooldown = stats.ability_recharge
 return true

func _hit(shield_hit: bool) -> void:
 brain.alert_time = 4.0
 if hit_effect_remaining > 0.0:
  return
 hit_effect_remaining = 0.12
 if player_controlled:
  SpaceAudio.play("shield")
 SpaceEffects.burst(get_parent(), global_position, Color(0.15, 0.7, 1.0) if shield_hit else Color(1, 0.45, 0.12), 4.0 if shield_hit else 1.8)

func _destroy(attacker: CombatShip) -> void:
 alive = false
 SpaceAudio.play("destroy")
 if is_instance_valid(attacker):
  attacker.kills += 1
 SpaceEffects.burst(get_parent(), global_position, Color(1, 0.4, 0.1), 12.0)
 visible = false
 collision_layer = 0
 collision_mask = 0
 velocity = Vector3.ZERO
 eliminated.emit(self, attacker)

# Reuse the existing ship and signal connections after a free-roam destruction.
func redeploy(at: Vector3, protection_seconds: float = 8.0) -> void:
 alive = true
 visible = true
 collision_layer = 1
 collision_mask = 3
 position = at
 rotation = Vector3.ZERO
 velocity = Vector3.ZERO
 health.dead = false
 health.configure(stats)
 health.damage_received = 0
 health.damage_by_attacker.clear()
 health.regen_delay = 0
 movement.boost_energy = stats.boost_capacity
 movement.thrust = Vector3.ZERO
 movement.boost_requested = false
 ability_remaining = 0
 ability_cooldown = 0
 targeting.select(null)
 brain.retreat_latch = false
 weapons.laser_remaining = 0
 weapons.missile_remaining = 0
 set_meta("spawn_protection", protection_seconds)
