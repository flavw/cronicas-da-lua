extends SceneTree
const Match = preload("res://scripts/match.gd")

func _initialize() -> void:
 call_deferred("verify")

func creature(key: String, id: int) -> Dictionary:
 var unit: Dictionary = Match.CARDS[key].duplicate(true)
 unit.merge({"key": key, "id": id, "ready": true})
 return unit

func wait_effect(main: Control, actor: Control, victims: Array) -> void:
 var moved := false
 var faded := false
 var origin: Vector2 = actor.get_node("Canvas").position
 for i in range(100):
  await create_timer(0.02).timeout
  if not main.busy:
   break
  if is_instance_valid(actor):
   moved = moved or actor.get_node("Canvas").position.distance_to(origin) > 3
  for victim in victims:
   if is_instance_valid(victim):
    faded = faded or victim.get_node("Canvas").modulate.a < 0.9
 assert(not main.busy, "Animação termina e libera entrada")
 assert(moved, "Carta se desloca em direção ao alvo")
 if not victims.is_empty():
  assert(faded, "Morte reduz opacidade antes de remover carta")

func verify() -> void:
 var main = load("res://main.tscn").instantiate()
 root.add_child(main)
 assert(main.sounds.size() == 6)
 for kind in main.sounds:
  assert(main.sounds[kind].stream.get_length() > 0.1)
 main.duel.players[0].board = [creature("warrior", 10)]
 main.duel.players[1].board = [creature("wolf", 11)]
 main.redraw()
 await process_frame
 await process_frame
 var actor: Control = main.field_nodes[0][10]
 var victim: Control = main.field_nodes[1][11]
 main.select(0)
 # Selection redraws the controls; use the current instances.
 await process_frame
 actor = main.field_nodes[0][10]
 victim = main.field_nodes[1][11]
 main.target(0)
 assert(main.busy and main.input_shield.visible)
 var active_match = main.duel
 main.restart()
 main.end_turn()
 assert(main.duel == active_match and main.duel.turn == 0, "Comandos bloqueados durante ataque")
 await wait_effect(main, actor, [victim])
 assert(main.duel.players[1].board.is_empty())
 assert(main.duel.players[0].board.size() == 1)
 assert(main.duel.last_action.dead.size() == 1)
 assert(not main.input_shield.visible)
 # Simultaneous combat death: both cards fade together.
 main.duel.players[0].board = [creature("wolf", 20)]
 main.duel.players[1].board = [creature("wolf", 21)]
 main.redraw()
 main.select(0)
 await process_frame
 actor = main.field_nodes[0][20]
 victim = main.field_nodes[1][21]
 main.target(0)
 await wait_effect(main, actor, [actor, victim])
 assert(main.duel.last_action.dead.size() == 2)
 assert(main.duel.players[0].board.is_empty() and main.duel.players[1].board.is_empty())
 # AI attacks the player's castle and awaits the same animation pipeline.
 main.duel.players[1].board = [creature("wolf", 30)]
 main.duel.players[1].hand = []
 main.duel.players[1].deck = ["mage"]
 main.redraw()
 await process_frame
 actor = main.field_nodes[1][30]
 main.end_turn()
 await process_frame
 actor = main.field_nodes[1][30]
 var ai_moved := false
 for i in range(150):
  await create_timer(0.02).timeout
  if is_instance_valid(actor):
   ai_moved = ai_moved or actor.get_node("Canvas").position.length() > 15
  if not main.busy:
   break
 assert(not main.busy and main.duel.turn == 0)
 assert(main.duel.players[0].hp == 18 and ai_moved)
 print("OK: 6 sons, ataque com deslocamento, morte com fade, morte simultânea, bloqueio de entrada e ataque da IA ao castelo.")
 quit()
