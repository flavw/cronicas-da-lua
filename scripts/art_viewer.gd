extends CanvasLayer

var artwork: TextureRect

static func is_open(owner: Node) -> bool:
 var tree_root := owner.get_tree().root
 return tree_root.has_meta("card_art_viewer") and is_instance_valid(tree_root.get_meta("card_art_viewer"))

static func open(owner: Node, texture: Texture2D) -> void:
 if texture == null or is_open(owner):
  return
 var viewer = load("res://scripts/art_viewer.gd").new()
 owner.get_tree().root.add_child(viewer)
 viewer.artwork.texture = texture
 owner.get_tree().root.set_meta("card_art_viewer",viewer)

func _ready() -> void:
 layer = 90
 var backdrop := ColorRect.new()
 backdrop.color = Color(0.008,0.012,0.02,1.0)
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
 add_child(backdrop)
 artwork = TextureRect.new()
 artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
 backdrop.add_child(artwork)
 artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 artwork.offset_left=40
 artwork.offset_top=28
 artwork.offset_right=-40
 artwork.offset_bottom=-28

func _input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.pressed:
  close()
 elif event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  close()
 get_viewport().set_input_as_handled()

func close() -> void:
 if get_tree().root.get_meta("card_art_viewer",null)==self:
  get_tree().root.remove_meta("card_art_viewer")
 queue_free()
