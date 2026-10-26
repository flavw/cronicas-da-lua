extends Control

signal closed
signal play_requested
const CardSkin=preload("res://scripts/card_skin.gd")
const Match = preload("res://scripts/match.gd")
const CardScene = preload("res://card_model.tscn")
const UiTheme = preload("res://scripts/ui_theme.gd")
@export var return_label := "Voltar ao duelo"
var screen := "library"
var library_selected := 0
var library_scroll_position := 0
var draft_cache: Dictionary={}
var personal_slot := 0
var personal_name := ""
var personal_cover := ""
var store: DeckStore
var slot := 0
var draft: Array = []
var draft_name := ""
var draft_base: int=-1
var addition_layer: CanvasLayer
var body: MarginContainer
var message := "Escolha cartas para montar seu deck."
var scroll_position := 0
var collection_scroll: ScrollContainer
var class_filter: int=-1
var type_filter: int=-1
var search_query: String=""
var focused_card: String=""
var pending_remove_key: String=""
var pending_open_slot: int=-1
var collection_tiles: Dictionary={}
const CLASS_NAMES=["Guerreiro","Mago","Neutro","Ladina","Clérigo","Horda"]
var name_edit: LineEdit

func configure(value: DeckStore) -> void:
 store = value
 load_slot(store.active)
 library_selected=store.active
 screen="library"
 message="%d espaços para jogar, criar e personalizar seus decks." % DeckStore.SLOT_COUNT
 render()

func _ready() -> void:
 if not theme:
  theme = UiTheme.build()
 if not store:
  configure(DeckStore.new())
 else:
  render()

func load_slot(index: int) -> void:
 pending_remove_key=""
 slot = index
 draft = store.slots[slot].cards.duplicate()
 draft_name = store.slots[slot].name
 draft_base=store.base_for(slot)
 if draft_cache.has(slot):
  draft=draft_cache[slot].cards.duplicate()
  draft_name=draft_cache[slot].name
  draft_base=int(draft_cache[slot].get("base_class",draft_base))
 message = "Escolha a classe base deste deck." if draft_base<0 else "Coleção: adicionar. Lista: localizar; repetir o clique remove. Salve antes de sair."

