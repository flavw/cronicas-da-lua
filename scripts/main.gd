extends Control

@export var enable_opening := true
@export_range(-1,1) var starting_player := -1
const MulliganView = preload("res://scripts/mulligan_view.gd")
var mulligan_layer: CanvasLayer
var mulligan_view: Control

const ArtViewer = preload("res://scripts/art_viewer.gd")
var preview_ticket := 0
var pending_preview_owner: Control
const Match = preload("res://scripts/match.gd")
const DeckStoreScript = preload("res://scripts/deck_store.gd")
const DeckEditorScene = preload("res://deck_editor.tscn")
var enemy_deck_style := 1
var combat_menu_layer: CanvasLayer
var deck_store = DeckStoreScript.new()
var duel = Match.new(deck_store.active_cards(), Match.default_deck(enemy_deck_style))
var deck_editor: Control
var deck_editor_layer: CanvasLayer
var summoning := -1
var needs_deck_fix := false
var casting := -1
var selected := -1
var magic := false
var healing := false
var busy := false
var root: VBoxContainer
const CardScene = preload("res://card_model.tscn")
const FieldScene = preload("res://field_card.tscn")
const CardVfxSkin = preload("res://scripts/card_skin.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")
const GameDisplaySettings=preload("res://scripts/game_display.gd")
const ResultScene = preload("res://result_overlay.tscn")
var preview: Control
var preview_owner: Control
var field_nodes: Array = [{}, {}]
var input_shield: Control
var sounds: Dictionary = {}
const Music=preload("res://scripts/game_music.gd")
var music: Node
const StatusVfx=preload("res://scripts/status_vfx.gd")
var block_feedback_until: int=0
var vfx_layer: CanvasLayer
var muted := false
var result_shown := false
var result_layer: CanvasLayer
var result_overlay: Control
var sound_counts: Dictionary = {}
var rules_dialog: AcceptDialog

func _input(event: InputEvent) -> void:
 if ArtViewer.is_open(self):
  return
 if not event is InputEventKey or not event.pressed or event.echo:
  return
 if event.ctrl_pressed or event.alt_pressed or event.meta_pressed or event.shift_pressed:
  return
 if event.keycode==KEY_ESCAPE:
  if is_instance_valid(rules_dialog) and rules_dialog.visible:
   rules_dialog.hide()
  elif is_instance_valid(deck_editor):return
  elif is_instance_valid(combat_menu_layer):close_combat_menu()
  else:open_combat_menu()
  get_viewport().set_input_as_handled()
  return
 var turn_key: bool = event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_KP_0] or event.physical_keycode == KEY_KP_0
 if not turn_key or not can_act():
  return
 if is_instance_valid(rules_dialog) and rules_dialog.visible:
  return
 var focus := get_viewport().gui_get_focus_owner()
 if focus is LineEdit or focus is TextEdit:
  return
 get_viewport().set_input_as_handled()
 end_turn()

func play_sound(kind: String) -> void:
 if sounds.has(kind) and not muted:
  sound_counts[kind] = int(sound_counts.get(kind, 0)) + 1
  sounds[kind].play()

func toggle_sound() -> void:
 muted = not muted
 music.set_muted(muted)
 for player in sounds.values():
  player.volume_db = -80 if muted else -10
 redraw()

func set_busy(value: bool) -> void:
 busy = value
 input_shield.visible = value
 if value:
  hide_preview()
  get_viewport().gui_release_focus()

func _ready() -> void:
 music=Music.ensure(get_tree())
 muted=muted or music.muted
 music.set_muted(muted)
 var background := Control.new()
 background.set_script(preload("res://scripts/board.gd"))
 background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(background)
 theme = UiTheme.build()
 var overlay := CanvasLayer.new()
 overlay.layer = 20
 add_child(overlay)
 preview = CardScene.instantiate()
 preview.custom_minimum_size = Vector2.ZERO
 preview.size = Vector2(360, 480)
 preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
 preview.hide()
 overlay.add_child(preview)
 var lock_layer := CanvasLayer.new()
 lock_layer.layer = 12
 add_child(lock_layer)
 vfx_layer = CanvasLayer.new()
 vfx_layer.layer = 11
 add_child(vfx_layer)
 input_shield = Control.new()
 input_shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 input_shield.mouse_filter = Control.MOUSE_FILTER_STOP
 input_shield.hide()
 lock_layer.add_child(input_shield)
 for kind in ["summon","attack","death","magic","victory","castle","block","heal","poison_apply","poison_tick"]:
  var player := AudioStreamPlayer.new()
  player.stream = load("res://assets/audio/%s.ogg" % kind)
  player.volume_db = -10
  player.max_polyphony = 6
  add_child(player)
  sounds[kind] = player
 if enable_opening:
  duel = Match.new(deck_store.active_cards(),Match.default_deck(enemy_deck_style),randi_range(0,1) if starting_player<0 else starting_player,true)
 redraw()
 if not Match.valid_deck(deck_store.active_cards()):
  needs_deck_fix=true
  open_decks()
 elif duel.opening:show_mulligan()

func label_text(value: String, size: int = 18) -> Label:
 var l := Label.new()
 l.text = value
 l.add_theme_font_size_override("font_size", size)
 l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 return l

func button(value: String, callback: Callable, enabled: bool = true) -> Button:
 var b := Button.new()
 b.text = value
 b.disabled = not enabled
 b.custom_minimum_size.y = 38
 b.pressed.connect(callback)
 return b

func ability_button(symbol: String, value: String, callback: Callable, enabled: bool = true) -> Button:
 var control := button("", callback, enabled)
 control.name="Ability_"+symbol
 control.tooltip_text=value
 var font: Font=get_theme_font("font","Button")
 control.custom_minimum_size=Vector2(font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x+64,44)
 var content:=HBoxContainer.new()
 content.name="AbilityContents"
 content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 content.offset_left=12;content.offset_right=-12;content.offset_top=6;content.offset_bottom=-6
 content.add_theme_constant_override("separation",8)
 content.mouse_filter=Control.MOUSE_FILTER_IGNORE
 control.add_child(content)
 var icon:=TextureRect.new()
 icon.name="AbilitySymbol"
 icon.texture=CardVfxSkin.texture(symbol)
 icon.custom_minimum_size=Vector2(32,32)
 icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
 content.add_child(icon)
 var caption:=Label.new()
 caption.text=value
 caption.add_theme_font_size_override("font_size",18)
 caption.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
 content.add_child(caption)
 if not enabled:content.modulate=Color(0.55,0.6,0.65)
 return control

