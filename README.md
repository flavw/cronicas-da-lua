# Crônicas da Lua — Duelo de Cartas

Jogo de cartas de fantasia em Godot, com duelos contra IA, dez criaturas e construção de decks. Projeto em desenvolvimento; PvP planejado.

## Como jogar

1. Clone ou baixe este repositório.
2. Importe `project.godot` no Godot 4.7 e aguarde a importação dos recursos.
3. Pressione F5 para jogar. O botão Decks permite editar e escolher seu deck.

Enter, Enter do teclado numérico ou numpad 0 passa o turno. Selecione uma criatura e clique no alvo permitido. Passe o mouse sobre uma carta para ver sua versão completa. O botão Regras abre o [manual](MANUAL.txt).

## Regras e recursos

- Castelos com 20 de vida; mana cresce até 10; campo com até cinco criaturas e mão com até oito cartas.
- Três espaços para decks de 12 cartas, com no máximo duas cópias por carta. Classes podem ser combinadas.
- Armadura reduz cada dano físico, incluindo contra-ataques. Magia ignora armadura e não provoca contra-ataque.
- Bloqueio N exige que os primeiros N ataques físicos tenham uma criatura bloqueadora como alvo. Recupera somente uma carga no início do turno do dono, até o máximo. Voo ignora essa restrição de alvo.
- Arrancada permite atacar no turno de entrada. Fúria do Lobo custa uma mana, aumenta seu ataque permanentemente e não esgota a criatura.
- Fazendeiro ganha uma vida atual e máxima no início do turno do dono. Clériga cura dois de vida de um aliado ou do castelo por uma mana e esgotamento.
- Animações de ataque, magia, morte e vitória; seis efeitos sonoros originais; botão para ligar/desligar o som.

## Organização

| Pasta ou arquivo | Conteúdo |
| --- | --- |
| `assets/art/` | As dez ilustrações de criaturas usadas pelo jogo, sem versões antigas duplicadas |
| `assets/ui/` | Tabuleiro, molduras, escudos de classe, ícones e efeitos visuais |
| `assets/audio/` | Seis sons usados na partida |
| `assets/fonts/` | Recurso SystemFont para títulos, usando fontes instaladas no sistema |
| `cards/` | Dez recursos CardData: atributos, habilidades, arte e enquadramento |
| `scripts/` | Regras, IA, interface, editor de decks e animações |
| `docs/art-prompts/` | Prompts das artes geradas com IA, separados dos recursos do jogo |
| `tests/` | Verificações das regras, decks, interface e apresentação |
| `tools/` | Scripts Python que recriam os sons sintetizados |
| `CARD_MODEL.md` | Instruções para editar as cartas no Godot |
| `MANUAL.txt` | Manual usado também pelo botão Regras |

`main.tscn` inicia a partida e `deck_editor.tscn` abre o editor. `card_model.tscn` define a carta completa e `field_card.tscn` a versão reduzida em campo. As galerias `card_gallery.tscn`, `expansion_gallery.tscn` e `support_gallery.tscn` permitem inspecionar as cartas no editor com F6.

A arte é compartilhada entre as duas apresentações. Artwork Zoom e Artwork Focus ajustam o enquadramento da carta completa. Ícones de Armadura e Bloqueio aparecem somente na versão reduzida, sem painel de fundo. A arte escurece e Zzzz flutua no canto superior direito quando a criatura está esgotada.

Os decks são salvos em `user://decks.json`. Salvar exige 12 cartas; Jogar salva, ativa e reinicia a partida. Rascunhos não salvos são descartados ao sair ou trocar de espaço. Caches `.godot/`, dados locais `.local/`, credenciais e executáveis exportados ficam fora do Git.

## Verificação

Execute a partir da pasta do projeto, usando o executável do Godot no PATH:

```sh
godot --headless --editor --path . --quit
godot --headless --path . --script tests/test_match.gd --quit-after 180
godot --headless --path . --script tests/test_abilities.gd --quit-after 180
godot --headless --path . --script tests/test_expansion.gd --quit-after 180
godot --headless --path . --script tests/test_support.gd --quit-after 180
```

`test_match.gd` verifica combate e 20 partidas completas. `test_abilities.gd`, `test_expansion.gd` e `test_support.gd` cobrem habilidades e cartas. `test_deck_editor.gd` verifica os três espaços de decks. Os testes de interface e apresentação também ficam em `tests/`.

Todos os arquivos necessários para abrir e continuar o projeto estão neste repositório. As artes foram geradas com IA; os prompts estão em `docs/art-prompts/`. Os sons são sintetizados pelos scripts de `tools/`.