func choose_slot(index: int) -> void:
 library_selected=index
 load_slot(index)
 screen="choose_class" if draft_base<0 else "edit"
 focused_card=""
 reset_collection_scroll()
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
  var previous_scroll=body.find_child("DeckLibraryScroll",true,false)
  if is_instance_valid(previous_scroll):library_scroll_position=previous_scroll.scroll_vertical
  if is_instance_valid(collection_scroll):scroll_position = collection_scroll.scroll_vertical
  remove_child(body)
  body.queue_free()
 else:
  var bg := ColorRect.new()
  bg.color = Color("0b1422")
  bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  add_child(bg)
 collection_scroll=null
 collection_tiles.clear()
 body = MarginContainer.new()
 body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for edge in ["left", "right", "top", "bottom"]:
  body.add_theme_constant_override("margin_" + edge, 24)
 add_child(body)
 var page := VBoxContainer.new()
 page.add_theme_constant_override("separation", 14)
 body.add_child(page)
 if screen=="library":
  render_library(page)
  return
 if screen=="choose_class":
  render_class_choice(page)
  return
 if screen=="personalize":
  render_personalize(page)
  return
 var title := HBoxContainer.new()
 page.add_child(title)
 var heading := text_label("EDITAR CARTAS · DECK %d" % (slot+1), 30)
 heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 title.add_child(heading)
 title.add_child(action_button("Meus decks",show_library))
 var columns := HBoxContainer.new()
 columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
 columns.add_theme_constant_override("separation", 24)
 page.add_child(columns)
 var collection := VBoxContainer.new()
 collection.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 columns.add_child(collection)
 var visible_keys: Array=collection_keys()
 collection.add_child(text_label("COLEÇÃO • %d de %d cartas" % [visible_keys.size(),Match.CARD_DATA.size()],19))
 build_collection_filters(collection)
 collection_scroll = ScrollContainer.new()
 collection_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
 collection_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 collection.add_child(collection_scroll)
 var grid := GridContainer.new()
 grid.name="CollectionGrid"
 grid.columns = 5 if get_viewport_rect().size.x>=1800 else 4
 grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 grid.add_theme_constant_override("h_separation", 12)
 grid.add_theme_constant_override("v_separation", 14)
 collection_scroll.add_child(grid)
 var keys: Array=sorted_keys()
 for key in visible_keys:
  var frame:=PanelContainer.new()
  frame.name="CollectionCard_"+String(key)
  frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var tile_style:=collection_style(key)
  frame.add_theme_stylebox_override("panel",tile_style)
  grid.add_child(frame)
  collection_tiles[key]=frame
  var tile:=VBoxContainer.new()
  frame.add_child(tile)
  var card = CardScene.instantiate()
  card.set_card(Match.CARD_DATA[key])
  card.custom_minimum_size = Vector2(214,286)
  card.resized.connect(func():card.custom_minimum_size.y=roundf(card.size.x*4.0/3.0))
  tile.add_child(card)
  card.name="CollectionView_"+String(key)
  card.focus_mode=Control.FOCUS_ALL
  card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
  card.gui_input.connect(collection_card_input.bind(key))
  var reason:=addition_reason(key)
  card.tooltip_text="Clique para adicionar uma cópia. Botão direito: ver arte." if reason.is_empty() else reason
  if not reason.is_empty():card.modulate=Color(0.7,0.7,0.75)
  var quantity:=text_label("%d / %d" % [draft.count(key),Match.copy_limit(key)],16)
  quantity.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  tile.add_child(quantity)
  var kind: String = CLASS_NAMES[Match.CARD_DATA[key].card_class].to_upper()
  if Match.CARD_DATA[key].legendary:kind+=" • LENDÁRIA"
  kind += " • "+Match.CARD_DATA[key].creature_type_name().to_upper()
  var class_label := text_label(kind, 14)
  class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  class_label.modulate = CardSkin.class_color(Match.CARD_DATA[key].card_class).lightened(0.2)
  tile.add_child(class_label)

 if visible_keys.is_empty():
  var empty:=text_label("Nenhuma carta encontrada. Altere os filtros ou a busca.",17)
  empty.name="CollectionEmpty"
  grid.add_child(empty)
 collection_scroll.set_deferred("scroll_vertical", scroll_position)
 var deck_column := VBoxContainer.new()
 deck_column.custom_minimum_size.x = 365
 deck_column.add_theme_constant_override("separation", 10)
 columns.add_child(deck_column)
 var deck_heading:=HBoxContainer.new()
 deck_column.add_child(deck_heading)
 var deck_title:=text_label("SEU DECK • %d / %d cartas" % [draft.size(),Match.DECK_SIZE],23)
 deck_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 deck_heading.add_child(deck_title)
 deck_heading.add_child(class_badge(draft,24,draft_base))
 var faction: int=draft_base
 var rule:=text_label("Somente neutros" if draft_base==CardData.CardClass.NEUTRAL else ("Horda • Humanos só com Pacto Sombrio" if draft_base==CardData.CardClass.HORDE else "Classe: %s • neutros permitidos" % CLASS_NAMES[maxi(0,draft_base)]),15)
 rule.name="DeckClassRule"
 rule.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 rule.modulate=Color("a3c7dd")
 deck_column.add_child(rule)
 var progress:=ProgressBar.new()
 progress.name="DeckProgress"
 progress.max_value=Match.DECK_SIZE;progress.value=draft.size();progress.show_percentage=false
 progress.custom_minimum_size.y=7
 deck_column.add_child(progress)
 var change:=action_button("Trocar classe base",begin_class_choice,draft.is_empty())
 change.name="ChangeDeckBase"
 change.tooltip_text="Esvazie o rascunho para trocar a classe." if not draft.is_empty() else "Escolher outra classe base"
 deck_column.add_child(change)
 if not DeckStore.accepts_base(draft_base,draft):
  var hint:=text_label("Remova da lista as cartas fora da classe base.",15)
  hint.modulate=Color("ff8591");hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  deck_column.add_child(hint)
 name_edit = LineEdit.new()
 name_edit.text = draft_name
 name_edit.max_length = 24
 name_edit.placeholder_text = "Nome do deck"
 name_edit.custom_minimum_size.y = 42
 name_edit.text_changed.connect(func(value: String): draft_name = value)
 deck_column.add_child(name_edit)
 var deck_scroll := ScrollContainer.new()
 deck_scroll.name="DeckListScroll"
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
  var item:=Button.new()
  item.name="DeckCard_"+String(key)
  item.custom_minimum_size=Vector2(0,40)
  item.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var row_class: int=Match.CARD_DATA[key].card_class
  var tint: Color=CardSkin.class_color(row_class).lightened(0.18)
  var style:=UiTheme.panel(Color("101c2a"),Color("273a4a") if row_class==CardData.CardClass.NEUTRAL else tint.darkened(0.5),6)
  style.border_width_left=1 if row_class==CardData.CardClass.NEUTRAL else 3
  if pending_remove_key==key:style.border_color=Color("e5c987")
  item.add_theme_stylebox_override("normal",style)
  item.tooltip_text="Primeiro clique: localizar na coleção. Segundo clique na mesma carta: remover uma cópia."
  item.pressed.connect(select_deck_card.bind(key))
  item.gui_input.connect(deck_card_input.bind(key))
  list.add_child(item)
  var content:=HBoxContainer.new()
  content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  content.offset_left=7;content.offset_right=-7;content.offset_top=4;content.offset_bottom=-4
  content.mouse_filter=Control.MOUSE_FILTER_IGNORE
  item.add_child(content)
  content.add_child(mana_badge(Match.CARD_DATA[key].cost))
  var caption:=text_label("%s  ×%d" % [Match.CARD_DATA[key].title,count],16)
  caption.name="DeckCardCaption"
  caption.clip_text=true;caption.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
  caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
  if row_class!=CardData.CardClass.NEUTRAL:caption.add_theme_color_override("font_color",tint)
  else:caption.add_theme_color_override("font_color",Color("f2d9a6"))
  content.add_child(caption)
 if draft.is_empty():
  list.add_child(text_label("Clique nas cartas da coleção para adicionar."))
 var average := float(total_mana) / maxf(1, draft.size())
 var creatures: int=0
 for key in draft:
  if Match.CARD_DATA[key].card_type==CardData.CardType.CREATURE:creatures+=1
 deck_column.add_child(text_label("%d criaturas · %d magias · Mana média %.1f" % [creatures,draft.size()-creatures,average],15))
 deck_column.add_child(text_label("20 cartas • 2 cópias · Lendárias: 1", 14))
 deck_column.add_child(action_button("Limpar este rascunho", clear_draft))
 var footer := HBoxContainer.new()
 footer.add_theme_constant_override("separation", 14)
 page.add_child(footer)
 var status := text_label(message, 17)
 status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 footer.add_child(status)
 var valid := Match.valid_deck(draft) and DeckStore.accepts_base(draft_base,draft)
 footer.add_child(action_button("Salvar deck", save_deck, valid or draft.is_empty()))
 footer.add_child(action_button("Jogar com este deck", play_deck, valid))

