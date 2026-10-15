class_name GalaxyChart
extends Control
signal course_requested(region)
var battle: FreeRoamMatch
func _ready() -> void:
 custom_minimum_size = Vector2(550, 230)
 mouse_filter = Control.MOUSE_FILTER_STOP
func _process(_delta: float) -> void: queue_redraw()
func point(region: int) -> Vector2:
 var center: Vector3 = FreeRoamWorld.CENTERS[region]
 return Vector2(45 + (center.x + 6500) / 13500 * 450, 25 + (1000 - center.z) / 10000 * 175)
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO, size), Color(.025, .04, .09))
 var font := ThemeDB.fallback_font
 for index in range(1, FreeRoamWorld.CENTERS.size()):
  draw_line(point(index - 1), point(index), Color(.2, .35, .5), 1)
 for index in range(FreeRoamWorld.CENTERS.size()):
  draw_circle(point(index), 5, FreeRoamWorld.COLORS[index])
  var title: String = FreeRoamWorld.NAMES[index]
  var label_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
  var offset := -label_width if point(index).x > size.x * .7 else -20.0
  draw_string(font, point(index) + Vector2(offset, -9), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
 if is_instance_valid(battle.pilot.ship):
  var position := battle.pilot.ship.position
  var marker := Vector2(45 + (position.x + 6500) / 13500 * 450, 25 + (1000 - position.z) / 10000 * 175)
  draw_circle(marker.clamp(Vector2(5,5),size-Vector2(5,5)), 3, Color.WHITE)
func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
  for region in range(FreeRoamWorld.CENTERS.size()):
   if event.position.distance_to(point(region)) < 20:
    course_requested.emit(region)
    accept_event()
    break
