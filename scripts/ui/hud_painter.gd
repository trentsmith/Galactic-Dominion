class_name HUDPainter
extends Control

const CYAN := Color(0.25, 0.85, 1)
const MUTED := Color(0.55, 0.67, 0.8)
const RED := Color(1, 0.35, 0.3)
var feedback: CombatFeedback
var battle: BattleMatch
var font: Font

func _ready() -> void:
 font = ThemeDB.fallback_font

func _process(_delta: float) -> void:
 queue_redraw()

func text(at: Vector2, content: String, color: Color = Color.WHITE, font_size: int = 16) -> void:
 draw_string(font, at, content, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func panel(rect: Rect2) -> void:
 var style := StyleBoxFlat.new()
 style.bg_color = Color(0.025, 0.035, 0.055, 0.82)
 style.border_color = Color(0.26, 0.4, 0.48, 0.5)
 style.set_border_width_all(1)
 style.set_corner_radius_all(8)
 draw_style_box(style, rect)

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
 var free_roam := battle is FreeRoamMatch
 var opponents := 0
 for candidate in battle.ships:
  if candidate.alive and candidate.team != ship.team: opponents += 1
 panel(Rect2(Vector2(24, 22), Vector2(285, 84)))
 text(Vector2(42, 48), "GALACTIC DOMINION", CYAN, 19)
 text(Vector2(42, 72), "FLIGHT SCHOOL / SAFE PRACTICE" if battle.training else "FREE ROAM / OPEN SPACE" if free_roam else "FLEET WAR 10v10 / " + SoloDifficulty.title(battle.difficulty).to_upper() if battle.team_size == 10 else "FLEET ROYALE / " + (SoloDifficulty.title(battle.difficulty).to_upper() if battle.network_role=="offline" else "ONLINE"), MUTED, 13)
 text(Vector2(42, 93), "ALLIES %d / HOSTILES %d" % [battle.living(battle.local_team()), opponents], Color.WHITE, 15)
 panel(Rect2(Vector2(width / 2 - 130, 22), Vector2(260, 61)))
 var exploring := battle is ExplorationMatch
 var remaining := maxi(0, int(battle.max_duration) - int(battle.elapsed))
 text(Vector2(width / 2 - 104, 48), "TRAINING" if battle.training else "FREE ROAM" if free_roam else "EXPLORATION" if exploring else "%02d:%02d   /   ZONE %dm" % [remaining / 60, remaining % 60, int(battle.zone.radius)], CYAN, 20)
 text(Vector2(width / 2 - 98, 70), "NO TIMER / NO INCOMING DAMAGE" if battle.training else "G SERVICE / J STAR CHART" if free_roam else "FREE FLIGHT / G SCAN / J MAP" if exploring else "FINAL COLLAPSE / NO RESPAWNS" if battle.elimination_only and battle.elapsed >= 480 else "CONTRACTING" if battle.elapsed > 30 else "CONTRACTION IN %ds" % int(30 - battle.elapsed), MUTED, 12)
 panel(Rect2(Vector2(24, height - 200), Vector2(320, 176)))
 text(Vector2(42, height - 174), "%s  /  %s" % [ship.callsign.to_upper(), ship.stats.class_name_text.to_upper()], CYAN, 16)
 bar(Vector2(42, height - 145), "HULL INTEGRITY", ship.health.hull, ship.health.max_hull, Color(0.6, 0.9, 0.65))
 bar(Vector2(42, height - 108), "SHIELD ENERGY", ship.health.shield, ship.health.max_shield, CYAN)
 bar(Vector2(42, height - 71), "BOOST RESERVE", ship.movement.boost_energy, ship.stats.boost_capacity, Color(1, 0.7, 0.25))
 text(Vector2(42, height - 36), "%d m/s  •  %s" % [int(ship.velocity.length()), "BOOST" if ship.movement.boost_requested else "CRUISE"], MUTED, 13)
 panel(Rect2(Vector2(width - 320, height - 200), Vector2(296, 176)))
 text(Vector2(width - 300, height - 171), "ARMAMENT", CYAN, 16)
 text(Vector2(width - 300, height - 143), "LMB   LASER    %s" % ("READY" if ship.weapons.laser_remaining <= 0 else "%.1fs" % ship.weapons.laser_remaining), Color.WHITE, 15)
 text(Vector2(width - 300, height - 115), "M     MISSILE  %s" % ("READY" if ship.weapons.missile_remaining <= 0 else "%.1fs" % ship.weapons.missile_remaining), Color.WHITE, 15)
 text(Vector2(width - 300, height - 87), "R   %s" % ship.stats.ability.to_upper(), CYAN, 15)
 text(Vector2(width - 300, height - 61), "ACTIVE %.1fs" % ship.ability_remaining if ship.ability_remaining > 0 else ("READY" if ship.ability_cooldown <= 0 else "RECHARGING %.1fs" % ship.ability_cooldown), MUTED, 13)
 text(Vector2(width - 300, height - 35), "ESC   PAUSE / SETTINGS", MUTED, 13)
 panel(Rect2(Vector2(width - 320, 22), Vector2(296, 58 + battle.fleet.ships.size() * 25)))
 text(Vector2(width - 300, 47), "FLEET  /  %s" % battle.fleet.current_command.to_upper(), CYAN, 16)
 for ally in battle.fleet.ships:
  var y := 72.0 + ally.fleet_slot * 25.0
  var color := CYAN if ally == ship else MUTED
  text(Vector2(width - 300, y), "F%d  %s  %s" % [ally.fleet_slot + 1, ally.stats.class_name_text, "%d%%" % int(ally.health.hull / ally.health.max_hull * 100) if ally.alive else "LOST"], color, 14)
 text(Vector2(42, 128), "PILOT  /  " + ship.crew_name.to_upper(), MUTED, 13)
 if is_instance_valid(ship.companion):
  text(Vector2(42, 149), "ALIEN COMPANION / AUTO ATTACK", CYAN, 13)
 text(Vector2(width / 2 - 234, height - 30), "1 Follow   2 Attack   3 Defend   4 Regroup   5 Retreat", MUTED, 14)
 # Reticle remains centered on the ship's weapon axis (camera is offset upward).
 var weapon_point := ship.global_position - ship.global_basis.z * 500.0
 var reticle := battle.camera.unproject_position(weapon_point)
 draw_arc(reticle, 15, 0, TAU, 32, Color(CYAN, 0.65), 1.5)
 draw_line(reticle - Vector2(24, 0), reticle - Vector2(10, 0), CYAN)
 draw_line(reticle + Vector2(10, 0), reticle + Vector2(24, 0), CYAN)
 draw_line(reticle - Vector2(0, 24), reticle - Vector2(0, 10), CYAN)
 draw_circle(reticle, 2, CYAN)
 if free_roam:
  var roaming := battle as FreeRoamMatch
  for index in range(FreeRoamWorld.CENTERS.size()):
   if ship.position.distance_to(FreeRoamWorld.CENTERS[index]) > 1600: continue
   _draw_location(FreeRoamWorld.CENTERS[index], FreeRoamWorld.NAMES[index] + " STATION", CYAN, ship)
  for landmark in roaming.world.landmarks:
   if ship.position.distance_to(landmark.position) < 1800:
    _draw_location(landmark.position, landmark.name, Color(.8, .65, 1), ship)
  for index in range(roaming.beacons.size()):
   if ship.position.distance_to(roaming.beacons[index].position) > 1400: continue
   if roaming.profile != null and not roaming.profile.exploration_records.has(roaming.signal_record(index)):
    _draw_location(roaming.beacons[index].position, "SIGNAL", Color(0.8, 0.5, 1), ship)
 if exploring:
  var exploration := battle as ExplorationMatch
  for index in range(exploration.beacons.size()):
   if exploration.profile.exploration_records.has(exploration._beacon_id(index)):
    continue
   var position := exploration.beacons[index].global_position
   if not battle.camera.is_position_behind(position):
    var screen := battle.camera.unproject_position(position)
    draw_circle(screen, 12, Color(0.75, 0.4, 1), false, 2)
    text(screen + Vector2(15, 0), "SIGNAL %dm" % int(ship.global_position.distance_to(position)), CYAN, 13)
 var target := ship.targeting.target
 for candidate in battle.ships:
  if candidate.alive and candidate != ship:
   if free_roam and candidate != target and ship.position.distance_to(candidate.position) > 1400: continue
   _draw_ship_marker(candidate, candidate == target)
 if is_instance_valid(target) and target.alive:
  _draw_target_card(target,ship)
 else:
  text(center + Vector2(-110, 95), "TAB  /  ACQUIRE TARGET", MUTED, 14)
 _draw_feedback(reticle)
 if ship.outside_time > 0:
  draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0.2, 0.1, 0.10))
  text(Vector2(width / 2 - 190, 120), "OUTSIDE SAFE ZONE  /  RETURN TO CENTER", RED, 18)
  var direction := ship.global_position.direction_to(Vector3.ZERO)
  var local := battle.camera.global_basis.inverse() * direction
  text(Vector2(width / 2 - 95, 143), "CENTER %s  %dm" % ["LEFT" if local.x < 0 else "RIGHT", int(ship.global_position.length())], RED, 15)

