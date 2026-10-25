extends Control

const Match = preload("res://scripts/match.gd")
const DeckStoreScript = preload("res://scripts/deck_store.gd")
const DeckEditorScene = preload("res://deck_editor.tscn")
var deck_store = DeckStoreScript.new()
var duel = Match.new(deck_store.active_cards(), Match.default_deck(1))
var deck_editor: Control
var deck_editor_layer: CanvasLayer
var selected := -1
var magic := false
var healing := false
var busy := false
var root: VBoxContainer
const CardScene = preload("res://card_model.tscn")
const FieldScene = preload("res://field_card.tscn")
const CardVfxSkin = preload("res://scripts/card_skin.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")
const ResultScene = preload("res://result_overlay.tscn")
var preview: Control
var preview_owner: Control
var field_nodes: Array = [{}, {}]
var input_shield: Control
var sounds: Dictionary = {}
var vfx_layer: CanvasLayer
var muted := false
var result_shown := false
var result_layer: CanvasLayer
var result_overlay: Control
var sound_counts: Dictionary = {}
var rules_dialog: AcceptDialog

func _input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo:
  return
 if event.ctrl_pressed or event.alt_pressed or event.meta_pressed or event.shift_pressed:
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
 for kind in ["summon", "attack", "death", "magic", "victory", "castle"]:
  var player := AudioStreamPlayer.new()
  player.stream = load("res://assets/audio/%s.wav" % kind)
  player.volume_db = -10
  player.max_polyphony = 6
  add_child(player)
  sounds[kind] = player
 redraw()

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

