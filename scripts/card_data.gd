@tool
class_name CardData
extends Resource

@export var legendary: bool=false:
 set(value):
  legendary=value
  emit_changed()
@export var collective: bool=false:
 set(value):
  collective=value
  emit_changed()

func copy_limit() -> int:
 return 1 if legendary else 2

enum CardClass { WARRIOR, MAGE, NEUTRAL, ROGUE, CLERIC, HORDE }
enum CreatureType { HUMAN, BEAST, ARTIFACT, MONSTER, UNDEAD }
@export var collectible: bool = true:
 set(value):
  collectible=value
  emit_changed()
@export var horde_deck_allowed: bool = false:
 set(value):
  horde_deck_allowed=value
  emit_changed()
@export var creature_type: CreatureType = CreatureType.HUMAN:
 set(value):
  creature_type=value
  emit_changed()

func creature_type_name() -> String:
 return "Magia" if card_type==CardType.SPELL else ["Humano","Fera","Artefato","Monstro","Morto-vivo"][creature_type]

func is_human() -> bool:
 return card_type==CardType.CREATURE and creature_type==CreatureType.HUMAN
enum CardType { CREATURE, SPELL }
enum SpellEffect { NONE, FORTIFY, ARCANE, SHADOW_STEP, RESTORE, VIGOR, CONDUCTIVE, RECONSTRUCT, AREA_ARCANE, HORDE_ROAR }
@export_range(0,10) var spores: int=0:
 set(value):
  spores=value
  emit_changed()
@export_range(0,10) var regeneration: int=0:
 set(value):
  regeneration=value
  emit_changed()

enum AuraEffect { NONE, ATTACK }
enum AuraTargets { ALLIED_NEUTRALS, ALLIES }
@export var aura_effect: AuraEffect = AuraEffect.NONE:
 set(value):
  aura_effect=value
  emit_changed()
@export_range(0,10) var aura_value: int = 0:
 set(value):
  aura_value=value
  emit_changed()
@export var aura_targets: AuraTargets = AuraTargets.ALLIED_NEUTRALS:
 set(value):
  aura_targets=value
  emit_changed()
@export var aura_includes_self: bool = true:
 set(value):
  aura_includes_self=value
  emit_changed()

enum EntryEffect { NONE, BUFF_ALLY, ARMOR_ALLY, SUMMON, POISON_ENEMY, BUFF_OTHER_ALLIES, SUMMON_AFTER_ENEMY_HUMAN_DEATH }
@export_range(0,10) var entry_value: int = 0:
 set(value):
  entry_value=value
  emit_changed()
@export var entry_summon_key: String = "":
 set(value):
  entry_summon_key=value
  emit_changed()
@export var entry_effect: EntryEffect = EntryEffect.NONE:
 set(value):
  entry_effect = value
  emit_changed()
@export_range(0,10) var entry_health: int = 0:
 set(value):
  entry_health = value
  emit_changed()
@export_range(0,10) var entry_attack: int = 0:
 set(value):
  entry_attack = value
  emit_changed()
@export var vigor: bool = false:
 set(value):
  vigor = value
  emit_changed()
@export_range(0,10) var envenom: int = 0:
 set(value):
  envenom = value
  emit_changed()
@export var card_type: CardType = CardType.CREATURE:
 set(value):
  card_type = value
  emit_changed()
@export var spell_effect: SpellEffect = SpellEffect.NONE:
 set(value):
  spell_effect = value
  emit_changed()
@export_range(0,10) var spell_value: int = 0:
 set(value):
  spell_value = value
  emit_changed()
@export_range(0,10) var spell_secondary: int = 0:
 set(value):
  spell_secondary = value
  emit_changed()
@export_range(0,5) var magic_power: int = 0:
 set(value):
  magic_power = value
  emit_changed()
@export var neutral_deck_only: bool = false:
 set(value):
  neutral_deck_only=value
  emit_changed()
@export var wall: bool = false:
 set(value):
  wall=value
  emit_changed()
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
@export_range(0, 10) var abascanto: int = 0:
 set(value):
  abascanto=value
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
@export_range(0, 10) var devotion: int = 0:
 set(value):
  devotion=value
  emit_changed()
@export_range(0, 10) var harvest: int = 0:
 set(value):
  harvest=value
  emit_changed()
@export_range(0, 10) var commerce: int = 0:
 set(value):
  commerce=value
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
@export var ability_name_override: String = "":
 set(value):
  ability_name_override = value
  emit_changed()
