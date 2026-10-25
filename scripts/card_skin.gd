@tool
extends RefCounted

static var cache: Dictionary = {}

static func texture(asset: String) -> Texture2D:
 if cache.has(asset):
  return cache[asset]
 var path := "res://assets/ui/%s.png" % asset
 if not ResourceLoader.exists(path):
  return null
 var source: Texture2D = load(path)
 var atlas := AtlasTexture.new()
 atlas.atlas = source
 # Ignore very faint alpha noise around generated UI sprites.
 var image := source.get_image()
 var low := image.get_size()
 var high := Vector2i.ZERO
 for y in range(0, image.get_height(), 2):
  for x in range(0, image.get_width(), 2):
   if image.get_pixel(x, y).a > 0.5:
    low.x = mini(low.x, x)
    low.y = mini(low.y, y)
    high.x = maxi(high.x, x)
    high.y = maxi(high.y, y)
 atlas.region = Rect2(Rect2i(low, high - low + Vector2i(2, 2)))
 atlas.filter_clip = true
 cache[asset] = atlas
 return atlas

static func shield(card_class: int) -> Texture2D:
 return texture(["shield-warrior", "shield-mage", "shield-neutral", "shield-rogue", "shield-cleric"][card_class])