func redraw() -> void:
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
 var header := HBoxContainer.new()
 root.add_child(header)
 var title := label_text("CRÔNICAS DA LUA", 26)
 title.add_theme_font_override("font", preload("res://assets/fonts/title_font.tres"))
 title.add_theme_color_override("font_color", Color("e7ce91"))
 title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 header.add_child(title)
 header.add_child(button("Nova partida", restart, not busy))
 header.add_child(button("Decks • %s" % deck_store.slots[deck_store.active].name.left(18), open_decks, not busy))
 header.add_child(button("Regras", show_rules))
 header.add_child(button("Som: desligado" if muted else "Som: ligado", toggle_sound, not busy))
 add_hero(1)
 add_board(1)
 var status := "Sua vez — invoque uma carta ou selecione uma criatura pronta."
 if duel.turn == 1:
  status = "A IA está pensando…"
 if selected >= 0:
  status = "Escolha uma criatura inimiga para magia." if magic else "Escolha uma criatura inimiga ou o herói da IA para atacar."
  if healing:
   status = "Escolha uma criatura aliada ferida ou seu castelo para curar."
  if not healing and not magic and not duel.players[0].board[selected].get("flying", false) and not duel.blockers(1).is_empty():
   status = "Bloqueio ativo: o ataque físico deve atingir um Escudeiro."
 if duel.winner != -1:
  status = ["Vitória!", "A IA venceu.", "Empate."][duel.winner]
 var status_panel := PanelContainer.new()
 status_panel.add_theme_stylebox_override("panel", UiTheme.panel(Color("101f2c"), Color("577686") if duel.turn == 0 else Color("6a5278"), 5))
 root.add_child(status_panel)
 var status_text := label_text(status, 18)
 status_text.modulate = Color("aad7ec") if duel.turn == 0 else Color("cbb9dd")
 status_panel.add_child(status_text)
 var actions := HBoxContainer.new()
 actions.alignment = BoxContainer.ALIGNMENT_CENTER
 root.add_child(actions)
 var has_selection: bool = selected >= 0 and selected < duel.players[0].board.size()
 if has_selection and duel.players[0].board[selected].attack > 0:
  actions.add_child(button("Ataque físico", func(): magic = false; healing = false; redraw(), can_act() and duel.players[0].board[selected].ready))
 var spell: Dictionary = duel.players[0].board[selected] if has_selection else {}
 var spell_damage: int = spell.get("magic_damage", 0)
 var spell_cost: int = spell.get("magic_cost", 1)
 if spell_damage > 0:
  actions.add_child(button("Magia %d • %d mana + esgotar" % [spell_damage, spell_cost], func(): magic = true; healing = false; redraw(), can_act() and spell.get("ready", false) and duel.players[0].mana >= spell_cost))
 if spell.get("heal_amount", 0) > 0:
  actions.add_child(button("Cura %d • %d mana + esgotar" % [spell.heal_amount, spell.heal_cost], select_heal, can_act() and spell.get("ready", false) and duel.players[0].mana >= spell.heal_cost))
 var fury_selected: bool = has_selection and duel.players[0].board[selected].get("fury", 0) > 0
 if fury_selected:
  actions.add_child(button("Fúria +1 • 1 mana", use_fury, can_act() and duel.players[0].mana >= 1))
 if has_selection:
  actions.add_child(button("Cancelar", func(): selected = -1; magic = false; healing = false; redraw()))
 var pass_turn := button("Encerrar turno →", end_turn, can_act())
 pass_turn.tooltip_text = "Encerrar turno: Enter ou 0 do teclado numérico"
 UiTheme.primary(pass_turn)
 actions.add_child(pass_turn)
 add_board(0)
 var p: Dictionary = duel.players[0]
 add_hero(0)
 var hand_panel := PanelContainer.new()
 hand_panel.add_theme_stylebox_override("panel", UiTheme.panel(Color(0.04, 0.08, 0.13, 0.93), Color("74633f"), 8))
 root.add_child(hand_panel)
 var hand_content := VBoxContainer.new()
 hand_panel.add_child(hand_content)
 var hand_caption := label_text("SUA MÃO   •   %d CARTAS" % p.hand.size(), 13)
 hand_caption.modulate = Color("aab9c7")
 hand_content.add_child(hand_caption)
 var hand := HBoxContainer.new()
 hand.alignment = BoxContainer.ALIGNMENT_CENTER
 hand.custom_minimum_size.y = 182
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
  art.custom_minimum_size = Vector2(108, 144)
  art.mouse_filter = Control.MOUSE_FILTER_PASS
  art.mouse_entered.connect(show_preview.bind(Match.CARD_DATA[key], -1, art))
  art.mouse_exited.connect(close_preview.bind(art))
  box.add_child(art)
  var summon := button("Invocar • %d" % Match.CARDS[key].cost, play.bind(i), can_act() and p.mana >= Match.CARDS[key].cost and p.board.size() < 5)
  summon.add_theme_font_size_override("font_size", 15)
  summon.custom_minimum_size.y = 32
  box.add_child(summon)
 var log_label := label_text("\n".join(duel.history.slice(maxi(0, duel.history.size() - 2))), 14)
 log_label.modulate = Color("a8b8c8")
 root.add_child(log_label)
 finish_if_needed()

func can_act() -> bool:
 return duel.turn == 0 and duel.winner == -1 and not busy and not is_instance_valid(deck_editor)

func add_board(side: int) -> void:
 var row := HBoxContainer.new()
 row.alignment = BoxContainer.ALIGNMENT_CENTER
 row.custom_minimum_size.y = 188
 row.add_theme_constant_override("separation", 10)
 root.add_child(row)
 var board: Array = duel.players[side].board
 for i in range(5):
  var slot := PanelContainer.new()
  slot.custom_minimum_size = Vector2(198, 188)
  var style := StyleBoxFlat.new()
  style.bg_color = Color("142638") if side == 0 else Color("282334")
  style.bg_color.a = 0.65
  style.set_border_width_all(2)
  style.border_color = Color("ecd599") if side == 0 and selected == i else Color("4a5360")
  style.set_corner_radius_all(12)
  style.content_margin_top = 6
  style.content_margin_bottom = 6
  slot.add_theme_stylebox_override("panel", style)
  row.add_child(slot)
  if i >= board.size():
   var empty := label_text("◇", 38)
   empty.modulate = Color(0.42, 0.48, 0.54, 0.5)
   slot.add_child(empty)
   continue
  var u: Dictionary = board[i]
  var art = FieldScene.instantiate()
  art.custom_minimum_size = Vector2(176, 176)
  var selectable: bool = u.ready or (u.get("fury", 0) > 0 and duel.players[0].mana >= 1)
  var enabled: bool = (not healing and duel.can_target(0, selected, i, magic)) if side == 1 else (duel.can_heal(0, selected, i) if healing else selectable)
  art.set_card(Match.CARD_DATA[u.key], u.health, can_act() and enabled, side == 0 and selected == i, u.attack, u.get("block", 0), not u.ready, u.armor)
  slot.add_child(art)
  field_nodes[side][u.get("id", -1)] = art
  art.activated.connect(target.bind(i) if side == 1 else (heal_target.bind(i) if healing else select.bind(i)))
  art.inspect_requested.connect(show_preview)
  art.inspect_closed.connect(close_preview)

