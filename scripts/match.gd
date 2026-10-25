class_name DuelMatch
extends RefCounted

const CARD_DATA = {
 "warrior": preload("res://cards/warrior.tres"),
 "mage": preload("res://cards/mage.tres"),
 "squire": preload("res://cards/squire.tres"),
 "wolf": preload("res://cards/wolf.tres"),
 "rogue": preload("res://cards/rogue.tres"),
 "raven": preload("res://cards/raven.tres"),
 "sentinel": preload("res://cards/sentinel.tres"),
 "fire_mage": preload("res://cards/fire_mage.tres"),
 "farmer": preload("res://cards/farmer.tres"),
 "cleric": preload("res://cards/cleric.tres")
}
const DECK_SIZE := 12
const MAX_COPIES := 2
static var CARDS: Dictionary = build_cards()

static func build_cards() -> Dictionary:
 var result := {}
 for key in CARD_DATA:
  result[key] = CARD_DATA[key].combat_data()
 return result
var players: Array = []
var turn := 0
var winner := -1
var next_id := 0
var history: Array[String] = []
var last_action: Dictionary = {}

static func default_deck(style: int = 0) -> Array[String]:
 var result: Array[String] = []
 for key in CARD_DATA:
  result.append(key)
 var extras := [["squire", "wolf", "mage", "sentinel"], ["rogue", "raven", "wolf", "warrior"], ["mage", "fire_mage", "sentinel", "squire"]]
 for key in extras[clampi(style, 0, 2)]:
  if result.size() >= DECK_SIZE:
   break
  result.append(key)
 return result

static func valid_deck(cards: Array) -> bool:
 if cards.size() != DECK_SIZE:
  return false
 var counts := {}
 for key in cards:
  if not key is String or not CARD_DATA.has(key):
   return false
  counts[key] = int(counts.get(key, 0)) + 1
  if counts[key] > MAX_COPIES:
   return false
 return true

func _init(player_deck: Array = [], ai_deck: Array = []) -> void:
 for side in range(2):
  var deck: Array[String] = []
  var supplied: Array = player_deck if side == 0 else ai_deck
  deck.assign(supplied if valid_deck(supplied) else default_deck(side))
  deck.shuffle()
  players.append({"hp": 20, "mana": 0, "max_mana": 0, "deck": deck, "hand": [], "board": [], "fatigue": 0})
  for i in range(3):
   draw(side)
 begin_turn()

func log_event(message: String) -> void:
 history.append(message)
 if history.size() > 60:
  history.pop_front()

func draw(side: int) -> void:
 var p: Dictionary = players[side]
 if p.deck.is_empty():
  p.fatigue += 1
  p.hp -= p.fatigue
  log_event("%s sofre %d de fadiga." % [side_name(side), p.fatigue])
 elif p.hand.size() < 8:
  p.hand.append(p.deck.pop_back())
 else:
  p.deck.pop_back()
  log_event("Mão cheia: carta descartada.")
 check_winner()

func side_name(side: int) -> String:
 return "Você" if side == 0 else "IA"

func begin_turn() -> void:
 var p: Dictionary = players[turn]
 p.max_mana = mini(10, p.max_mana + 1)
 p.mana = p.max_mana
 for unit in p.board:
  unit.ready = true
  var max_block: int = CARD_DATA[unit.key].block
  unit.block = mini(max_block, int(unit.get("block", 0)) + 1)
  if unit.get("growth", 0) > 0:
   var gain: int = unit.growth
   unit.max_health = int(unit.get("max_health", CARD_DATA[unit.key].health)) + gain
   unit.health += gain
   log_event("%s ganha +%d de vida: %d/%d." % [unit.name, gain, unit.health, unit.max_health])
 draw(turn)
 log_event("Turno de %s — %d mana." % [side_name(turn), p.mana])

func end_turn(side: int) -> bool:
 if side != turn or winner != -1:
  return false
 turn = 1 - turn
 begin_turn()
 return true