func begin_class_choice() -> void:
 if not draft.is_empty() and draft_base>=0:
  message="Esvazie o rascunho para trocar a classe base.";render();return
 screen="choose_class"
 render()

func select_base_class(value: int) -> void:
 if value not in [0,1,2,3,4,5]:return
 if not draft.is_empty() and draft_base>=0 and draft_base!=value:return
 draft_base=value
 class_filter=-1;type_filter=-1;search_query="";focused_card=""
 screen="edit"
 message="Coleção: adicionar. Lista: localizar; repetir o clique remove."
 reset_collection_scroll();render()

func render_class_choice(page: VBoxContainer) -> void:
 library_title(page,"CLASSE BASE · DECK %d" % (slot+1),"Meus decks",show_library)
 var intro:=text_label("Escolha a classe deste deck. A coleção mostrará apenas cartas compatíveis.",20)
 intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 page.add_child(intro)
 var center:=CenterContainer.new()
 center.size_flags_vertical=Control.SIZE_EXPAND_FILL
 page.add_child(center)
 var grid:=GridContainer.new()
 grid.name="BaseClassChoices";grid.columns=3
 grid.add_theme_constant_override("h_separation",20);grid.add_theme_constant_override("v_separation",20)
 center.add_child(grid)
 for value in [0,1,3,4,5,2]:
  var choice:=Button.new()
  choice.name="ChooseBase_%d" % value
  choice.custom_minimum_size=Vector2(330,170)
  choice.pressed.connect(select_base_class.bind(value))
  grid.add_child(choice)
  var content:=VBoxContainer.new()
  content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  content.offset_left=14;content.offset_right=-14;content.offset_top=14;content.offset_bottom=-14
  content.alignment=BoxContainer.ALIGNMENT_CENTER
  content.mouse_filter=Control.MOUSE_FILTER_IGNORE
  choice.add_child(content)
  var icon:=TextureRect.new()
  icon.texture=CardSkin.class_symbol(value)
  icon.custom_minimum_size=Vector2(54,54)
  icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
  content.add_child(icon)
  var title:=text_label("Neutros" if value==CardData.CardClass.NEUTRAL else CLASS_NAMES[value],25)
  title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.modulate=CardSkin.class_color(value).lightened(0.2)
  title.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(title)
  var note:=text_label("Somente cartas neutras" if value==CardData.CardClass.NEUTRAL else ("Sem Humanos, exceto Pacto Sombrio" if value==CardData.CardClass.HORDE else "Classe e neutros compatíveis"),16)
  note.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;note.mouse_filter=Control.MOUSE_FILTER_IGNORE
  content.add_child(note)
 var hint:=text_label("A escolha só é gravada ao salvar o deck. Para trocar a base, esvazie o rascunho.",16)
 hint.modulate=Color("9eb3c6");page.add_child(hint)

func collection_card_input(event: InputEvent,key: String) -> void:
 var clicked: bool=event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT
 var confirmed: bool=event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER,KEY_SPACE]
 if clicked or confirmed:
  get_viewport().set_input_as_handled()
  add_card(key,true)

func select_deck_card(key: String) -> void:
 if pending_remove_key==key:
  remove_card(key)
 else:
  pending_remove_key=key
  locate_card(key)

func deck_card_input(event: InputEvent,key: String) -> void:
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
  get_viewport().set_input_as_handled()
  pending_remove_key=""
  locate_card(key)

func animate_addition(key: String,source: Rect2) -> void:
 await get_tree().process_frame
 await get_tree().process_frame
 if screen!="edit":return
 var target: Control=find_child("DeckCard_"+key,true,false)
 if not is_instance_valid(target):return
 var scroll: ScrollContainer=find_child("DeckListScroll",true,false)
 if scroll:scroll.ensure_control_visible(target)
 await get_tree().process_frame
 if not is_instance_valid(target) or screen!="edit":return
 if not is_instance_valid(addition_layer):
  addition_layer=CanvasLayer.new();addition_layer.layer=40;add_child(addition_layer)
 var ghost=CardScene.instantiate()
 ghost.name="CardAddFlight"
 ghost.card_data=Match.CARD_DATA[key]
 ghost.custom_minimum_size=Vector2.ZERO;ghost.position=source.position;ghost.size=source.size
 ghost.mouse_filter=Control.MOUSE_FILTER_IGNORE
 addition_layer.add_child(ghost)
 var destination: Vector2=target.get_global_rect().get_center()-source.size*0.11
 var tween:=create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
 tween.tween_property(ghost,"position",destination,0.28)
 tween.tween_property(ghost,"scale",Vector2.ONE*0.22,0.28)
 tween.tween_property(ghost,"modulate:a",0.25,0.28)
 tween.finished.connect(ghost.queue_free)

