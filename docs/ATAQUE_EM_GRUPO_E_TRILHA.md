# Ataque em grupo, castelos e trilha

## Atacar com todos

O novo botão executa ataques físicos na ordem atual do campo, priorizando o castelo. Se houver Bloqueio, a criatura ataca o primeiro alvo legal; Voo continua podendo atingir o castelo. A fila guarda IDs de atacantes e procura a posição atual antes de cada combate, para que mortes e mudanças de índices não pulem criaturas. Alvos e condições são recalculados após cada ataque.

Só usa ataques legais: ignora criaturas esgotadas, Muralhas e criaturas sem força física, respeitando Vigor. Não ativa habilidades, não gasta mana, não encerra o turno e para se a partida acabar. Durante a sequência, outros comandos de duelo ficam bloqueados. Cada ataque usa a animação e os sons normais; o layout tem tempo para se atualizar entre combates.

## Castelos

Artes originais geradas para `assets/art/castle_player.png` e `assets/art/castle_enemy.png`, em azul e vinho. Substituem os símbolos no alvo clicável sem alterar regras, vida ou posicionamento.

## Aldeia ao Amanhecer

Composição instrumental original sintetizada localmente: 32 compassos a 84 BPM, cerca de 91,43 segundos, em ré menor, com harpa, flauta, sustentação suave e percussão leve. Ogg Vorbis estéreo, 44,1 kHz, aproximadamente 644 KiB. As caudas e a ambiência atravessam a emenda do loop; o volume do jogo fica abaixo dos efeitos de combate.

O autoload `GameMusic` mantém um único reprodutor entre menu, duelo e novas partidas. A opção Som pausa/retoma a música junto ao controle dos efeitos, sem reiniciar a faixa. A preferência dura a sessão do jogo. Não é necessário Python para jogar: o áudio pronto está no projeto.

Para recompor, execute `tools/generate_music.py` usando Python com numpy e ffmpeg no PATH. A partitura, instrumentos e síntese estão no próprio script; não usa gravações externas. A saída é codificada por pipe diretamente para Ogg, sem manter WAV.

## Verificação

`test_attack_all_and_music.gd`: prioridade de alvos, Bloqueio/Voo, mortes e mudança de índices, parada na vitória, ausência de gastos extras, recursos dos castelos, duração/loop/mute e um único reprodutor. A sequência lógica usa animação substituída; `VERIFY_ATTACK_ANIMATION=1` habilita o cenário curto de duas animações reais. Testes sem interface carregam a faixa sem iniciar reprodução de áudio. `ffprobe` confirma estéreo, 44,1 kHz, Ogg Vorbis e duração de 91,43 s.
