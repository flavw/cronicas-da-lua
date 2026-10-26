# Ações e castelos

- Muralha da Aldeia agora custa 4 mana. Os atributos e a habilidade não mudaram.
- Localizar uma carta destaca apenas sua moldura, sem texto adicional. Clicar em outra carta da coleção remove o destaque anterior sem refazer a interface ou impedir o clique. Clicar em outra carta da lista do deck transfere a localização.
- Seu castelo usa tons azuis e o adversário usa tons vermelhos, inclusive quando desabilitados. Os SVGs separados ficam em `assets/ui/castle-player.svg` e `castle-enemy.svg`.
- Botões de Fúria, Disparo Arcano e Cura têm área própria de 32 px para o símbolo. Os filhos visuais não interceptam o mouse; clicar no símbolo também ativa o botão. Cura usa `assets/ui/heal-icon.svg`, mantendo o símbolo de esgotar reservado ao custo.
- Explicações de Aura, Chamado, Bloqueio, Fúria, Vigor, Cultivo, Cura e várias magias foram encurtadas. A legenda da ampulheta foi removida da ajuda e do manual; os custos de esgotar continuam funcionando.

Validação: testes de Muralha, filtros e clique na coleção, ajuda/hover, estados de habilidades, Fúria, Vigor, Chamados e magias aprovados. Capturas estáticas conferiram as cores e os símbolos; clique nativo sobre o símbolo de Fúria confirmou o consumo de mana e o bônus.