func sorted_keys() -> Array:
 var keys: Array=Match.CARD_DATA.keys()
 keys.sort_custom(func(a,b):
  var ca: CardData=Match.CARD_DATA[a]
  var cb: CardData=Match.CARD_DATA[b]
  return ca.title.naturalnocasecmp_to(cb.title)<0 if ca.cost==cb.cost else ca.cost<cb.cost)
 return keys

func searchable(value: String) -> String:
 var result:=value.to_lower()
 for pair in [["á","a"],["à","a"],["ã","a"],["â","a"],["é","e"],["ê","e"],["í","i"],["ó","o"],["ô","o"],["õ","o"],["ú","u"],["ç","c"]]:result=result.replace(pair[0],pair[1])
 return result

func matches_filters(key: String) -> bool:
 var data: CardData=Match.CARD_DATA[key]
 if not data.collectible:return false
 if draft_base<0 or not DeckStore.accepts_base(draft_base,[key]):return false
 if class_filter>=0 and data.card_class!=class_filter:return false
 if type_filter in [0,1] and data.card_type!=type_filter:return false
 if type_filter>=2 and (data.card_type!=CardData.CardType.CREATURE or data.creature_type!=type_filter-2):return false
 if not search_query.strip_edges().is_empty():
  var content: String=data.title+" "+data.creature_type_name()
  for entry in data.ability_entries():content+=" "+entry.name+" "+String(entry.get("summary",""))
  if not searchable(content).contains(searchable(search_query.strip_edges())):return false
 return true

func collection_keys() -> Array:
 return sorted_keys().filter(func(key):return matches_filters(key))

func build_collection_filters(parent: VBoxContainer) -> void:
 var row:=HBoxContainer.new();parent.add_child(row)
 var picker:=OptionButton.new();picker.name="CollectionClassFilter"
 var values: Array=[-1] if draft_base==CardData.CardClass.NEUTRAL else [-1,draft_base,CardData.CardClass.NEUTRAL]
 var labels: Array=["Neutros"] if draft_base==CardData.CardClass.NEUTRAL else [CLASS_NAMES[draft_base]+" e neutros","Somente "+CLASS_NAMES[draft_base],"Somente neutros"]
 for label in labels:picker.add_item(label)
 picker.select(maxi(0,values.find(class_filter)))
 picker.item_selected.connect(func(index):class_filter=values[index];reset_collection_scroll();render())
 row.add_child(picker)
 var types:=OptionButton.new();types.name="CollectionTypeFilter"
 for label in ["Todos os tipos","Criaturas","Magias","Humano","Fera","Artefato","Monstro","Morto-vivo"]:types.add_item(label)
 types.select(type_filter+1)
 types.item_selected.connect(func(index):type_filter=index-1;reset_collection_scroll();render())
 row.add_child(types)
 var search_row:=HBoxContainer.new();parent.add_child(search_row)
 var search:=LineEdit.new();search.name="CollectionSearch";search.placeholder_text="Buscar nome, habilidade ou tipo…";search.text=search_query
 search.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 search.text_changed.connect(func(value):
  var caret: int=search.caret_column
  search_query=value;reset_collection_scroll();render()
  var replacement: LineEdit=find_child("CollectionSearch",true,false)
  replacement.grab_focus();replacement.caret_column=caret)
 search_row.add_child(search)
 search_row.add_child(action_button("Limpar filtros",clear_collection_filters))

func reset_collection_scroll() -> void:
 scroll_position=0
 if is_instance_valid(collection_scroll):collection_scroll.scroll_vertical=0

func clear_collection_filters() -> void:
 class_filter=-1;type_filter=-1;search_query=""
 reset_collection_scroll();render()

func collection_style(key: String) -> StyleBoxFlat:
 var style:=UiTheme.panel(Color("44351b") if key==focused_card else Color("0e1a28"),Color("ffe09b") if key==focused_card else Color("273a4a"),6)
 if key==focused_card:
  style.set_border_width_all(4)
  style.shadow_color=Color(1.0,0.75,0.25,0.42)
  style.shadow_size=10
 for edge in ["left","right","top","bottom"]:style.set("content_margin_"+edge,5)
 return style

func _input(event: InputEvent) -> void:
 if screen!="edit" or focused_card.is_empty() or not is_instance_valid(collection_scroll):return
 if not event is InputEventMouseButton or not event.pressed:return
 if event.button_index not in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:return
 if not collection_scroll.get_global_rect().has_point(event.position):return
 for key in collection_tiles:
  var tile: Control=collection_tiles[key]
  if key!=focused_card and is_instance_valid(tile) and tile.get_global_rect().has_point(event.position):
   var previous_key:=focused_card
   var previous: Control=collection_tiles.get(focused_card)
   focused_card=""
   pending_remove_key=""
   if is_instance_valid(previous):previous.add_theme_stylebox_override("panel",collection_style(previous_key))
   return

