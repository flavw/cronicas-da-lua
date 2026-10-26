extends SceneTree
const Match=preload("res://scripts/match.gd")
func _initialize() -> void:call_deferred("verify")
func unit(key: String,id: int) -> Dictionary:
 var u: Dictionary=Match.CARDS[key].duplicate(true)
 u.merge({"key":key,"id":id,"ready":true,"max_health":u.health,"poison":0})
 return u
func verify() -> void:
 var main=load("res://main.tscn").instantiate()
 main.starting_player=1
 root.add_child(main)
 await process_frame
 assert(main.duel.opening and not main.can_act() and is_instance_valid(main.mulligan_view))
 assert(main.duel.players[0].hand.size()==4 and main.duel.players[1].hand.size()==3)
 main.mulligan_view.toggle_card(0)
 main.mulligan_view.toggle_card(2)
 assert(main.mulligan_view.selected==[0,2])
 # Keep AI from spending its turn on animations in this phase/transition test.
 main.duel.players[1].hand=["conductive_bolt","conductive_bolt","vigor_vow"]
 main.duel.players[1].deck=["conductive_bolt","vigor_vow"]
 main.mulligan_view.confirmed.emit([0,2])
 assert(main.duel.opening and main.duel.mulligan_rounds[0]==1)
 main.mulligan_view.confirmed.emit([])
 assert(not main.duel.opening and main.busy and not is_instance_valid(main.mulligan_view))
 await create_timer(1.0).timeout
 assert(main.duel.turn==0 and main.can_act())
 main.duel.players[0].board=[unit("farmer",10),unit("cleric",11)]
 main.duel.players[0].board[0].vigor=true
 main.duel.players[0].board[0].health=4
 main.duel.players[0].board[0].poison=2
 main.duel.players[1].poison=3
 main.duel.players[0].mana=10
 main.redraw()
 var field=main.field_nodes[0][10]
 assert(field.get_node("Canvas/StatusIcons/Vigor").visible and field.get_node("Canvas/StatusIcons/Vigor/Value").text=="4")
 assert(field.get_node("Canvas/StatusIcons/Poison").visible and field.get_node("Canvas/StatusIcons/Poison/Value").text=="2")
 main.show_preview(Match.CARD_DATA.farmer,4,field)
 var entries=main.preview.view_entries()
 assert(entries.any(func(entry):return entry.name=="Vigor" and "atual (ataque e defesa): 4" in entry.description))
 assert(entries.any(func(entry):return entry.name=="Envenenado 2"))
 assert(main.preview.get_node("CardCanvas/Ability").get_child_count()==2,"Veneno recebido só aparece no status e tooltip, não duplica habilidades")
 main.hide_preview()
 main.duel.players[0].hp=1
 main.duel.players[0].poison=1
 main.duel.players[0].board=[unit("wolf",30)]
 main.duel.players[0].board[0].health=1
 main.duel.players[0].board[0].poison=2
 main.duel.resolve_poison(0)
 main.redraw()
 assert(main.duel.winner==-1 and main.duel.players[0].hp==1 and main.duel.players[0].poison==0 and main.duel.players[0].board.is_empty())
 assert(not main.result_shown,"Veneno da criatura não atinge o castelo nem encerra a partida")
 main.queue_free()
 await process_frame
 await create_timer(0.35).timeout
 print("OK: mulligan visual 4 cartas/troca parcial, IA começa e passa, Vigor concedido e indicadores Veneno/Vigor e fim de Veneno de criatura sem dano no castelo.")
 quit()
