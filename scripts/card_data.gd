@tool
class_name CardData
extends Resource

enum CardClass { WARRIOR, MAGE, NEUTRAL, ROGUE, CLERIC }
@export var title: String = "Nova carta":
 set(value):
  title = value
  emit_changed()
@export_range(0, 10) var cost: int = 1:
 set(value):
  cost = value
  emit_changed()
@export var attack: int = 1:
 set(value):
  attack = value
  emit_changed()
@export var health: int = 2:
 set(value):
  health = value
  emit_changed()
@export var armor: int = 0:
 set(value):
  armor = value
  emit_changed()
@export var card_class: CardClass = CardClass.NEUTRAL:
 set(value):
  card_class = value
  emit_changed()
@export_range(0, 10) var block: int = 0:
 set(value):
  block = value
  emit_changed()
@export_range(0, 10) var fury: int = 0:
 set(value):
  fury = value
  emit_changed()
@export var swift: bool = false:
 set(value):
  swift = value
  emit_changed()
@export var flying: bool = false:
 set(value):
  flying = value
  emit_changed()
@export_range(0, 10) var magic_damage: int = 0:
 set(value):
  magic_damage = value
  emit_changed()
@export_range(0, 10) var magic_cost: int = 1:
 set(value):
  magic_cost = value
  emit_changed()
@export_range(0, 10) var growth: int = 0:
 set(value):
  growth = value
  emit_changed()
@export_range(0, 10) var heal_amount: int = 0:
 set(value):
  heal_amount = value
  emit_changed()
@export_range(0, 10) var heal_cost: int = 1:
 set(value):
  heal_cost = value
  emit_changed()
@export_multiline var ability_text: String = "Sem habilidades":
 set(value):
  ability_text = value
  emit_changed()
@export var artwork: Texture2D:
 set(value):
  artwork = value
  emit_changed()
@export_range(1.0, 2.0, 0.01) var artwork_zoom: float = 1.0:
 set(value):
  artwork_zoom = clampf(value, 1.0, 2.0)
  emit_changed()
@export var artwork_focus: Vector2 = Vector2(0.5, 0.5):
 set(value):
  artwork_focus = value.clamp(Vector2.ZERO, Vector2.ONE)
  emit_changed()

func combat_data() -> Dictionary:
 return {"name": title, "cost": cost, "attack": attack, "health": health, "armor": armor, "block": block, "fury": fury, "swift": swift, "flying": flying, "magic_damage": magic_damage, "magic_cost": magic_cost, "growth": growth, "heal_amount": heal_amount, "heal_cost": heal_cost}
