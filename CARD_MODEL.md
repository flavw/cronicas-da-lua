# Modelo editável de cartas

Abra card_gallery.tscn para ver as oito cartas ou expansion_gallery.tscn para ver as quatro da expansão. Execute com F6. Abra card_model.tscn para editar as camadas comuns.

Selecione uma carta e expanda Card Data no Inspector. Nome, custo, ataque, vida, armadura, classe, habilidades e ilustração são recursos compartilhados com a partida. Salve e reinicie a partida para aplicar mudanças nas regras. O texto da habilidade é uma descrição; novas mecânicas precisam de implementação.

A camada Artwork preenche todo o fundo, sem uma faixa vazia reservada para o título. Nome, custo, regras e escudo são sobrepostos à ilustração. Artwork Zoom amplia a arte (1 = enquadramento mínimo que preenche a carta) e Artwork Focus define o centro do recorte em coordenadas entre 0 e 1. X controla esquerda/direita e Y cima/baixo. O enquadramento é limitado para nunca revelar áreas vazias. Para mover o recorte, pode ser necessário aumentar um pouco o zoom. Cada recurso guarda seu próprio enquadramento, com atualização no editor.

As versões limpas da Guerreira, Maga, Escudeiro e Lobo ficam em assets/art/. As imagens originais com molduras permanecem em assets/. As artes da expansão já não têm textos ou molduras gravados. As quatro versões limpas foram preparadas com imagegen; o prompt está em assets/art/PROMPT.md.

Classes: Warrior vermelho, Mage roxo, Neutral cinza, Rogue verde. Para criar uma carta independente, duplique um recurso em cards/ antes de editar.

Camadas em CardCanvas: Frame, Artwork, TitleBanner, Title, CostGem, Cost, RulesPanel, Ability, Shield, Stats. O conteúdo dos Labels é alimentado por Card Data. As imagens transparentes da interface ficam em assets/ui/.

field_card.tscn é a versão quadrada usada em campo, mostrando arte e ataque/vida atual. O enquadramento do modelo completo não muda o recorte quadrado do campo. Passe o mouse para abrir a carta completa. Esgotado escurece a arte e mostra Zzzz animado. As mesmas cartas completas são usadas no editor de decks, na mão e na prévia por mouse.

A coleção agora tem 10 cartas. Card Class inclui CLERIC, com escudo branco/dourado. Growth, Heal Amount e Heal Cost são editáveis no Inspector. Inspect Mode habilita o painel StatusIcons da prévia: peitoral + armadura e escudo + cargas de Bloqueio. Cada ícone e valor é um nó separado, com SVGs editáveis em assets/ui. support_gallery.tscn apresenta os exemplos.


Correção dos indicadores: StatusIcons fica exclusivamente em field_card.tscn, como HBoxContainer sem fundo, no canto inferior esquerdo da versão reduzida. O card_model.tscn completo não contém esses ícones nem Inspect Mode. Armadura e Bloqueio são atualizados com os valores da criatura em campo.