func redraw() -> void:
 duel.refresh_auras()
 hide_preview()
 field_nodes = [{}, {}]
 if is_instance_valid(root):
  remove_child(root)
  root.queue_free()
 root = VBoxContainer.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.offset_left = 28
 root.offset_right = -28
 root.offset_top = 16
 root.offset_bottom = -16
 root.add_theme_constant_override("separation", 6)
 add_child(root)
 var header:=Control.new()
 header.name="EnemyCitadel"
 header.custom_minimum_size.y=112
 root.add_child(header)
 var center:=CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 center.mouse_filter=Control.MOUSE_FILTER_IGNORE
 header.add_child(center)
 var enemy_identity:=VBoxContainer.new()
 enemy_identity.alignment=BoxContainer.ALIGNMENT_CENTER
 enemy_identity.add_theme_constant_override("separation",3)
 center.add_child(enemy_identity)
 var enemy_name:=label_text(opponent_label(),22)
 enemy_name.name="EnemyDeckName"
 enemy_name.modulate=Color("e5c7d5")
 header.add_child(enemy_name)
 enemy_name.position=Vector2(4,5)
 var enemy_counts:=label_text("Mão %d · Baralho %d" % [duel.players[1].hand.size(),duel.players[1].deck.size()],14)
 enemy_counts.name="EnemyCardCounts"
 enemy_counts.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
 enemy_counts.modulate=Color("a6b8ca")
 header.add_child(enemy_counts)
 enemy_counts.position=Vector2(4,36)
 add_hero(1,enemy_identity)
 var settings:=button("",open_combat_menu)
 settings.name="CombatSettings"
 settings.icon=CardVfxSkin.texture("settings-icon")
 settings.expand_icon=true
 settings.add_theme_constant_override("icon_max_width",24)
 settings.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
 settings.offset_left=-36;settings.offset_right=0;settings.offset_top=0;settings.offset_bottom=36
 settings.tooltip_text="Menu do combate · Esc"
 header.add_child(settings)
 add_board(1)
 var status := "Sua vez — invoque uma carta ou selecione uma criatura pronta."
 if duel.turn == 1:
  status = "A IA está pensando…"
 if casting >= 0:
  status = "Conjurar %s — escolha um alvo permitido." % Match.CARD_DATA[duel.players[0].hand[casting]].title
  if Match.CARD_DATA[duel.players[0].hand[casting]].spell_effect==CardData.SpellEffect.RECONSTRUCT:
   status="Reconstrução — escolha seu castelo ou uma Muralha aliada para restaurar 2 de vida."
 if summoning>=0:
  status=Match.CARD_DATA[duel.players[0].hand[summoning]].entry_prompt()
 if selected >= 0:
  status = "Escolha uma criatura inimiga para magia." if magic else "Escolha uma criatura inimiga ou o castelo da IA para atacar."
  if healing:
   status = "Cure um aliado ou seu castelo; em Mortos-vivos, Cura causa dano mágico."
  if not healing and not magic and not duel.players[0].board[selected].get("flying", false) and not duel.blockers(1).is_empty():
   status = "Bloqueio ativo: ataque uma criatura com cargas."
 if duel.winner != -1:
  status = ["Vitória!", "A IA venceu.", "Empate."][duel.winner]
 var status_panel := PanelContainer.new()
 status_panel.add_theme_stylebox_override("panel", UiTheme.panel(Color("101f2c"), Color("577686") if duel.turn == 0 else Color("6a5278"), 5))
 var command_bar:=HBoxContainer.new()
 command_bar.name="BattleCommands"
 command_bar.add_theme_constant_override("separation",12)
 root.add_child(command_bar)
 status_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 command_bar.add_child(status_panel)
 var status_text := label_text(status, 16)
 status_text.custom_minimum_size.x=240
 status_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 status_text.modulate = Color("aad7ec") if duel.turn == 0 else Color("cbb9dd")
 status_panel.add_child(status_text)
 var actions := HBoxContainer.new()
 actions.alignment = BoxContainer.ALIGNMENT_CENTER
 actions.name="BattleActions"
 command_bar.add_child(actions)
 var all_attack:=button("Atacar com todos",attack_all,can_act() and can_attack_all())
 all_attack.name="AttackAll"
 all_attack.tooltip_text="Ataques físicos na ordem do campo. Prioriza o castelo; respeita Bloqueio e Voo. Não usa habilidades nem mana."
 actions.add_child(all_attack)
 var has_selection: bool = selected >= 0 and selected < duel.players[0].board.size()
 if has_selection and not duel.players[0].board[selected].get("wall",false) and Match.physical_attack(duel.players[0].board[selected]) > 0:
  actions.add_child(button("Ataque físico", func(): magic = false; healing = false; redraw(), can_act() and duel.players[0].board[selected].ready))
 var spell: Dictionary = duel.players[0].board[selected] if has_selection else {}
 var spell_damage: int = spell.get("magic_damage", 0)
 if spell_damage > 0:
  spell_damage += duel.magic_bonus(0)
 var spell_cost: int = spell.get("magic_cost", 1)
 if spell_damage > 0:
  actions.add_child(ability_button("arcane-icon", "Disparo Arcano %d • %d mana + esgotar" % [spell_damage, spell_cost], func(): magic = true; healing = false; redraw(), can_act() and spell.get("ready", false) and duel.players[0].mana >= spell_cost and not duel.players[1].board.is_empty()))
 if spell.get("heal_amount", 0) > 0:
  actions.add_child(ability_button("heal-icon", "Cura %d • %d mana + esgotar" % [spell.heal_amount, spell.heal_cost], select_heal, can_act() and spell.get("ready", false) and duel.players[0].mana >= spell.heal_cost and context_for(spell,0).heal_target))
 var fury_selected: bool = has_selection and duel.players[0].board[selected].get("fury", 0) > 0
 if fury_selected:
  actions.add_child(ability_button("fury-icon", "Fúria +1 • 1 mana", use_fury, can_act() and duel.players[0].mana >= 1))
 if has_selection or casting >= 0 or summoning>=0:
  actions.add_child(button("Cancelar", func(): selected = -1; casting = -1; summoning = -1; magic = false; healing = false; redraw()))
 var pass_turn := button("Encerrar turno →", end_turn, can_act())
 pass_turn.name="EndTurn"
 pass_turn.tooltip_text = "Encerrar turno: Enter ou 0 do teclado numérico"
 UiTheme.primary(pass_turn)
 var remaining:=remaining_actions()
 pass_turn.set_meta("actions_remaining",not remaining.is_empty())
 if not remaining.is_empty():
  pass_turn.add_theme_stylebox_override("normal",UiTheme.panel(Color("5b4518"),Color("e3bb59"),8))
  pass_turn.add_theme_stylebox_override("hover",UiTheme.panel(Color("7a5b20"),Color("ffe193"),8))
  pass_turn.add_theme_color_override("font_color",Color("ffe49b"))
  pass_turn.tooltip_text="Ainda pode: %s.\nEnter ou 0 do teclado numérico para encerrar." % ", ".join(remaining)
 actions.add_child(pass_turn)
 add_board(0)
 var p: Dictionary = duel.players[0]
 var footer:=HBoxContainer.new()
 footer.name="BattleFooter"
 footer.add_theme_constant_override("separation",12)
 root.add_child(footer)
 var life_panel:=PanelContainer.new()
 life_panel.name="CastleVitals"
 life_panel.custom_minimum_size.x=312
 life_panel.add_theme_stylebox_override("panel",UiTheme.panel(Color("0c1724"),Color("455568"),8))
 footer.add_child(life_panel)
 var life_column:=VBoxContainer.new()
 life_column.alignment=BoxContainer.ALIGNMENT_CENTER
 life_panel.add_child(life_column)
 var life_caption:=label_text("SEU CASTELO",15)
 life_caption.modulate=Color("95aabd")
 life_column.add_child(life_caption)
 add_hero(0,life_column)
 var hand_panel := PanelContainer.new()
 hand_panel.add_theme_stylebox_override("panel", UiTheme.panel(Color(0.04, 0.08, 0.13, 0.93), Color("74633f"), 8))
 hand_panel.name="PlayerHandPanel"
 hand_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 footer.add_child(hand_panel)
 var hand_content := VBoxContainer.new()
 hand_panel.add_child(hand_content)
 var hand_caption := label_text("SUA MÃO · %d CARTAS     |     BARALHO · %d" % [p.hand.size(),p.deck.size()], 14)
 hand_caption.name="PlayerCardCounts"
 hand_caption.modulate = Color("aab9c7")
 hand_content.add_child(hand_caption)
 var hand := HBoxContainer.new()
 hand.alignment = BoxContainer.ALIGNMENT_CENTER
 hand.custom_minimum_size.y = 182
 hand.add_theme_constant_override("separation",4)
 hand_content.add_child(hand)
 if p.hand.is_empty():
  var empty_hand := label_text("Seu próximo turno traz uma nova carta.", 17)
  empty_hand.modulate = Color("8393a5")
  hand.add_child(empty_hand)
 for i in range(p.hand.size()):
  var key: String = p.hand[i]
  var box := VBoxContainer.new()
  hand.add_child(box)
  var art = CardScene.instantiate()
  art.set_card(Match.CARD_DATA[key])
  art.set_meta("preview_managed", true)
  art.ability_context = context_for(Match.CARDS[key],0,false)
  art.ability_context["castable"] = duel.has_spell_target(0,i)
  art.set_meta("ability_context",art.ability_context)
  art.custom_minimum_size = Vector2(144, 192)
  art.name="HandCard_%d" % i
  art.mouse_filter = Control.MOUSE_FILTER_STOP
  art.gui_input.connect(hand_card_input.bind(i))
  var playable: bool=hand_card_can_play(i)
  art.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND if playable else Control.CURSOR_ARROW
  art.modulate=Color.WHITE if playable else Color(0.58,0.62,0.7)
  art.mouse_entered.connect(request_preview.bind(Match.CARD_DATA[key], -1, art))
  art.mouse_exited.connect(close_preview.bind(art))
  box.add_child(art)
  var hand_frame: StyleBoxFlat=art.get_node("CardCanvas/Frame").get_theme_stylebox("panel").duplicate()
  if playable:
   hand_frame.shadow_color=Color(0.5,0.8,0.9,0.36)
   hand_frame.shadow_size=5
  if casting==i or summoning==i:
   hand_frame.border_color=Color("ffe09b")
   hand_frame.set_border_width_all(3)
  art.get_node("CardCanvas/Frame").add_theme_stylebox_override("panel",hand_frame)
 var mana_panel:=PanelContainer.new()
 mana_panel.name="ManaReserves"
 mana_panel.custom_minimum_size.x=208
 mana_panel.add_theme_stylebox_override("panel",UiTheme.panel(Color("0c1724"),Color("455568"),8))
 footer.add_child(mana_panel)
 var mana_column:=VBoxContainer.new()
 mana_column.alignment=BoxContainer.ALIGNMENT_CENTER
 mana_column.add_theme_constant_override("separation",14)
 mana_panel.add_child(mana_column)
 var mana_caption:=label_text("RESERVA DE MANA",12)
 mana_caption.modulate=Color("95aabd")
 mana_column.add_child(mana_caption)
 add_mana(1,mana_column)
 add_mana(0,mana_column)
 var log_label := label_text(duel.history[-1] if not duel.history.is_empty() else "", 12)
 log_label.name="BattleHistory"
 log_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 log_label.modulate = Color("a8b8c8")
 root.add_child(log_label)
 finish_if_needed()

