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
var livery_clock := 0.0
var livery_orbits: Array[Node3D] = []
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
 SpaceModelFactory.ship(self, stats, team)
 for child in get_children():
  if child.has_meta("orbit_speed"):livery_orbits.append(child)
 engine_mesh = find_child("MainEngine",true,false)
 muzzle_mesh = find_child("MuzzleFlash",true,false)
 shield_mesh = find_child("ShieldShell",true,false)
 _build_component_visuals()

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

func _mesh(shape: Mesh, position: Vector3, color: Color, unshaded: bool = false) -> MeshInstance3D:
 var mesh := MeshInstance3D.new()
 mesh.mesh = shape
 mesh.position = position
 var material := CartoonStyle.material(color, unshaded)
 mesh.material_override = material
 add_child(mesh)
 return mesh

func _process(delta: float) -> void:
 livery_clock += delta
 for orbit in livery_orbits:orbit.rotate_object_local(Vector3.UP,float(orbit.get_meta("orbit_speed"))*delta)

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
 movement.slow_remaining = 0
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
 movement.slow_remaining = 0
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
