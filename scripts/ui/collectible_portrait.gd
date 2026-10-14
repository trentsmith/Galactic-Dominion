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
 draw_circle(Vector2.ZERO, 72, Color(0.1, 0.13, 0.25))
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
  else:
   var skin := color.lightened(0.2)
   draw_circle(Vector2(0, -5), 37, Color(0.05, 0.07, 0.14))
   draw_circle(Vector2(0, -5), 34, skin)
   for side in [-1, 1]:
    draw_circle(Vector2(side * 24, 9), 6, Color(1, 0.48, 0.65))
    draw_circle(Vector2(side * 14, -11), 11, Color(0.04, 0.055, 0.13))
    draw_circle(Vector2(side * 14 - 3, -15), 4, Color.WHITE)
    draw_circle(Vector2(side * 20, 49), 10, skin.lightened(0.15))
   draw_arc(Vector2(0, 9), 10, 0.12, PI - 0.12, 16, Color(0.18, 0.1, 0.22), 3)
   if definition.species == "Vesperi":
    for side in [-1, 1]:
     draw_line(Vector2(side * 18, -31), Vector2(side * 26, -58), skin, 6)
     draw_circle(Vector2(side * 26, -58), 8, definition.accent)
   elif definition.species == "Auralith":
    for side in [-1, 1]:
     draw_circle(Vector2(side * 29, -38), 15, skin)
    draw_circle(Vector2(0, -35), 7, definition.accent)
   else:
    for side in [-1, 1]:
     draw_colored_polygon(PackedVector2Array([Vector2(side * 16, -29),Vector2(side * 30, -54),Vector2(side * 37, -25)]),Color(1,0.85,0.58))
   if definition.rarity in ["legendary", "mythic"]:
    draw_arc(Vector2(0, -3), 53, 0, TAU, 48, rarity, 4)
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
