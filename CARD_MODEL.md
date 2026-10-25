# Modelo editável de cartas

Abra `card_gallery.tscn` para ver as dez cartas, `expansion_gallery.tscn` para as quatro cartas da expansão ou `support_gallery.tscn` para os exemplos de suporte. Execute com F6. Abra `card_model.tscn` para editar as camadas comuns.

Selecione uma carta e expanda Card Data no Inspector. Nome, custo, ataque, vida, armadura, classe, habilidades e ilustração são recursos compartilhados com a partida. Salve e reinicie a partida para aplicar mudanças nas regras. O texto da habilidade é uma descrição; novas mecânicas precisam de implementação.

## Arte e enquadramento

Todas as dez artes de criaturas usadas pelo jogo ficam em `assets/art/`. Não há versões antigas duplicadas. Os recursos em `cards/` apontam para essas imagens. Os prompts de geração ficam em `docs/art-prompts/`.

A camada Artwork preenche todo o fundo da carta completa. Nome, custo, regras e escudo são sobrepostos à ilustração. Artwork Zoom amplia a arte (1 = enquadramento mínimo que preenche a carta) e Artwork Focus define o centro do recorte em coordenadas entre 0 e 1. X controla esquerda/direita e Y cima/baixo. O enquadramento é limitado para nunca revelar áreas vazias. Para mover o recorte, pode ser necessário aumentar um pouco o zoom. Cada recurso guarda seu próprio enquadramento, com atualização no editor.

`field_card.tscn` é a versão quadrada usada em campo. Ela compartilha a ilustração da carta completa e mostra ataque/vida atuais. O enquadramento do modelo completo não muda o recorte quadrado do campo. Passe o mouse para abrir a carta completa. As cartas completas também são usadas na mão e no editor de decks.

## Camadas e indicadores

Camadas em CardCanvas: Frame, Artwork, TitleBanner, Title, CostGem, Cost, RulesPanel, Ability, Shield e Stats. O conteúdo dos Labels é alimentado por Card Data. Molduras, escudos, ícones e efeitos ficam em `assets/ui/`.

StatusIcons fica exclusivamente em `field_card.tscn`, como HBoxContainer sem fundo, no canto inferior esquerdo da versão reduzida. O peitoral mostra Armadura e o escudo mostra as cargas atuais de Bloqueio, incluindo zero quando consumidas. A carta completa não contém esses ícones nem a propriedade Inspect Mode. Esgotado escurece a arte e mostra Zzzz animado no canto superior direito.

## Classes e novas cartas

Classes: Warrior vermelho, Mage roxo, Neutral cinza, Rogue verde e Cleric branco/dourado. Growth, Heal Amount e Heal Cost também são editáveis no Inspector.

Para criar uma carta independente, duplique um recurso em `cards/` antes de editar. Salve a ilustração em `assets/art/`, selecione-a em Artwork e ajuste o enquadramento. Registre o novo recurso em CARD_DATA, em `scripts/match.gd`, para incluí-lo na coleção e no editor de decks. Habilidades novas precisam de regras na lógica da partida.