@export_multiline var ability_help_override: String = "":
 set(value):
  ability_help_override = value
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
 return {"name": title,"creature_type":creature_type,"horde_deck_allowed":horde_deck_allowed,"legendary":legendary,"collective":collective, "card_class":card_class, "neutral_deck_only":neutral_deck_only, "cost": cost, "attack": attack, "health": health, "armor": armor, "abascanto":abascanto, "block": block, "fury": fury, "swift": swift, "flying": flying, "magic_damage": magic_damage, "magic_cost": magic_cost, "growth": growth,"spores":spores,"regeneration":regeneration,"harvest":harvest,"commerce":commerce,"devotion":devotion, "heal_amount": heal_amount, "heal_cost": heal_cost, "card_type":card_type, "spell_effect":spell_effect, "spell_value":spell_value, "spell_secondary":spell_secondary, "magic_power":magic_power,"wall":wall,"vigor":vigor,"envenom":envenom,"entry_attack":entry_attack,"entry_health":entry_health,"entry_effect":entry_effect,"entry_value":entry_value,"entry_summon_key":entry_summon_key,"aura_effect":aura_effect,"aura_value":aura_value,"aura_targets":aura_targets,"aura_includes_self":aura_includes_self}
func ability_entries(remaining_block: int = -1, magic_bonus: int = 0, remaining_armor: int = -1, granted_vigor: bool = false, poison_stacks: int = 0, received_aura_attack: int = 0, remaining_abascanto: int = -1) -> Array[Dictionary]:
 var entries: Array[Dictionary] = []
 if horde_deck_allowed:
  entries.append({"name":"Pacto Sombrio","icon":"class-horde","description":"Pode entrar em decks da Horda mesmo sendo Humana. Continua sendo do tipo Humano."})
 if legendary:
  entries.append({"name":"Lendária","icon":"legendary-icon","description":"Apenas 1 cópia desta carta por deck."})
 if collective:
  entries.append({"name":"Multidão","icon":"collective-icon","badge":"Collective","value":attack,"description":"Ataque e vida base iguais ao número de neutros aliados em campo, incluindo esta criatura. Herda as habilidades dos OUTROS NEUTROS ALIADOS, exceto Chamados. Valores compatíveis somam; habilidades únicas não acumulam. Atualiza enquanto as fontes estiverem em campo. Bônus permanentes e dano sofrido são preservados. Não copia outras Multidões nem raridade."})
 if card_type == CardType.SPELL:
  var entry := {"cost":cost,"spell":true,"name":"Magia","description":"Escolha um efeito de magia no campo Spell Effect do Inspector."}
  match spell_effect:
   SpellEffect.HORDE_ROAR:
    entry.merge({"name":"Monstros: ataque +%d neste turno" % spell_value,"icon":"fury-icon","description":"Todos os seus aliados do tipo Monstro que já estão em campo ganham +%d de ataque até o fim deste turno. Não afeta Humanos, Feras, Artefatos ou Mortos-vivos. Bônus acumulam e expiram juntos; não deixa criaturas prontas." % spell_value},true)
   SpellEffect.AREA_ARCANE:
    entry.merge({"name":"Dano em área %d" % (spell_value+magic_bonus),"icon":"arcane-icon","description":"Cause %d de dano mágico a todas as criaturas inimigas. Ignora Armadura, sem contra-ataque." % (spell_value+magic_bonus)},true)
   SpellEffect.RECONSTRUCT:
    entry.merge({"name":"Restaurar %d" % spell_secondary,"icon":"rebuild-icon","description":"Restaure %d de vida do seu castelo ou de uma Muralha aliada. Reconstrução pode reparar Muralhas mesmo que não recebam cura comum." % spell_secondary},true)
   SpellEffect.VIGOR:
    entry.merge({"name":"Conceder Vigor","icon":"vigor-icon","description":"Concede Vigor permanente a um aliado que ainda não tenha essa habilidade. Não acumula."},true)
   SpellEffect.CONDUCTIVE:
    entry.merge({"name":"Descarga %d/%d" % [spell_value+magic_bonus,(spell_value+magic_bonus)*2],"icon":"lightning-icon","description":"Cause %d de dano mágico a uma criatura inimiga. Se ela tiver Armadura maior que zero, dobre o dano para %d. O bônus de Amplificar entra antes da multiplicação. Armadura não é subtraída do dano. Não atinge castelos e não há contra-ataque." % [spell_value+magic_bonus,(spell_value+magic_bonus)*2]},true)
   SpellEffect.FORTIFY:
    entry.merge({"name":"Fortificar","icon":"armor-icon","description":"Um aliado ganha +%d de ataque e +%d de Armadura permanentemente." % [spell_value,spell_secondary]},true)
   SpellEffect.ARCANE:
    entry.merge({"name":"Chama Arcana %d" % (spell_value+magic_bonus),"icon":"arcane-icon","description":"Cause %d de dano mágico a uma criatura inimiga. Ignora Armadura e Bloqueio, sem contra-ataque." % (spell_value+magic_bonus)},true)
   SpellEffect.SHADOW_STEP:
    entry.merge({"name":"Passo Sombrio","icon":"shadow-step-icon","description":"Um aliado ganha +%d de ataque permanente e fica pronto para agir novamente." % spell_value},true)
   SpellEffect.RESTORE:
    entry.merge({"name":"Restaurar %d" % spell_value,"icon":"heal-icon","description":"Cure %d de vida de uma criatura aliada ou do seu castelo. Remove Veneno dos vivos. Em Mortos-vivos de qualquer lado, causa esse valor de dano mágico, ignorando Armadura, sem curar ou remover Veneno; Abascanto pode anular." % spell_value},true)
  if not ability_name_override.is_empty(): entry.name = ability_name_override
  if not ability_help_override.is_empty(): entry.description = ability_help_override
  entries.append(entry)
  if spell_effect==SpellEffect.RECONSTRUCT:
   entries.append({"name":"Campo neutro: compre 1","icon":"draw-icon","description":"Se todas as suas criaturas em campo forem neutras, compre 1 carta. Campo vazio também ativa o efeito."})
  if neutral_deck_only:
   entries.append({"name":"Só deck neutro","description":"Seu deck original precisa conter apenas cartas neutras. A restrição vale na montagem e na conjuração, mesmo depois que as cartas forem compradas ou saírem do campo."})
  return entries
 if aura_effect!=AuraEffect.NONE:
  var group: String="todos os seus neutros em campo" if aura_targets==AuraTargets.ALLIED_NEUTRALS else "todos os seus aliados em campo"
  var self_note: String=" Inclui esta criatura." if aura_includes_self else " Não inclui esta criatura."
  entries.append({"name":"Aura","icon":"aura-icon","badge":"Aura","value":aura_value,"summary":aura_summary(),"description":"Enquanto estiver em campo, %s recebem +%d de ataque.%s Acumula com outras Auras; termina quando a fonte sai do campo." % [group,aura_value,self_note]})
 if entry_effect!=EntryEffect.NONE:
  var details: String="Ao entrar pela mão, ativa o efeito uma vez."
  if entry_effect==EntryEffect.BUFF_ALLY:
   details+="\nConcede %s permanente a outro aliado. A vida aumenta a atual e a máxima. Sem outro aliado, entra sem bônus." % entry_summary()
  elif entry_effect==EntryEffect.ARMOR_ALLY:
   details+="\nOutro aliado ganha +%d de Armadura permanente. Sem outro aliado, entra sem bônus." % entry_value
  elif entry_effect==EntryEffect.SUMMON_AFTER_ENEMY_HUMAN_DEATH:
   details+="\nSe ao menos um Humano inimigo morreu nesta partida, invoque um Carniçal 2/2 Morto-vivo. Precisa de espaço no campo depois da invocação desta criatura. Sem a condição, entra normalmente sem invocar."
  elif entry_effect==EntryEffect.SUMMON:
   details+="\nInvoca um Familiar Rúnico 0/3, Amplificar 1, se houver espaço. Ele entra esgotado."
  elif entry_effect==EntryEffect.POISON_ENEMY:
   details+="\nAplica Veneno %d a uma criatura inimiga. Sem inimigos, entra sem aplicar o efeito." % entry_value
  elif entry_effect==EntryEffect.BUFF_OTHER_ALLIES:
   details+="\nConceda +%d de ataque e +%d de vida atual e máxima permanentemente a todos os OUTROS aliados, de qualquer classe. Não afeta esta criatura, inimigos ou castelos. Preserva dano anterior e prontidão." % [entry_attack,entry_health]
  entries.append({"name":"Chamado","icon":"entry-icon","badge":"Entry","summary":entry_summary(),"description":details})
 if wall:
  entries.append({"name":"Muralha","icon":"wall-icon","badge":"Wall","description":"Imune a Veneno. Não pode receber cura comum nem declarar ataques. Reconstrução pode repará-la."})
 if vigor or granted_vigor:
  entries.append({"name":"Vigor","badge":"Vigor","icon":"vigor-icon","description":"No ataque e defesa, usa o maior valor entre ataque e vida atual. Vale contra castelos, sem alterar o ataque exibido."})
 if magic_power > 0:
  entries.append({"name":"Amplificar %d" % magic_power,"badge":"Amplify","value":magic_power,"icon":"amplify-icon","description":"Enquanto esta criatura estiver em campo, as magias e habilidades de dano mágico aliadas causam +%d de dano. Soma com outras fontes de Amplificar. O bônus acaba quando ela sai do campo." % magic_power})
 var effective_armor := armor if remaining_armor<0 else remaining_armor
 if effective_armor > 0:
  entries.append({"name": "Armadura %d" % effective_armor, "badge_icon":"armor-icon","badge":"Armor","value":effective_armor, "description": "Reduz cada dano físico recebido em %d, inclusive de contra-ataques. Não é consumida e não reduz dano mágico." % effective_armor})
 if block > 0:
  var charges := block if remaining_block < 0 else remaining_block
  entries.append({"name": "Bloqueio %d" % charges, "badge_icon":"block-icon","badge":"Block","value":charges, "description": "Com cargas, deve ser alvo dos ataques físicos. Cada ataque recebido gasta 1 carga. Recupera 1 no início do seu turno, até %d. Voo e magia ignoram; contra-ataques não gastam cargas." % block})
 if abascanto > 0:
  var charges: int=abascanto if remaining_abascanto<0 else remaining_abascanto
  entries.append({"name":"Abascanto %d" % charges,"badge":"Abascanto","value":charges,"icon":"abascanto-icon","description":"Anula uma magia ofensiva ou uma ocorrência de dano mágico recebido por carga. Recupera 1 no início do seu turno, até %d. Não protege de ataques físicos nem Veneno." % abascanto})
 if fury > 0:
  entries.append({"name": "Fúria %d" % fury,"badge":"Fury","value":fury, "cost": 1, "icon": "fury-icon", "description": "Pague 1 mana: ganhe +%d de ataque permanente, sem esgotar. Pode repetir." % fury})
 if swift:
  entries.append({"name": "Arrancada","icon":"swift-icon","badge":"Swift", "description": "Entra pronta e pode atacar no mesmo turno em que é invocada."})
 if flying:
  entries.append({"name": "Voo","icon":"flying-icon","badge":"Flying", "description": "Seus ataques físicos ignoram a obrigação de atacar criaturas com Bloqueio. Se escolher atacar uma delas, consome uma carga normalmente."})
 if magic_damage > 0:
  entries.append({"name": "Disparo Arcano %d" % (magic_damage+magic_bonus),"badge":"Arcane","value":magic_damage+magic_bonus, "cost": magic_cost, "tap": true, "icon": "arcane-icon", "description": "Pague %d mana e esgote: cause %d de dano mágico a uma criatura inimiga. Ignora Armadura, sem contra-ataque." % [magic_cost, magic_damage+magic_bonus]})
 if spores>0:
  entries.append({"name":"Esporos %d" % spores,"icon":"spores-icon","badge":"Spores","value":spores,"description":"No início do seu turno, todos os seus Monstros em campo ganham +%d de vida atual e máxima, incluindo esta criatura se for Monstro. Acumula. Ganho de atributo, não Cura nem Cultivo." % spores})
 if regeneration>0:
  entries.append({"name":"Regeneração %d" % regeneration,"icon":"regeneration-icon","badge":"Regeneration","value":regeneration,"description":"No fim do seu turno, após resolver Veneno, recupera %d de vida até a vida máxima. Não esgota. É Cura: ativa Devoção quando recupera vida e causa dano mágico em Mortos-vivos. Muralhas não podem receber essa Cura." % regeneration})
 if growth > 0:
  entries.append({"name": "Cultivo %d" % growth,"icon":"growth-icon","badge":"Growth","value":growth, "description": "No início do seu turno, ganha +%d de vida atual e máxima." % growth})
 if devotion > 0:
  entries.append({"name":"Devoção %d" % devotion,"icon":"devotion-icon","badge":"Devotion","value":devotion,"description":"Sempre que uma cura recuperar vida de qualquer criatura ou castelo, inclusive do oponente, ganha +%d/+%d permanentemente. Conta uma vez por alvo curado, não por ponto de vida. Cura sem recuperação e ganhos de atributos não ativam." % [devotion,devotion]})
 if harvest > 0:
  entries.append({"name":"Colheita %d" % harvest,"icon":"harvest-icon","badge":"Harvest","value":harvest,"description":"Sempre que o Cultivo de um aliado for ativado, ganha +%d/+%d permanentemente. Conta uma vez por ativação, independentemente do valor de Cultivo. Inclui seu próprio Cultivo, se receber essa habilidade." % [harvest,harvest]})
 if commerce > 0:
  entries.append({"name":"Comércio %d" % commerce,"icon":"commerce-icon","badge":"Commerce","value":commerce,"description":"Sempre que o Cultivo de um aliado for ativado, receba +%d mana temporária neste turno. Conta uma vez por ativação de Cultivo; a mana temporária é gasta antes da mana normal e desaparece ao fim do turno." % commerce})
 if heal_amount > 0:
  entries.append({"name": "Cura %d" % heal_amount,"badge":"Heal","value":heal_amount, "cost": heal_cost, "tap": true, "icon": "heal-icon", "description": "Pague %d mana e esgote: cure %d de vida de um aliado ou do seu castelo. Remove Veneno dos vivos. Em Mortos-vivos de qualquer lado, causa esse valor de dano mágico, ignorando Armadura, sem curar ou remover Veneno; Abascanto pode anular." % [heal_cost, heal_amount]})
 if envenom > 0:
  entries.append({"name":"Envenenar %d" % envenom,"badge":"Envenom","value":envenom,"icon":"envenom-icon","description":"Ataques e contra-ataques físicos aplicam %d de Veneno somente a criaturas, mesmo quando a Armadura absorve o dano. Acumula. No fim do turno do alvo, causa dano igual ao Veneno acumulado, ignorando Armadura, e termina. Magia não aplica Veneno." % envenom})
 if received_aura_attack>0:
  entries.append({"name":"Bônus de Aura","icon":"aura-icon","badge":"AuraBonus","value":"+%d" % received_aura_attack,"runtime":true,"description":"Recebe +%d de ataque de Auras aliadas. Esse bônus é temporário e desaparece quando as fontes correspondentes saem do campo." % received_aura_attack})
 if poison_stacks > 0:
  entries.append({"name":"Envenenado %d" % poison_stacks,"badge":"Poison","value":poison_stacks,"icon":"poison-icon","runtime":true,"description":"No fim do seu turno, perde %d de vida ignorando Armadura. Depois o Veneno termina. Curar seres vivos remove todo o Veneno; em Mortos-vivos, Cura causa dano e mantém o Veneno." % poison_stacks})
 if entries.is_empty() and not ability_text.is_empty():
  entries.append({"name": "Habilidade", "description": ability_text})
 if not entries.is_empty():
  if not ability_name_override.is_empty():
   entries[0].name = ability_name_override
  if not ability_help_override.is_empty():
   entries[0].description = ability_help_override
 return entries

