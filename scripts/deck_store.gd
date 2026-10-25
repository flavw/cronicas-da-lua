class_name DeckStore
extends RefCounted

const Match = preload("res://scripts/match.gd")
const SLOT_COUNT := 3
var slots: Array = []
var active := 0
var path: String
var error_message := ""

func _init(storage_path: String = "user://decks.json", read_saved: bool = true) -> void:
 path = storage_path
 var names := ["Equilíbrio", "Assalto", "Arcano"]
 for i in range(SLOT_COUNT):
  slots.append({"name": names[i], "cards": Match.default_deck(i)})
 if read_saved:
  load_saved()

func load_saved() -> void:
 if not FileAccess.file_exists(path):
  return
 var file := FileAccess.open(path, FileAccess.READ)
 if not file:
  return
 var parser := JSON.new()
 if parser.parse(file.get_as_text()) != OK:
  return
 var data = parser.data
 if not data is Dictionary or not data.get("slots") is Array or data.slots.size() != SLOT_COUNT:
  return
 for i in range(SLOT_COUNT):
  var slot = data.slots[i]
  if slot is Dictionary and slot.get("name") is String and slot.get("cards") is Array and Match.valid_deck(slot.cards):
   slots[i] = {"name": clean_name(slot.name, i), "cards": slot.cards.duplicate()}
 var saved_active = data.get("active", 0)
 if (saved_active is int or saved_active is float) and saved_active >= 0 and saved_active < SLOT_COUNT:
  active = int(saved_active)

func clean_name(value: String, slot: int) -> String:
 var trimmed := value.strip_edges().left(24)
 return "Deck %d" % (slot + 1) if trimmed.is_empty() else trimmed

func persist() -> bool:
 var file := FileAccess.open(path, FileAccess.WRITE)
 if not file:
  error_message = "Não foi possível salvar os decks no computador."
  return false
 file.store_string(JSON.stringify({"version": 1, "active": active, "slots": slots}, "  "))
 file.flush()
 if file.get_error() != OK:
  error_message = "Ocorreu um erro ao salvar os decks."
  return false
 error_message = ""
 return true

func save_slot(slot: int, name: String, cards: Array) -> bool:
 if slot < 0 or slot >= SLOT_COUNT or not Match.valid_deck(cards):
  error_message = "Use 12 cartas, com no máximo 2 cópias de cada."
  return false
 var previous: Dictionary = slots[slot].duplicate(true)
 slots[slot] = {"name": clean_name(name, slot), "cards": cards.duplicate()}
 if not persist():
  slots[slot] = previous
  return false
 return true

func activate(slot: int) -> bool:
 if slot < 0 or slot >= SLOT_COUNT:
  return false
 var previous := active
 active = slot
 if not persist():
  active = previous
  return false
 return true

func active_cards() -> Array:
 return slots[active].cards.duplicate()
