@tool
extends Control

signal inspect_requested(data: CardData, health: int, owner: Control)
signal inspect_closed(owner: Control)
signal activated
const CardSkin = preload("res://scripts/card_skin.gd")
@export var card_data: CardData:
 set(value):
  card_data = value
  refresh()
var current_health := -1
var available := false
var selected := false
var exhausted := false

func _ready() -> void:
 mouse_entered.connect(func(): inspect_requested.emit(card_data, current_health, self))
 mouse_exited.connect(func(): inspect_closed.emit(self))
 resized.connect(layout_card)
 refresh()
 layout_card()
 if not Engine.is_editor_hint():
  var icon: Control = $Canvas/Exhausted
  var base := icon.position
  var bob := create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
  bob.tween_property(icon, "position", base - Vector2(0, 6), 0.65)
  bob.parallel().tween_property(icon, "modulate:a", 0.55, 0.65)
  bob.tween_property(icon, "position", base, 0.65)
  bob.parallel().tween_property(icon, "modulate:a", 1.0, 0.65)

func layout_card() -> void:
 var factor := minf(size.x / 200.0, size.y / 200.0)
 $Canvas.scale = Vector2.ONE * factor
 $Canvas.position = (size - Vector2(200, 200) * factor) / 2.0

func refresh() -> void:
 if not is_node_ready() or not card_data:
  return
 # Keep the upper illustration (face) when cropping the portrait to a square.
 var art = card_data.artwork
 if art is AtlasTexture:
  var crop := AtlasTexture.new()
  crop.atlas = art.atlas
  crop.region = art.region
  if card_data.card_class != CardData.CardClass.NEUTRAL:
   crop.region.position.y += 35
   crop.region.size.y -= 35
  crop.region.size.y = minf(crop.region.size.y, crop.region.size.x * 0.82)
  crop.filter_clip = true
  art = crop
 $Canvas/Artwork.texture = art
 $Canvas/Shield.texture = CardSkin.shield(card_data.card_class)
 $Canvas/Stats.text = "%d/%d" % [get_meta("attack", card_data.attack), card_data.health if current_health < 0 else current_health]
 $Canvas/Stats.add_theme_font_size_override("font_size", 25 if $Canvas/Stats.text.length() <= 3 else 19)
 $Canvas/Stats.add_theme_color_override("font_color", Color("352819") if card_data.card_class == CardData.CardClass.CLERIC else Color("fff7e6"))
 var style := StyleBoxFlat.new()
 style.bg_color = Color("101822")
 style.set_border_width_all(3)
 style.border_color = Color("ffe09a") if selected else (Color("bd9956") if available else Color("655e51"))
 style.set_corner_radius_all(10)
 $Canvas/Frame.add_theme_stylebox_override("panel", style)
 $Canvas/Artwork.modulate = Color(0.5, 0.5, 0.6) if exhausted else Color.WHITE
 $Canvas/Exhausted.texture = CardSkin.texture("exhausted-zzz")
 $Canvas/Exhausted.visible = exhausted
 var armor_value: int = get_meta("armor", card_data.armor)
 var block_value: int = get_meta("block", -1)
 if block_value < 0:
  block_value = card_data.block
 $Canvas/StatusIcons/Armor.visible = armor_value > 0
 $Canvas/StatusIcons/Armor/Value.text = str(armor_value)
 $Canvas/StatusIcons/Block.visible = card_data.block > 0
 $Canvas/StatusIcons/Block/Value.text = str(block_value)

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and available:
  accept_event()
  activated.emit()

func set_card(data: CardData, health: int, enabled: bool, highlighted: bool = false, modified_attack: int = -1, remaining_block: int = -1, is_exhausted: bool = false, remaining_armor: int = -1) -> void:
 current_health = health
 available = enabled
 selected = highlighted
 exhausted = is_exhausted
 set_meta("attack", data.attack if modified_attack < 0 else modified_attack)
 set_meta("block", remaining_block)
 set_meta("armor", data.armor if remaining_armor < 0 else remaining_armor)
 card_data = data