func locate_card(key: String) -> void:
 if not Match.CARD_DATA.has(key):return
 if not DeckStore.accepts_base(draft_base,[key]):
  message="Carta fora da classe base. Clique nela na lista para remover.";render();return
 if not matches_filters(key):
  class_filter=-1;type_filter=-1;search_query=""
 focused_card=key
 message="%s localizada na coleção." % Match.CARD_DATA[key].title
 render()
 reveal_card.call_deferred(key)

func reveal_card(key: String) -> void:
 await get_tree().process_frame
 await get_tree().process_frame
 if screen!="edit" or not is_instance_valid(collection_scroll):return
 var tile: Control=collection_tiles.get(key)
 if not is_instance_valid(tile):return
 collection_scroll.ensure_control_visible(tile)
 scroll_position=collection_scroll.scroll_vertical

func addition_reason(key: String) -> String:
 if not Match.CARD_DATA.has(key):return "Carta desconhecida."
 if draft_base<0:return "Escolha uma classe base primeiro."
 if not Match.CARD_DATA[key].collectible:return "Criatura invocada: não pode entrar no deck."
 if Match.neutral_monster_forbidden(draft_base,key):return "Monstros neutros só podem entrar na Horda ou em decks só de neutros."
 if not DeckStore.accepts_base(draft_base,[key]):return "Humanos precisam de Pacto Sombrio para entrar na Horda." if draft_base==CardData.CardClass.HORDE and Match.CARD_DATA[key].is_human() else "Esta carta não pertence à classe base do deck."
 if not Match.can_add_class(draft,key):return "Use somente uma classe por deck. Neutros são permitidos."
 if draft.count(key)>=Match.copy_limit(key):return "Lendária: máximo de 1 cópia." if Match.CARD_DATA[key].legendary else "Máximo de 2 cópias desta carta."
 if draft.size()>=Match.DECK_SIZE:return "Deck completo: remova uma carta antes de adicionar."
 return ""

func add_card(key: String,animate: bool=false) -> bool:
 pending_remove_key=""
 var reason:=addition_reason(key)
 if not reason.is_empty():
  message=reason
  render()
  return false
 var source:=Rect2()
 if animate:
  var card: Control=find_child("CollectionView_"+key,true,false)
  if is_instance_valid(card):source=card.get_global_rect()
 draft.append(key)
 message = "Rascunho alterado • %d / 20 cartas." % draft.size()
 render()
 if animate and source.size.x>0:animate_addition.call_deferred(key,source)
 return true

func remove_card(key: String) -> bool:
 pending_remove_key=""
 var index := draft.find(key)
 if index < 0:
  return false
 draft.remove_at(index)
 message = "Rascunho alterado • %d / 20 cartas." % draft.size()
 render()
 return true

func clear_draft() -> void:
 draft.clear()
 message = "Rascunho vazio. O deck salvo continua guardado."
 render()

func save_deck() -> bool:
 var saved := store.save_slot(slot, draft_name, draft,draft_base)
 if saved:draft_cache.erase(slot)
 message = ("Espaço vazio salvo." if draft.is_empty() else "Deck salvo neste computador.") if saved else store.error_message
 render()
 return saved

func play_deck() -> void:
 if not Match.valid_deck(draft) or not DeckStore.accepts_base(draft_base,draft):
  message="Complete um deck de 20 cartas, uma classe + neutros, antes de jogar."
  render()
  return
 if save_deck() and store.activate(slot):
  play_requested.emit()
 else:
  message = store.error_message
  render()

func mana_badge(cost: int) -> Control:
 var badge:=Control.new()
 badge.name="DeckManaCost"
 badge.custom_minimum_size=Vector2(28,28)
 badge.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var gem:=TextureRect.new()
 gem.texture=CardSkin.texture("mana-cost-symbol")
 gem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 gem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 gem.size=Vector2(28,28)
 gem.mouse_filter=Control.MOUSE_FILTER_IGNORE
 badge.add_child(gem)
 var number:=Label.new()
 number.text=str(cost)
 number.position=Vector2(0,-2)
 number.size=Vector2(28,28)
 number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 number.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 var font:=SystemFont.new()
 font.font_names=PackedStringArray(["Noto Sans","Segoe UI","DejaVu Sans"])
 font.font_weight=800
 number.add_theme_font_override("font",font)
 number.add_theme_font_size_override("font_size",20)
 number.add_theme_color_override("font_color",Color("0b0c0e"))
 number.mouse_filter=Control.MOUSE_FILTER_IGNORE
 badge.add_child(number)
 return badge

func show_library() -> void:
 pending_open_slot=-1
 pending_remove_key=""
 if screen in ["edit","choose_class"]:
  if draft!=store.slots[slot].cards or draft_name!=store.slots[slot].name or draft_base!=store.base_for(slot):
   draft_cache[slot]={"cards":draft.duplicate(),"name":draft_name,"base_class":draft_base}
  else:draft_cache.erase(slot)
 screen="library"
 message="Escolha um deck para jogar, editar cartas ou personalizar."
 render()

