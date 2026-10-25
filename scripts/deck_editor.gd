extends Control

signal closed
signal play_requested
const Match = preload("res://scripts/match.gd")
const CardScene = preload("res://card_model.tscn")
const UiTheme = preload("res://scripts/ui_theme.gd")
var store: DeckStore
var slot := 0
var draft: Array = []
var draft_name := ""
var body: MarginContainer
var message := "Escolha cartas para montar seu deck."
var scroll_position := 0
var collection_scroll: ScrollContainer
var name_edit: LineEdit

func configure(value: DeckStore) -> void:
 store = value
 choose_slot(store.active)

func _ready() -> void:
 if not theme:
  theme = UiTheme.build()
 if not store:
  store = DeckStore.new()
  choose_slot(store.active)
 else:
  render()

func choose_slot(index: int) -> void:
 slot = index
 draft = store.slots[slot].cards.duplicate()
 draft_name = store.slots[slot].name
 message = "Editando espaço %d. Salve antes de trocar de espaço." % (slot + 1)
 render()

func text_label(value: String, font_size: int = 18) -> Label:
 var label := Label.new()
 label.text = value
 label.add_theme_font_size_override("font_size", font_size)
 return label

func action_button(value: String, callback: Callable, enabled: bool = true) -> Button:
 var button := Button.new()
 button.text = value
 button.custom_minimum_size = Vector2(44, 40)
 button.disabled = not enabled
 button.pressed.connect(callback)
 if value == "Jogar com este deck":
  UiTheme.primary(button)
 return button

