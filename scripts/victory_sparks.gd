extends Control
var elapsed := 0.0
var celebrate := true

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
 elapsed += delta
 if celebrate:
  queue_redraw()

func _draw() -> void:
 if not celebrate:
  return
 var center := size * 0.5 - Vector2(0, 95)
 for i in range(12):
  var angle := i * TAU / 12.0 + elapsed * 0.025
  var near := Vector2.from_angle(angle) * 80
  var far_a := Vector2.from_angle(angle - 0.065) * 550
  var far_b := Vector2.from_angle(angle + 0.065) * 550
  draw_colored_polygon(PackedVector2Array([center + near, center + far_a, center + far_b]), Color(1, 0.78, 0.3, 0.035))
 for i in range(64):
  var x := fposmod(i * 127.0 + sin(elapsed * 0.7 + i) * 24, size.x)
  var y := size.y - fposmod(i * 79.0 + elapsed * (18 + i % 8 * 4), size.y + 60)
  var alpha := 0.35 + 0.25 * sin(elapsed * 2 + i)
  draw_circle(Vector2(x, y), 1.2 + i % 3 * 0.6, Color(1, 0.8, 0.4, alpha))
 if elapsed < 1.8:
  var progress := elapsed / 1.8
  for i in range(36):
   var direction := Vector2.from_angle(i * TAU / 36.0)
   draw_circle(center + direction * (100 + progress * 520), 3, Color(1, 0.87, 0.56, (1 - progress) * 0.65))
