extends SceneTree
const Match = preload("res://scripts/match.gd")
func _initialize() -> void:
 call_deferred("verify")
func creature(key: String, id: int) -> Dictionary:
 var u: Dictionary = Match.CARDS[key].duplicate(true)
 u.merge({"key": key, "id": id, "ready": true, "max_health": u.health})
 return u
func verify() -> void:
 var main = load("res://main.tscn").instantiate()
 root.add_child(main)
 main.duel.players[0].board = [creature("cleric", 10), creature("farmer", 11), creature("warrior", 12), creature("squire", 13)]
 main.duel.players[0].board[1].health = 1
 main.duel.players[0].board[3].block = 0
 main.duel.players[0].mana = 5
 main.duel.players[0].hp = 18
 main.redraw()
 main.select(0)
 main.select_heal()
 assert(not main.find_child("PlayerCastle", true, false).disabled)
 assert(main.find_child("EnemyCastle", true, false).disabled)
 main.field_nodes[0][11].activated.emit()
 assert(main.duel.players[0].board[1].health == 2)
 for i in range(40):
  if not main.busy:
   break
  await create_timer(0.02).timeout
 main.duel.players[0].board[0].ready = true
 main.select(0)
 main.select_heal()
 main.find_child("PlayerCastle", true, false).pressed.emit()
 assert(main.duel.players[0].hp == 20)
 for i in range(40):
  if not main.busy:
   break
  await create_timer(0.02).timeout
 main.show_preview(Match.CARD_DATA.warrior, 1, main.field_nodes[0][12])
 assert(not main.preview.has_node("CardCanvas/StatusIcons"))
 assert(main.field_nodes[0][12].get_node("Canvas/StatusIcons/Armor/Value").text == "2")
 main.show_preview(Match.CARD_DATA.squire, 2, main.field_nodes[0][13])
 assert(not main.preview.has_node("CardCanvas/StatusIcons"))
 assert(main.field_nodes[0][13].get_node("Canvas/StatusIcons/Block/Value").text == "0")
 print("OK: cura e ícones de Armadura 2/Bloqueio 0 somente no card de campo.")
 main.queue_free()
 await process_frame
 await process_frame
 quit()
