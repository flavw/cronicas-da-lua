extends RefCounted

static func panel(color: Color = Color("101f30"), border: Color = Color("665737"), padding: int = 10) -> StyleBoxFlat:
 var style := StyleBoxFlat.new()
 style.bg_color = color
 style.border_color = border
 style.set_border_width_all(1)
 style.set_corner_radius_all(10)
 style.content_margin_left = padding
 style.content_margin_right = padding
 style.content_margin_top = padding
 style.content_margin_bottom = padding
 style.shadow_color = Color(0, 0, 0, 0.35)
 style.shadow_size = 5
 return style

static func build() -> Theme:
 var theme := Theme.new()
 theme.default_font_size = 18
 theme.set_color("font_color", "Label", Color("e5e7e8"))
 theme.set_color("font_color", "Button", Color("f2d9a6"))
 theme.set_color("font_hover_color", "Button", Color("fff3d8"))
 theme.set_color("font_disabled_color", "Button", Color("667789"))
 theme.set_stylebox("normal", "Button", panel(Color("16273a"), Color("847044"), 8))
 theme.set_stylebox("hover", "Button", panel(Color("263e54"), Color("dfbe77"), 8))
 theme.set_stylebox("pressed", "Button", panel(Color("0c1725"), Color("e7cb8c"), 8))
 theme.set_stylebox("disabled", "Button", panel(Color("101b28"), Color("2d3b49"), 8))
 var focus := panel(Color(0, 0, 0, 0), Color("7fc5e6"), 8)
 focus.set_border_width_all(2)
 theme.set_stylebox("focus", "Button", focus)
 theme.set_stylebox("panel", "PanelContainer", panel())
 theme.set_stylebox("normal", "LineEdit", panel(Color("0a1421"), Color("665737"), 10))
 theme.set_stylebox("focus", "LineEdit", panel(Color("101f30"), Color("8ebad2"), 10))
 theme.set_color("font_color", "LineEdit", Color("ece4d5"))
 theme.set_constant("separation", "HBoxContainer", 8)
 theme.set_constant("separation", "VBoxContainer", 6)
 return theme

static func primary(button: Button) -> void:
 button.add_theme_stylebox_override("normal", panel(Color("294637"), Color("b9a96d"), 8))
 button.add_theme_stylebox_override("hover", panel(Color("3e6048"), Color("e5d194"), 8))
 button.add_theme_stylebox_override("pressed", panel(Color("1c3329"), Color("dac486"), 8))
