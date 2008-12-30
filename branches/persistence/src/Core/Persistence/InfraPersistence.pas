unit InfraPersistence;

interface
uses
  SysUtils,
  SyncObjs,
  {TStrings}Classes,
  {Zeos}ZDbcIntfs,
  {Infra}InfraCommon,
  {InfraInf}InfraCommonIntf, InfraValueTypeIntf, InfraPersistenceIntf;

type
  EInfraConnectionProviderError = class(Exception);
  
  TConfiguration = class(TBaseElement, IConfiguration)
    FProperties: TStrings;
    function GetProperties: TStrings;
    function GetPropertyItem(const pName: string): string;
    procedure SetPropertyItem(const pName: string; const Value: string);
  public
    constructor Create; override;
    destructor Destroy; override;
    property Properties: TStrings read GetProperties;
    property PropertyItem[const pName: string]: string read GetPropertyItem write SetPropertyItem;
  end;

  /// Classe respons�vel por prover conex�es com o SGDB 
  TInfraConnectionProvider = class(TBaseElement, IConnectionProvider)
  private
    FConfiguration: IConfiguration;
    FDriverManager: IZDriverManager;    // O DriverManager que ser� usado pra criar as conex�es
    FPool: array of IZConnection;       // O pool
    FCriticalSection: TCriticalSection;
    function BuildConnectionString(pConfiguration: IConfiguration): string; // CriticalSection usado para evitar conflitos em aplica��es multi-thread
  protected
    function GetFreeConnection: IZConnection; // Procura por uma conexao livre
    function CreateConnection: IZConnection;  // Cria uma nova conexao
    function FindConnection(const pConnection: IZConnection): IZConnection; // Procura por uma conexao no pool
  public
    constructor Create(MaxSize, ExpirationTime: Integer;
      ADriverManager: IZDriverManager; AConfiguration: IConfiguration); reintroduce;
    destructor Destroy; override;
    function GetConnection: IZConnection; // Caso tenha conexoes dispon�veis no Pool bloqueia uma e retorna-a
    procedure Close; // Fecha todas as conex�es do pool
    procedure ReleaseConnection(const pConnection: IZConnection); // Devolve a conexao ao Pool
  end;

implementation

{ TConfiguration }

constructor TConfiguration.Create;
begin
  inherited;
  FProperties := TStringList.Create;
end;

destructor TConfiguration.Destroy;
begin
  FreeAndNil(FProperties);
  inherited;
end;

function TConfiguration.GetProperties: TStrings;
begin
  Result := FProperties;
end;

function TConfiguration.GetPropertyItem(const pName: string): string;
begin
  Result := FProperties.Values[pName]
end;

procedure TConfiguration.SetPropertyItem(const pName, Value: string);
begin
  FProperties.Values[pName] := Value;
end;

{ ******************************************************************************

                          TInfraConnectionProvider

*******************************************************************************}

{**
  Cria uma nova inst�ncia de TInfraConnectionProvider.
  @param MaxSize Tamanho m�ximo do Pool de conex�es
  @param ADriverManager Um objeto do tipo IZDriverManager que criar� as conex�es
  @param AConfiguration Um objeto do tipo IConfiguration que cont�m todas as
    informa��es para criar uma nova conex�o
}
constructor TInfraConnectionProvider.Create(MaxSize, ExpirationTime: Integer;
  ADriverManager: IZDriverManager; AConfiguration: IConfiguration);
begin
  inherited Create;
  FCriticalSection := TCriticalSection.Create;
  FDriverManager := ADriverManager;
  FConfiguration := AConfiguration;
  SetLength(FPool, MaxSize);
end;

destructor TInfraConnectionProvider.Destroy;
begin
  SetLength(FPool, 0);
  FConfiguration := nil;
  FCriticalSection.Free;
  inherited;
end;

procedure TInfraConnectionProvider.Close;
var
  i: Integer;
begin
  for i := Low(FPool) to High(FPool) do
    ReleaseConnection(FPool[i]);
end;

{**
  Localiza um objeto no Pool. Se este n�o for encontrado retorna nil
  @param pConnection Objeto a ser localizado
  @return Retorna o objeto encontrado ou nil caso n�o seja localizado
}
function TInfraConnectionProvider.FindConnection(const pConnection: IZConnection): IZConnection;
var
  i: Integer;
begin
  Result := nil;
  for i := Low(FPool) to High(FPool) do
    if FPool[i] = pConnection then
    begin
      Result := FPool[i];
      Break;
    end;
end;

{**
  Libera uma conex�o para ser reutilizada
  @param pConnection Conex�o a ser liberada
}
procedure TInfraConnectionProvider.ReleaseConnection(const pConnection: IZConnection);
begin
  if FindConnection(pConnection) = nil then
    raise EInfraConnectionProviderError.Create('Conex�o n�o encontrada no Pool deste Provider');

  if pConnection.IsClosed then
    raise EInfraConnectionProviderError.Create('Conex�o j� fechada');

  // Ao fechar a conexao, ela, automaticamente, fica dispon�vel no pool
  pConnection.Close;

  // TODO: Criar Thread para verificar o tempo de expira��o do objeto
  // ...
end;

{**
  Procura no Pool por uma conex�o dispon�vel (ou seja, uma conexao fechada).
  E, caso a encontre, retorna-a.
  @return Retorna um objeto do tipo IZConnection
}
function TInfraConnectionProvider.GetFreeConnection: IZConnection;
var
  i: Integer;
begin
  Result := nil;
  for i := Low(FPool) to High(FPool) do
    if Assigned(FPool[i]) and FPool[i].IsClosed then
    begin
      Result := FPool[i];
      Break;
    end;
end;

function TInfraConnectionProvider.BuildConnectionString(pConfiguration: IConfiguration): string;
begin
  Result := 'zdbc:' + pConfiguration.PropertyItem['protocol'] +
    '://' + pConfiguration.PropertyItem['hostname'] +
    '/' + pConfiguration.PropertyItem['database'] +
    '?username=' + pConfiguration.PropertyItem['username'] +
    ';password=' + pConfiguration.PropertyItem['password'];
end;

{**
  Cria uma nova conexao, caso haja algum slot vazio.
  Caso contr�rio, levanta uma exce��o EInfraConnectionProviderError
  @return Retorna um objeto do tipo IZConnection
}
function TInfraConnectionProvider.CreateConnection: IZConnection;
var
  i: Integer;
begin
  for i := Low(FPool) to High(FPool) do
    if not Assigned(FPool[i]) then
    begin
      FPool[i] := FDriverManager.GetConnection(BuildConnectionString(FConfiguration));
      Result := FPool[i];
      Exit;
    end;

  raise EInfraConnectionProviderError.Create('N�mero m�ximo de conex�es excedido');
end;

{**
  Procura no Pool por uma conex�o dispon�vel e, caso a encontre, retorna-a.
  Caso contr�rio, tenta criar uma nova conex�o. Se isto n�o for poss�vel,
  levanta uma exce��o EInfraConnectionProviderError
  @return Retorna um objeto do tipo IZConnection
}
function TInfraConnectionProvider.GetConnection: IZConnection;
begin
  FCriticalSection.Acquire;
  try
    Result := GetFreeConnection;
    if not Assigned(Result) then
      Result := CreateConnection;
  finally
    FCriticalSection.Release;
  end;
end;

end.

