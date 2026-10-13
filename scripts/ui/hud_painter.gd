class_name HUDPainter
extends Control

const CYAN := Color(0.25, 0.85, 1)
const MUTED := Color(0.55, 0.67, 0.8)
const RED := Color(1, 0.35, 0.3)
var battle: BattleMatch
var font: Font

func _ready() -> void:
 font = ThemeDB.fallback_font

func _process(_delta: float) -> void:
 queue_redraw()

func text(at: Vector2, content: String, color: Color = Color.WHITE, font_size: int = 16) -> void:
 draw_string(font, at, content, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func panel(rect: Rect2) -> void:
 draw_rect(rect, Color(0.015, 0.03, 0.065, 0.88))
 draw_line(rect.position, rect.position + Vector2(rect.size.x, 0), Color(0.25, 0.55, 0.7, 0.5), 1)

func bar(at: Vector2, label: String, value: float, maximum: float, color: Color) -> void:
 text(at, label, MUTED, 13)
 text(at + Vector2(210, 0), "%d / %d" % [int(value), int(maximum)], color, 13)
 draw_rect(Rect2(at + Vector2(0, 8), Vector2(280, 7)), Color(0.1, 0.16, 0.22))
 draw_rect(Rect2(at + Vector2(0, 8), Vector2(280 * clampf(value / maximum, 0, 1), 7)), color)

func _draw() -> void:
 if not is_instance_valid(battle) or not is_instance_valid(battle.pilot.ship):
  return
 var ship := battle.pilot.ship
 var width := size.x
 var height := size.y
 var center := size / 2.0
 panel(Rect2(Vector2(24, 22), Vector2(285, 84)))
 text(Vector2(42, 48), "GALACTIC DOMINION", CYAN, 19)
 text(Vector2(42, 72), "FLEET ROYALE  /  VANGUARD", MUTED, 13)
 text(Vector2(42, 93), "ALLIES  %d / 3     HOSTILES  %d / 3" % [battle.living(0), battle.living(1)], Color.WHITE, 15)
 panel(Rect2(Vector2(width / 2 - 130, 22), Vector2(260, 61)))
 var remaining := maxi(0, 480 - int(battle.elapsed))
 text(Vector2(width / 2 - 104, 48), "%02d:%02d   /   ZONE %dm" % [remaining / 60, remaining % 60, int(battle.zone.radius)], CYAN, 20)
 text(Vector2(width / 2 - 98, 70), "CONTRACTING" if battle.elapsed > 30 else "CONTRACTION IN %ds" % int(30 - battle.elapsed), MUTED, 12)
 panel(Rect2(Vector2(24, height - 200), Vector2(320, 176)))
 text(Vector2(42, height - 174), "%s  /  %s" % [ship.callsign.to_upper(), ship.stats.class_name_text.to_upper()], CYAN, 16)
 bar(Vector2(42, height - 145), "HULL INTEGRITY", ship.health.hull, ship.health.max_hull, Color(0.6, 0.9, 0.65))
 bar(Vector2(42, height - 108), "SHIELD ENERGY", ship.health.shield, ship.health.max_shield, CYAN)
 bar(Vector2(42, height - 71), "BOOST RESERVE", ship.movement.boost_energy, ship.stats.boost_capacity, Color(1, 0.7, 0.25))
 text(Vector2(42, height - 36), "%d m/s  •  %s" % [int(ship.velocity.length()), "BOOST" if ship.movement.boost_requested else "CRUISE"], MUTED, 13)
 panel(Rect2(Vector2(width - 320, height - 200), Vector2(296, 176)))
 text(Vector2(width - 300, height - 171), "ARMAMENT", CYAN, 16)
 text(Vector2(width - 300, height - 143), "LMB   LASER    %s" % ("READY" if ship.weapons.laser_remaining <= 0 else "%.1fs" % ship.weapons.laser_remaining), Color.WHITE, 15)
 text(Vector2(width - 300, height - 115), "RMB   MISSILE  %s" % ("READY" if ship.weapons.missile_remaining <= 0 else "%.1fs" % ship.weapons.missile_remaining), Color.WHITE, 15)
 text(Vector2(width - 300, height - 87), "R   %s" % ship.stats.ability.to_upper(), CYAN, 15)
 text(Vector2(width - 300, height - 61), "ACTIVE %.1fs" % ship.ability_remaining if ship.ability_remaining > 0 else ("READY" if ship.ability_cooldown <= 0 else "RECHARGING %.1fs" % ship.ability_cooldown), MUTED, 13)
 text(Vector2(width - 300, height - 35), "ESC   PAUSE / SETTINGS", MUTED, 13)
 panel(Rect2(Vector2(width - 320, 22), Vector2(296, 128)))
 text(Vector2(width - 300, 47), "FLEET  /  %s" % battle.fleet.current_command.to_upper(), CYAN, 16)
 for ally in battle.fleet.ships:
  var y := 72.0 + ally.fleet_slot * 25.0
  var color := CYAN if ally == ship else MUTED
  text(Vector2(width - 300, y), "F%d  %s  %s" % [ally.fleet_slot + 1, ally.stats.class_name_text, "%d%%" % int(ally.health.hull / ally.health.max_hull * 100) if ally.alive else "LOST"], color, 14)
 text(Vector2(42, 128), "PILOT  /  " + ship.crew_name.to_upper(), MUTED, 13)
 text(Vector2(width / 2 - 234, height - 30), "1 Follow   2 Attack   3 Defend   4 Regroup   5 Retreat", MUTED, 14)
 # Reticle remains centered on the ship's weapon axis (camera is offset upward).
 var weapon_point := ship.global_position - ship.global_basis.z * 500.0
 var reticle := battle.camera.unproject_position(weapon_point)
 draw_arc(reticle, 15, 0, TAU, 32, Color(CYAN, 0.65), 1.5)
 draw_line(reticle - Vector2(24, 0), reticle - Vector2(10, 0), CYAN)
 draw_line(reticle + Vector2(10, 0), reticle + Vector2(24, 0), CYAN)
 draw_line(reticle - Vector2(0, 24), reticle - Vector2(0, 10), CYAN)
 draw_circle(reticle, 2, CYAN)
 var target := ship.targeting.target
 for candidate in battle.ships:
  if candidate.alive and candidate != ship:
   _draw_ship_marker(candidate, candidate == target)
 if is_instance_valid(target) and target.alive:
  var info := "%s  /  %dm" % [target.callsign.to_upper(), int(ship.global_position.distance_to(target.global_position))]
  text(center + Vector2(-120, 95), info, RED, 15)
  text(center + Vector2(-120, 118), "MISSILE LOCK" if ship.targeting.locked() else "ACQUIRING  %d%%" % int(ship.targeting.lock_time / 1.2 * 100), CYAN if ship.targeting.locked() else MUTED, 13)
 else:
  text(center + Vector2(-110, 95), "TAB  /  ACQUIRE TARGET", MUTED, 14)
 if ship.outside_time > 0:
  draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.1, 0.10))
  text(Vector2(width / 2 - 190, 120), "OUTSIDE SAFE ZONE  /  RETURN TO CENTER", RED, 18)
  var direction := ship.global_position.direction_to(Vector3.ZERO)
  var local := battle.camera.global_basis.inverse() * direction
  text(Vector2(width / 2 - 95, 143), "CENTER %s  %dm" % ["LEFT" if local.x < 0 else "RIGHT", int(ship.global_position.length())], RED, 15)

