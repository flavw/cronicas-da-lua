# Crônicas da Lua — Duelo de Cartas

Um jogo de cartas de fantasia em Godot, com duelos contra IA, dez criaturas e construção de decks. Projeto em desenvolvimento; PvP planejado.

## Como jogar

1. Clone ou baixe este repositório.
2. Importe o arquivo `project.godot` no Godot 4.7.
3. Pressione F5 e escolha seu deck no botão Decks.

Enter ou numpad 0 passa o turno. Consulte o botão Regras para o manual completo.

## Recursos

- Combate físico e mágico, armadura, Bloqueio, Voo, Arrancada, Fúria e cura.
- Três espaços para decks de 12 cartas, com até duas cópias por carta.
- Cartas em camadas editáveis, prévia ampliada, animações e seis efeitos sonoros.
- Artes geradas com IA; prompts incluídos junto aos assets.

## Detalhes do projeto

Abra project.godot no Godot 4.7 e pressione F5 para jogar contra IA. O manual completo está em MANUAL.txt e no botão Regras dentro do jogo.

Selecione uma criatura pronta e clique em um alvo permitido. A Maga (0/2) seleciona magia automaticamente. O botão Fúria aumenta permanentemente o ataque do Lobo por 1 mana, sem esgotá-lo. O Escudeiro exige que o primeiro ataque físico seja nele (Bloqueio 1; recupera apenas 1 carga no início de cada turno do dono, até o máximo da criatura). Clique no castelo da IA para ataques diretos quando não houver Bloqueio ativo. Passe o mouse para ver as cartas completas e os atributos atuais.

O modelo editável fica em card_model.tscn; a galeria em card_gallery.tscn; a versão quadrada em field_card.tscn. Veja CARD_MODEL.md para editar os recursos cards/*.tres no Inspector. Guerreiro usa escudo vermelho, mago roxo e neutro cinza.

Decks: 12 cartas, até 2 cópias de cada. Castelos: 20 de vida. Mana crescente até 10. Campo: 5 criaturas. Mão: 8 cartas. Criaturas entram esgotadas, exceto Arrancada. Magia ignora armadura e não tem contra-ataque. Consulte o manual para Bloqueio, Fúria e fadiga.

scripts/match.gd contém regras e IA; scripts/main.gd contém interface. PvP é uma etapa futura.

Verificações: tests/test_match.gd (regras básicas e 20 partidas), tests/test_abilities.gd (Bloqueio e Fúria), tests/test_card_ui.gd (hover, atributos e clique no castelo). Execute Godot com --path . --script tests/<arquivo>.gd. Testes de regras aceitam --headless.



Efeitos: cartas avançam até criaturas ou castelos, retornam e destacam o impacto. Criaturas derrotadas encolhem e desaparecem juntas após o combate. As mesmas animações são usadas pelo jogador e pela IA. A entrada fica bloqueada até o efeito terminar.

Sons originais sintetizados em assets/audio: summon.wav (invocação/Fúria), attack.wav (ataque/magia) e death.wav (morte). Volume inicial: -10 dB. tools/generate_sounds.py recria os três WAVs. tests/test_effects.gd verifica efeitos, mortes simultâneas e ataque da IA ao castelo.



Magia: projétil magic-missile.png viaja da Maga ao alvo sem mover a carta. Esgotado: a arte escurece e exhausted-zzz.png flutua no canto superior direito. Ambos gerados com imagegen; prompts em assets/ui/EFFECT_PROMPTS.md. Fúria paga apenas mana, pode repetir enquanto houver mana e não modifica o estado de esgotamento do Lobo.


Expansão: Ladina Relâmpago (4 mana, 4/2, Arrancada), Corvo das Brumas (3 mana, 2/3, Voo), Sentinela de Ferro (2 mana, 1/3, Armadura 1), Feiticeira das Brasas (4 mana, 2/3, magia 2 por 2 mana + esgotar). Ladinas usam escudo verde. Artes sem textos em assets/; prompts em assets/EXPANSION_PROMPTS.md.

Editor: botão Decks, 3 espaços, 12 cartas por deck, no máximo 2 cópias. Salvar persiste em user://decks.json; Jogar salva, ativa e reinicia. Rascunhos não salvos são descartados ao sair/trocar. deck_editor.tscn também pode ser executada com F6. A galeria completa tem 10 cartas; expansion_gallery.tscn mostra as 4 novas. Testes: tests/test_expansion.gd e tests/test_deck_editor.gd.


Composição: a arte preenche o fundo inteiro do card, sob nome/custo/regras. Cada recurso Card Data expõe Artwork Zoom e Artwork Focus para enquadrar individualmente. Guerreira, Maga, Escudeiro e Lobo usam versões limpas em assets/art; os PNGs originais foram preservados. Consulte CARD_MODEL.md.


Visual: arena de pedra/madeira, painéis de vida com barras, mana com gemas, mão em painel, ações contextuais, botões e editor com tema consistente. Vitória/derrota/empate usam result_overlay.tscn; vitória tem medalhão animado, raios, partículas e fanfarra. Jogar novamente reinicia com o deck ativo; Editar decks abre o editor; Ver tabuleiro fecha o painel. O resultado só aparece uma vez por partida.

Novos sons: assets/audio/magic.wav, victory.wav e castle.wav. Há 6 efeitos no total, e o botão Som permite desligar/ligar. tools/generate_extra_sounds.py recria os três novos. Fundo e medalhão gerados com imagegen em assets/ui/; prompts em POLISH_PROMPTS.md. tests/test_presentation.gd verifica fechamento de partida, reprodução única, reinício e som desligado.


Suporte: Fazendeiro (2, 1/2) ganha +1 vida atual/máxima no início do turno do dono. Clériga da Aurora (3, 1/4; escudo branco/dourado) cura 2 por 1 mana + esgotar em criatura aliada ou castelo. A coleção tem 10 cartas; decks continuam com 12 e até 2 cópias. Decks salvos são preservados; use a coleção ou Restaurar sugestão para incluir as novas. support_gallery.tscn mostra os novos cards. Os ícones de Armadura e Bloqueio aparecem somente nas cartas reduzidas em campo, sem painel de fundo. tests/test_support.gd e test_support_ui.gd verificam regras e seleção de cura. Artes feitas com imagegen em assets/farmer.png, cleric.png e ui/shield-cleric.png; prompts em assets/SUPPORT_PROMPTS.md.

