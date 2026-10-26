extends SceneTree
const Match=preload("res://scripts/match.gd")
func _initialize() -> void:call_deferred("verify")
func verify() -> void:
 for reduced in [false,true]:
  var view=load("res://field_card.tscn" if reduced else "res://card_model.tscn").instantiate()
  if reduced:view.set_card(Match.CARD_DATA.cleric,4,true,false,1)
  else:view.set_card(Match.CARD_DATA.cleric,4,1)
  root.add_child(view)
  await process_frame
  var stats=view.get_node("Canvas/Stats" if reduced else "CardCanvas/Stats")
  assert(stats.text=="1/4" and stats.values[2]==1,"Vigor não converte a vida no ataque exibido")
  if reduced:view.set_card(Match.CARD_DATA.cleric,2,true,false,1)
  else:view.set_card(Match.CARD_DATA.cleric,2,1)
  assert(stats.text=="1/2","Ferimento altera apenas a vida exibida")
  if not reduced:
   var gem: Control=view.get_node("CardCanvas/CostGem")
   var value: Control=view.get_node("CardCanvas/Cost")
   assert(value.position.y==gem.position.y-3)
  view.queue_free()
  await process_frame
 var card=load("res://card_model.tscn").instantiate()
 card.ability_context={"vigor":true}
 card.set_card(Match.CARD_DATA.farmer,5,0)
 root.add_child(card)
 await process_frame
 assert(card.get_node("CardCanvas/Stats").text=="0/5")
 assert(card.view_entries().any(func(e):return e.name=="Vigor" and "ataque e defesa" in e.description))
 card.set_card(Match.CARD_DATA.fire_mage)
 var rows: Control=card.get_node("CardCanvas/Ability")
 var badge=rows.find_child("AbilityManaCost",true,false)
 assert(badge.get_child(1).text=="1" and badge.get_child(1).position.y==-2)
 card.queue_free()
 await process_frame
 print("OK: mana com centralização óptica, ataque de Vigor sem conversão visual, ferimentos, Vigor concedido e Disparo Arcano 2 custo 1.")
 quit()
