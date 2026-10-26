extends Control

var kind: String
var amount: int=0
var progress: float=0.0:
 set(value):
  progress=value
  queue_redraw()

func configure(effect: String,rect: Rect2,value: int=0) -> void:
 kind=effect;amount=value
 position=rect.position;size=rect.size
 mouse_filter=Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
 var fade: float=sin(progress*PI)
 var center:=size*0.5
 var radius: float=minf(size.x,size.y)*0.38
 if kind=="block":
  draw_rect(Rect2(Vector2.ZERO,size),Color(1.0,0.85,0.3,fade*0.22))
  draw_rect(Rect2(Vector2(2,2),size-Vector2(4,4)),Color(1.0,0.85,0.35,fade),false,6)
  var c:=center+Vector2(0,-12)
  var shield:=PackedVector2Array([c+Vector2(-19,-22),c+Vector2(19,-22),c+Vector2(17,8),c+Vector2(0,25),c+Vector2(-17,8),c+Vector2(-19,-22)])
  draw_colored_polygon(shield,Color(0.15,0.22,0.32,fade*.8))
  draw_polyline(shield,Color(1,0.9,0.5,fade),3,true)
  return
 var tint:=Color("7bf2b0") if kind in ["heal","attack_buff"] else Color("ffc370") if kind=="arcane_area" else Color("acde58")
 tint.a=fade
 draw_arc(center,radius*(0.7+progress*.5),0,TAU,48,Color(tint,fade*.65),3,true)
 for i in range(7):
  var angle: float=TAU*i/7.0
  var at:=center+Vector2(cos(angle)*radius*.65,sin(angle)*radius*.35)-Vector2(0,progress*45)
  if kind=="heal":
   draw_line(at-Vector2(5,0),at+Vector2(5,0),tint,3,true)
   draw_line(at-Vector2(0,5),at+Vector2(0,5),tint,3,true)
  else:
   draw_circle(at,3.0+sin(progress*PI+i)*1.4,tint)
   draw_circle(at,6.0,Color(0.4,0.15,0.6,fade*.4),false,1,true)
 if amount>0:
  var text: String=("+" if kind=="heal" else "−" if kind in ["poison_tick","arcane_area"] else "+")+str(amount)
  draw_string(ThemeDB.fallback_font,center+Vector2(-12,-progress*30),text,HORIZONTAL_ALIGNMENT_LEFT,-1,24,tint)