func opponent_label() -> String:
 var faction: int=Match.deck_class(Match.default_deck(enemy_deck_style))
 var names: Dictionary={-1:"Neutros",0:"Guerreiro",1:"Mago",3:"Ladina",4:"Clérigo",5:"Horda"}
 return "IA — "+String(names.get(faction,"Neutros"))

func has_allied_wall() -> bool:
 return duel.players[0].board.any(func(unit):return unit.health>0 and unit.get("wall",false))

func hand_card_can_play(index: int) -> bool:
 if not can_act() or index<0 or index>=duel.players[0].hand.size():return false
 var card: CardData=Match.CARD_DATA[duel.players[0].hand[index]]
 if card.card_type==CardData.CardType.SPELL:return duel.has_spell_target(0,index)
 var owner: int=Match.entry_target_side(0,card.combat_data())
 if owner>=0 and not duel.players[owner].board.is_empty():
  for target_index in range(duel.players[owner].board.size()):
   if duel.can_play(0,index,target_index):return true
  return false
 return duel.can_play(0,index)

func hand_card_input(event: InputEvent,index: int) -> void:
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and hand_card_can_play(index):
  get_viewport().set_input_as_handled()
  play(index)

func remaining_actions() -> PackedStringArray:
 var found:=PackedStringArray()
 if not can_act():return found
 for index in range(duel.players[0].hand.size()):
  if hand_card_can_play(index):
   found.append("jogar cartas")
   break
 for index in range(duel.players[0].board.size()):
  var unit: Dictionary=duel.players[0].board[index]
  for target_index in range(-1,duel.players[1].board.size()):
   if duel.can_target(0,index,target_index,false) and not "atacar" in found:found.append("atacar")
   if duel.can_target(0,index,target_index,true) and not "usar habilidades" in found:found.append("usar habilidades")
   if duel.can_heal(0,index,target_index,1) and not "usar habilidades" in found:found.append("usar habilidades")
  for target_index in range(-1,duel.players[0].board.size()):
   if duel.can_heal(0,index,target_index) and not "usar habilidades" in found:found.append("usar habilidades")
  if unit.get("fury",0)>0 and duel.players[0].mana>=1 and not "usar habilidades" in found:found.append("usar habilidades")
 return found

