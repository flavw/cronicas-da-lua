extends SceneTree
const Match=preload("res://scripts/match.gd")
const Store=preload("res://scripts/deck_store.gd")
func _initialize() -> void:call_deferred("verify")
func verify() -> void:
 var store=Store.new("user://test_deck_library.json",false)
 var original: Array=store.slots.duplicate(true)
 assert(store.persist())
 var editor=load("res://deck_editor.tscn").instantiate()
 editor.configure(store)
 root.add_child(editor)
 await process_frame
 await process_frame
 assert(editor.screen=="library")
 assert(editor.find_child("DeckLibrary",true,false).get_child_count()==Store.SLOT_COUNT)
 assert(editor.find_child("DeckSuggestion",true,false)==null,"Escolha de deck separada da edição de cartas")
 assert(store.cover_for(0)=="wall_smith" and store.cover_for(4)=="")
 var cover=editor.find_child("DeckTile2",true,false).find_child("DeckCoverArtwork",true,false)
 var click:=InputEventMouseButton.new()
 click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true
 click.position=cover.get_global_rect().get_center()
 root.push_input(click,true)
 await process_frame
 assert(editor.screen=="library" and editor.library_selected==1 and store.active==0,"Clique na capa apenas seleciona o deck")
 click.pressed=false
 root.push_input(click,true)
 editor.find_child("DeckActionEdit",true,false).pressed.emit()
 assert(editor.screen=="edit" and editor.slot==1)
 editor.show_library()
 editor.open_personalize(0)
 assert(editor.screen=="personalize" and editor.find_child("CoverChoice_warrior",true,false)!=null)
 assert(editor.find_child("CoverChoice_mage",true,false)==null,"Capa só usa cartas do próprio deck")
 var input=editor.find_child("PersonalizeName",true,false)
 input.text="Lua de Aço"
 input.text_changed.emit(input.text)
 editor.choose_cover("warrior")
 assert(editor.find_child("PersonalizeName",true,false).text=="Lua de Aço")
 assert(store.slots[0].name==original[0].name and store.slots[0].get("cover","")=="","Escolha não salva antes de confirmar")
 editor.show_library()
 assert(store.slots[0].name==original[0].name)
 editor.open_personalize(0)
 editor.personal_name="Lua de Aço"
 editor.choose_cover("warrior")
 assert(editor.save_personalization() and editor.screen=="library")
 assert(store.slots[0].name=="Lua de Aço" and store.cover_for(0)=="warrior")
 assert(store.slots[0].cards==original[0].cards and store.active==0)
 var reopened=Store.new(store.path)
 assert(reopened.slots[0].name=="Lua de Aço" and reopened.cover_for(0)=="warrior")
 assert(not store.save_metadata(0,"Inválida","mage") and store.cover_for(0)=="warrior")
 editor.open_personalize(4)
 editor.personal_name="Meu projeto"
 editor.choose_cover("warrior")
 assert(editor.personal_cover=="" and editor.save_personalization())
 assert(store.slots[4].name=="Meu projeto" and store.slots[4].cards.is_empty())
 editor.choose_slot(0)
 assert(editor.screen=="edit" and editor.find_child("DeckLibrary",true,false)==null)
 assert(editor.remove_card("squire"))
 editor.draft_name="Rascunho"
 editor.show_library()
 assert(editor.draft_cache[0].cards.size()==Match.DECK_SIZE-1 and store.slots[0].cards.size()==Match.DECK_SIZE)
 editor.open_personalize(0)
 editor.personal_name="Baluarte"
 assert(editor.save_personalization())
 editor.choose_slot(0)
 assert(editor.draft.size()==Match.DECK_SIZE-1 and editor.draft_name=="Baluarte","Voltar preserva rascunho na sessão")
 assert(editor.add_card("squire") and editor.save_deck() and not editor.draft_cache.has(0))
 assert(store.cover_for(0)=="warrior","Editar cartas mantém capa se ainda pertence ao deck")
 assert(editor.remove_card("warrior") and editor.remove_card("warrior"))
 assert(editor.add_card("generous_peasant") and editor.add_card("generous_peasant") and editor.save_deck())
 assert(store.slots[0].get("cover","")=="" and store.cover_for(0)=="wall_smith","Remover a carta da capa volta à arte automática")
 editor.show_library()
 var played: Array=[]
 editor.play_requested.connect(func():played.append(true))
 editor.play_saved(4)
 assert(played.is_empty() and store.active==0)
 editor.play_saved(3)
 assert(played.size()==1 and store.active==3)
 # Migration from the previous file schema preserves names, lists and active deck.
 var previous: Array=original.duplicate(true)
 for slot in previous:slot.erase("cover")
 var file:=FileAccess.open("user://test_deck_library_migration.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"version":3,"active":2,"slots":previous}));file.close()
 var migrated=Store.new("user://test_deck_library_migration.json")
 assert(migrated.slots.size()==Store.SLOT_COUNT and migrated.active==2)
 for i in range(Store.SLOT_COUNT):assert(migrated.slots[i].name==previous[i].name and migrated.slots[i].cards==previous[i].cards)
 assert(migrated.cover_for(0)=="wall_smith" and migrated.cover_for(4)=="")
 assert(JSON.parse_string(FileAccess.get_file_as_string(migrated.path)).version==Store.DECKSET_VERSION)
 editor.queue_free()
 await process_frame
 await create_timer(0.35).timeout
 var main=load("res://main.tscn").instantiate()
 main.enable_opening=false
 main.deck_store=Store.new("user://test_deck_library_game.json",false)
 root.add_child(main)
 main.open_decks()
 await process_frame
 assert(main.deck_editor.screen=="library")
 main.deck_editor.play_saved(3)
 await process_frame
 assert(not is_instance_valid(main.deck_editor) and main.deck_store.active==3 and main.can_act())
 var actual: Array=main.duel.players[0].deck.duplicate()
 actual.append_array(main.duel.players[0].hand);actual.sort()
 var expected: Array=Match.default_deck(3);expected.sort()
 assert(actual==expected,"Jogar pela biblioteca inicia a lista salva selecionada")
 var game_path: String=main.deck_store.path
 main.queue_free()
 await process_frame
 await create_timer(0.35).timeout
 DirAccess.remove_absolute(ProjectSettings.globalize_path(game_path))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(migrated.path))
 print("OK: biblioteca separada, capa por carta própria, renomear/persistir/cancelar, vazio, rascunho, edição e migração sem perda.")
 quit()