func _draw_ship_marker(ship: CombatShip, selected: bool) -> void:
 var camera := battle.camera
 var color := RED if ship.team == 1 else CYAN
 var screen := camera.unproject_position(ship.global_position)
 var behind := camera.is_position_behind(ship.global_position)
 if behind or screen.x < 15 or screen.x > size.x - 15 or screen.y < 15 or screen.y > size.y - 15:
  if not selected:
   return
  var direction := screen - size / 2
  if behind:
   direction = -direction
  direction = direction.normalized()
  screen = size / 2 + direction * minf(size.x * 0.42, size.y * 0.38)
  draw_circle(screen, 8, color, false, 2)
  text(screen + Vector2(12, 5), "TARGET", color, 12)
  return
 var radius := 20.0 if selected else 8.0
 draw_rect(Rect2(screen - Vector2.ONE * radius, Vector2.ONE * radius * 2), color, false, 1.5)
 if ship.team == 1:
  draw_rect(Rect2(screen + Vector2(-25, -radius - 14), Vector2(50, 4)), Color(0.1, 0.1, 0.15))
  draw_rect(Rect2(screen + Vector2(-25, -radius - 14), Vector2(50 * ship.health.hull / ship.health.max_hull, 4)), RED)
  draw_rect(Rect2(screen + Vector2(-25, -radius - 20), Vector2(50 * ship.health.shield / ship.health.max_shield, 3)), CYAN)
 if selected:
  text(screen + Vector2(25, -8), ship.stats.class_name_text, color, 12)