func _draw_ship_marker(ship: CombatShip, selected: bool) -> void:
 var camera := battle.camera
 var color := RED if ship.team != battle.local_team() else CYAN
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
 if ship.team != battle.local_team():
  var length := 90.0 if selected else 64.0
  var origin := screen + Vector2(-length/2,-radius-23)
  draw_rect(Rect2(origin-Vector2(2,2),Vector2(length+4,18)),Color(.01,.015,.025,.95))
  draw_rect(Rect2(origin,Vector2(length,5)),Color(.1,.16,.22))
  draw_rect(Rect2(origin,Vector2(length*clampf(ship.health.shield/maxf(1,ship.health.max_shield),0,1),5)),CYAN)
  draw_rect(Rect2(origin+Vector2(0,8),Vector2(length,6)),Color(.2,.08,.08))
  draw_rect(Rect2(origin+Vector2(0,8),Vector2(length*clampf(ship.health.hull/maxf(1,ship.health.max_hull),0,1),6)),Color(1,.65,.35))
 if selected:
  text(screen + Vector2(25, -8), ship.stats.class_name_text, color, 12)

func _draw_location(at: Vector3, name_text: String, color: Color, ship: CombatShip) -> void:
 if battle.camera.is_position_behind(at): return
 var screen := battle.camera.unproject_position(at)
 if screen.x < 20 or screen.x > size.x - 20 or screen.y < 20 or screen.y > size.y - 20: return
 draw_circle(screen, 9, color, false, 1.5)
 text(screen + Vector2(14, 0), "%s / %dm" % [name_text, int(ship.position.distance_to(at))], color, 12)

