unit InfraOPFConnectionProvider;

interface

uses
  {Infra}
  InfraCommon,
  InfraOPFIntf,
  {Zeos}
  ZDbcIntfs;

type
  /// Classe respons�vel por prover conex�es com o SGDB
  TConnectionProvider = class(TBaseElement, IConnectionProvider)
  private
    FConnRefCount: integer;
    FCurrentConnection: IZConnection;
    FConfiguration: IConfiguration;
    FConnectionString: string;
    function BuildConnectionString(pConfiguration: IConfiguration): string;
  protected
    function GetConnection: IZConnection;
    procedure ReleaseConnection;
  public
    constructor Create(const pConfiguration: IConfiguration); reintroduce;
  end;

implementation

uses
  InfraCommonIntf,
  InfraOPFConsts;

{ TInfraConnectionProvider }

{**
  Cria uma nova inst�ncia de TInfraConnectionProvider.
  @param pConnectionString URL de conexao com o banco de dados
}
constructor TConnectionProvider.Create(const pConfiguration: IConfiguration);
begin
  inherited Create;
  if not Assigned(pConfiguration) then
    raise EInfraArgumentError.CreateFmt(cErrorPersistenceWithoutConfig,
      ['TConnectionProvider.Create']);
  FConfiguration := pConfiguration;
  FConnectionString := BuildConnectionString(FConfiguration);
  FCurrentConnection := nil;
  FConnRefCount := 0;
end;

{**
  Nesta vers�o apenas retorna uma nova conex�o a cada chamada, por isso
  pode ser lento, no pr�ximo release o ConnectionProvider vai ser um Pool
  completo e Thread safe
  @return Retorna uma nova conex�o (Do tipo IZConnection)
}
function TConnectionProvider.GetConnection: IZConnection;
begin
  Inc(FConnRefCount);
  if not Assigned(FCurrentConnection) then
    FCurrentConnection := DriverManager.GetConnection(FConnectionString);
  Result := FCurrentConnection;
end;

{**
  Libera a conex�o de volta ao pool para ser reutilizada
  @param pConnection Conex�o a ser liberada
}
procedure TConnectionProvider.ReleaseConnection;
begin
  Dec(FConnRefCount);
  if (FConnRefCount = 0) and Assigned(FCurrentConnection) then
  begin
    FCurrentConnection.Close;
    FCurrentConnection := nil;
  end;
end;

{*
  Constr�i a URL de conex�o com o banco
  @param pConfiguration Objeto com as configura��es de conex�o com o banco de dados
  @return Retorna uma string no formato
    zdbc:<driver>://<hostname>/<databasename>?username=<username>;password=<password>
*}
function TConnectionProvider.BuildConnectionString(pConfiguration: IConfiguration):
    string;
begin
  Result := 'zdbc:' + pConfiguration.GetAsString(cCONFIGKEY_DRIVER) +
    '://' + pConfiguration.GetAsString(cCONFIGKEY_HOSTNAME) +
    '/' + pConfiguration.GetAsString(cCONFIGKEY_DATABASENAME) +
    '?username=' + pConfiguration.GetAsString(cCONFIGKEY_USERNAME) +
    ';password=' + pConfiguration.GetAsString(cCONFIGKEY_PASSWORD);
end;

end.