func library_title(page: VBoxContainer,value: String,back_text: String,callback: Callable) -> void:
 var heading:=HBoxContainer.new()
 page.add_child(heading)
 var title:=text_label(value,30)
 title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 heading.add_child(title)
 heading.add_child(action_button(back_text,callback))

func deck_description(cards: Array) -> String:
 if cards.is_empty():return "Espaço vazio"
 return "%d/20 cartas%s" % [cards.size()," · Composição a corrigir" if Match.deck_class(cards)==-2 or not Match.restrictions_met(cards) else ""]

func class_badge(cards: Array,icon_size: int=22,base: int=-3) -> Control:
 if cards.is_empty() and base<0:return Control.new()
 var faction: int=Match.deck_class(cards) if base==-3 else base
 if faction==-2:
  var error:=text_label("!",icon_size)
  error.tooltip_text="Classes misturadas"
  error.modulate=Color("ff8591")
  return error
 var icon_class: int=CardData.CardClass.NEUTRAL if faction==-1 else faction
 var icon:=TextureRect.new()
 icon.name="DeckClassSymbol"
 icon.texture=CardSkin.class_symbol(icon_class)
 icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 icon.custom_minimum_size=Vector2(icon_size,icon_size)
 icon.size=Vector2(icon_size,icon_size)
 icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 icon.mouse_filter=Control.MOUSE_FILTER_PASS
 icon.tooltip_text=["Guerreiro","Mago","Neutro","Ladina","Clérigo","Horda"][icon_class]
 icon.set_meta("card_class",icon_class)
 return icon

func cover_art(key: String,dimensions: Vector2) -> Control:
 var frame:=PanelContainer.new()
 frame.custom_minimum_size=dimensions
 frame.add_theme_stylebox_override("panel",UiTheme.panel(Color("102337"),Color("35485d"),0))
 frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
 if key=="" or not Match.CARD_DATA.has(key) or not Match.CARD_DATA[key].artwork:
  var empty:=text_label("+\nCRIE SEU DECK",24)
  empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  empty.modulate=Color("879eb4")
  frame.add_child(empty)
  return frame
 var art:=TextureRect.new()
 art.name="DeckCoverArtwork"
 art.texture=Match.CARD_DATA[key].artwork
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode=TextureRect.STRETCH_SCALE
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var material:=ShaderMaterial.new()
 material.shader=preload("res://scripts/artwork.gdshader")
 material.set_shader_parameter("source_aspect",float(art.texture.get_width())/art.texture.get_height())
 material.set_shader_parameter("view_aspect",dimensions.x/dimensions.y)
 material.set_shader_parameter("artwork_focus",Vector2(0.5,0.30))
 art.material=material
 art.resized.connect(func():material.set_shader_parameter("view_aspect",art.size.x/maxf(1,art.size.y)))
 frame.add_child(art)
 return frame

func render_library(page: VBoxContainer) -> void:
 library_title(page,"MEUS DECKS",return_label,func():closed.emit())
 var intro:=text_label("Selecione um deck; clique novamente para abrir ou use as ações à direita.",17)
 intro.modulate=Color("9eb3c6")
 page.add_child(intro)
 var columns:=HBoxContainer.new()
 columns.size_flags_vertical=Control.SIZE_EXPAND_FILL
 columns.add_theme_constant_override("separation",28)
 page.add_child(columns)
 var scroll:=ScrollContainer.new()
 scroll.name="DeckLibraryScroll"
 scroll.follow_focus=true
 scroll.set_deferred("scroll_vertical",library_scroll_position)
 scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 columns.add_child(scroll)
 var center:=CenterContainer.new()
 center.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 center.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
 scroll.add_child(center)
 var grid:=GridContainer.new()
 grid.name="DeckLibrary"
 grid.columns=5 if get_viewport_rect().size.x>=1800 else 3
 grid.add_theme_constant_override("h_separation",24)
 grid.add_theme_constant_override("v_separation",22)
 center.add_child(grid)
 for i in range(DeckStore.SLOT_COUNT):
  var saved: Dictionary=store.slots[i]
  var tile:=PanelContainer.new()
  tile.name="DeckTile%d" % (i+1)
  tile.custom_minimum_size=Vector2(240,320)
  tile.mouse_filter=Control.MOUSE_FILTER_STOP
  tile.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
  tile.focus_mode=Control.FOCUS_ALL
  tile.gui_input.connect(library_cover_input.bind(i))
  var faction: int=store.base_for(i)
  var border: Color=CardSkin.class_color(faction) if faction>=0 else CardSkin.class_color(CardData.CardClass.NEUTRAL)
  var style:=UiTheme.panel(Color("101e2d"),Color("e4c987") if library_selected==i else border,2)
  style.set_border_width_all(2 if library_selected==i else 1)
  tile.add_theme_stylebox_override("panel",style)
  grid.add_child(tile)
  tile.add_child(cover_art(store.cover_for(i),Vector2(236,316)))
  var overlay:=Control.new()
  overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
  tile.add_child(overlay)
  var gradient:=Gradient.new()
  gradient.set_color(0,Color(0.015,0.025,0.045,0))
  gradient.set_color(1,Color(0.015,0.025,0.045,0.96))
  var texture:=GradientTexture2D.new()
  texture.gradient=gradient
  texture.width=2;texture.height=96
  texture.fill_from=Vector2(0,0);texture.fill_to=Vector2(0,1)
  var fade:=TextureRect.new()
  fade.texture=texture
  fade.position=Vector2(0,216);fade.size=Vector2(236,100)
  fade.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  fade.mouse_filter=Control.MOUSE_FILTER_IGNORE
  overlay.add_child(fade)
  var badge:=text_label("%02d%s" % [i+1," · ATIVO" if store.active==i else ""],12)
  badge.position=Vector2(10,8)
  badge.add_theme_color_override("font_outline_color",Color("07101c"))
  badge.add_theme_constant_override("outline_size",3)
  badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
  overlay.add_child(badge)
  if not saved.cards.is_empty() or store.base_for(i)>=0:
   var symbol:=class_badge(saved.cards,22,store.base_for(i))
   symbol.position=Vector2(204,8)
   overlay.add_child(symbol)
  var name_label:=text_label(saved.name,18)
  name_label.name="DeckName"
  name_label.position=Vector2(10,263);name_label.size=Vector2(216,26)
  name_label.clip_text=true
  name_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
  name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
  overlay.add_child(name_label)
  var description:=text_label(deck_description(saved.cards)+( " · Rascunho" if draft_cache.has(i) else ""),13)
  description.position=Vector2(10,291);description.size=Vector2(216,20)
  description.modulate=Color("a6bbce")
  description.mouse_filter=Control.MOUSE_FILTER_IGNORE
  overlay.add_child(description)
 scroll.call_deferred("ensure_control_visible",grid.get_child(library_selected))
 render_library_actions(columns)
 var note:=text_label(message,15)
 note.modulate=Color("9bb1c5")
 page.add_child(note)

