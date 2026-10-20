class_name TrainingFlight
extends BattleMatch
## Isolated, non-rewarding practice session. No hostile AI, timer or zone damage.
const LESSONS := [
 ["Find your wings", "Hold W to fly forward for a moment. S reverses thrust. Release the keys to slow down."],
 ["Slide sideways", "Hold A or D to strafe. You can move sideways without turning your ship."],
 ["Up and down", "Hold Space to climb, or Ctrl to descend. Spaceflight works in every direction."],
 ["Point your ship", "Move the mouse to steer. Your weapons aim along the centre reticle. Q / E rolls the ship."],
 ["A little extra speed", "Hold W + Shift to boost. Watch the orange boost reserve; release Shift to recharge."],
 ["Choose a target", "Press Tab to select the practice drone ahead. It will never attack you."],
 ["Land a laser hit", "Point the reticle at the drone and hold Left Click. Its health bar shows successful hits."],
 ["Lock and launch", "Keep the drone in front until MISSILE LOCK appears, then press M to launch. A lock is required."],
 ["Meet your fleet", "Press F2 or F3 to take control of a different ship. In battles, AI flies the ship you leave."],
 ["Lead the team", "Press 1 for Follow. Orders 2–5 are Attack, Defend, Regroup and Retreat. Your fleet listens to you."]
]
var lesson := 0
var progress := 0.0
var lesson_origin := Vector3.ZERO
var lesson_basis := Basis.IDENTITY
var initial_ship: CombatShip
var drone: CombatShip
var guide: CanvasLayer
var lesson_title: Label
var instructions: Label
var meter: ProgressBar
var completed := false

func _ready() -> void:
 set_meta("training",true)
 training = true
 profile = null
 super._ready()
 for ship in ships:
  ship.set_physics_process(false)
  ship.health.protection = 0.0 if ship.team == 0 else 1.0
  if is_instance_valid(ship.companion):
   ship.companion.queue_free()
   ship.companion = null
  ship.weapons.fired.connect(_on_fired)
  if ship.team == 1:
   ship.callsign = "Practice drone"
   ship.health.max_hull = 1000000
   ship.health.hull = 1000000
   ship.health.shield = 0
   if drone == null:
    drone = ship
    drone.health.hit.connect(_on_drone_hit)
   else:
    ship.alive = false
    ship.hide()
    ship.collision_layer = 0
 for ally in fleet.ships:ally.position = Vector3(ally.fleet_slot * 35,0,100)
 fleet.control_changed.connect(_on_control)
 _on_control(pilot.ship)
 hud.overlay.hide()
 _build_guide()
 retry_lesson()
 print("GALACTIC_TUTORIAL_READY lessons=%d" % LESSONS.size())

func _on_control(controlled: CombatShip) -> void:
 for ally in fleet.ships:ally.set_physics_process(ally == controlled)

func _build_guide() -> void:
 # Keep the real combat HUD reticle and health/weapon displays visible.
 hud.overlay.show()
 guide = CanvasLayer.new()
 guide.layer = 3
 add_child(guide)
 var panel := PanelContainer.new()
 panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
 panel.position = Vector2(-285,110)
 var style := StyleBoxFlat.new()
 style.bg_color = Color(.02,.035,.06,.96)
 style.border_color = Color(.3,.65,.7,.6)
 style.set_border_width_all(1)
 style.set_corner_radius_all(10)
 panel.add_theme_stylebox_override("panel",style)
 panel.custom_minimum_size = Vector2(570,0)
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel.theme = CartoonStyle.ui_theme()
 guide.add_child(panel)
 var margin := MarginContainer.new()
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,16)
 panel.add_child(margin)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation",8)
 margin.add_child(column)
 lesson_title = Label.new()
 lesson_title.add_theme_font_size_override("font_size",20)
 column.add_child(lesson_title)
 instructions = Label.new()
 instructions.custom_minimum_size.x = 530
 instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 column.add_child(instructions)
 meter = ProgressBar.new()
 meter.max_value = LESSONS.size()
 meter.show_percentage = false
 meter.custom_minimum_size.y = 6
 column.add_child(meter)
 var hint := Label.new()
 hint.text = "ESC  Pause · retry this lesson · skip training"
 hint.add_theme_font_size_override("font_size",12)
 column.add_child(hint)