func render() -> void:
 if not is_node_ready():
  return
 if is_instance_valid(body):
  scroll_position = collection_scroll.scroll_vertical
  remove_child(body)
  body.queue_free()
 else:
  var bg := ColorRect.new()
  bg.color = Color("0b1422")
  bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  add_child(bg)
 body = MarginContainer.new()
 body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left", "right", "top", "bottom"]:
  body.add_theme_constant_override("margin_" + edge, 24)
 add_child(body)
 var page := VBoxContainer.new()
 page.add_theme_constant_override("separation", 14)
 body.add_child(page)
 var title := HBoxContainer.new()
 page.add_child(title)
 var heading := text_label("EDITOR DE DECKS", 30)
 heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 title.add_child(heading)
 title.add_child(action_button("Voltar ao duelo", func(): closed.emit()))
 var tabs := HBoxContainer.new()
 tabs.add_theme_constant_override("separation", 12)
 page.add_child(tabs)
 for i in range(DeckStore.SLOT_COUNT):
  var active_text := " • ATIVO" if store.active == i else ""
  var tab := action_button("%s %d • %s%s" % ["✓" if i == slot else "", i + 1, store.slots[i].name, active_text], choose_slot.bind(i))
  tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  tabs.add_child(tab)
 var columns := HBoxContainer.new()
 columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
 columns.add_theme_constant_override("separation", 24)
 page.add_child(columns)
 var collection := VBoxContainer.new()
 collection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 columns.add_child(collection)
 collection.add_child(text_label("COLEÇÃO • %d cartas • todas as classes podem ser combinadas" % Match.CARD_DATA.size(), 19))
 collection_scroll = ScrollContainer.new()
 collection_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 collection_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 collection.add_child(collection_scroll)
 var grid := GridContainer.new()
 grid.columns = 4
 grid.add_theme_constant_override("h_separation", 12)
 grid.add_theme_constant_override("v_separation", 14)
 collection_scroll.add_child(grid)
 var keys: Array = Match.CARD_DATA.keys()
 keys.sort_custom(func(a, b): return Match.CARD_DATA[a].cost < Match.CARD_DATA[b].cost)
 for key in keys:
  var tile := VBoxContainer.new()
  grid.add_child(tile)
  var card = CardScene.instantiate()
  card.set_card(Match.CARD_DATA[key])
  card.custom_minimum_size = Vector2(188, 251)
  tile.add_child(card)
  var controls := HBoxContainer.new()
  controls.alignment = BoxContainer.ALIGNMENT_CENTER
  tile.add_child(controls)
  var count := draft.count(key)
  controls.add_child(action_button("−", remove_card.bind(key), count > 0))
  var quantity := text_label("%d / 2" % count, 20)
  quantity.custom_minimum_size.x = 70
  quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  controls.add_child(quantity)
  controls.add_child(action_button("+", add_card.bind(key), count < Match.MAX_COPIES and draft.size() < Match.DECK_SIZE))
  var kind: String = ["GUERREIRO", "MAGO", "NEUTRO", "LADINA", "CLÉRIGO"][Match.CARD_DATA[key].card_class]
  var class_label := text_label(kind, 14)
  class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  class_label.modulate = [Color("ef8a8a"), Color("c9a2ff"), Color("b9c3cf"), Color("6cdea4"), Color("f3e6b8")][Match.CARD_DATA[key].card_class]
  tile.add_child(class_label)
 collection_scroll.set_deferred("scroll_vertical", scroll_position)
 var deck_column := VBoxContainer.new()
 deck_column.custom_minimum_size.x = 365
 deck_column.add_theme_constant_override("separation", 10)
 columns.add_child(deck_column)
 deck_column.add_child(text_label("SEU DECK • %d / %d cartas" % [draft.size(), Match.DECK_SIZE], 23))
 name_edit = LineEdit.new()
 name_edit.text = draft_name
 name_edit.max_length = 24
 name_edit.placeholder_text = "Nome do deck"
 name_edit.custom_minimum_size.y = 42
 name_edit.text_changed.connect(func(value: String): draft_name = value)
 deck_column.add_child(name_edit)
 var deck_scroll := ScrollContainer.new()
 deck_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 deck_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 deck_column.add_child(deck_scroll)
 var list := VBoxContainer.new()
 list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 list.add_theme_constant_override("separation", 9)
 deck_scroll.add_child(list)
 var total_mana := 0
 for key in keys:
  var count := draft.count(key)
  if count == 0:
   continue
  total_mana += Match.CARD_DATA[key].cost * count
  var row := HBoxContainer.new()
  list.add_child(row)
  var item := text_label("%d  %s  ×%d" % [Match.CARD_DATA[key].cost, Match.CARD_DATA[key].title, count], 16)
  item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  row.add_child(item)
  row.add_child(action_button("−", remove_card.bind(key)))
 if draft.is_empty():
  list.add_child(text_label("Adicione cartas usando + na coleção."))
 var average := float(total_mana) / maxf(1, draft.size())
 deck_column.add_child(text_label("Custo médio: %.1f mana" % average, 18))
 deck_column.add_child(text_label("12 cartas • máximo 2 cópias de cada", 16))
 deck_column.add_child(action_button("Limpar este rascunho", clear_draft))
 deck_column.add_child(action_button("Restaurar sugestão", reset_draft))
 var footer := HBoxContainer.new()
 footer.add_theme_constant_override("separation", 14)
 page.add_child(footer)
 var status := text_label(message, 17)
 status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 footer.add_child(status)
 var valid := Match.valid_deck(draft)
 footer.add_child(action_button("Salvar deck", save_deck, valid))
 footer.add_child(action_button("Jogar com este deck", play_deck, valid))

func add_card(key: String) -> bool:
 if not Match.CARD_DATA.has(key) or draft.size() >= Match.DECK_SIZE or draft.count(key) >= Match.MAX_COPIES:
  return false
 draft.append(key)
 message = "Rascunho alterado • %d / 12 cartas." % draft.size()
 render()
 return true

func remove_card(key: String) -> bool:
 var index := draft.find(key)
 if index < 0:
  return false
 draft.remove_at(index)
 message = "Rascunho alterado • %d / 12 cartas." % draft.size()
 render()
 return true

func clear_draft() -> void:
 draft.clear()
 message = "Rascunho vazio. O deck salvo continua guardado."
 render()

func reset_draft() -> void:
 draft = Match.default_deck(slot)
 message = "Sugestão restaurada no rascunho."
 render()

func save_deck() -> bool:
 var saved := store.save_slot(slot, draft_name, draft)
 message = "Deck salvo neste computador." if saved else store.error_message
 render()
 return saved

func play_deck() -> void:
 if save_deck() and store.activate(slot):
  play_requested.emit()
 else:
  message = store.error_message
  render()
