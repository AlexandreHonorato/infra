unit InfraOPFConnectionProvider;

interface

uses
  SysUtils,
  InfraCommon,
  InfraCommonIntf,
  InfraOPFIntf,
  ZDbcIntfs;

type
  IConnectionProviderFactory = interface
    ['{78BFE625-5F7D-4642-BDB6-332B070018C0}']
    function CreateProvider(const pConnectionString: string): IConnectionProvider;
  end;

  /// Classe respons�vel por prover conex�es com o SGDB
  TConnectionProvider = class(TBaseElement, IConnectionProvider)
  private
    FConnectionString: string;
  protected
    function GetConnection: IZConnection;
    procedure ReleaseConnection(const pConnection: IZConnection);
  public
    constructor Create(const pConnectionString: string); reintroduce;
  end;

  TConnectionProviderFactory = class(TInterfacedObject, IConnectionProviderFactory)
  public
    function CreateProvider(const pConnectionString: string): IConnectionProvider;
  end;

var
  ConnectionProviderFactory: IConnectionProviderFactory;

implementation

uses
  InfraOPFConsts;

{ TInfraConnectionProvider }

{**
  Cria uma nova inst�ncia de TInfraConnectionProvider.
  @param pConnectionString URL de conexao com o banco de dados 
}
constructor TConnectionProvider.Create(const pConnectionString: string);
begin
  inherited Create;
  if Trim(pConnectionString) = EmptyStr then
    raise EInfraArgumentError.Create('pConnectionString');
  FConnectionString := pConnectionString;
end;

{**
  Libera a conex�o de volta ao pool para ser reutilizada
  @param pConnection Conex�o a ser liberada
}
procedure TConnectionProvider.ReleaseConnection(const pConnection: IZConnection);
begin
  // A ser implementado no novo Pool
end;

{**
  Nesta vers�o apenas retorna uma nova conex�o a cada chamada, por isso
  pode ser lento, no pr�ximo release o ConnectionProvider vai ser um Pool
  completo e Thread safe
  @return Retorna uma nova conex�o (Do tipo IZConnection)
}
function TConnectionProvider.GetConnection: IZConnection;
begin
  Result := DriverManager.GetConnection(FConnectionString);
end;

{ TConnectionProviderFactory }

function TConnectionProviderFactory.CreateProvider(const pConnectionString: string): IConnectionProvider;
begin
  Result := TConnectionProvider.Create(pConnectionString);
end;

initialization
  ConnectionProviderFactory := TConnectionProviderFactory.Create;
finalization
  ConnectionProviderFactory := nil;
end.

