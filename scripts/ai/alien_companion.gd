class_name AlienCompanion
extends Node3D
var ship: CombatShip
var definition: CollectibleDefinition
var visual: AlienVisual
var orbit_time := 0.0
var attack_cooldown := 0.0
var attacks := 0
var attack_range := 320.0
var attack_damage := 6.0
var attack_interval := 1.4

func _ready() -> void:
 visual = AlienVisual.new()
 visual.definition = definition
 add_child(visual)
 # Rare appearances use their species' normal combat behavior.
 match definition.species:
  "Comet Pup":
   attack_damage = 9
   attack_interval = 2.0
   attack_range = 260
  "Moon Moth":
   attack_damage = 5
   attack_interval = 1.6
  "Kharon":
   attack_damage = 10
   attack_interval = 2.1
  "Auralith":
   attack_damage = 4
   attack_interval = 1.0
  "Drakari":
   attack_damage = 8
   attack_interval = 1.7
 scale = Vector3.ONE * 0.7

func _process(delta: float) -> void:
 orbit_time += delta
 var clock := orbit_time
 if ship.get_parent() is BattleMatch: clock = ship.get_parent().elapsed
 var phase := clock * 1.35 + ship.fleet_slot * 2.1
 position = Vector3(cos(phase) * 5.8, 2.1 + sin(phase * 1.7) * 0.7, sin(phase) * 5.8)
 visual.rotation.y = -phase - PI / 2
 visible = ship.alive

func _physics_process(delta: float) -> void:
 # Clients and hangar previews animate companions, but never generate damage.
 if not ship.alive or not ship.is_physics_processing(): return
 if ship.get_parent() is BattleMatch and ship.get_parent().network_role == "client": return
 attack_cooldown = maxf(0, attack_cooldown - delta)
 if attack_cooldown > 0 or float(ship.get_meta("spawn_protection", 0)) > 0: return
 var target := choose_target()
 if is_instance_valid(target): fire_at(target)

func choose_target() -> CombatShip:
 if is_instance_valid(ship.targeting.target) and ship.targeting.target.alive and ship.targeting.target.team != ship.team and ship.global_position.distance_to(ship.targeting.target.global_position) <= attack_range:
  return ship.targeting.target
 var best: CombatShip
 var distance := attack_range * attack_range
 for candidate in get_tree().get_nodes_in_group("ships"):
  if candidate == ship or not candidate.alive or candidate.team == ship.team: continue
  var next: float = ship.global_position.distance_squared_to(candidate.global_position)
  if next < distance:
   distance = next
   best = candidate
 return best

func fire_at(target: CombatShip) -> bool:
 if not ship.is_physics_processing() or (ship.get_parent() is BattleMatch and ship.get_parent().network_role == "client"): return false
 if attack_cooldown > 0 or not ship.alive or not is_instance_valid(target) or not target.alive or target.team == ship.team or ship.global_position.distance_to(target.global_position) > attack_range: return false
 var shot := SpaceProjectile.new()
 shot.spec = WeaponSpec.new()
 shot.spec.damage = attack_damage
 shot.spec.speed = 170
 shot.spec.lifetime = 2.5
 shot.spec.tracking = definition.species in ["Drakari","Moon Moth"]
 if definition.species == "Moon Moth":
  shot.spec.speed = 125
  shot.spec.lifetime = 3.2
  shot.spec.turn_rate = 1.8
 if definition.species == "Comet Pup":
  shot.spec.speed = 230
  shot.spec.lifetime = 1.5
 shot.team = ship.team
 shot.shooter = ship
 shot.target = target
 shot.companion_shot = true
 shot.projectile_color = definition.color.lightened(0.25)
 ship.get_parent().add_child(shot)
 shot.global_position = global_position
 var distance := shot.global_position.distance_to(target.global_position)
 shot.direction = shot.global_position.direction_to(target.global_position + target.velocity * distance / shot.spec.speed)
 attack_cooldown = attack_interval
 attacks += 1
 ship.shots += 1
 if float(ship.get_meta("spawn_protection", 0)) > 0:
  ship.set_meta("spawn_protection", 0.0)
  ship.health.protection = 1
 SpaceEffects.burst(ship.get_parent(), global_position, definition.color, 0.5)
 return true