func play(side: int, hand_index: int) -> bool:
 if winner != -1 or side != turn:
  return false
 var p: Dictionary = players[side]
 if hand_index < 0 or hand_index >= p.hand.size() or p.board.size() >= 5:
  return false
 var key: String = p.hand[hand_index]
 var card: Dictionary = CARDS[key]
 if p.mana < card.cost:
  return false
 p.mana -= card.cost
 p.hand.remove_at(hand_index)
 var unit: Dictionary = card.duplicate(true)
 unit.merge({"key": key, "id": next_id, "ready": card.get("swift", false), "max_health": card.health})
 next_id += 1
 p.board.append(unit)
 last_action = {"kind": "summon", "side": side, "attacker": unit.id, "dead": []}
 log_event("%s invoca %s." % [side_name(side), card.name])
 return true

static func damage(unit: Dictionary, amount: int, magical: bool = false) -> int:
 var dealt: int = amount if magical else maxi(0, amount - int(unit.armor))
 unit.health -= dealt
 return dealt

func blockers(side: int) -> Array[int]:
 var result: Array[int] = []
 for i in range(players[side].board.size()):
  if players[side].board[i].get("block", 0) > 0:
   result.append(i)
 return result

func can_target(side: int, index: int, target: int, magical: bool = false) -> bool:
 if winner != -1 or side != turn:
  return false
 var p: Dictionary = players[side]
 var foe: Dictionary = players[1 - side]
 if index < 0 or index >= p.board.size() or target < -1 or target >= foe.board.size():
  return false
 var unit: Dictionary = p.board[index]
 if not unit.ready:
  return false
 if magical:
  return unit.get("magic_damage", 0) > 0 and p.mana >= unit.get("magic_cost", 1) and target >= 0
 if unit.attack <= 0:
  return false
 var guards := blockers(1 - side)
 return unit.get("flying", false) or guards.is_empty() or target in guards

func fury(side: int, index: int) -> bool:
 if winner != -1 or side != turn or index < 0 or index >= players[side].board.size():
  return false
 var p: Dictionary = players[side]
 var unit: Dictionary = p.board[index]
 if unit.get("fury", 0) <= 0 or p.mana < 1:
  return false
 p.mana -= 1
 unit.attack += unit.fury
 last_action = {"kind": "fury", "side": side, "attacker": unit.get("id", -1), "dead": []}
 log_event("%s usa Fúria %d: ataque agora %d, sem esgotar." % [unit.name, unit.fury, unit.attack])
 return true

func can_heal(side: int, index: int, target: int) -> bool:
 if winner != -1 or side != turn:
  return false
 var p: Dictionary = players[side]
 if index < 0 or index >= p.board.size() or target < -1 or target >= p.board.size():
  return false
 var caster: Dictionary = p.board[index]
 if not caster.ready or caster.get("heal_amount", 0) <= 0 or p.mana < caster.get("heal_cost", 1):
  return false
 if target == -1:
  return p.hp > 0 and p.hp < 20
 var ally: Dictionary = p.board[target]
 return ally.health > 0 and ally.health < int(ally.get("max_health", CARD_DATA[ally.key].health))

func heal(side: int, index: int, target: int) -> bool:
 if not can_heal(side, index, target):
  return false
 var p: Dictionary = players[side]
 var caster: Dictionary = p.board[index]
 var restored: int
 if target == -1:
  restored = mini(caster.heal_amount, 20 - int(p.hp))
  p.hp += restored
 else:
  var ally: Dictionary = p.board[target]
  restored = mini(caster.heal_amount, int(ally.get("max_health", CARD_DATA[ally.key].health)) - int(ally.health))
  ally.health += restored
 p.mana -= caster.heal_cost
 caster.ready = false
 last_action = {"kind": "heal", "side": side, "attacker": caster.get("id", -1), "target": -1 if target == -1 else p.board[target].get("id", -1), "castle": target == -1, "dead": []}
 log_event("%s cura %d de vida de %s." % [caster.name, restored, "seu castelo" if target == -1 else p.board[target].name])
 return true

