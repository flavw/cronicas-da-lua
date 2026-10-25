@tool
extends Control

const CardSkin = preload("res://scripts/card_skin.gd")
@export var card_data: CardData:
 set(value):
  if card_data and card_data.changed.is_connected(refresh):
   card_data.changed.disconnect(refresh)
  card_data = value
  if card_data:
   card_data.changed.connect(refresh)
  refresh()
var current_health := -1
var current_attack := -1
var current_block := -1

func _ready() -> void:
 resized.connect(layout_card)
 refresh()
 layout_card()

func layout_card() -> void:
 var canvas: Control = $CardCanvas
 var factor := minf(size.x / 360.0, size.y / 480.0)
 canvas.scale = Vector2.ONE * factor
 canvas.position = (size - Vector2(360, 480) * factor) / 2.0

func refresh() -> void:
 if not is_node_ready() or not card_data:
  return
 $CardCanvas/Artwork.texture = card_data.artwork
 var art: TextureRect = $CardCanvas/Artwork
 if not art.material:
  var material := ShaderMaterial.new()
  material.shader = preload("res://scripts/artwork.gdshader")
  art.material = material
 if card_data.artwork:
  var image_size: Vector2 = card_data.artwork.get_size()
  art.material.set_shader_parameter("view_aspect", 354.0 / 474.0)
  art.material.set_shader_parameter("source_aspect", image_size.x / image_size.y)
  art.material.set_shader_parameter("artwork_zoom", card_data.artwork_zoom)
  art.material.set_shader_parameter("artwork_focus", card_data.artwork_focus)
 $CardCanvas/Title.text = card_data.title
 $CardCanvas/Cost.text = str(card_data.cost)
 $CardCanvas/Ability.text = card_data.ability_text
 $CardCanvas/Stats.text = "%d/%d" % [card_data.attack if current_attack < 0 else current_attack, card_data.health if current_health < 0 else current_health]
 $CardCanvas/Stats.add_theme_font_size_override("font_size", 30 if $CardCanvas/Stats.text.length() <= 3 else 23)
 if current_block == 0 and card_data.block > 0:
  $CardCanvas/Ability.text = "Bloqueio consumido."
 $CardCanvas/TitleBanner.texture = CardSkin.texture("name-banner")
 $CardCanvas/CostGem.texture = CardSkin.texture("mana-gem")
 $CardCanvas/RulesPanel.texture = CardSkin.texture("rules-panel")
 $CardCanvas/Shield.texture = CardSkin.shield(card_data.card_class)
 # Adapt the type size to long names and ability text without rasterizing text.
 $CardCanvas/Title.add_theme_font_size_override("font_size", 22 if card_data.title.length() >= 14 else 27)
 $CardCanvas/Ability.add_theme_font_size_override("font_size", 14 if "\n" in card_data.ability_text or card_data.ability_text.length() > 45 else 24)
 $CardCanvas/Ability.offset_right = 285
 $CardCanvas/Stats.add_theme_color_override("font_color", Color("352819") if card_data.card_class == CardData.CardClass.CLERIC else Color("fff7e6"))
 tooltip_text = ""

func set_card(data: CardData, remaining_health: int = -1, modified_attack: int = -1, remaining_block: int = -1) -> void:
 current_health = remaining_health
 current_attack = modified_attack
 current_block = remaining_block
 card_data = data