func show_preview(data: CardData, health: int, owner: Control) -> void:
 if busy or is_instance_valid(deck_editor) or not is_instance_valid(preview):
  return
 preview_owner = owner
 preview.set_card(data, health, owner.get_meta("attack", -1), owner.get_meta("block", -1))
 preview.tooltip_text = ""
 var bounds := owner.get_global_rect()
 var viewport := get_viewport_rect().size
 var x := bounds.end.x + 16
 if x + preview.size.x > viewport.x - 16:
  x = bounds.position.x - preview.size.x - 16
 preview.position = Vector2(clampf(x, 16, viewport.x - preview.size.x - 16), clampf(bounds.position.y - 110, 16, viewport.y - preview.size.y - 16))
 preview.show()

func close_preview(owner: Control) -> void:
 if preview_owner == owner:
  hide_preview()

func hide_preview() -> void:
 preview_owner = null
 if is_instance_valid(preview):
  preview.hide()

func add_hero(side: int) -> void:
 var p: Dictionary = duel.players[side]
 var row := HBoxContainer.new()
 row.alignment = BoxContainer.ALIGNMENT_CENTER
 row.add_theme_constant_override("separation", 15)
 var panel := PanelContainer.new()
 panel.custom_minimum_size.x = 1040
 panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
 panel.add_theme_stylebox_override("panel", UiTheme.panel(Color(0.045, 0.075, 0.12, 0.92), Color("5c5366") if side == 1 else Color("536b75"), 4))
 root.add_child(panel)
 panel.add_child(row)
 var castle := Button.new()
 castle.name = "EnemyCastle" if side == 1 else "PlayerCastle"
 castle.icon = preload("res://assets/ui/castle.svg")
 castle.expand_icon = true
 castle.custom_minimum_size = Vector2(76, 56)
 castle.add_theme_constant_override("icon_max_width", 68)
 castle.add_theme_color_override("icon_disabled_color", Color(0.8, 0.8, 0.9))
 castle.tooltip_text = "Ataque direto ao castelo da IA" if side == 1 else ("Curar seu castelo" if healing else "Seu castelo")
 var castle_allowed: bool = (healing and duel.can_heal(0, selected, -1)) if side == 0 else (not healing and duel.can_target(0, selected, -1, magic))
 castle.disabled = not can_act() or not castle_allowed
 castle.pressed.connect(heal_target.bind(-1) if side == 0 else target.bind(-1))
 row.add_child(castle)
 var details := VBoxContainer.new()
 details.custom_minimum_size.x = 250
 details.add_theme_constant_override("separation", 2)
 row.add_child(details)
 var life := label_text("%s   •   VIDA %d" % ["IA" if side == 1 else "VOCÊ", p.hp], 20)
 life.modulate = Color("f28e82") if p.hp <= 5 else Color("eadbbd")
 details.add_child(life)
 var info := label_text("Mão %d   •   Baralho %d" % [p.hand.size(), p.deck.size()], 13)
 info.modulate = Color("9db0c1")
 details.add_child(info)
 var hp := ProgressBar.new()
 hp.max_value = 20
 hp.value = maxi(0, p.hp)
 hp.show_percentage = false
 hp.custom_minimum_size = Vector2(160, 5)
 hp.add_theme_stylebox_override("background", UiTheme.panel(Color("291c27"), Color("403038"), 0))
 hp.add_theme_stylebox_override("fill", UiTheme.panel(Color("ab5258"), Color("d98576"), 0))
 details.add_child(hp)
 add_mana(side, row)