func act(side: int, index: int, target: int, magical: bool = false) -> bool:
 if not can_target(side, index, target, magical):
  return false
 var p: Dictionary = players[side]
 var foe: Dictionary = players[1 - side]
 if index < 0 or index >= p.board.size() or target < -1 or target >= foe.board.size():
  return false
 var unit: Dictionary = p.board[index]
 if not unit.ready:
  return false
 last_action = {"kind": "magic" if magical else "attack", "side": side, "attacker": unit.get("id", -1), "target": -1 if target == -1 else foe.board[target].get("id", -1), "castle": target == -1, "dead": []}
 unit.ready = false
 if magical:
  p.mana -= unit.magic_cost
  damage(foe.board[target], unit.magic_damage, true)
  log_event("%s causa %d dano mágico — ignora armadura, sem contra-ataque." % [unit.name, unit.magic_damage])
 elif target == -1:
  foe.hp -= unit.attack
  log_event("%s causa %d ao herói." % [unit.name, unit.attack])
 else:
  var defender: Dictionary = foe.board[target]
  if defender.get("block", 0) > 0:
   defender.block -= 1
   log_event("Bloqueio de %s consumido." % defender.name)
  var counter: int = defender.attack
  var dealt := damage(defender, unit.attack)
  var received := damage(unit, counter)
  log_event("%s ataca %s: %d dano, %d recebido." % [unit.name, defender.name, dealt, received])
 for owner in range(players.size()):
  var player: Dictionary = players[owner]
  for victim in player.board:
   if victim.health <= 0:
    last_action.dead.append({"side": owner, "id": victim.get("id", -1)})
  player.board = player.board.filter(func(u: Dictionary) -> bool: return u.health > 0)
 check_winner()
 return true

func check_winner() -> void:
 if players.size() < 2:
  return
 if players[0].hp <= 0 and players[1].hp <= 0:
  winner = 2
 elif players[0].hp <= 0:
  winner = 1
 elif players[1].hp <= 0:
  winner = 0

func ai_step() -> bool:
 if turn != 1 or winner != -1:
  return false
 var p: Dictionary = players[1]
 var enemy: Dictionary = players[0]
 # Use magic to finish creatures, especially armored ones.
 for i in range(p.board.size()):
  if p.board[i].get("heal_amount", 0) > 0:
   for j in range(p.board.size()):
    if can_heal(1, i, j) and p.board[j].health <= 2:
     return heal(1, i, j)
   if p.hp <= 12 and can_heal(1, i, -1):
    return heal(1, i, -1)
  if p.board[i].ready and p.board[i].get("magic_damage", 0) > 0 and p.mana >= p.board[i].get("magic_cost", 1):
   for j in range(enemy.board.size()):
    if enemy.board[j].health <= p.board[i].magic_damage:
     return act(1, i, j, true)
 for i in range(p.hand.size()):
  if p.mana >= CARDS[p.hand[i]].cost and p.board.size() < 5:
   return play(1, i)
 for i in range(p.board.size()):
  var u: Dictionary = p.board[i]
  if not u.ready:
   continue
  if u.attack == 0:
   if u.get("magic_damage", 0) > 0 and p.mana >= u.get("magic_cost", 1) and not enemy.board.is_empty():
    return act(1, i, 0, true)
   continue
  if enemy.hp <= u.attack and can_target(1, i, -1):
   return act(1, i, -1)
  if u.get("fury", 0) > 0 and p.mana >= 1 and not enemy.board.is_empty() and u.attack <= 2:
   return fury(1, i)
  if u.get("magic_damage", 0) > 0 and p.mana >= u.get("magic_cost", 1) and not enemy.board.is_empty():
   for j in range(enemy.board.size()):
    if enemy.board[j].armor > 0:
     return act(1, i, j, true)
  for j in range(enemy.board.size()):
   var v: Dictionary = enemy.board[j]
   if can_target(1, i, j) and maxi(0, u.attack - v.armor) >= v.health and maxi(0, v.attack - u.armor) < u.health:
    return act(1, i, j)
  var guards := blockers(0)
  if not guards.is_empty() and not u.get("flying", false):
   return act(1, i, guards[0])
  if can_target(1, i, -1):
   return act(1, i, -1)
 return false
