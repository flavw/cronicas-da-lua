extends SceneTree
const Match=preload("res://scripts/match.gd")
func _initialize() -> void:call_deferred("verify")
func unit(key: String,id: int,ready: bool=true) -> Dictionary:
 var u: Dictionary=Match.CARDS[key].duplicate(true)
 u.merge({"key":key,"id":id,"ready":ready,"max_health":u.health,"poison":0})
 return u
func settle() -> void:
 for i in range(5):await process_frame
func click(node: Control,button: int=MOUSE_BUTTON_LEFT) -> void:
 var event:=InputEventMouseButton.new();event.position=node.get_global_rect().get_center();event.button_index=button;event.pressed=true
 root.push_input(event,true);event.pressed=false;root.push_input(event,true)
func key(code: int) -> void:
 var event:=InputEventKey.new();event.keycode=code;event.pressed=true;root.push_input(event,true)
func verify() -> void:
 var main=load("res://main.tscn").instantiate();main.enable_opening=false;main.muted=true;root.add_child(main)
 for p in main.duel.players:p.board=[];p.hand=[];p.mana=3;p.max_mana=3;p.hp=20
 main.duel.players[0].hand=["squire"];main.redraw();await settle()
 assert(main.find_child("EndTurn",true,false).get_meta("actions_remaining"))
 for button in main.find_children("*","Button",true,false):assert(not button.text.begins_with("Invocar") and not button.text.begins_with("Conjurar"))
 var hand=main.find_child("HandCard_0",true,false)
 click(hand,MOUSE_BUTTON_RIGHT);await settle()
 assert(main.duel.players[0].hand==["squire"] and main.ArtViewer.is_open(main))
 root.get_meta("card_art_viewer").close();await settle()
 click(hand);await settle()
 assert(main.duel.players[0].hand.is_empty() and main.duel.players[0].board.size()==1 and main.duel.players[0].mana==2)
 assert(not main.find_child("EndTurn",true,false).get_meta("actions_remaining"))
 main.duel.players[0].board=[unit("wolf",1)];main.duel.players[0].mana=0;main.redraw()
 assert("atacar" in main.remaining_actions())
 main.duel.players[0].board[0].ready=false
 assert(main.remaining_actions().is_empty())
 main.duel.players[0].mana=1
 assert("usar habilidades" in main.remaining_actions(),"Fúria continua disponível esgotado")
 main.duel.players[0].board=[unit("mage",2)];main.duel.players[1].board=[]
 assert(main.remaining_actions().is_empty(),"Magia sem alvo não conta")
 main.duel.players[1].board=[unit("wolf",3)]
 assert("usar habilidades" in main.remaining_actions())
 main.duel.players[0].board=[unit("cleric",4)];main.duel.players[1].board=[]
 assert(not "usar habilidades" in main.remaining_actions(),"Cura sem feridos não conta")
 main.duel.players[0].hp=19
 assert("usar habilidades" in main.remaining_actions())
 main.duel.players[0].board=[]
 for i in range(5):main.duel.players[0].board.append(unit("squire",i+10,false))
 main.duel.players[0].hand=["wolf"];main.duel.players[0].mana=2
 assert(main.remaining_actions().is_empty(),"Campo cheio impede invocar")
 main.duel.players[0].board=[];main.duel.players[0].hand=["astral_flame"];main.duel.players[0].mana=3;main.duel.players[1].board=[unit("wolf",30)]
 main.redraw();await settle();click(main.find_child("HandCard_0",true,false));await settle()
 assert(main.casting==0 and main.duel.players[0].mana==3 and main.duel.players[0].hand==["astral_flame"])
 var castle=main.find_child("EnemyCastle",true,false)
 var field=main.find_child("EnemyBattlefield",true,false)
 assert(absf(castle.get_global_rect().get_center().x-field.get_global_rect().get_center().x)<2)
 assert(castle.get_global_rect().end.y<=field.get_global_rect().position.y)
 assert(main.find_child("EnemyDeckName",true,false).text==main.opponent_label())
 assert(main.find_child("EnemyDeckName",true,false).get_global_rect().position.x<60)
 click(main.find_child("CombatSettings",true,false));await settle()
 assert(is_instance_valid(main.combat_menu_layer) and not main.can_act())
 key(KEY_ESCAPE);await settle()
 assert(not is_instance_valid(main.combat_menu_layer) and main.casting==0)
 key(KEY_ESCAPE);await settle();assert(is_instance_valid(main.combat_menu_layer))
 key(KEY_ESCAPE);await settle();assert(not is_instance_valid(main.combat_menu_layer))
 var battle_root=main.root
 main.set_busy(true);main.open_combat_menu();main.close_combat_menu()
 assert(main.root==battle_root and not main.can_act(),"Fechar menu durante efeito não recria os nós animados")
 main.set_busy(false)
 main.restart();await settle()
 assert(main.find_child("EnemyDeckName",true,false).text==main.opponent_label())
 var actual: Array=main.duel.players[1].hand.duplicate();actual.append_array(main.duel.players[1].deck);actual.sort()
 var expected: Array=Match.default_deck(main.enemy_deck_style);expected.sort();assert(actual==expected)
 main.queue_free();await process_frame;await create_timer(0.35).timeout
 print("OK: clique invoca/conjura, arte no botão direito, ações legais, menu Esc/engrenagem, castelo central e nome real do deck inimigo.")
 quit()