func open_combat_menu() -> void:
 if is_instance_valid(combat_menu_layer) or is_instance_valid(deck_editor) or ArtViewer.is_open(self):return
 hide_preview()
 get_viewport().gui_release_focus()
 combat_menu_layer=CanvasLayer.new()
 combat_menu_layer.name="CombatMenuLayer"
 combat_menu_layer.layer=60
 add_child(combat_menu_layer)
 var surface:=Control.new()
 surface.theme=theme
 surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 combat_menu_layer.add_child(surface)
 var shade:=ColorRect.new()
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.color=Color(0.02,0.035,0.06,0.86)
 shade.gui_input.connect(func(event):
  if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:close_combat_menu())
 surface.add_child(shade)
 var center:=CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 center.mouse_filter=Control.MOUSE_FILTER_IGNORE
 surface.add_child(center)
 var panel:=PanelContainer.new()
 panel.custom_minimum_size.x=340
 panel.add_theme_stylebox_override("panel",UiTheme.panel(Color("101e2d"),Color("7c8d9e"),20))
 center.add_child(panel)
 var content:=VBoxContainer.new()
 content.add_theme_constant_override("separation",10)
 panel.add_child(content)
 content.add_child(label_text("MENU",23))
 var resume:=button("Continuar · Esc",close_combat_menu)
 resume.name="ResumeCombat"
 content.add_child(resume)
 var display_mode:=button("Modo janela · F11" if GameDisplaySettings.is_fullscreen(get_window()) else "Tela cheia · F11",func():GameDisplaySettings.toggle(get_window()))
 display_mode.add_to_group("display_mode_buttons")
 display_mode.pressed.connect(func():display_mode.text="Modo janela · F11" if GameDisplaySettings.is_fullscreen(get_window()) else "Tela cheia · F11")
 content.add_child(display_mode)
 content.add_child(button("Início",combat_menu_action.bind("start"),not busy))
 content.add_child(button("Nova partida",combat_menu_action.bind("restart"),not busy))
 content.add_child(button("Meus decks",combat_menu_action.bind("decks"),not busy))
 content.add_child(button("Regras",combat_menu_action.bind("rules")))
 var sound:=button("Som: desligado" if muted else "Som: ligado",toggle_sound,not busy)
 sound.pressed.connect(func():sound.text="Som: desligado" if muted else "Som: ligado")
 content.add_child(sound)
 resume.grab_focus()

func close_combat_menu() -> void:
 if is_instance_valid(combat_menu_layer):
  remove_child(combat_menu_layer)
  combat_menu_layer.queue_free()
 combat_menu_layer=null
 if not busy:redraw()

func combat_menu_action(action: String) -> void:
 close_combat_menu()
 match action:
  "start":get_tree().change_scene_to_file("res://start_menu.tscn")
  "restart":restart()
  "decks":open_decks()
  "rules":show_rules()

func can_act() -> bool:
 return Match.valid_deck(deck_store.active_cards()) and not duel.opening and duel.turn == 0 and duel.winner == -1 and not busy and not is_instance_valid(deck_editor) and not ArtViewer.is_open(self) and not is_instance_valid(combat_menu_layer)

func add_board(side: int) -> void:
 var row := HBoxContainer.new()
 row.alignment = BoxContainer.ALIGNMENT_CENTER
 row.name="EnemyBattlefield" if side==1 else "PlayerBattlefield"
 row.custom_minimum_size.y = 252
 row.size_flags_vertical=Control.SIZE_EXPAND_FILL
 row.add_theme_constant_override("separation", 10)
 root.add_child(row)
 var board: Array = duel.players[side].board
 for i in range(Match.MAX_BOARD):
  var slot := PanelContainer.new()
  slot.custom_minimum_size = Vector2(240, 252)
  slot.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var style := StyleBoxFlat.new()
  style.bg_color = Color("142638") if side == 0 else Color("282334")
  style.bg_color.a = 0.65
  style.set_border_width_all(2)
  style.border_color = Color("ecd599") if side == 0 and selected == i else Color("4a5360")
  style.set_corner_radius_all(12)
  style.content_margin_top = 6
  style.content_margin_bottom = 6
  style.content_margin_left = 6
  style.content_margin_right = 6
  slot.add_theme_stylebox_override("panel", style)
  row.add_child(slot)
  if i >= board.size():
   var empty := label_text("◇", 38)
   empty.modulate = Color(0.42, 0.48, 0.54, 0.5)
   slot.add_child(empty)
   continue
  var u: Dictionary = board[i]
  var art = FieldScene.instantiate()
  art.custom_minimum_size = Vector2(224, 224)
  var selectable: bool = u.ready or (u.get("fury", 0) > 0 and duel.players[0].mana >= 1)
  var enabled: bool = duel.can_heal(0,selected,i,side) if healing else (duel.can_target(0, selected, i, magic) if side == 1 else selectable)
  if casting >= 0:
   enabled = duel.can_cast(0,casting,side,i)
  if summoning>=0:
   enabled=side==Match.entry_target_side(0,Match.CARDS[duel.players[0].hand[summoning]]) and duel.can_play(0,summoning,i)
  art.set_card(duel.card_for_unit(u), u.health, can_act() and enabled, (enabled if summoning>=0 else (duel.can_cast(0,casting,side,i) if casting>=0 else side == 0 and selected == i)), Match.attack_value(u), u.get("block", 0), not u.ready, u.armor)
  art.set_meta("max_health",u.get("max_health",Match.CARD_DATA[u.key].health))
  art.set_meta("ability_context",context_for(u,side))
  art.set_meta("vigor",u.get("vigor",false))
  art.set_meta("poison",u.get("poison",0))
  art.set_meta("abascanto",u.get("abascanto",0))
  slot.add_child(art)
  field_nodes[side][u.get("id", -1)] = art
  art.activated.connect(summon_target.bind(side,i) if summoning>=0 else (cast_target.bind(side,i) if casting >= 0 else (heal_target.bind(i,side) if healing else (target.bind(i) if side == 1 else select.bind(i)))))
  if side==1:art.activation_rejected.connect(notify_blocked_attack.bind(i))
  art.inspect_requested.connect(request_preview)
  art.inspect_closed.connect(close_preview)

