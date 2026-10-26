extends SceneTree

func _initialize() -> void:
 call_deferred("verify")

func verify() -> void:
 var menu = load("res://start_menu.tscn").instantiate()
 root.add_child(menu)
 current_scene = menu
 await process_frame
 assert(menu.find_child("GameTitle", true, false).text == "CRÔNICAS\nDA LUA")
 menu.open_decks()
 await process_frame
 var editor = menu.deck_layer.get_child(0)
 assert(editor.return_label == "Voltar ao início")
 assert(editor.draft.size() == 20)
 editor.closed.emit()
 await process_frame
 assert(not is_instance_valid(menu.deck_layer))
 menu.show_rules()
 assert(menu.rules_dialog.visible)
 menu.rules_dialog.hide()
 menu.start_game()
 await process_frame
 await process_frame
 assert(current_scene.name == "Duelo", "Jogar abre a partida")
 var duel = current_scene
 duel.open_combat_menu()
 var back: Button
 for node in duel.find_children("*", "Button", true, false):
  if node.text == "Início":
   back = node
 assert(back != null)
 back.pressed.emit()
 await process_frame
 await process_frame
 assert(current_scene.name == "StartMenu", "Início retorna ao menu")
 current_scene.queue_free()
 await process_frame
 await process_frame
 print("OK: título, editor e retorno, regras, iniciar duelo e voltar ao início.")
 quit()