func add_mana(side: int, parent: Node = null) -> void:
 var p: Dictionary = duel.players[side]
 var row := HBoxContainer.new()
 row.alignment = BoxContainer.ALIGNMENT_CENTER
 row.add_theme_constant_override("separation", 6)
 (root if parent == null else parent).add_child(row)
 var counter := label_text("MANA %d / %d" % [p.mana, p.max_mana], 20)
 counter.custom_minimum_size.x = 150
 row.add_child(counter)
 for i in range(10):
  var gem := TextureRect.new()
  gem.texture = CardVfxSkin.texture("mana-gem")
  gem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  gem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  gem.custom_minimum_size = Vector2(24, 24)
  gem.modulate = Color.WHITE if i < p.mana else (Color(0.37, 0.42, 0.52) if i < p.max_mana else Color(0.18, 0.22, 0.28))
  gem.tooltip_text = "Disponível" if i < p.mana else ("Gasta neste turno" if i < p.max_mana else "Ainda bloqueada")
  row.add_child(gem)

func select(index: int) -> void:
 if not can_act():
  return
 selected = index
 healing = false
 magic = duel.players[0].board[index].attack == 0 and duel.players[0].board[index].get("magic_damage", 0) > 0
 redraw()

func play(index: int) -> void:
 if not can_act() or not duel.play(0, index):
  return
 play_sound("summon")
 selected = -1
 healing = false
 magic = false
 redraw()

func target(index: int) -> void:
 if can_act() and selected >= 0 and not healing:
  var snapshot := field_nodes.duplicate()
  if not duel.act(0, selected, index, magic):
   return
  set_busy(true)
  selected = -1
  magic = false
  await animate_action(duel.last_action, snapshot)
  set_busy(false)
  redraw()

func select_heal() -> void:
 if not can_act() or selected < 0:
  return
 healing = true
 magic = false
 redraw()

func heal_target(index: int) -> void:
 if not can_act() or not healing:
  return
 var snapshot := field_nodes.duplicate()
 if not duel.heal(0, selected, index):
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
 selected = -1
 healing = false
 magic = false
 duel.end_turn(0)
 set_busy(true)
 redraw()
 await get_tree().create_timer(0.65).timeout
 while duel.turn == 1 and duel.winner == -1:
  var snapshot := field_nodes.duplicate()
  if not duel.ai_step():
   break
  await animate_action(duel.last_action, snapshot)
  redraw()
  await get_tree().create_timer(0.25).timeout
 if duel.winner == -1:
  duel.end_turn(1)
 set_busy(false)
 redraw()

func animate_action(action: Dictionary, snapshot: Array) -> void:
 var kind: String = action.get("kind", "")
 if kind in ["summon", "fury"]:
  play_sound("summon")
  return
 if kind not in ["attack", "magic", "heal"]:
  return
 var side: int = action.side
 var attacker: Control = snapshot[side].get(action.attacker)
 var destination: Control
 if action.castle:
  destination = find_child(("PlayerCastle" if side == 0 else "EnemyCastle") if kind == "heal" else ("EnemyCastle" if side == 0 else "PlayerCastle"), true, false)
 else:
  destination = snapshot[side if kind == "heal" else 1 - side].get(action.target)
 if kind == "heal":
  play_sound("summon")
  if is_instance_valid(destination):
   var glow: Control = destination.get_node("Canvas") if destination.has_node("Canvas") else destination
   var initial := glow.modulate
   var pulse := create_tween()
   pulse.tween_property(glow, "modulate", Color(1.2, 1.7, 1.2), 0.08)
   pulse.tween_property(glow, "modulate", initial, 0.18)
   await pulse.finished
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
 if not action.dead.is_empty():
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
 clear_result()
 result_shown = false
 duel = Match.new(deck_store.active_cards(), Match.default_deck(randi_range(0, 2)))
 selected = -1
 healing = false
 magic = false
 redraw()

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
 deck_editor.play_requested.connect(func(): close_decks(); restart())

func close_decks() -> void:
 if is_instance_valid(deck_editor_layer):
  remove_child(deck_editor_layer)
  deck_editor_layer.queue_free()
 deck_editor = null
 deck_editor_layer = null
 redraw()

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

