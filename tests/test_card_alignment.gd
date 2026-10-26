extends SceneTree
const Match=preload("res://scripts/match.gd")
func _initialize() -> void:
 call_deferred("verify")
func verify() -> void:
 for reduced in [false,true]:
  var view=load("res://field_card.tscn" if reduced else "res://card_model.tscn").instantiate()
  if reduced:
   view.set_card(Match.CARD_DATA.warrior,1,true,false,12)
  else:
   view.set_card(Match.CARD_DATA.warrior,1,12)
  root.add_child(view)
  await process_frame
  await process_frame
  var canvas: Control=view.get_node("Canvas" if reduced else "CardCanvas")
  var stats: Control=canvas.get_node("Stats")
  assert(not canvas.has_node("Shield"),"Sem escudo decorativo")
  assert(stats.get_rect().end.x <= canvas.size.x-10,"Atributos respeitam margem direita")
  var first: Control=stats.get_child(0)
  var last: Control=stats.get_child(2)
  var group_center: float=(first.position.x+last.position.x+last.size.x)*0.5
  assert(absf(group_center-stats.size.x*0.5)<0.5,"Números de larguras diferentes mantêm o centro")
  assert(is_equal_approx(first.position.y,last.position.y))
  assert(is_equal_approx(first.size.y,last.size.y),"Ataque e vida compartilham a linha de base")
  if not reduced:
   var title: Label=canvas.get_node("Title")
   assert(title.horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER)
   assert(is_equal_approx(title.get_rect().get_center().x,180.0))
   var ability: Control=canvas.get_node("Ability")
   assert(is_equal_approx(ability.get_rect().get_center().x,180.0))
   assert(ability.get_child(0).alignment==BoxContainer.ALIGNMENT_CENTER)
   var fade: GradientTexture2D=canvas.get_node("RulesPanel").texture
   assert(fade.gradient.get_color(fade.gradient.get_point_count()-1).a<0.8)
  view.queue_free()
  await process_frame
 print("OK: textos centrais, degradê suave e atributos em texto alinhados em cartas completas e reduzidas.")
 quit()
