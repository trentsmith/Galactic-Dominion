class_name CollectiblePortrait
extends Control

var definition: CollectibleDefinition

func _ready() -> void:
 custom_minimum_size = Vector2(190, 170)
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
 if definition == null:
  return
 var center := size / 2
 var scale_factor := minf(size.x / 190.0, size.y / 170.0)
 draw_set_transform(center, 0, Vector2.ONE * scale_factor)
 var color := definition.color
 var rarity := definition.rarity_color()
 draw_circle(Vector2.ZERO, 72, Color(0.035, 0.06, 0.11))
 draw_arc(Vector2.ZERO, 76, 0, TAU, 64, rarity, 2)
 if definition.kind == "crew":
  var style := definition.visual_style
  draw_rect(Rect2(-42, 27, 84, 37), color.darkened(0.5))
  if style.begins_with("human"):
   draw_circle(Vector2(0, -8), 43, Color(0.2, 0.3, 0.4))
   draw_circle(Vector2(0, -8), 36, Color(0.7, 0.5, 0.38))
   draw_rect(Rect2(-35, -25, 70, 24), color.lightened(0.25))
   draw_line(Vector2(-30, -19), Vector2(8, -19), Color.WHITE, 2)
   if style == "human_solar":
    draw_arc(Vector2(0, -8), 53, 0, TAU, 48, Color(1, 0.8, 0.2), 4)
    draw_circle(Vector2(0, -12), 16, Color(0.2, 0.1, 0.05))
  elif style.begins_with("vesperi"):
   draw_circle(Vector2(0, -10), 33, color)
   for side in [-1, 1]:
    draw_line(Vector2(side * 19, -35), Vector2(side * 32, -60), color.lightened(0.3), 3)
    draw_circle(Vector2(side * 32, -60), 5, rarity)
    draw_circle(Vector2(side * 13, -14), 8, Color(0.03, 0.03, 0.06))
    draw_circle(Vector2(side * 13, -15), 3, Color(0.8, 1, 1))
   if style == "vesperi_prism":
    draw_polyline(PackedVector2Array([Vector2(-22, 10), Vector2(0, -28), Vector2(22, 10)]), Color.WHITE, 2)
  elif style == "kharon":
   draw_colored_polygon(PackedVector2Array([Vector2(-37, -3), Vector2(-24, -35), Vector2(-6, -43), Vector2(8, -32), Vector2(27, -37), Vector2(37, -3), Vector2(22, 25), Vector2(-22, 25)]), color)
   for side in [-1, 1]:
    draw_line(Vector2(side * 5, -5), Vector2(side * 23, -10), Color(1, 0.85, 0.35), 4)
  else:
   draw_circle(Vector2(0, -12), 34, color)
   for x in [-15, 15]:
    for y in [-23, -6]:
     draw_circle(Vector2(x, y), 5, Color(0.02, 0.08, 0.14))
     draw_circle(Vector2(x, y), 2, Color(0.8, 1, 1))
   draw_arc(Vector2(0, -12), 43, PI / 6, PI * 5 / 6, 24, color.lightened(0.3), 4)
 elif definition.kind == "component":
  draw_rect(Rect2(-32, -32, 64, 64), color.darkened(0.5))
  draw_rect(Rect2(-25, -25, 50, 50), color, false, 3)
  if definition.slot == "engine":
   for x in [-16, 0, 16]:
    draw_line(Vector2(x, 17), Vector2(x, 48), color.lightened(0.4), 5)
  elif definition.slot == "shield":
   draw_arc(Vector2.ZERO, 20, 0, TAU, 32, Color.WHITE, 3)
  elif definition.slot == "weapon":
   draw_line(Vector2(-16, 20), Vector2(18, -40), Color.WHITE, 6)
  else:
   for x in [-12, 12]:
    for y in [-12, 12]:
     draw_circle(Vector2(x, y), 4, Color.WHITE)
 else:
  draw_colored_polygon(PackedVector2Array([Vector2(0, -48), Vector2(16, 12), Vector2(58, 24), Vector2(55, 38), Vector2(-55, 38), Vector2(-58, 24), Vector2(-16, 12)]), color)
  draw_line(Vector2(0, -38), Vector2(0, 38), rarity, 4)
  if definition.visual_style == "celestial":
   draw_arc(Vector2(0, 5), 50, 0, TAU, 48, Color(1, 0.8, 0.2), 3)