func entry_needs_target() -> bool:
 return entry_effect in [EntryEffect.BUFF_ALLY,EntryEffect.ARMOR_ALLY,EntryEffect.POISON_ENEMY]

func entry_summary() -> String:
 match entry_effect:
  EntryEffect.BUFF_ALLY:
   if entry_attack==0:return "Vida +%d" % entry_health
   if entry_health==0:return "Ataque +%d" % entry_attack
   return "+%d/+%d" % [entry_attack,entry_health]
  EntryEffect.BUFF_OTHER_ALLIES:return "Outros aliados: vida +%d" % entry_health if entry_attack==0 else "Outros aliados: +%d/+%d" % [entry_attack,entry_health]
  EntryEffect.ARMOR_ALLY:return "Armadura +%d" % entry_value
  EntryEffect.SUMMON:return "Familiar Rúnico"
  EntryEffect.SUMMON_AFTER_ENEMY_HUMAN_DEATH:return "Carniçal 2/2 condicional"
  EntryEffect.POISON_ENEMY:return "Veneno %d" % entry_value
 return ""

func entry_prompt() -> String:
 if entry_effect==EntryEffect.POISON_ENEMY:
  return "Chamado: escolha uma criatura inimiga para aplicar %s." % entry_summary()
 return "Chamado: escolha outro aliado para receber %s antes de invocar." % entry_summary()

func aura_summary() -> String:
 match aura_effect:
  AuraEffect.ATTACK:return "%s: ataque +%d" % ["Neutros" if aura_targets==AuraTargets.ALLIED_NEUTRALS else ("Aliados" if aura_includes_self else "Outros aliados"),aura_value]
 return ""

