extends SceneTree
const Match = preload("res://scripts/match.gd")

func _init() -> void:
 var u := {"armor": 2, "health": 3}
 assert(Match.damage(u, 2) == 0)
 assert(u.health == 3 and u.armor == 2)
 assert(Match.damage(u, 3) == 1)
 assert(Match.damage(u, 1, true) == 1)
 var m = Match.new()
 m.players[0].mana = 10
 m.players[0].hand = ["mage"]
 assert(m.play(0, 0))
 assert(not m.act(0, 0, -1))
 m.players[0].board[0].ready = true
 m.players[1].board = [{"key": "warrior", "name": "Guerreira", "armor": 2, "health": 1, "attack": 3, "ready": true}]
 assert(m.act(0, 0, 0, true))
 assert(m.players[1].board.is_empty())
 assert(m.players[0].board[0].health == 2, "Poder da Maga não gera contra-ataque, mesmo contra ataque 3")
 assert(m.players[0].mana == 7)
 assert(not m.players[0].board[0].ready)
 assert(not m.act(1, 0, -1))
 m.players[0].board[0].ready = true
 m.players[1].board = [{"key": "wolf", "name": "Lobo", "armor": 2, "health": 3, "attack": 9, "ready": true}]
 assert(m.act(0, 0, 0, true))
 assert(m.players[1].board[0].health == 2)
 assert(m.players[0].board[0].health == 2, "Alvo sobrevivente também não contra-ataca magia")
 for game in range(20):
  var sim = Match.new()
  for step in range(1500):
   if sim.winner != -1:
    break
   if sim.turn == 1:
    if not sim.ai_step():
     sim.end_turn(1)
   else:
    var p: Dictionary = sim.players[0]
    var played := false
    for i in range(p.hand.size()):
     if sim.play(0, i):
      played = true
      break
    if played:
     continue
    var attacked := false
    for i in range(p.board.size()):
     var guards: Array = sim.blockers(1)
     if p.board[i].key == "mage":
      if not sim.players[1].board.is_empty() and sim.act(0, i, 0, true):
       attacked = true
       break
     elif sim.act(0, i, -1 if guards.is_empty() else guards[0]):
      attacked = true
      break
    if not attacked:
     sim.end_turn(0)
  assert(sim.winner != -1, "Partida deve terminar")
 print("OK: armadura, magia, custo, esgotamento, turno e 20 partidas completas.")
 quit()