func _draw_target_card(target: CombatShip, ship: CombatShip) -> void:
 var at := Vector2(size.x/2-230,size.y-158)
 panel(Rect2(at,Vector2(460,106)))
 text(at+Vector2(16,22),"%s / %s / %dm" % [target.callsign,target.stats.class_name_text,int(ship.global_position.distance_to(target.global_position))],Color.WHITE,14)
 var hull_percent := int(100*target.health.hull/maxf(1,target.health.max_hull))
 text(at+Vector2(16,45),"HULL %d%% · %d / %d" % [hull_percent,ceil(target.health.hull),target.health.max_hull],Color(1,.75,.45),13)
 draw_rect(Rect2(at+Vector2(16,52),Vector2(204,7)),Color(.16,.08,.08))
 draw_rect(Rect2(at+Vector2(16,52),Vector2(204*clampf(target.health.hull/maxf(1,target.health.max_hull),0,1),7)),Color(1,.65,.35))
 text(at+Vector2(240,45),"SHIELD %d / %d" % [ceil(target.health.shield),target.health.max_shield],CYAN,13)
 draw_rect(Rect2(at+Vector2(240,52),Vector2(204,7)),Color(.08,.15,.2))
 draw_rect(Rect2(at+Vector2(240,52),Vector2(204*clampf(target.health.shield/maxf(1,target.health.max_shield),0,1),7)),CYAN)
 var lock_fraction := clampf(ship.targeting.lock_time/maxf(.01,ship.targeting.lock_duration),0,1)
 var lock_status := "LOCK READY · PRESS M" if ship.targeting.locked() else "LOCK %d%% · KEEP TARGET AHEAD" % int(lock_fraction*100)
 if ship.targeting.locked() and ship.weapons.missile_remaining>0:lock_status = "LOCK HELD · MISSILE RELOAD %.1fs" % ship.weapons.missile_remaining
 text(at+Vector2(16,81),lock_status,CYAN,13)
 draw_rect(Rect2(at+Vector2(16,90),Vector2(428,4)),Color(.08,.15,.2))
 draw_rect(Rect2(at+Vector2(16,90),Vector2(428*lock_fraction,4)),Color(.5,1,.75))