func retry_lesson() -> void:
 if completed:return
 progress = 0
 lesson_origin = pilot.ship.global_position
 lesson_basis = pilot.ship.global_basis
 initial_ship = pilot.ship
 if lesson < 5:pilot.ship.targeting.select(null)
 if lesson == 9:fleet.issue_command("attack")
 if lesson in [5,6,7]:
  pilot.ship.velocity = Vector3.ZERO
  pilot.ship.targeting.select(null if lesson == 5 else drone)
  pilot.ship.weapons.laser_remaining = 0
  pilot.ship.weapons.missile_remaining = 0
  drone.position = pilot.ship.global_position - pilot.ship.global_basis.z * 160
 lesson_title.text = "FLIGHT SCHOOL  %d / %d  ·  %s" % [lesson+1,LESSONS.size(),LESSONS[lesson][0]]
 instructions.text = LESSONS[lesson][1]
 meter.value = lesson

func _physics_process(delta: float) -> void:
 if completed:return
 elapsed += delta
 var ship := pilot.ship
 # Invulnerable allies and a stationary drone make experimentation safe.
 for ally in fleet.ships:ally.health.protection = 0
 match lesson:
  0:
   if Input.is_action_pressed("forward") and ship.global_position.distance_to(lesson_origin)>12:progress += delta
  1:
   if (Input.is_action_pressed("strafe_left") or Input.is_action_pressed("strafe_right")) and ship.velocity.length()>2:progress += delta
  2:
   if (Input.is_action_pressed("up") or Input.is_action_pressed("down")) and ship.velocity.length()>2:progress += delta
  3:
   if lesson_basis.z.dot(ship.global_basis.z)<.98:advance();return
  4:
   if ship.movement.boost_requested and ship.movement.boost_energy<ship.stats.boost_capacity-5 and ship.velocity.length()>10:progress += delta
  5:
   if ship.targeting.target == drone:advance();return
  8:
   if ship != initial_ship:advance();return
  9:
   if fleet.current_command == "follow":advance();return
 if progress >= .65:advance()
 # Prevent getting lost in the training void. Retry places the drone ahead again.
 if ship.position.length()>2000:
  ship.position = Vector3(0,0,100)
  ship.velocity = Vector3.ZERO
  retry_lesson()

func _on_drone_hit(_shield_hit: bool) -> void:
 if lesson == 6:advance()

func _on_fired(missile: bool) -> void:
 if lesson == 7 and missile:advance()

func advance() -> void:
 if completed:return
 lesson += 1
 if lesson >= LESSONS.size():
  complete_training()
 else:retry_lesson()

func complete_training() -> void:
 completed = true
 for ship in ships:ship.set_physics_process(false)
 pilot.set_physics_process(false)
 fleet.set_process_unhandled_input(false)
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 guide.hide()
 var host := get_parent()
 host.settings.set_value("tutorial","flight_completed",true)
 host._save_settings()
 var layer := CanvasLayer.new()
 layer.layer = 4
 add_child(layer)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 layer.add_child(center)
 var panel := PanelContainer.new()
 panel.theme = CartoonStyle.ui_theme()
 panel.custom_minimum_size = Vector2(520,0)
 center.add_child(panel)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation",16)
 panel.add_child(column)
 var title := Label.new()
 title.text = "FLIGHT SCHOOL COMPLETE"
 title.add_theme_font_size_override("font_size",26)
 column.add_child(title)
 var detail := Label.new()
 detail.text = "You can fly, fight and lead a fleet.\nNext: explore at your own pace, or meet the wildlife.\n\nPlanet basics: Hold G to scan · T track · C capture\nReturn to your landed ship and press E to deliver captures.\nTraining grants no salvage or collectible rewards."
 column.add_child(detail)
 for option in [["Explore the galaxy",host.start_free_roam],["Visit the first planet",host.start_planet.bind(0)],["Replay flight school",host.start_tutorial],["Command deck",host.return_to_menu]]:
  var button := Button.new()
  button.text = option[0]
  button.custom_minimum_size.y = 42
  button.pressed.connect(option[1])
  column.add_child(button)
