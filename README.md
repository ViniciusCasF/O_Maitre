# O_Maitre

**Colaboradores**

* Rammid Andrew Barreto da Silva
* Vitor Augusto da Fonseca Lima
* Vinicus Castro Filaretti

## Objetivo do Projeto

O objetivo deste sistema é modernizar a gestão de restaurantes, permitindo que os clientes realizem pedidos diretamente pelo celular, que os garçons recebam os pedidos em tempo real, que a cozinha tenha um controle dos alimentos e que o dono do restaurante possa administrar o negócio através do software.

## Público Alvo

O sistema é voltado para restaurantes que buscam oferecer maior autonomia aos clientes e mais eficiência no trabalho de seus funcionários. Além disso, traz um toque de modernidade ao processo de atendimento: enquanto muitos estabelecimentos já utilizam QR Codes apenas para exibir o cardápio, a proposta aqui é permitir que o cliente realize seus pedidos diretamente pelo celular.  

## Principais Funcionalidades

### App Cliente
* Ter um cardápio com todos os produtos.
* Ter telas individuais para cada produto.
* consulta da conta com todos os produtos consumidos, incluindo a possibilidade do cliente adicionar 10% como taxa de serviço.
* O método de pagamento vai ser o pix.
* Catraca na entrada e saída do restaurante.
  * Liberação da entrada e entrega de comanda.
  * Validação na saída, que só é autorizada após o pagamento da conta.


### App Garçon
* Acesso ao cardápio completo, com telas individuais para cada produto
* Registro de pedidos em nome do cliente (para aqueles que não utilizam o app)
* Geração de código PIX para pagamento dos clientes
* Recebimento de notificações de pedidos prontos (comidas e bebidas) para realizar a entrega nas mesas


### App Cozinha
* Visualização em tempo real de todos os pedidos recebidos, exibindo cronômetro individual para medir o tempo até ficar pronto.
* Filtros e agrupamento de pedidos semelhantes (ex.: juntar duas pizzas iguais para assar de uma vez, otimizando tempo e recursos).
* Indicação visual de prioridade (ex.: pedidos mais antigos ficam na frente).
* Possibilidade de marcar cada pedido em diferentes estados: Recebido, Em preparo, Pronto para entrega (Integrar essa funcionalidade no app do cliente).
* A cozinha pode ser fechada, e ao fazer isso, não recebe mais pedidos, e só precisa terminar os que já foram abertos.


### App Proprietário
* Controle de estoque detalhado
  * Desconto automático de insumos ao registrar pedidos (ex.: uma porção de batatas reduz 400g do estoque total).
  * Alerta de estoque baixo e sugestão de reposição (exporta um arquivo de texto mostrando tudo que deve ser comprado).
* O dono pode escolher qual mesa vai ser atendida por qual garçon, otimizando o atendimento e não sobrecarregando os funcionários.
* Registros de todos os pedidos, mostrando o valor recebido no dia/semana/mês, além de mostrar os gastos com os alimentos e bebidas.
* Controle para abrir/fechar o restaurante, e ao fechar, a catraca de entrada não vai autorizar a entrada de ninguém, e os produtos no app do cliente não vão mais aparecer, estando disponível apenas a conta.