func _draw_feedback(reticle: Vector2) -> void:
 if not is_instance_valid(feedback):return
 var center := size/2
 reticle = feedback_anchor(reticle)
 for impact in feedback.directions:
  var direction := feedback.indicator_direction(impact.position)
  var tangent := Vector2(-direction.y,direction.x)
  var point := reticle+direction*112
  var color := Color(1,.4,.25) if impact.hull else CYAN
  color.a = clampf(float(impact.remaining)/1.2,0,1)
  draw_colored_polygon(PackedVector2Array([point+direction*14,point-direction*2+tangent*10,point-direction*2-tangent*10]),color)
 if feedback.damage_remaining>0:
  text(center+Vector2(-145,-85),feedback.damage_label,Color(1,.6,.4),15)
 if feedback.hit_remaining>0:
  var color := Color(1,.8,.4) if feedback.hit_hull else CYAN
  for side in [-1.0,1.0]:
   for vertical in [-1.0,1.0]:
    draw_line(reticle+Vector2(side*19,vertical*19),reticle+Vector2(side*26,vertical*26),color,2)
  text(reticle+Vector2(28,-25),"-%d %s" % [ceil(feedback.hit_amount),"HULL HIT" if feedback.hit_hull else "SHIELD HIT"],color,13)
 if feedback.incoming_count>0:
  panel(Rect2(center+Vector2(-230,-150),Vector2(460,38)))
  text(center+Vector2(-210,-125),"INCOMING MISSILE ×%d · BOOST + STRAFE" % feedback.incoming_count,Color(1,.5,.3),17)
 if feedback.notice_remaining>0:
  text(center+Vector2(-215,163),feedback.notice,feedback.notice_color,14)
 var ship := battle.pilot.ship
 if ship.health.hull<=ship.health.max_hull*.25 and ship.alive:
  draw_rect(Rect2(Vector2.ZERO,Vector2(size.x,5)),Color(1,.3,.2,.7))
  text(Vector2(42,size.y-213),"CRITICAL HULL · %s SWITCH / 5 RETREAT" % ("F1–F10" if battle.team_size==10 else "F1–F3"),Color(1,.45,.3),13)

func feedback_anchor(projected: Vector2) -> Vector2:
 # Offscreen/behind-camera weapon projections can be enormous during ship changes.
 return projected if projected.is_finite() and Rect2(Vector2.ZERO,size).has_point(projected) else size/2
