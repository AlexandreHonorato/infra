# Requisitos #

  * simples de usar, mas flexivel para suportar o que for preciso;
  * nada de remendos, se tiver de refatorar para adicionar nova funcionalidade, refatora-se
  * suportar mapeamento através de anotação, sendo que poderão ser carregados opcionalmente de arquivo (xml ou outro) ou definidos diretamente no código. O mapeamento deve sempre ser anotado no typeinfo das respectivas classes;
  * suportar persistencia e carga de herança em todas as suas formas (tabela-por-classe, tabela-por-hierarquia, tabela-por-classeconcreta). Ver tipo de mapeamento de herança aqui: http://www.ibm.com/developerworks/library/ws-mapping-to-rdb/
  * suportar associações bidirecionais;
  * suportar associações reflexivas;
  * suportar estratégias de geração de chave diversas (Generator/Sequences, GUID, HighLow, etc...);
  * suportar mapeamento, carga e persistencia de coleções
  * suportar geração de sqls de delete/save/update/insert através do mapeamento;
  * suportar processamento em lote, ou seja, poder efetuar operações de update ou delete em uma coleção de registro, sem a necessidade de precisar fazer carga destes objetos antes;
  * suportar consultas usando join;
  * suportar relacionamentos onetoone, onetomany, manytoone, manytomany;
  * suportar a carga lazy ou não;
  * Suportar bancos diferentes e seus dialetos e funções;
  * Ter uma camada de abstração para connection e resultset plugável (ZEOS, IBX, DBX, MYDAC, ADO, ETC...);
  * Suportar transacao;
  * Suportar cache de objetos para evitar ir no banco para objetos já carregados;
  * suportar consultas baseado em criteria;
  * suportar agregações baseado em criteria sum, count, avg, etc...;
  * suportar consultas informando a sql diretamente, como "namedqueries" do hibernate;
```
   Query query = session.getNamedQuery("tracksNoLongerThan");
   query.setTime("length", length);
   return query.list();
```
  * suportar consultas baseadas em hql ou oql - Infra Query Language;
  * suporte a bancos legados: chaves compostas e uso de storedprocedures;
  * suportar geração do banco de dados baseado no mapeamento. geração do schema;
  * geração de eventos antes e após de certas tarefas. PostUpdate, PostLoad, PreLoad, PreUpdate, etc...;
  * versionamento de objetos;
  * suportar um pool de conexões para evitar abrir várias conexões com o banco sem necessidade;
  * suporte a paginação de registro
```
   Query q = session.getNamedQuery("DomesticCats");
   q.setFirstResult(20);
   q.setMaxResults(10);
   List cats = q.list();
```
  * suportar multiplos bancos ao mesmo tempo. dá uma olhada no burow, parece que ele trata até controle transacional por negócio - http://nhforge.org/wikis/burrow/introduction.aspx
  * Adicionar algum esquema de Log dentro do framework para facilitar depuração. isso vai mostrar a ordem e o momento da execução das SQL's e outras coisas. Talvez possamos usar o http://log4delphi.sourceforge.net/ ;
  * Suportar mapeamento de formulas, ou seja, atributos que são resultados de cálculos entre campos ou subselects;
```
  Column{ Name="TotalIncludingTax", formula="TOTAL + TAX_RATE * TOTAL", type="Double"

  ou ainda

  Column{ Name="AverageBidAmount", formula="( select AVG(b.AMOUNT) from BID b where b.ITEM_ID = ITEM_ID )", type="Double"
```