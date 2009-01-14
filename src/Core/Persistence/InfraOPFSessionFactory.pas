unit InfraOPFSessionFactory;

interface

uses
  InfraCommon,
  InfraOPFIntf,
  ZDbcIntfs;

type
  TSessionFactory = class(TBaseElement, ISessionFactory)
  private
    FClosed: Boolean;
    FConfiguration: IConfiguration;
    FConnectionProvider: IConnectionProvider;
    FConnectionString: string;
    function BuildConnectionString(pConfiguration: IConfiguration): string;
    function GetIsClosed: Boolean;
  protected
    function OpenSession: ISession; overload;
    function OpenSession(pConnection: IZConnection): ISession; overload;
    procedure Close;
    property isClosed: Boolean read GetIsClosed;
  public
    constructor Create(pConfiguration: IConfiguration); reintroduce;
  end;

implementation

uses
  InfraOPFConsts,
  InfraOPFSession,
  InfraOPFConnectionProvider,
  InfraCommonIntf;

{ TSessionFactory }

procedure TSessionFactory.Close;
begin
  FClosed := True;
end;

constructor TSessionFactory.Create(pConfiguration: IConfiguration);
begin
  inherited Create;
  // Clona a conexao para n�o guardar referencia a ela, assim,
  // modificar o Configuration ap�s ser a SessionFactory, n�o ter� efeito 
  FConfiguration := pConfiguration.Clone;
  FConnectionString := BuildConnectionString(FConfiguration);
  // TODO: depois precisamos passar mais informa��es para o ConnectionProvider,
  // mas acho desnecess�rio mandar o Configuration: O acoplamento geral est�
  // aumentando muito
  FConnectionProvider := TConnectionProvider.Create(FConnectionString);
end;

{*
  Constr�i a URL de conex�o com o banco
  @param pConfiguration Objeto com as configura��es de conex�o com o banco de dados
  @return Retorna uma string no formato
    zdbc:<driver>://<hostname>/<databasename>?username=<username>;password=<password>
*}
function TSessionFactory.BuildConnectionString(pConfiguration: IConfiguration):
    string;
begin
  Result := 'zdbc:' + pConfiguration.GetAsString(cCONFIGKEY_DRIVER) +
    '://' + pConfiguration.GetAsString(cCONFIGKEY_HOSTNAME) +
    '/' + pConfiguration.GetAsString(cCONFIGKEY_DATABASENAME) +
    '?username=' + pConfiguration.GetAsString(cCONFIGKEY_USERNAME) +
    ';password=' + pConfiguration.GetAsString(cCONFIGKEY_PASSWORD);
end;

{**
  Retorna se a f�brica est� fechada

  @return Retorna True se a f�brica estiver fechada
}
function TSessionFactory.GetIsClosed: Boolean;
begin
  Result := FClosed;
end;

{**
  Cria uma nova Session com a conexao informada
  Chame OpenSession para criar uma nova instancia de Session.

  @param pConnection Parameter Description
  @return Retorna um novo objeto Session
}
function TSessionFactory.OpenSession(pConnection: IZConnection): ISession;
begin
  Result := TSession.Create(pConnection, FConfiguration);
end;

{**
  Cria uma nova Session. Cria uma nova conexao
  Chame OpenSession para criar uma nova instancia de Session.

  @return Retorna um novo objeto Session
}
function TSessionFactory.OpenSession: ISession;
begin
  Result := TSession.Create(FConnectionProvider.GetConnection, FConfiguration);
end;

end.
