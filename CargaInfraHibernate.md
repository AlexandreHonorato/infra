### TPersistenceService - O serviço do Infra responsável pela persistencia ###
  * Faz referencia a um objeto TConfiguration e a um TSessionFatory;
  * O usuário final terá acesso apenas a este servico e a partir dele poderá fazer todo o resto;

### TConfiguration - Responsável pelas configurações da persistencia ###
  * Bem parecida com um map (chave - valor);
  * Guarda as chaves e valores que serão usados por várias classes do InfraHibernate para configurar determinandas propriedades ou criar determinadas classes com base em determinados nome de classes (ex: Dialect, ConnectionString, UserName, Password, PoolSize, etc...)

### TSessionFactory - Uma fábrica para obejtos Sessions ###
  * Possui um método chamado OpenSession que retorna um novo objeto Session.
  * Caso não se passe o Connection no OepnSession um novo Connection é solciitado do ConnectionProvider;
  * Cria um novo Session e configura ele com o Connection adiquirido;

### TSession - classe responsável pela operação de carga de um objeto ###
  * Possui um método Load onde passamos o tipo de objeto e o OID (identificador do objeto no banco). Um infratype é retornado com o objeto populado.
  * Durante o Load o Session irá criar um Loader e chamar o método Loader.Load(TypeID, Session, OID). O resultado disso é um objeto populado para ser retornado a quem pediu a carga;

### TLoader - Responsável gerar a SQL e preencher um objeto a partir do resultado desta SQL ###
  * Possui um método Load que ao ser chamado irá:
    * Criar uma instância do objeto a partir do TypeID (Metadata da classe);
    * Gerar a instrução SQL de select;
    * Guardar em um ResultSet a execução da SQL, através da chamada ao Connection.ExecuteQuery;
    * Preencher o objeto criado com a linha atual do ResultSet;
  * O preenchimento do objeto se dá pelo FillObject(Obj, ResultSet). Este método faz o seguinte:
    * Passa por cada propriedade do objeto (à partir do seu metadata);
    * Verifica se o metadata da propriedade suportar collumn e o nome do column ou o nome do atributo;
    * Tentar pegar o valor desta coluna usando ResultSet.GetValue(NomeColuna)
    * Atribui o valor retornado ao atributo do objeto anteriormente criado;
  * A geração da SQL ainda é simples. Neste primeiro momento só gera instruções na forma _SELECT **All** FROM tabela WHERE campopk = oid_. Para gerar este SQL faz-se:
    * Substitui "tabela" na SQL acima com o que estiver na anotação IEntity ou pelo nome da classe;
    * Substitui "campopk" na SQL, procurando o atributo anotado com IID (neste caso nao se tem um default mas poderia ser o primeiro atributo registrado na reflexão da classe).
    * Substitui "oid" na SQL, com o valor do OID passado pelo programador. Por enquanto está tratando OID como inteiro e por isso precisamos usar os converters;
**PS: Provavelmente esta classe será dividida pois está com muita responsabilidade.**

### TConnectionProvider - Repsonsável por criar Connections ###
  * Uma fábrica de objetos Connection;
  * Usa um Pool para manter as conexões;
  * Faz uso do Configuration para criar um Connection antes de retorná-lo;

### TDBXConnection - Representa Uma conexão com o banco de dados através da biblioteca DBX ###
  * Implementa as interfaces DBXConnection e Connection;
  * Empacota um TSQLConnection;
  * Possui um método ExecuteQuery(sQL: string, Params: IInfraList): IResultSet;
  * Quando o ExecuteQuery é chamado:
    * Cria seus descendente de ResultSet DBXResultSet, passando o TSQLConnection, o SQL e os parâmetros;
  * Retorna o ResultSet criado;
**PS: por enquanto estamos tratando apenas conexões com firebird usando DBX**

### TDBXResultSet - Classe que controla a navegação no dataset ###
  * Implementa as interfaces ResultSet e DBXResultSet;
  * Empacota um dataset tipo TSQLQuery na criação, configurando este dataset com o TSQLConnection passado como parâmetro;
  * Tem os métodos para navegar no dataset Next e EOF;
  * Possui o método GetValue(const CollumName: string): IInfraType, para retornar o valor de um campo do dataset já convertido como InfraType (ou seja, pronto para ser atribuido ao objeto);
  * Tem um método Open(pSQL: string; pParams: IInfraList) que configura e abre o dataset interno;