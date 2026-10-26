extends SceneTree
const Match = preload("res://scripts/match.gd")

func creature(key: String, id: int) -> Dictionary:
 var unit: Dictionary = Match.CARDS[key].duplicate(true)
 unit.merge({"key": key, "id": id, "ready": true, "max_health": unit.health})
 return unit

func _init() -> void:
 var m = Match.new()
 m.players[0].mana = 10
 m.players[0].hand = ["farmer", "cleric"]
 assert(m.play(0, 0))
 assert(m.players[0].board[0].health == 3 and m.players[0].board[0].max_health == 3)
 assert(m.end_turn(0))
 assert(m.players[0].board[0].health == 3, "Não cresce no turno inimigo")
 assert(m.end_turn(1))
 assert(m.players[0].board[0].health == 4 and m.players[0].board[0].max_health == 4)
 m.players[0].board[0].health = 1
 m.end_turn(0)
 m.end_turn(1)
 assert(m.players[0].board[0].health == 2 and m.players[0].board[0].max_health == 5, "Crescimento preserva o dano sofrido")
 m.players[0].board.append(creature("cleric", 100))
 m.players[0].mana = 1
 assert(m.heal(0, 1, 0))
 assert(m.players[0].board[0].health == 4)
 assert(m.players[0].mana == 0 and not m.players[0].board[1].ready)
 assert(not m.heal(0, 1, 0))
 m.players[0].board[1].ready = true
 m.players[0].mana = 3
 m.players[0].board[0].health=5
 assert(not m.heal(0, 1, 0), "Alvo cheio não gasta mana nem esgota")
 assert(m.players[0].mana == 3 and m.players[0].board[1].ready)
 m.players[0].hp = 19
 assert(m.heal(0, 1, -1))
 assert(m.players[0].hp == 20 and m.players[0].mana == 2)
 m.players[0].board[1].ready = true
 m.players[0].board[1].health = 2
 assert(m.heal(0, 1, 1), "Clériga pode curar a si mesma")
 assert(m.players[0].board[1].health == 4)
 for style in range(3):
  assert(Match.valid_deck(Match.default_deck(style)))
 assert(Match.CARD_DATA.size() == 34)
 print("OK: crescimento por turno, vida máxima, cura de aliado/castelo/própria, custo, esgotamento e decks com 34 cartas disponíveis.")
 quit()
