extends SceneTree
const Match=preload("res://scripts/match.gd")
const Store=preload("res://scripts/deck_store.gd")
func unit(key: String,id: int) -> Dictionary:
 var u: Dictionary=Match.CARDS[key].duplicate(true)
 u.merge({"key":key,"id":id,"ready":false,"max_health":u.health,"poison":0})
 return u
func fixture(key: String):
 var m=Match.new()
 for p in m.players:p.board=[];p.hand=[];p.mana=10
 m.players[0].hand=[key]
 m.next_id=100
 return m
func _init() -> void:
 assert(Match.CARD_DATA.size()==38)
 for style in range(4):
  var cards: Array=Match.default_deck(style)
  assert(Match.valid_deck(cards))
  var key: String=["wall_smith","mist_alchemist","aether_summoner","dawn_oracle"][style]
  assert(cards.count(key)==2)
 var m=fixture("wall_smith")
 var ally=unit("squire",1)
 m.players[0].board=[ally]
 assert(not m.play(0,0) and m.players[0].mana==10)
 assert(m.play(0,0,0) and ally.armor==1 and ally.block==1 and not ally.ready)
 m.players[0].hand=["wall_smith"]
 assert(m.play(0,0,0) and ally.armor==2)
 m.end_turn(0);m.end_turn(1)
 assert(ally.armor==2,"Armadura é permanente e Chamado não repete")
 m=fixture("wall_smith")
 assert(m.play(0,0) and m.players[0].board.size()==1 and m.players[0].board[0].armor==0)
 m=fixture("aether_summoner")
 var hand_size: int=m.players[0].hand.size()
 var deck_size: int=m.players[0].deck.size()
 assert(m.play(0,0) and m.players[0].board.size()==2 and m.players[0].mana==6)
 assert(m.players[0].board[0].key=="aether_summoner" and m.players[0].board[1].key=="runic_familiar")
 assert(m.players[0].board[0].id!=m.players[0].board[1].id and not m.players[0].board[1].ready)
 assert(m.players[0].board[1].attack==0 and m.players[0].board[1].health==3 and m.magic_bonus(0)==1)
 assert(m.players[0].hand.size()==hand_size-1 and m.players[0].deck.size()==deck_size)
 m.players[0].board[1].health=0
 assert(m.magic_bonus(0)==0,"Aura acaba quando Familiar morre")
 for occupied in [4,5,6]:
  m=fixture("aether_summoner")
  for i in range(occupied):m.players[0].board.append(unit("wolf",i))
  if occupied==6:
   assert(not m.play(0,0) and m.players[0].mana==10)
  else:
   assert(m.play(0,0) and m.players[0].board.size()==6)
   assert((occupied==4)==m.last_action.has("spawned"))
 m=fixture("mist_alchemist")
 var foe=unit("wall_guard",1)
 foe.poison=1
 m.players[1].board=[foe]
 m.players[0].board=[unit("wolf",2)]
 assert(Match.entry_target_side(0,Match.CARDS.mist_alchemist)==1)
 assert(not m.play(0,0) and m.players[0].mana==10)
 assert(m.play(0,0,0) and foe.poison==3 and foe.health==4 and foe.block==2)
 assert(m.players[0].board[0].poison==0 and m.players[1].hp==20)
 m.end_turn(0)
 assert(foe.health==4)
 m.end_turn(1)
 assert(foe.health==1 and foe.poison==0,"Veneno do Chamado acumula e ignora Armadura no fim do turno do alvo")
 m=fixture("mist_alchemist")
 m.players[0].board=[unit("wolf",2)]
 assert(m.play(0,0) and m.players[1].hp==20 and m.players[1].poison==0)
 m=fixture("dawn_oracle")
 ally=unit("cleric",1);ally.health=1;ally.poison=1
 m.players[0].board=[ally]
 assert(m.play(0,0,0) and ally.attack==1 and ally.health==3 and ally.max_health==6 and ally.poison==1 and not ally.ready)
 assert(Match.physical_attack(ally)==3 and Match.physical_attack(m.players[0].board[1])==3)
 # The same production AI chooses an enemy for poison and an ally for armor/life.
 for key in ["wall_smith","mist_alchemist","dawn_oracle","aether_summoner"]:
  m=fixture(key);m.turn=1
  m.players[1].hand=[key];m.players[1].board=[unit("cleric",1)]
  m.players[0].board=[unit("squire",2)]
  assert(m.ai_step() and m.last_action.kind=="summon")
  if key=="mist_alchemist":assert(m.players[0].board[0].poison==2 and m.players[1].board[0].poison==0)
 var store=Store.new("user://test_call_deck_reset.json",false)
 var file:=FileAccess.open(store.path,FileAccess.WRITE)
 var old: Array=store.slots.duplicate(true)
 old[0].name="Deck antigo"
 file.store_string(JSON.stringify({"version":1,"active":2,"slots":old}));file.close()
 var reset=Store.new(store.path)
 assert(reset.active==0 and reset.slots[0].name=="Muralha Lunar")
 var persisted=JSON.parse_string(FileAccess.get_file_as_string(store.path))
 assert(persisted.version==Store.DECKSET_VERSION and persisted.slots[0].cards==Match.default_deck(0))
 assert(reset.save_slot(0,"Minha edição",Match.default_deck(3)))
 var reopened=Store.new(store.path)
 assert(reopened.slots[0].name=="Minha edição" and reopened.slots[0].cards==Match.default_deck(3),"Troca ocorre uma vez e preserva edições novas")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path))
 print("OK: quatro Chamados, alvo aliado/inimigo, aura e limite de espaço, veneno, vida/Vigor, IA, quatro receitas e troca única de decks.")
 quit()
