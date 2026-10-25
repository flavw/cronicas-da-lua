extends SceneTree
const Match = preload("res://scripts/match.gd")
const Store = preload("res://scripts/deck_store.gd")

func _initialize() -> void:
 call_deferred("verify")

func verify() -> void:
 var main = load("res://main.tscn").instantiate()
 root.add_child(main)
 var store = Store.new("user://decks_test_editor.json", false)
 main.deck_store = store
 main.open_decks()
 await process_frame
 var editor = main.deck_editor
 assert(editor != null and editor.draft.size() == 12)
 assert(not main.can_act(), "Editor bloqueia ações do duelo")
 editor.clear_draft()
 assert(editor.add_card("rogue") and editor.add_card("rogue"))
 assert(not editor.add_card("rogue"), "Editor recusa terceira cópia")
 assert(editor.draft.size() == 2)
 editor.draft_name = "Rascunho incompleto"
 assert(not editor.save_deck(), "Deck incompleto não substitui salvo")
 assert(store.slots[0].name == "Equilíbrio")
 editor.reset_draft()
 assert(editor.remove_card("squire"))
 assert(editor.add_card("rogue"))
 assert(not editor.add_card("raven"), "Deck com 12 cartas não aceita a 13ª")
 editor.draft_name = "Ladinas da Lua"
 assert(editor.save_deck())
 var saved_first: Array = store.slots[0].cards.duplicate()
 editor.choose_slot(1)
 editor.draft_name = "Meu segundo deck"
 assert(editor.save_deck())
 assert(store.slots[0].cards == saved_first, "Espaços independentes")
 editor.choose_slot(2)
 editor.draft_name = "Magia e Metal"
 editor.play_deck()
 await process_frame
 assert(main.deck_editor == null and store.active == 2)
 var actual: Array = main.duel.players[0].deck.duplicate()
 actual.append_array(main.duel.players[0].hand)
 actual.sort()
 var expected: Array = store.slots[2].cards.duplicate()
 expected.sort()
 assert(actual == expected)
 var reopened = Store.new("user://decks_test_editor.json")
 assert(reopened.slots[0].name == "Ladinas da Lua")
 assert(reopened.slots[1].name == "Meu segundo deck")
 assert(reopened.slots[2].name == "Magia e Metal" and reopened.active == 2)
 # Bad files fall back safely to complete suggested decks.
 var file := FileAccess.open(store.path, FileAccess.WRITE)
 file.store_string("not valid json")
 file.close()
 var recovered = Store.new(store.path)
 for deck in recovered.slots:
  assert(Match.valid_deck(deck.cards))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path))
 print("OK: editor limita cópias/tamanho, preserva 3 espaços, salva nomes, ativa deck e recupera arquivo inválido.")
 quit()
