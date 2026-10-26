class_name ArmadaChart
extends Control
var battle: BattleMatch
func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE;visible=false
func _unhandled_input(event: InputEvent) -> void:
 if not battle.finished and not get_tree().paused and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_J:
  visible=not visible;get_viewport().set_input_as_handled()
func _process(_delta: float) -> void:
 if battle.finished:hide();return
 if visible:queue_redraw()
func point(at: Vector3) -> Vector2:
 return size*.5+Vector2(at.x,at.z)*(minf(size.x,size.y)*.36/ArmadaSector.RADIUS)
func detected(enemy: CombatShip) -> bool:
 return enemy.alive and battle.pilot.ship.position.distance_squared_to(enemy.position)<=ArmadaSector.SENSOR*ArmadaSector.SENSOR
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color(.008,.015,.03,.97))
 var font:=ThemeDB.fallback_font
 draw_string(font,Vector2(40,45),"ARMADA / 200 v 200 / SECTOR %d / J TO CLOSE"%battle.map_seed,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color(.6,.9,1))
 draw_string(font,Vector2(40,75),"Contacts are local sensor detections. Unseen enemies are not shown. Flight continues.",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(.6,.7,.8))
 draw_arc(size*.5,minf(size.x,size.y)*.36,0,TAU,96,Color(.2,.35,.45))
 for field in battle.sector_map.fields:draw_circle(point(field),17,Color(.22,.29,.35,.5))
 for hazard in battle.sector_map.hazards:
  draw_circle(point(hazard.position),10,Color(1,.7,.2) if hazard.kind=="star" else Color(.8,.25,.8))
 for ship in battle.ships:
  if not ship.alive:continue
  if ship.team!=battle.local_team() and not detected(ship):continue
  draw_circle(point(ship.position),2.5,Color(.2,.8,1) if ship.team==battle.local_team() else Color(1,.3,.2))
 draw_circle(point(battle.pilot.ship.position),6,Color.WHITE,false,2)
 draw_string(font,Vector2(40,size.y-35),"BLUE: ALLIES   RED: DETECTED ENEMY   GOLD: STAR   VIOLET: BLACK HOLE   GREY: ASTEROID FIELD",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color(.7,.8,.9))
