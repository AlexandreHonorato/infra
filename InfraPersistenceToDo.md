# Introdução #

Abaixo temos duas listas:

  * To Do - é a lista de tudo que está por fazer e está sendo discutido entre a equipe sobre a parte de persistencia.
  * Done - é a lista de tudo que está pronto.

## To Do ##

  * Passar todas as strings para um resourcestring ou unit a parte com constantes;
  * ConnectionProvider - Classe responsável por criar e oferecer uma conexão zeos para o PersistenceEngine.
```
* Analisar e implementar o ConnectionProvider para se tornar um pool, usando semáforo, lista dupla, ou lista com iterators;
* É possivel setar uma conexão externa através do SetConnection e neste caso o connection provider passa a usar esta conexão.
```
  * Configuration - Esta classe Guarda as configurações sobre a persistencia:
    1. Informações sobre a conexão;
    1. De onde carregar os templates;
    1. Classe Reader para leitura de templates
    1. Quantidade maxima de conexões, etc.;
```
* Adicionar os métodos:
  function GetValue(Nome: string; Default: Integer): Integer; overload;
  function GetValue(Nome: string; Default: Double): Double; overload
  function GetValue(Nome: string; Default: string): string; overload
  function GetValue(Nome: string; Default: ): Double; overload
```
  * PersistenceService - servico pelo qual o programador acessa a persistencia;
```
* O servico deve oferecer um configuration para o programador preencher.
* Cada OpenSession retorna um novo objeto Session.
* Um único PersistenceEngine é criado no service e deve ser passado para o Session durante a criação do mesmo.
* Quando o programador chama SetConnection este é repassado para o ConnectionProvider do PersistenceEngine;
* O Session é contextualizado.
```
  * SQLCommand;
```
* O PersistenceEngine tem de ser passado no construtor do SQLCommand para quando o programador chamar o GetResult.
* GetResult é o método que causará a execução do command e sempre retornará um InfraList ou a lista definida no atributo TypeInfoList.
* Os parametros de um SQLCommand são definidos antes do template ser carregado, afinal o template só será carregado no GetResult.
* O SQLCommand precisa do metada do objeto e da lista ara que o PersistenceEngine possa criar os objetos corretamente e preencher a lista que é devolvida.
```
  * Session;
```
* O Load gera um SQLCommand e devolve ao programador para que ele possa preencher os parametros (se necessário) e chamar o GetResult para obter o objeto.
* O LoadList é similar ao Load só que retorna a lista de objetos quando chamando o GetResult do SQLCommand retornado.
* O Load tem várias sobrecargas:
  * Load(CommandName) - Retorna um SQLCommand sem definir parâmetros;
  * Load(CommandName, Objeto) - Retorna um SQLCommand e armazena o objeto passado para que o PersistenceEngine possa extrair o valor dos parâmetros. SQLCommand.ClassType pode ser extraido do Objeto.
  * Load(CommandName, ClassType) - Retorna um SQLCommand já definindo qual o tipo de classe que o PersistenceEngine deve instanciar.
* O LoadList tem várias sobrecargas:
  * LoadList(CommandName) - Retorna um SQLCommand sem definir parâmetros ou tipo de objeto e lista a ser instanciada. O programador vai provavelmente definir isso no retorno.
  * LoadList(CommandName, ClassType, ListType) - Retorna um SQLCommand sem definir parâmetros mas já definindo o tipo de objeto e lista a ser instanciada.
  * LoadList(CommandName, Objeto, ListType) - Retorna um SQLCommand e armazena o objeto passado para que o PersistenceEngine possa extrair o valor dos parâmetros. ClassType ser extraido do Objeto.
  * LoadList(CommandName, Objeto, List) - Retorna um SQLCommand e armazena o objeto passado para que o PersistenceEngine possa extrair o valor dos parâmetros. Neste caso o Session usa a lista passada para fazer o preenchimento dos objetos.
* O Save cria um SQLCommand, armazena em uma lista interna de commands no session e retorna o mesmo para que o usuário possa preencher os parâmetros.
* O processo do Delete é similar ao do Save.
* O Session armazena os SQLCommand's de Save e Delete na lista até que o programador chame o método o Flush.
* O Flush chama o PersistenceEngine para cada SQLCommand da lista interna
* O Flush deve limpar a lista de SQLCommands caso todas as gravações tenham tido sucesso.
```
  * TemplateReader;
```
* Recebe o configuration na criação para poder recuperar corretamente os templates sql.
```

  * PersistenceEngine;
```
* O service passa o configuration como parametro para o construtor desta classe para que ele possa repassar para o Reader de tamplates.
* O Load vai carregar o template com base no SQLCommand, executar a SQL passando os parametros e preencher a List com objetos do tipo definido no SQLCommand.
* O Execute é similar ao Load mas nao preenche lista alguma e deve retornar o numero de linhas afetadas pelo comando.
```
  * Documentar Classes
    1. Configuration;
    1. ConnectionProvider;
    1. PersistenceEngine
    1. Session;
    1. SqlCommand;
    1. TemplateReader;

  * Adicionar no artigo do wiki InfraPersistence:
```
* Lista de items possiveis para o configuration;
```

## Done ##