func request_preview(data: CardData, health: int, owner: Control) -> void:
 hide_preview()
 pending_preview_owner = owner
 var ticket := preview_ticket
 await get_tree().create_timer(0.25).timeout
 if ticket != preview_ticket or not is_instance_valid(owner) or pending_preview_owner != owner:
  return
 var hovered := get_viewport().gui_get_hovered_control()
 if ArtViewer.is_open(self) or not owner.is_visible_in_tree():
  return
 if hovered != owner and (not is_instance_valid(hovered) or not owner.is_ancestor_of(hovered)):
  return
 pending_preview_owner = null
 show_preview(data,health,owner)

func context_for(unit: Dictionary, side: int, on_board: bool = true) -> Dictionary:
 var heal_target: bool = duel.players[side].hp<20
 for ally in duel.players[side].board:
  heal_target = heal_target or Match.is_undead(ally) or (not ally.get("wall",false) and (ally.health < ally.get("max_health",ally.health) or ally.get("poison",0)>0))
 for enemy in duel.players[1-side].board:heal_target=heal_target or Match.is_undead(enemy)
 return {"side":side,"on_board":on_board,"turn":duel.turn,"ready":unit.get("ready",false),"mana":duel.players[side].mana,"busy":busy,"winner":duel.winner,"max_health":unit.get("max_health",unit.get("health",1)),"magic_target":not duel.players[1-side].board.is_empty(),"heal_target":heal_target,"magic_bonus":duel.magic_bonus(side),"armor":unit.get("armor",0),"vigor":unit.get("vigor",false),"poison":unit.get("poison",0),"aura_attack":unit.get("aura_attack",0),"turn_attack":unit.get("turn_attack",0),"abascanto":unit.get("abascanto",0)}

func show_preview(data: CardData, health: int, owner: Control) -> void:
 if busy or is_instance_valid(deck_editor) or not is_instance_valid(preview):
  return
 preview_owner = owner
 preview.ability_context = owner.get_meta("ability_context",{})
 preview.set_card(data, health, owner.get_meta("attack", -1), owner.get_meta("block", -1))
 preview.tooltip_text = ""
 var bounds := owner.get_global_rect()
 var viewport := get_viewport_rect().size
 var x := bounds.end.x + 16
 if x + preview.size.x > viewport.x - 16:
  x = bounds.position.x - preview.size.x - 16
 preview.position = Vector2(clampf(x, 16, viewport.x - preview.size.x - 16), clampf(bounds.position.y - 110, 16, viewport.y - preview.size.y - 16))
 preview.show()
 preview.set_hint_forced(true,true)

func close_preview(owner: Control) -> void:
 if pending_preview_owner == owner:
  preview_ticket += 1
  pending_preview_owner = null
 if preview_owner == owner:
  hide_preview()

func hide_preview() -> void:
 preview_ticket += 1
 pending_preview_owner = null
 preview_owner = null
 if is_instance_valid(preview):
  preview.set_hint_forced(false)
  preview.hide()

func add_hero(side: int, parent: Node = null) -> void:
 var p: Dictionary = duel.players[side]
 var row := HBoxContainer.new()
 row.alignment = BoxContainer.ALIGNMENT_CENTER
 row.add_theme_constant_override("separation", 6)
 (root if parent==null else parent).add_child(row)
 var castle := Button.new()
 castle.name = "EnemyCastle" if side == 1 else "PlayerCastle"
 var castle_texture: Texture2D=preload("res://assets/art/castle_enemy.png") if side==1 else preload("res://assets/art/castle_player.png")
 castle.custom_minimum_size = Vector2(288,104)
 castle.text=""
 castle.add_theme_font_size_override("font_size",36)
 castle.add_theme_color_override("font_disabled_color",Color("f28e82") if p.hp<=5 else Color("fff1d5"))
 castle.add_theme_color_override("font_color",Color("f28e82") if p.hp<=5 else Color("fff1d5"))
 for state in ["normal","hover","pressed","focus","disabled"]:castle.add_theme_color_override("icon_"+state+"_color",Color.WHITE)
 var castle_bg: Color=Color("38202c") if side==1 else Color("152d47")
 var castle_edge: Color=Color("c76d79") if side==1 else Color("70b7e7")
 castle.add_theme_stylebox_override("normal",UiTheme.panel(castle_bg,castle_edge,6))
 castle.add_theme_stylebox_override("disabled",UiTheme.panel(castle_bg,castle_edge.darkened(0.3),6))
 castle.tooltip_text = "Ataque direto ao castelo da IA" if side == 1 else ("Curar seu castelo" if healing else "Seu castelo")
 var castle_allowed: bool = (healing and duel.can_heal(0, selected, -1)) if side == 0 else (not healing and duel.can_target(0, selected, -1, magic))
 if casting >= 0:
  castle_allowed = duel.can_cast(0,casting,side,-1)
  castle.tooltip_text = "Alvo permitido para a magia" if castle_allowed else "Esta magia não pode atingir este castelo"
 if summoning>=0:castle_allowed=false
 castle.disabled = not can_act() or not castle_allowed
 castle.pressed.connect(cast_target.bind(side,-1) if casting >= 0 else (heal_target.bind(-1) if side == 0 else target.bind(-1)))
 row.add_child(castle)
 var art:=TextureRect.new()
 art.name="CastleArtwork"
 art.texture=castle_texture
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
 art.clip_contents=true
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 art.offset_left=6;art.offset_right=-66;art.offset_top=6;art.offset_bottom=-6
 castle.add_child(art)
 var life:=label_text(str(p.hp),36)
 life.name="CastleLife"
 life.mouse_filter=Control.MOUSE_FILTER_IGNORE
 life.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 life.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 life.anchor_left=1.0
 life.offset_left=-64;life.offset_right=-4
 life.add_theme_color_override("font_color",Color("f28e82") if p.hp<=5 else Color("fff1d5"))
 castle.add_child(life)
 if side==1 and can_act() and not magic and not healing and casting<0 and summoning<0 and not duel.attack_blockers(0,selected,-1).is_empty():
  var blocked:=Control.new()
  blocked.name="BlockedCastleTarget"
  blocked.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  blocked.tooltip_text="Bloqueio: ataque uma criatura com cargas."
  blocked.gui_input.connect(blocked_castle_input)
  castle.add_child(blocked)

