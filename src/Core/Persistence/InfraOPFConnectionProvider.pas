unit InfraOPFConnectionProvider;

interface

uses
  InfraCommon,
  InfraCommonIntf,
  InfraOPFIntf,
  ZDbcIntfs;

type
  IConnectionProviderFactory = interface
    ['{78BFE625-5F7D-4642-BDB6-332B070018C0}']
    function CreateProvider(pConfiguration: IConfiguration): IConnectionProvider;
  end;

  /// Classe respons�vel por prover conex�es com o SGDB
  TConnectionProvider = class(TBaseElement, IConnectionProvider)
  private
    /// Armazena uma refer�ncia ao objeto que cont�m as configura��es do Framework
    FConfiguration: IConfiguration;
    function BuildConnectionString(pConfiguration: IConfiguration): string;
  protected
    function GetConnection: IZConnection;
    procedure ReleaseConnection(const pConnection: IZConnection);
  public
    constructor Create(pConfiguration: IConfiguration); reintroduce;
  end;

  TConnectionProviderFactory = class(TInterfacedObject, IConnectionProviderFactory)
  public
    function CreateProvider(pConfiguration: IConfiguration): IConnectionProvider;
  end;

var
  ConnectionProviderFactory: IConnectionProviderFactory;

implementation

uses
  InfraOPFConsts;

{ TInfraConnectionProvider }

{**
  Cria uma nova inst�ncia de TInfraConnectionProvider.
  @param pConfiguration Um objeto do tipo IConfiguration que cont�m todas as
  informa��es necess�rias sobre a conex�o.
}
constructor TConnectionProvider.Create(pConfiguration: IConfiguration);
begin
  inherited Create;
  if not Assigned(pConfiguration) then
    raise EInfraArgumentError.Create(
      'Configuration in ConnectionProvider.Create');
  FConfiguration := pConfiguration;
end;

{**
  Libera a conex�o de volta ao pool para ser reutilizada
  @param pConnection Conex�o a ser liberada
}
procedure TConnectionProvider.ReleaseConnection(const pConnection: IZConnection);
begin
  // A ser implementado no novo Pool
end;

{*
  Constr�i a URL de conex�o com o banco
  @param pConfiguration Objeto com as configura��es de conex�o com o banco de dados
  @return Retorna uma string no formato
    zdbc:<driver>://<hostname>/<databasename>?username=<username>;password=<password>
*}
function TConnectionProvider.BuildConnectionString(pConfiguration: IConfiguration): string;
begin
  Result := 'zdbc:' + pConfiguration.GetAsString(cCONFIGKEY_DRIVER) +
    '://' + pConfiguration.GetAsString(cCONFIGKEY_HOSTNAME) +
    '/' + pConfiguration.GetAsString(cCONFIGKEY_DATABASENAME) +
    '?username=' + pConfiguration.GetAsString(cCONFIGKEY_USERNAME) +
    ';password=' + pConfiguration.GetAsString(cCONFIGKEY_PASSWORD);
end;

{**
  Nesta vers�o apenas retorna uma nova conex�o a cada chamada, por isso
  pode ser lento, no pr�ximo release o ConnectionProvider vai ser um Pool
  completo e Thread safe
  @return Retorna uma nova conex�o (Do tipo IZConnection)
}
function TConnectionProvider.GetConnection: IZConnection;
begin
  Result := DriverManager.GetConnection(
    BuildConnectionString(FConfiguration));
end;

{ TConnectionProviderFactory }

function TConnectionProviderFactory.CreateProvider(
  pConfiguration: IConfiguration): IConnectionProvider;
begin
  Result := TConnectionProvider.Create(pConfiguration);
end;

initialization
  ConnectionProviderFactory := TConnectionProviderFactory.Create;
finalization
  ConnectionProviderFactory := nil;
end.

