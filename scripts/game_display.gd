extends Node

static func is_fullscreen(window: Window) -> bool:
 return window.mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN]

static func toggle(window: Window) -> void:
 if is_fullscreen(window):
  window.mode=Window.MODE_WINDOWED
  var bounds:=DisplayServer.screen_get_usable_rect(window.current_screen)
  var factor: float=minf(1.0,minf(bounds.size.x/1600.0,bounds.size.y/900.0)*0.95)
  window.size=Vector2i(Vector2(1600,900)*factor)
  window.position=bounds.position+(bounds.size-window.size)/2
 else:window.mode=Window.MODE_FULLSCREEN
 for control in window.get_tree().get_nodes_in_group("display_mode_buttons"):
  control.text="Modo janela · F11" if is_fullscreen(window) else "Tela cheia · F11"

func _input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F11:
  toggle(get_window())
  get_viewport().set_input_as_handled()