func add_mana(side: int, parent: Node = null) -> void:
 var p: Dictionary = duel.players[side]
 var box:=VBoxContainer.new()
 box.name="EnemyMana" if side==1 else "PlayerMana"
 box.add_theme_constant_override("separation",3)
 (root if parent == null else parent).add_child(box)
 var heading:=HBoxContainer.new()
 box.add_child(heading)
 var side_label:=label_text("IA" if side==1 else "VOCÊ",13)
 side_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 side_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
 side_label.modulate=Color("dba9bd") if side==1 else Color("9bdcff")
 heading.add_child(side_label)
 var temporary: int=int(p.get("temporary_mana",0))
 var base_mana: int=maxi(0,int(p.mana)-temporary)
 var counter:=label_text("%d / %d" % [base_mana,p.max_mana],24)
 counter.name="ManaCounter"
 counter.modulate=Color("c5eaff")
 heading.add_child(counter)
 if temporary>0:
  var bonus:=label_text("+%d" % temporary,22)
  bonus.name="TemporaryMana"
  bonus.modulate=Color("86f5bd")
  bonus.tooltip_text="Mana temporária: é usada antes da mana normal e desaparece ao fim do turno."
  heading.add_child(bonus)
 var gems:=HBoxContainer.new()
 gems.add_theme_constant_override("separation",3)
 gems.alignment=BoxContainer.ALIGNMENT_CENTER
 box.add_child(gems)
 for i in range(10):
  var gem := TextureRect.new()
  gem.texture = CardVfxSkin.texture("mana-gem")
  gem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  gem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  gem.custom_minimum_size = Vector2(16,16)
  gem.modulate = Color("86f5bd") if i >= base_mana and i < p.mana else (Color.WHITE if i < base_mana else (Color(0.37,0.42,0.52) if i < p.max_mana else Color(0.18,0.22,0.28)))
  gem.tooltip_text = "Mana temporária" if i >= base_mana and i < p.mana else ("Disponível" if i < base_mana else ("Gasta neste turno" if i < p.max_mana else "Ainda bloqueada"))
  gems.add_child(gem)

func select(index: int) -> void:
 if not can_act():
  return
 selected = index
 casting = -1
 summoning = -1
 healing = false
 magic = Match.physical_attack(duel.players[0].board[index]) == 0 and duel.players[0].board[index].get("magic_damage", 0) > 0
 redraw()

func play(index: int) -> void:
 if not can_act() or index < 0 or index >= duel.players[0].hand.size():
  return
 summoning=-1
 var data: CardData=Match.CARD_DATA[duel.players[0].hand[index]]
 var owner: int=Match.entry_target_side(0,data.combat_data())
 if data.entry_needs_target() and owner>=0 and not duel.players[owner].board.is_empty():
  if not duel.can_play(0,index,0):return
  summoning=index
  casting=-1
  selected=-1
  healing=false
  magic=false
  redraw()
  return
 if Match.CARD_DATA[duel.players[0].hand[index]].card_type == CardData.CardType.SPELL:
  if not duel.has_spell_target(0,index):
   return
  if data.spell_effect in [CardData.SpellEffect.AREA_ARCANE,CardData.SpellEffect.HORDE_ROAR] or (data.spell_effect==CardData.SpellEffect.RECONSTRUCT and not has_allied_wall()):
   casting=index
   await cast_target(1 if data.spell_effect==CardData.SpellEffect.AREA_ARCANE else 0,-1)
   return
  summoning=-1
  casting = index
  selected = -1
  healing = false
  magic = false
  redraw()
  return
 if not duel.play(0, index):
  return
 play_sound("summon")
 casting = -1
 summoning = -1
 selected = -1
 healing = false
 magic = false
 redraw()
 animate_records(duel.last_action.get("poisoned",[]),field_nodes,"poison_apply","poison_apply")

func target(index: int) -> void:
 if can_act() and selected >= 0 and not healing:
  var snapshot := field_nodes.duplicate()
  if not duel.act(0, selected, index, magic):
   notify_blocked_attack(index)
   return
  set_busy(true)
  selected = -1
  magic = false
  await animate_action(duel.last_action, snapshot)
  set_busy(false)
  redraw()

func can_attack_all() -> bool:
 for index in range(duel.players[0].board.size()):
  if duel.preferred_attack_target(0,index)!=-2:return true
 return false

func attack_all() -> void:
 if not can_act() or not can_attack_all():return
 var attackers: Array=[]
 for unit in duel.players[0].board:attackers.append(unit.id)
 selected=-1;casting=-1;summoning=-1;magic=false;healing=false
 set_busy(true)
 for id in attackers:
  if duel.winner!=-1 or duel.turn!=0:break
  var index: int=-1
  for current in range(duel.players[0].board.size()):
   if duel.players[0].board[current].id==id:index=current;break
  if index<0:continue
  var destination: int=duel.preferred_attack_target(0,index)
  if destination==-2:continue
  var snapshot: Array=field_nodes.duplicate()
  if not duel.act(0,index,destination,false):continue
  await animate_action(duel.last_action,snapshot)
  redraw()
  await get_tree().process_frame
  await get_tree().process_frame
 set_busy(false)
 redraw()

func cast_target(target_side: int, index: int) -> void:
 if not can_act() or casting < 0:
  return
 var snapshot := field_nodes.duplicate()
 if not duel.cast(0,casting,target_side,index):
  return
 casting = -1
 summoning = -1
 selected = -1
 healing = false
 magic = false
 set_busy(true)
 await animate_action(duel.last_action,snapshot)
 set_busy(false)
 redraw()

func select_heal() -> void:
 if not can_act() or selected < 0:
  return
 healing = true
 magic = false
 redraw()

func heal_target(index: int, target_side: int=0) -> void:
 if not can_act() or not healing:
  return
 var snapshot := field_nodes.duplicate()
 if not duel.heal(0, selected, index,target_side):
  return
 set_busy(true)
 selected = -1
 healing = false
 magic = false
 await animate_action(duel.last_action, snapshot)
 set_busy(false)
 redraw()

func use_fury() -> void:
 if can_act() and duel.fury(0, selected):
  play_sound("summon")
  selected = -1
  healing = false
  magic = false
  redraw()

func end_turn() -> void:
 if not can_act():
  return
 casting = -1
 summoning = -1
 selected = -1
 healing = false
 magic = false
 var snapshot := field_nodes.duplicate()
 set_busy(true)
 duel.end_turn(0)
 await animate_action(duel.last_action,snapshot)
 redraw()
 if duel.turn==1 and duel.winner==-1:
  await run_ai_turn()
 else:
  set_busy(false)
  redraw()

