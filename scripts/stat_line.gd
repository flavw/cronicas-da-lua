@tool
extends Control

const NORMAL = Color("fff4da")
const BONUS = Color("62efa3")
const PENALTY = Color("ff7682")
var variable_stats := false
var text: String:
 get:
  return "*/*" if variable_stats else "%d/%d" % [values[0],values[1]]
var values: Array = [0,0,0,0,0]
var attack_label: Label
var health_label: Label

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 resized.connect(redraw_values)
 attack_label = make_label()
 var slash := make_label()
 slash.text = "/"
 slash.add_theme_color_override("font_color",NORMAL)
 health_label = make_label()
 redraw_values()

func make_label() -> Label:
 var label := Label.new()
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 label.add_theme_constant_override("outline_size",2)
 label.add_theme_color_override("font_outline_color",Color("090d15"))
 add_child(label)
 return label

func set_values(attack: int, health: int, base_attack: int, base_health: int, max_health: int = -1) -> void:
 values = [attack,health,base_attack,base_health,base_health if max_health < 0 else max_health]
 if is_node_ready():
  redraw_values()

func redraw_values() -> void:
 if not is_node_ready() or not is_instance_valid(attack_label):
  return
 attack_label.text = "*" if variable_stats else str(values[0])
 health_label.text = "*" if variable_stats else str(values[1])
 attack_label.add_theme_color_override("font_color",BONUS if values[0]>values[2] else (PENALTY if values[0]<values[2] else NORMAL))
 health_label.add_theme_color_override("font_color",PENALTY if values[1]<values[4] or values[1]<values[3] else (BONUS if values[1]>values[3] else NORMAL))
 var font_size := get_theme_font_size("font_size")
 var font := get_theme_font("font")
 var widths: Array[float] = []
 var total := 0.0
 for label in get_children():
  label.add_theme_font_size_override("font_size",font_size)
  label.add_theme_font_override("font",font)
  var width: float = font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
  widths.append(width)
  total += width
 var x := (size.x-total)*0.5
 for i in range(get_child_count()):
  var label: Label = get_child(i)
  label.position = Vector2(x,0)
  label.size = Vector2(widths[i],size.y)
  x += widths[i]
 tooltip_text = "Ataque %d (base %d) / Vida %d de %d (base %d)" % [values[0],values[2],values[1],values[4],values[3]]