func render_library_actions(parent: HBoxContainer) -> void:
 var saved: Dictionary=store.slots[library_selected]
 var panel:=PanelContainer.new()
 panel.name="LibraryActions"
 panel.custom_minimum_size.x=300
 panel.add_theme_stylebox_override("panel",UiTheme.panel(Color("101e2d"),Color("726346"),20))
 parent.add_child(panel)
 var content:=VBoxContainer.new()
 content.add_theme_constant_override("separation",16)
 panel.add_child(content)
 var caption:=text_label("DECK SELECIONADO",13)
 caption.modulate=Color("9eb1c4")
 content.add_child(caption)
 var title:=text_label(saved.name,27)
 title.name="SelectedDeckName"
 title.custom_minimum_size.x=260
 title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 content.add_child(title)
 var meta:=HBoxContainer.new()
 meta.add_theme_constant_override("separation",10)
 content.add_child(meta)
 if not saved.cards.is_empty() or store.base_for(library_selected)>=0:meta.add_child(class_badge(saved.cards,24,store.base_for(library_selected)))
 meta.add_child(text_label(deck_description(saved.cards),16))
 if library_selected==store.active:
  var active:=text_label("Deck ativo",15)
  active.modulate=Color("cdbc83")
  content.add_child(active)
 var spacer:=Control.new()
 spacer.custom_minimum_size.y=18
 content.add_child(spacer)
 var edit:=action_button("Criar deck" if saved.cards.is_empty() else "Editar cartas",choose_slot.bind(library_selected))
 edit.name="DeckActionEdit"
 edit.custom_minimum_size.y=48
 content.add_child(edit)
 var personalize:=action_button("Capa e nome",open_personalize.bind(library_selected))
 personalize.name="DeckActionPersonalize"
 personalize.custom_minimum_size.y=48
 content.add_child(personalize)
 var play:=action_button("Jogar",play_saved.bind(library_selected),Match.valid_deck(saved.cards) and DeckStore.accepts_base(store.base_for(library_selected),saved.cards))
 play.name="DeckActionPlay"
 play.custom_minimum_size.y=48
 play.tooltip_text="Jogar com a versão salva deste deck"
 UiTheme.primary(play)
 content.add_child(play)
 var hint:=text_label("Comece adicionando cartas a este espaço." if saved.cards.is_empty() else ("Há um rascunho pendente. Jogar usa o deck salvo." if draft_cache.has(library_selected) else "A capa e o nome podem ser alterados sem mudar as cartas."),15)
 hint.custom_minimum_size.x=260
 hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 hint.modulate=Color("8fa8bd")
 content.add_child(hint)

func select_library_deck(index: int) -> void:
 if index<0 or index>=DeckStore.SLOT_COUNT:return
 library_selected=index
 message="Deck selecionado. Use as ações à direita."
 render()
 var tile=find_child("DeckTile%d" % (index+1),true,false)
 if tile:tile.grab_focus()