func run_ai_turn() -> void:
 set_busy(true)
 await get_tree().create_timer(0.65).timeout
 while duel.turn == 1 and duel.winner == -1:
  var snapshot := field_nodes.duplicate()
  if not duel.ai_step():break
  await animate_action(duel.last_action,snapshot)
  redraw()
  await get_tree().create_timer(0.25).timeout
 if duel.turn==1 and duel.winner==-1:
  var snapshot := field_nodes.duplicate()
  duel.end_turn(1)
  await animate_action(duel.last_action,snapshot)
 set_busy(false)
 redraw()

func status_effect(kind: String,node: Control,amount: int=0) -> Tween:
 if not is_instance_valid(node):return null
 var effect=StatusVfx.new()
 effect.name="StatusEffect_"+kind
 effect.configure(kind,node.get_global_rect(),amount)
 vfx_layer.add_child(effect)
 var tween:=create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
 tween.tween_property(effect,"progress",1.0,0.38 if kind=="block" else 0.45)
 tween.finished.connect(effect.queue_free)
 return tween

func animate_records(records: Array,snapshot: Array,effect: String,sound: String) -> void:
 if records.is_empty():return
 # Wait for freshly redrawn cards to receive their container positions.
 await get_tree().process_frame
 await get_tree().process_frame
 play_sound(sound)
 var last: Tween
 for entry in records:
  var node: Control=find_child("PlayerCastle" if entry.side==0 else "EnemyCastle",true,false) if entry.castle else snapshot[entry.side].get(entry.id)
  if is_instance_valid(node):last=status_effect(effect,node,int(entry.get("amount",0)))
 if last:await last.finished

func blocked_castle_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  get_viewport().set_input_as_handled()
  notify_blocked_attack(-1)

func notify_blocked_attack(target_index: int) -> void:
 if not can_act() or magic or healing or casting>=0 or summoning>=0:return
 var guards:=duel.attack_blockers(0,selected,target_index)
 if guards.is_empty() or Time.get_ticks_msec()<block_feedback_until:return
 block_feedback_until=Time.get_ticks_msec()+300
 play_sound("block")
 for index in guards:
  var unit: Dictionary=duel.players[1].board[index]
  var node: Control=field_nodes[1].get(unit.id)
  if is_instance_valid(node):status_effect("block",node)

