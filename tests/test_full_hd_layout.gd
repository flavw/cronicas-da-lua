extends SceneTree
const Store=preload("res://scripts/deck_store.gd")
const Match=preload("res://scripts/match.gd")
func _initialize() -> void:call_deferred("verify")
func settle() -> void:
 for i in range(6):await process_frame
func inside(node: Control) -> bool:
 return root.get_visible_rect().grow(1).encloses(node.get_global_rect())
func verify() -> void:
 assert(ProjectSettings.get_setting("display/window/size/viewport_width")==1920 and ProjectSettings.get_setting("display/window/size/viewport_height")==1080)
 assert(ProjectSettings.get_setting("display/window/stretch/aspect")=="keep" and ProjectSettings.get_setting("display/window/size/mode")==3)
 root.size=Vector2i(1920,1080);root.content_scale_size=Vector2i(1920,1080)
 var menu=load("res://start_menu.tscn").instantiate();root.add_child(menu);await settle()
 assert(inside(menu.find_child("GameTitle",true,false)) and inside(menu.find_child("PlayAI",true,false)))
 menu.queue_free();await process_frame
 var main=load("res://main.tscn").instantiate();main.enable_opening=false;main.muted=true;root.add_child(main)
 main.duel.players[0].board=[];main.duel.players[1].board=[]
 for side in range(2):
  for key in ["dawn_warden","wolf","farmer","village_leader","squire"]:main.duel.spawn_unit(side,key)
 main.duel.players[0].hand=["wolf","wolf","mage","mage","fireball","fireball","squire","squire"]
 main.duel.players[0].mana=10;main.redraw();await settle()
 for name in ["EnemyCastle","PlayerCastle","BattleCommands","BattleFooter","PlayerHandPanel","CombatSettings"]:assert(inside(main.find_child(name,true,false)),name)
 for card in main.find_children("HandCard_*","Control",true,false):assert(inside(card) and card.size.x>=144)
 main.duel.players[0].board[0].ready=true;main.select(0);await settle()
 assert(inside(main.find_child("BattleCommands",true,false)))
 main.queue_free();await process_frame
 var store=Store.new("user://unused_full_hd.json",false)
 var editor=load("res://deck_editor.tscn").instantiate();editor.configure(store);root.add_child(editor);await settle()
 var library=editor.find_child("DeckLibrary",true,false)
 assert(library.columns==5 and inside(library) and library.get_child_count()==9)
 editor.choose_slot(0);await settle()
 assert(editor.find_child("CollectionGrid",true,false).columns==5)
 for node in editor.collection_tiles.values():assert(node.get_global_rect().end.x<=root.get_visible_rect().size.x)
 editor.queue_free();await process_frame;await create_timer(0.35).timeout
 print("OK: base 1920x1080/16:9, telas inicial/duelo, mão cheia e ações sem cortes, biblioteca/coleção com 5 colunas.")
 quit()
