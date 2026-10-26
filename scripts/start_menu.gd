extends Control

const UiTheme = preload("res://scripts/ui_theme.gd")
const Match = preload("res://scripts/match.gd")
const CardScene = preload("res://card_model.tscn")
const DeckScene = preload("res://deck_editor.tscn")
const TitleFont = preload("res://assets/fonts/title_font.tres")
var store := DeckStore.new()
var deck_layer: CanvasLayer
var rules_dialog: AcceptDialog
var play_button: Button

func _ready() -> void:
 theme = UiTheme.build()
 var background := ColorRect.new()
 background.color = Color("09121d")
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 background.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(background)
 var arena := TextureRect.new()
 arena.texture = preload("res://assets/ui/arena-background.png")
 arena.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 arena.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
 arena.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 arena.modulate = Color(0.5, 0.57, 0.67, 0.35)
 arena.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(arena)
 var margins := MarginContainer.new()
 margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left", "right"]:
  margins.add_theme_constant_override("margin_" + edge, 86)
 for edge in ["top", "bottom"]:
  margins.add_theme_constant_override("margin_" + edge, 60)
 add_child(margins)
 var columns := HBoxContainer.new()
 columns.add_theme_constant_override("separation", 70)
 margins.add_child(columns)
 var left := VBoxContainer.new()
 left.custom_minimum_size.x = 500
 left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 left.alignment = BoxContainer.ALIGNMENT_CENTER
 left.add_theme_constant_override("separation", 22)
 columns.add_child(left)
 var eyebrow := text_label("DUELO   •   FANTASIA   •   ESTRATÉGIA", 13, Color("8fabbc"))
 left.add_child(eyebrow)
 var title := text_label("CRÔNICAS\nDA LUA", 68, Color("e6d4a8"))
 title.name = "GameTitle"
 title.add_theme_font_override("font", TitleFont)
 left.add_child(title)
 var subtitle := text_label("Cada carta, uma história.\nCada duelo, uma nova noite.", 22, Color("a4b4c2"))
 left.add_child(subtitle)
 var spacer := Control.new()
 spacer.custom_minimum_size.y = 8
 left.add_child(spacer)
 play_button = menu_button("Jogar contra IA", start_game)
 play_button.name = "PlayAI"
 UiTheme.primary(play_button)
 left.add_child(play_button)
 var decks := menu_button("Meus decks", open_decks)
 decks.name = "OpenDecks"
 left.add_child(decks)
 left.add_child(menu_button("Como jogar", show_rules))
 var pvp := menu_button("Duelo PvP · em breve", func(): pass)
 pvp.disabled = true
 left.add_child(pvp)
 left.add_child(menu_button("Sair", func(): get_tree().quit()))
 var note := text_label("%d cartas  /  %d classes + neutros  /  %d decks" % [Match.CARD_DATA.values().filter(func(card):return card.collectible).size(),CardData.CardClass.size()-1,DeckStore.SLOT_COUNT], 14, Color("708595"))
 left.add_child(note)
 var right := CenterContainer.new()
 right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 columns.add_child(right)
 var display := Control.new()
 display.custom_minimum_size = Vector2(550, 640)
 display.mouse_filter = Control.MOUSE_FILTER_IGNORE
 right.add_child(display)
 var moon := Label.new()
 moon.text = "☾"
 moon.add_theme_font_size_override("font_size", 100)
 moon.add_theme_color_override("font_color", Color(0.66,0.79,0.88,0.45))
 moon.position = Vector2(218,-38)
 display.add_child(moon)
 for i in range(2):
  var card = CardScene.instantiate()
  card.card_data = Match.CARD_DATA.warrior if i == 0 else Match.CARD_DATA.mage
  card.custom_minimum_size = Vector2.ZERO
  card.size = Vector2(318,424)
  card.position = Vector2(10,100) if i == 0 else Vector2(228,181)
  card.pivot_offset = Vector2(159,212)
  card.rotation = deg_to_rad(-9 if i == 0 else 8)
  card.mouse_filter = Control.MOUSE_FILTER_IGNORE
  display.add_child(card)
 var footer := text_label("CRÔNICAS DA LUA  ·  DUELO DE CARTAS", 12, Color("566c7b"))
 footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
 footer.offset_left=86;footer.offset_right=700
 footer.offset_top=-32;footer.offset_bottom=-12
 add_child(footer)
 play_button.grab_focus()

func text_label(value: String, font_size: int, color: Color) -> Label:
 var label := Label.new()
 label.text = value
 label.add_theme_font_size_override("font_size", font_size)
 label.add_theme_color_override("font_color", color)
 return label

func menu_button(value: String, callback: Callable) -> Button:
 var button := Button.new()
 button.text = value
 button.custom_minimum_size = Vector2(390, 48)
 button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
 button.pressed.connect(callback)
 return button

func start_game() -> void:
 get_tree().change_scene_to_file("res://main.tscn")

func open_decks() -> void:
 if is_instance_valid(deck_layer):
  return
 deck_layer = CanvasLayer.new()
 deck_layer.layer = 30
 add_child(deck_layer)
 var editor = DeckScene.instantiate()
 editor.return_label = "Voltar ao início"
 editor.configure(store)
 deck_layer.add_child(editor)
 editor.closed.connect(close_decks)
 editor.play_requested.connect(start_game)

func close_decks() -> void:
 if is_instance_valid(deck_layer):
  remove_child(deck_layer)
  deck_layer.queue_free()
 deck_layer = null
 play_button.grab_focus()

func show_rules() -> void:
 if not is_instance_valid(rules_dialog):
  rules_dialog = AcceptDialog.new()
  rules_dialog.title = "Como jogar — Crônicas da Lua"
  var manual := RichTextLabel.new()
  manual.custom_minimum_size = Vector2(780,500)
  manual.text = FileAccess.get_file_as_string("res://MANUAL.txt")
  rules_dialog.add_child(manual)
  add_child(rules_dialog)
 rules_dialog.popup_centered(Vector2i(840,600))