func animate_action(action: Dictionary, snapshot: Array) -> void:
 var kind: String = action.get("kind", "")
 if kind in ["summon", "fury"]:
  play_sound("summon")
  await animate_records(action.get("poisoned",[]),snapshot,"poison_apply","poison_apply")
  return
 if kind in ["poison","turn_end"]:
  await animate_records(action.get("ticks",[]),snapshot,"poison_tick","poison_tick")
  await animate_records(action.get("healed",[]),snapshot,"heal","heal")
  await animate_records(action.get("regeneration_damage",[]),snapshot,"arcane_area","magic")
  await animate_deaths(action,snapshot)
  return
 if kind not in ["attack", "magic", "heal", "spell"]:
  return
 var side: int = action.side
 var attacker: Control = snapshot[side].get(action.attacker)
 var destination: Control
 if kind == "spell":
  destination = find_child("PlayerCastle" if action.target_side==0 else "EnemyCastle",true,false) if action.castle else snapshot[action.target_side].get(action.target)
 elif action.castle:
  destination = find_child(("PlayerCastle" if side == 0 else "EnemyCastle") if kind == "heal" else ("EnemyCastle" if side == 0 else "PlayerCastle"), true, false)
 else:
  destination = snapshot[int(action.get("target_side",side if kind == "heal" else 1-side))].get(action.target)
 if kind == "spell":
  if int(action.effect)==CardData.SpellEffect.HORDE_ROAR:
   await animate_records(action.get("buffs",[]),snapshot,"attack_buff","magic")
  elif int(action.effect)==CardData.SpellEffect.AREA_ARCANE:
   await animate_records(action.get("area_hits",[]),snapshot,"arcane_area","magic")
  elif int(action.effect) in [CardData.SpellEffect.RESTORE,CardData.SpellEffect.RECONSTRUCT]:
   if action.get("undead_damage",false) and is_instance_valid(destination):
    await animate_missile(find_child("PlayerCastle" if side==0 else "EnemyCastle",true,false),destination)
   elif action.get("healed",[]).is_empty():play_sound("magic")
   else:await animate_records(action.healed,snapshot,"heal","heal")
  elif int(action.effect) in [CardData.SpellEffect.ARCANE,CardData.SpellEffect.CONDUCTIVE] and is_instance_valid(destination):
   var source: Control = find_child("PlayerCastle" if side==0 else "EnemyCastle",true,false)
   await animate_missile(source,destination)
  else:
   play_sound("magic")
   if is_instance_valid(destination):
    var glow: Control = destination.get_node("Canvas") if destination.has_node("Canvas") else destination
    var original: Color = glow.modulate
    var pulse := create_tween()
    pulse.tween_property(glow,"modulate",Color(1.15,1.5,1.25),0.08)
    pulse.tween_property(glow,"modulate",original,0.18)
    await pulse.finished
 elif kind == "heal":
  await animate_records(action.get("healed",[]),snapshot,"heal","heal")
 elif kind == "magic" and is_instance_valid(attacker) and is_instance_valid(destination):
  await animate_missile(attacker, destination)
 elif is_instance_valid(attacker) and is_instance_valid(destination):
  var canvas: Control = attacker.get_node("Canvas")
  var start := canvas.position
  var travel := destination.get_global_rect().get_center() - attacker.get_global_rect().get_center()
  attacker.z_index = 10
  var lunge := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
  lunge.tween_property(canvas, "position", start + travel * 0.82, 0.18)
  await lunge.finished
  play_sound("castle" if action.castle else "attack")
  var hit: Control = destination.get_node("Canvas") if destination.has_node("Canvas") else destination
  var initial_color := hit.modulate
  var recoil := create_tween().set_parallel(true)
  recoil.tween_property(canvas, "position", start, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
  recoil.tween_property(hit, "modulate", Color(1.6, 0.75, 0.75), 0.06)
  recoil.chain().tween_property(hit, "modulate", initial_color, 0.08)
  await recoil.finished
  attacker.z_index = 0
 else:
  play_sound("magic" if kind == "magic" else ("castle" if action.castle else "attack"))
 await animate_records(action.get("poisoned",[]),snapshot,"poison_apply","poison_apply")
 await animate_deaths(action,snapshot)

func animate_deaths(action: Dictionary,snapshot: Array) -> void:
 if not action.get("dead",[]).is_empty():
  play_sound("death")
  var fade := create_tween().set_parallel(true)
  var found := false
  for victim in action.dead:
   var node: Control = snapshot[victim.side].get(victim.id)
   if not is_instance_valid(node):
    continue
   found = true
   var canvas: Control = node.get_node("Canvas")
   canvas.pivot_offset = Vector2(100, 100)
   fade.tween_property(canvas, "modulate:a", 0.0, 0.32)
   fade.tween_property(canvas, "scale", canvas.scale * 0.82, 0.32)
  if found:
   await fade.finished
  else:
   fade.kill()

func animate_missile(attacker: Control, destination: Control) -> void:
 var missile := TextureRect.new()
 missile.name = "MagicMissile"
 missile.texture = CardVfxSkin.texture("magic-missile")
 missile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 missile.stretch_mode = TextureRect.STRETCH_SCALE
 missile.mouse_filter = Control.MOUSE_FILTER_IGNORE
 missile.size = Vector2(130, 52)
 missile.pivot_offset = missile.size * 0.5
 var source := attacker.get_global_rect().get_center()
 var target_point := destination.get_global_rect().get_center()
 missile.position = source - missile.pivot_offset
 missile.rotation = (target_point - source).angle()
 vfx_layer.add_child(missile)
 play_sound("magic")
 var flight := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
 flight.tween_property(missile, "position", target_point - missile.pivot_offset, 0.38)
 await flight.finished
 missile.queue_free()
 var hit: Control = destination.get_node("Canvas")
 var original := hit.modulate
 var impact := create_tween()
 impact.tween_property(hit, "modulate", Color(1.3, 0.8, 1.8), 0.06)
 impact.tween_property(hit, "modulate", original, 0.12)
 await impact.finished

func restart() -> void:
 # Prevent an outstanding AI coroutine from entering the new match.
 if busy:
  return
 if not Match.valid_deck(deck_store.active_cards()):
  needs_deck_fix=true
  open_decks()
  return
 clear_result()
 result_shown = false
 casting = -1
 summoning = -1
 enemy_deck_style=randi_range(0, Match.DECK_NAMES.size()-1)
 duel = Match.new(deck_store.active_cards(), Match.default_deck(enemy_deck_style),(randi_range(0,1) if starting_player<0 else starting_player) if enable_opening else 0,enable_opening)
 selected = -1
 healing = false
 magic = false
 redraw()
 if duel.opening:show_mulligan()

func open_decks() -> void:
 if busy or is_instance_valid(deck_editor):
  return
 hide_preview()
 get_viewport().gui_release_focus()
 deck_editor_layer = CanvasLayer.new()
 deck_editor_layer.layer = 30
 add_child(deck_editor_layer)
 deck_editor = DeckEditorScene.instantiate()
 deck_editor.configure(deck_store)
 deck_editor.theme = theme
 deck_editor_layer.add_child(deck_editor)
 deck_editor.closed.connect(close_decks)
 deck_editor.play_requested.connect(play_selected_deck)

func close_decks(restart_fixed: bool=true) -> void:
 if is_instance_valid(deck_editor_layer):
  remove_child(deck_editor_layer)
  deck_editor_layer.queue_free()
 deck_editor = null
 deck_editor_layer = null
 redraw()
 if restart_fixed and needs_deck_fix and Match.valid_deck(deck_store.active_cards()):
  needs_deck_fix=false
  restart()

func play_selected_deck() -> void:
 close_decks(false)
 needs_deck_fix=false
 restart()

func finish_if_needed() -> void:
 if duel.winner == -1 or busy or result_shown:
  return
 result_shown = true
 hide_preview()
 result_layer = CanvasLayer.new()
 result_layer.layer = 40
 add_child(result_layer)
 result_overlay = ResultScene.instantiate()
 result_overlay.configure(duel.winner, deck_store.slots[deck_store.active].name, duel.players[0].hp)
 result_layer.add_child(result_overlay)
 result_overlay.replay_requested.connect(restart)
 result_overlay.deck_requested.connect(func(): clear_result(); open_decks())
 result_overlay.dismissed.connect(clear_result)
 if duel.winner == 0:
  play_sound("victory")
 elif duel.winner == 1:
  play_sound("death")

func clear_result() -> void:
 if is_instance_valid(result_layer):
  remove_child(result_layer)
  result_layer.queue_free()
 result_layer = null
 result_overlay = null

func show_rules() -> void:
 if is_instance_valid(rules_dialog):
  rules_dialog.popup_centered(Vector2i(840, 600))
  return
 var dialog := AcceptDialog.new()
 rules_dialog = dialog
 dialog.title = "Manual do duelo"
 var manual := RichTextLabel.new()
 manual.custom_minimum_size = Vector2(780, 500)
 manual.text = FileAccess.get_file_as_string("res://MANUAL.txt")
 manual.scroll_active = true
 dialog.add_child(manual)
 add_child(dialog)
 dialog.popup_centered(Vector2i(840, 600))
 dialog.confirmed.connect(dialog.queue_free)


func show_mulligan() -> void:
 hide_preview()
 if is_instance_valid(mulligan_layer):
  remove_child(mulligan_layer)
  mulligan_layer.queue_free()
 mulligan_layer=CanvasLayer.new()
 mulligan_layer.layer=50
 add_child(mulligan_layer)
 mulligan_view=Control.new()
 mulligan_view.set_script(MulliganView)
 mulligan_view.configure(duel)
 mulligan_layer.add_child(mulligan_view)
 mulligan_view.confirmed.connect(finish_mulligan)

func finish_mulligan(indices: Array) -> void:
 if not duel.mulligan(0,indices):return
 while duel.opening and not duel.mulligan_done[1]:
  var swaps: Array=[]
  var limit: int=duel.mulligan_max_cards(1)
  for i in range(duel.players[1].hand.size()):
   if Match.CARD_DATA[duel.players[1].hand[i]].cost>=4 and swaps.size()<limit:swaps.append(i)
  if not duel.mulligan(1,swaps):break
 if duel.opening:
  show_mulligan()
  return
 hide_preview()
 remove_child(mulligan_layer)
 mulligan_layer.queue_free()
 mulligan_layer=null
 mulligan_view=null
 redraw()
 if duel.turn==1 and duel.winner==-1:await run_ai_turn()

func summon_target(side: int,index: int) -> void:
 if not can_act() or summoning<0:return
 if side!=Match.entry_target_side(0,Match.CARDS[duel.players[0].hand[summoning]]):return
 if not duel.play(0,summoning,index):return
 play_sound("summon")
 summoning=-1
 casting=-1
 selected=-1
 healing=false
 magic=false
 redraw()
 animate_records(duel.last_action.get("poisoned",[]),field_nodes,"poison_apply","poison_apply")