func library_cover_input(event: InputEvent,index: int) -> void:
 var mouse: bool=event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT
 var keyboard: bool=event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_ENTER,KEY_SPACE]
 if not mouse and not keyboard:return
 get_viewport().set_input_as_handled()
 if (mouse and event.double_click) or (pending_open_slot==index and library_selected==index):
  pending_open_slot=-1
  choose_slot(index)
 else:
  pending_open_slot=index
  select_library_deck(index)

func play_saved(index: int) -> void:
 library_selected=index
 if not store.activate(index):
  message=store.error_message
  render()
  return
 play_requested.emit()

func open_personalize(index: int) -> void:
 library_selected=index
 personal_slot=index
 personal_name=store.slots[index].name
 personal_cover=String(store.slots[index].get("cover",""))
 screen="personalize"
 message="Escolha a arte de uma carta do próprio deck e salve a personalização."
 render()

func choose_cover(key: String) -> void:
 if key!="" and key not in store.slots[personal_slot].cards:return
 personal_cover=key
 render()

func render_personalize(page: VBoxContainer) -> void:
 library_title(page,"CAPA E NOME · DECK %d" % (personal_slot+1),"Meus decks",show_library)
 var columns:=HBoxContainer.new()
 columns.size_flags_vertical=Control.SIZE_EXPAND_FILL
 columns.add_theme_constant_override("separation",28)
 page.add_child(columns)
 var preview:=PanelContainer.new()
 preview.custom_minimum_size.x=370
 preview.add_theme_stylebox_override("panel",UiTheme.panel(Color("101e2d"),Color("8d7954"),16))
 columns.add_child(preview)
 var preview_content:=VBoxContainer.new()
 preview_content.add_theme_constant_override("separation",14)
 preview.add_child(preview_content)
 var chosen: String=personal_cover if personal_cover!="" else DeckStore.automatic_cover(store.slots[personal_slot].cards)
 preview_content.add_child(cover_art(chosen,Vector2(338,430)))
 var preview_name:=text_label(store.clean_name(personal_name,personal_slot),25)
 preview_name.name="CoverPreviewName"
 preview_name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 preview_name.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 preview_content.add_child(preview_name)
 var meta:=text_label(deck_description(store.slots[personal_slot].cards),16)
 meta.autowrap_mode=TextServer.AUTOWRAP_OFF
 meta.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 meta.modulate=Color("9db2c7")
 var preview_meta:=HBoxContainer.new()
 preview_meta.alignment=BoxContainer.ALIGNMENT_CENTER
 if not store.slots[personal_slot].cards.is_empty() or store.base_for(personal_slot)>=0:preview_meta.add_child(class_badge(store.slots[personal_slot].cards,22,store.base_for(personal_slot)))
 preview_meta.add_child(meta)
 preview_content.add_child(preview_meta)
 var fields:=VBoxContainer.new()
 fields.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 fields.add_theme_constant_override("separation",12)
 columns.add_child(fields)
 fields.add_child(text_label("NOME DO DECK",15))
 var input:=LineEdit.new()
 input.name="PersonalizeName"
 input.text=personal_name
 input.max_length=24
 input.custom_minimum_size.y=46
 input.text_changed.connect(func(value: String):personal_name=value;preview_name.text=store.clean_name(value,personal_slot))
 fields.add_child(input)
 fields.add_child(text_label("CAPA · ESCOLHA UMA CARTA DO DECK",15))
 var automatic:=action_button("✓ Capa automática" if personal_cover=="" else "Usar capa automática",choose_cover.bind(""))
 fields.add_child(automatic)
 var scroll:=ScrollContainer.new()
 scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 fields.add_child(scroll)
 var grid:=GridContainer.new()
 grid.name="CoverChoices"
 grid.columns=4
 grid.add_theme_constant_override("h_separation",12)
 grid.add_theme_constant_override("v_separation",12)
 scroll.add_child(grid)
 var seen: Dictionary={}
 for key in store.slots[personal_slot].cards:
  if seen.has(key):continue
  seen[key]=true
  var option:=VBoxContainer.new()
  option.custom_minimum_size.x=158
  grid.add_child(option)
  option.add_child(cover_art(key,Vector2(158,150)))
  var title:=text_label(Match.CARD_DATA[key].title,14)
  title.custom_minimum_size.x=158
  title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  option.add_child(title)
  var button:=action_button("✓ Selecionada" if key==personal_cover else "Escolher",choose_cover.bind(key))
  button.name="CoverChoice_"+String(key)
  if key==personal_cover:UiTheme.primary(button)
  option.add_child(button)
 if seen.is_empty():
  var empty:=text_label("Adicione cartas ao deck para poder escolher uma arte de capa.",18)
  empty.custom_minimum_size.x=540
  empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  grid.add_child(empty)
 var footer:=HBoxContainer.new()
 page.add_child(footer)
 var note:=text_label(message,16)
 note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 note.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 footer.add_child(note)
 var save:=action_button("Salvar capa e nome",save_personalization)
 UiTheme.primary(save)
 footer.add_child(save)

func save_personalization() -> bool:
 if not store.save_metadata(personal_slot,personal_name,personal_cover):
  message=store.error_message
  render()
  return false
 if draft_cache.has(personal_slot):draft_cache[personal_slot].name=store.slots[personal_slot].name
 screen="library"
 message="Capa e nome salvos."
 render()
 return true

