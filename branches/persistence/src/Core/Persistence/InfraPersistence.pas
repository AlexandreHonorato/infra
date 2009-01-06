unit InfraPersistence;

interface

uses
  SysUtils,
  SyncObjs,
  Classes,
  Contnrs,
  {Zeos}
  ZDbcIntfs,
  {Infra}
  InfraCommon,
  InfraCommonIntf,
  InfraValueTypeIntf,
  InfraPersistenceIntf;
  
type
  /// Classe para armazenar as configura��es do Framework
  TConfiguration = class(TBaseElement, IConfiguration)
  private
    /// Aqui s�o armazenadas as configura��es no formato <nome>=<valor>
    FProperties: TStrings;
  protected
    function GetProperties: TStrings;
    function GetAsInteger(const pName: string): Integer; overload;
    function GetAsDouble(const pName: string): Double; overload;
    function GetAsString(const pName: string): string; overload;
    function GetValue(const pName: string; const pDefaultValue: Integer): Integer; overload;
    function GetValue(const pName: string; const pDefaultValue: Double): Double; overload;
    function GetValue(const pName: string; const pDefaultValue: string): string; overload;
    procedure SetValue(const pName: string; const Value: Integer); overload;
    procedure SetValue(const pName: string; const Value: Double); overload;
    procedure SetValue(const pName: string; const Value: string); overload;
    procedure Clear;

    property Properties: TStrings read GetProperties;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

  /// Classe respons�vel por prover conex�es com o SGDB
  TConnectionProvider = class(TBaseElement, IConnectionProvider)
  private
    /// Armazena uma refer�ncia ao objeto que cont�m as configura��es do Framework
    FConfiguration: IConfiguration;
    /// O pool
    FSlots: array of IZConnection;
    /// CriticalSection usado para evitar conflitos em aplica��es multi-thread
    FCriticalSection: TCriticalSection;
    
    function BuildConnectionString(pConfiguration: IConfiguration): string;
    procedure CloseConnections;
  protected
    function GetFreeConnection: IZConnection;
    function CreateConnection: IZConnection;
    function FindConnection(const pConnection: IZConnection): IZConnection;
  public
    constructor Create(pConfiguration: IConfiguration); reintroduce;
    destructor Destroy; override;
    function GetConnection: IZConnection;
    procedure Close;
    procedure ReleaseConnection(const pConnection: IZConnection); 
  end;

  /// Descri��o da classe
  TPersistentState = class(TBaseElement, IPersistentState)
  private
    FState: TPersistentStateKind;
    FIsPersistent: Boolean;
  protected
    function GetIsPersistent: Boolean;
    function GetState: TPersistentStateKind;
    procedure SetIsPersistent(Value: Boolean);
    procedure SetState(Value: TPersistentStateKind);
    property IsPersistent: Boolean read GetIsPersistent write SetIsPersistent;
    property State: TPersistentStateKind read GetState write SetState;
  end;

  /// Descri��o da classe
  TSQLCommand = class(TBaseElement, ISQLCommand)
  private
    FName: string;
    FParams: ISQLCommandParams;    
  protected
    FPersistenceEngine: IPersistenceEngine;
    function GetName: string;
    function GetParams:ISQLCommandParams;
    procedure SetName(const Value: string);
    property Params: ISQLCommandParams read GetParams;
  public
    constructor Create(pPersistenceEngine: IPersistenceEngine); reintroduce;
  end;

  /// Descri��o da classe
  TSQLCommandQuery = class(TSQLCommand, ISQLCommandQuery)
  private
    FClassID: TGUID;
    FListID: TGUID;
    function CreateList: IInfraList;
  protected
    function GetResult: IInfraType;
    function GetList: IInfraList;
    function GetListID: TGUID;
    function GetClassID: TGUID;
    procedure SetListID(const Value: TGUID);
    procedure SetClassID(const Value: TGUID);
    property ClassID: TGUID read GetClassID write SetClassID;
    property ListID: TGUID read GetListID write SetListID;
  end;

  /// Descri��o da classe
  TSession = class(TBaseElement, ISession)
  private
    FPersistenceEngine: IPersistenceEngine;
    FCommandList: ISQLCommandList;
  protected
    function Load(const pCommandName: string; 
      const pObj: IInfraObject = nil): ISQLCommandQuery; overload;
    function Load(const pCommandName: string; 
      const pClassID: TGUID): ISQLCommandQuery; overload;
    function Load(const pCommandName: string;
      const pClassID: TGUID; const pListID: TGUID): ISQLCommandQuery; overload;
    function Load(const pCommandName: string;
      const pObj: IInfraObject; const pListID: TGUID): ISQLCommandQuery; overload;
    function Delete(const pCommandName: string; const pObj: IInfraObject): ISQLCommand;
    function Save(const pCommandName: string; const pObj: IInfraObject): ISQLCommand;
    function Flush: Integer;
  public
    constructor Create(const pPersistenceEngine: IPersistenceEngine); reintroduce;
  end;

  /// Descri��o da classe
  TPersistenceEngine = class(TBaseElement, IPersistenceEngine)
  private
    FConfiguration: IConfiguration;
    FConnnectionProvider: IConnectionProvider;
    FParse: IParseParams;
    function GetReader: ITemplateReader;
    procedure SetParameters(const pStatement: IZPreparedStatement;
      const pSqlCommand: ISqlCommand);
    function GetRowFromResultSet(
      const pSqlCommand: ISQLCommandQuery;
      const pResultSet: IZResultSet): IInfraObject;
  protected
    procedure DoLoad(const pST: IZPreparedStatement; const pSqlCommand:
      ISQLCommandQuery; const pList: IInfraList);
    procedure SetConnection(const pConnection: IZConnection);
    procedure Load(const pSqlCommand: ISQLCommandQuery; const pList: IInfraList);
    function Execute(const pSqlCommand: ISqlCommand): Integer;
  public
    constructor Create(pConfiguration: IConfiguration); reintroduce;
  end;

  /// Descri��o da classe
  TInfraPersistenceService = class(TBaseElement, IInfraPersistenceService)
  private
    FConfiguration: IConfiguration;
    FPersistenceEngine: IPersistenceEngine;
    function GetPersistenceEngine: IPersistenceEngine;
  protected
    function GetConfiguration: IConfiguration;
    function OpenSession: ISession; overload;
    procedure SetConnection(const pConnection: IZConnection);
    property Configuration: IConfiguration read GetConfiguration;
  end;

  /// Descri��o da classe
  TTemplateReader = class(TElement, ITemplateReader)
  private
    FConfiguration: IConfiguration;
  protected
    function Read(const pTemplateName: string): string;
    function GetConfiguration: IConfiguration;
    procedure SetConfiguration(const Value: IConfiguration);
    property Configuration: IConfiguration read GetConfiguration write SetConfiguration;
  public
    constructor Create; reintroduce; virtual;
  end;

  /// Classe utilit�ria para obter par�metros e macros de uma instru��o SQL
  TParseParams = class(TBaseElement, IParseParams)
  private
    FParams: TStrings;
    FMacroParams: TStrings;
  protected
    procedure Parse(const pSQL: string);
    function GetParams: TStrings;
    function GetMacroParams: TStrings;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

implementation

uses
  InfraPersistenceConsts,
  InfraBasicList,
  InfraConsts,
  List_SQLCommandList,
  List_SQLCommandParam,
  InfraValueType, RegExpr;

{ TConfiguration }

/// Cria uma nova inst�ncia de TConfiguration

constructor TConfiguration.Create;
begin
  inherited;
  FProperties := TStringList.Create;
end;

/// Destr�i a inst�ncia de TConfiguration

destructor TConfiguration.Destroy;
begin
  FreeAndNil(FProperties);
  inherited;
end;

///  Limpa todas as propriedades

procedure TConfiguration.Clear;
begin
  FProperties.Clear;
end;

{**
  Obtem o valor de uma propriedade como Double

  @param pName Nome da propriedade da qual se quer obter o valor
  @returns O valor da propriedade como Double
}

function TConfiguration.GetAsDouble(const pName: string): Double;
begin
  Result := StrToFloat(FProperties.Values[pName]);
end;

{**
  Obtem o valor de uma propriedade como Integer

  @param pName Nome da propriedade da qual se quer obter o valor
  @returns O valor da propriedade como Integer
}

function TConfiguration.GetAsInteger(const pName: string): Integer;
begin
  Result := StrToInt(FProperties.Values[pName]);
end;

{**
  Obtem o valor de uma propriedade como string

  @param pName Nome da propriedade da qual se quer obter o valor
  @returns O valor da propriedade como string
}

function TConfiguration.GetAsString(const pName: string): string;
begin
  Result := FProperties.Values[pName];
end;

{**
  Obtem uma referencia ao objeto que cont�m as propriedades

  @returns Um objeto do tipo TStrings
}

function TConfiguration.GetProperties: TStrings;
begin
  Result := FProperties;
end;

{**
  Obtem o valor de uma propriedade como Integer e, se n�o existir, o valor default

  @param pName Nome da propriedade da qual se quer obter o valor
  @returns O valor da propriedade como Integer ou o valor default
}

function TConfiguration.GetValue(const pName: string;
  const pDefaultValue: Integer): Integer;
begin
  if FProperties.IndexOfName(pName) <> -1 then
    Result := StrToIntDef(FProperties.Values[pName], pDefaultValue)
  else
    Result := pDefaultValue;
end;

{**
  Obtem o valor de uma propriedade como Double e, se n�o existir, o valor default

  @param pName Nome da propriedade da qual se quer obter o valor
  @returns O valor da propriedade como Double ou o valor default
}

function TConfiguration.GetValue(const pName: string;
  const pDefaultValue: Double): Double;
begin
  if FProperties.IndexOfName(pName) <> -1 then
    Result := StrToFloatDef(FProperties.Values[pName], pDefaultValue)
  else
    Result := pDefaultValue;
end;

{**
  Obtem o valor de uma propriedade como string e, se n�o existir, o valor default

  @param pName Nome da propriedade da qual se quer obter o valor
  @returns O valor da propriedade como string ou o valor default
}

function TConfiguration.GetValue(const pName, pDefaultValue: string): string;
begin
  if FProperties.IndexOfName(pName) <> -1 then
    Result := FProperties.Values[pName]
  else
    Result := pDefaultValue;
end;

{**
  Atribui o valor de uma propriedade como Integer

  @param pName Nome da propriedade � qual se quer atribuir o valor
}

procedure TConfiguration.SetValue(const pName: string; const Value: Integer);
begin
  FProperties.Values[pName] := IntToStr(Value);
end;

{**
  Atribui o valor de uma propriedade como Double

  @param pName Nome da propriedade � qual se quer atribuir o valor
}

procedure TConfiguration.SetValue(const pName: string; const Value: Double);
begin
  FProperties.Values[pName] := FloatToStr(Value);
end;

{**
  Atribui o valor de uma propriedade como string

  @param pName Nome da propriedade � qual se quer atribuir o valor
}

procedure TConfiguration.SetValue(const pName, Value: string);
begin
  FProperties.Values[pName] := Value;
end;

{ TInfraConnectionProvider }

{**
  Cria uma nova inst�ncia de TInfraConnectionProvider.

  @param MaxSize Tamanho m�ximo do Pool de conex�es
  @param AConfiguration Um objeto do tipo IConfiguration que cont�m todas as
    informa��es para criar uma nova conex�o
}
constructor TConnectionProvider.Create(pConfiguration: IConfiguration);
var
  iMax: Integer;
begin
  if not Assigned(pConfiguration) then
    raise EInfraArgumentError.Create('Configuration in ConnectionProvider.Create');
  inherited Create;
  FCriticalSection := TCriticalSection.Create;
  FConfiguration := pConfiguration;
  iMax := FConfiguration.GetValue(cCONFIGKEY_MAXCONNECTIONS, cGlobalMaxConnections);
  SetLength(FSlots, iMax);
end;

destructor TConnectionProvider.Destroy;
begin
  CloseConnections;
  SetLength(FSlots, 0);
  FCriticalSection.Free;
  inherited;
end;

/// Fecha todas as conex�es ativas

procedure TConnectionProvider.CloseConnections;
var
  i: Integer;
begin
  for i := Low(FSlots) to High(FSlots) do
    if Assigned(FSlots[i]) then
      FSlots[i].Close;
end;

/// Devolve todas as conex�es ao pool
 
procedure TConnectionProvider.Close;
var
  i: integer;
begin
  for i := Low(FSlots) to High(FSlots) do
    if Assigned(FSlots[i]) then
      ReleaseConnection(FSlots[i]);
end;

{**
  Localiza um objeto no Pool. Se este n�o for encontrado retorna nil

  @param pConnection Objeto a ser localizado
  @return Retorna o objeto encontrado ou nil caso n�o seja localizado
}

function TConnectionProvider.FindConnection(const pConnection: IZConnection): IZConnection;
var
  i: Integer;
begin
  Result := nil;
  for i := Low(FSlots) to High(FSlots) do
    if FSlots[i] = pConnection then
    begin
      Result := FSlots[i];
      Break;
    end;
end;

{**
  Libera uma conex�o de volta ao pool para ser reutilizada

  @param pConnection Conex�o a ser liberada
}
procedure TConnectionProvider.ReleaseConnection(const pConnection: IZConnection);
begin
  if FindConnection(pConnection) = nil then
    raise EPersistenceConnectionProviderError.Create(cErrorConnectionNotFoundOnPool);
  if pConnection.IsClosed then
    raise EPersistenceConnectionProviderError.Create(cErrorAlreadyClosedConnection);
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
function TConnectionProvider.GetFreeConnection: IZConnection;
var
  i: Integer;
begin
  Result := nil;
  for i := Low(FSlots) to High(FSlots) do
    if not Assigned(FSlots[i]) or
      (Assigned(FSlots[i]) and FSlots[i].IsClosed) then
    begin
      Result := FSlots[i];
      Break;
    end;
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
  Cria uma nova conexao, caso haja algum slot vazio.
  Caso contr�rio, levanta uma exce��o EInfraConnectionProviderError

  @return Retorna um objeto do tipo IZConnection
}
function TConnectionProvider.CreateConnection: IZConnection;
var
  i: Integer;
begin
  for i := Low(FSlots) to High(FSlots) do
    if not Assigned(FSlots[i]) then
    begin
      FSlots[i] := DriverManager.GetConnection(BuildConnectionString(FConfiguration));
      Result := FSlots[i];
      Exit;
    end;
  raise EPersistenceConnectionProviderError.Create(cErrorConnectionsLimitExceeded);
end;

{**
  Procura no Pool por uma conex�o dispon�vel e, caso a encontre, retorna-a.
  Caso contr�rio, tenta criar uma nova conex�o. Se isto n�o for poss�vel,
  levanta uma exce��o EInfraConnectionProviderError

  @return Retorna um objeto do tipo IZConnection
}
function TConnectionProvider.GetConnection: IZConnection;
begin
  FCriticalSection.Acquire;
  try
    // *** alterado at� que o pool funcione
    // Result := CreateConnection;
    Result := DriverManager.GetConnection(BuildConnectionString(FConfiguration));
  finally
    FCriticalSection.Release;
  end;
end;

{ TPersistentState }

{*

  @return ResultDescription
}

function TPersistentState.GetIsPersistent: Boolean;
begin
  Result := FIsPersistent;
end;

{*

  @return ResultDescription
}

function TPersistentState.GetState: TPersistentStateKind;
begin
  Result := FState;
end;

{*

  @param Value   ParameterDescription
  @return ResultDescription
}

procedure TPersistentState.SetIsPersistent(Value: Boolean);
begin
  FIsPersistent := Value;
end;

{*

  @param Value   ParameterDescription
  @return ResultDescription
}

procedure TPersistentState.SetState(Value: TPersistentStateKind);
begin
  FState := Value;
end;

{ TSQLCommand }

{*
  Cria uma nova inst�ncia de TSQLCommand.

  @param pPersistenceEngine   ParameterDescription
}

constructor TSQLCommand.Create(pPersistenceEngine: IPersistenceEngine);
begin
  inherited Create;
  FPersistenceEngine := pPersistenceEngine;
  FParams := TSQLCommandParams.Create;
end;

{*

  @return Retorna o nome ???? DE QUE MESMO ????
}

function TSQLCommand.GetName: string;
begin
  Result := FName;
end;

{*

  @param Value   ParameterDescription
}

procedure TSQLCommand.SetName(const Value: string);
begin
  if not AnsiSameText(FName, Value) then
    FName := Value;
end;

{*

  @return ResultDescription
}

function TSQLCommand.GetParams: ISQLCommandParams;
begin
  Result := FParams;
end;

{ TSQLCommandQuery }

{*

  @return ResultDescription
}

function TSQLCommandQuery.GetClassID: TGUID;
begin
  Result := FClassID;
end;

{*

  @return ResultDescription
}

function TSQLCommandQuery.GetListID: TGUID;
begin
  Result := FListID;
end;

{*

  @return ResultDescription
}

function TSQLCommandQuery.CreateList: IInfraList;
begin
  Result := TypeService.CreateInstance(FListID) as IInfraList;
end;

{*

  @return ResultDescription
}

function TSQLCommandQuery.GetResult: IInfraType;
var
  vList: IInfraList;
begin
  vList := CreateList;
  FPersistenceEngine.Load(Self, vList);
  // *** deveria gerar exce��o caso o load acima retornar mais de um objeto na lista????
  Result := vList[0] as IInfratype;
end;

{*

  @return ResultDescription
}

function TSQLCommandQuery.GetList: IInfraList;
begin
  Result := CreateList;
  FPersistenceEngine.Load(Self, Result);
end;

{*

  @param Value   ParameterDescription
}

procedure TSQLCommandQuery.SetClassID(const Value: TGUID);
begin
  FClassID := Value;
end;

{*

  @param Value   ParameterDescription
}

procedure TSQLCommandQuery.SetListID(const Value: TGUID);
begin
  FListID := Value;
end;

{ TSession }

{*

  @param pPersistenceEngine   ParameterDescription
}

constructor TSession.Create(const pPersistenceEngine: IPersistenceEngine);
begin
  if not Assigned(pPersistenceEngine) then
    raise EInfraArgumentError.Create('PersistenceEngine in Session.Create');
  inherited Create;
  FPersistenceEngine := pPersistenceEngine;
  FCommandList := TSQLCommandList.Create;
end;

{*

  @param pCommandName   ParameterDescription
  @param pClassID   ParameterDescription
  @return ResultDescription
}

function TSession.Load(const pCommandName: string; const pClassID: TGUID): ISQLCommandQuery;
begin
  Result := TSQLCommandQuery.Create(FPersistenceEngine);
  Result.Name := pCommandName;
  Result.ListID := IInfraList;
  if not IsEqualGUID(pClassID, NullGUID) then
    Result.ClassID := pClassID;
end;

{*

  @param pCommandName   ParameterDescription
  @param pClassID   ParameterDescription
  @param pListID   ParameterDescription
  @return ResultDescription
}

function TSession.Load(const pCommandName: string; const pClassID, pListID: TGUID): ISQLCommandQuery;
begin
  Result := Load(pCommandName, pClassID);
  Result.ListID := pListID;
end;

{*

  @param pCommandName   ParameterDescription
  @param pObj   ParameterDescription
  @param pListID   ParameterDescription
  @return ResultDescription
}

function TSession.Load(const pCommandName: string; const pObj: IInfraObject = nil): ISQLCommandQuery;
begin
  if Assigned(pObj) then
    Result := Load(pCommandName, pObj.TypeInfo.TypeID)
  else
    Result := Load(pCommandName, NullGUID);
  if Assigned(pObj) then
    Result.Params.AddObject(pObj);
end;

{*

  @param pCommandName   ParameterDescription
  @param pObj   ParameterDescription
  @return ResultDescription
}

function TSession.Load(const pCommandName: string; const pObj: IInfraObject; const pListID: TGUID): ISQLCommandQuery;
begin
  Result := Load(pCommandName, pObj.TypeInfo.TypeID, pListID);
  Result.Params.AddObject(pObj);
end;

{*

  @param pCommandName   ParameterDescription
  @param pObj   ParameterDescription
  @return ResultDescription
}

function TSession.Save(const pCommandName: string; const pObj: IInfraObject): ISQLCommand;
begin
  Result := TSQLCommand.Create(FPersistenceEngine);
  with Result do
  begin
    Name := pCommandName;
    Params.AddObject(pObj);
  end;
  FCommandList.Add(Result);
end;

{*

  @return ResultDescription
}

function TSession.Delete(const pCommandName: string; const pObj: IInfraObject): ISQLCommand;
var
  vState: IPersistentState;
begin
  if Supports(pObj, IPersistentState, vState) then
  begin
    vState.State := osDeleted;
    Save(pCommandName, pObj);
  end;
end;

{*

  @param pConfiguration   ParameterDescription
  @return ResultDescription
}

function TSession.Flush: Integer;
var
  i: integer;
begin
  Result := 0;
  for i := 0 to FCommandList.Count - 1 do
    Result := Result + FPersistenceEngine.Execute(FCommandList[i]);
end;

{ TPersistenceEngine }

{*
  Cria uma nova inst�ncia de TPersistenceEngine
  @param pConfiguration   ParameterDescription
}

constructor TPersistenceEngine.Create(pConfiguration: IConfiguration);
begin
  inherited Create;
  if not Assigned(pConfiguration) then
    raise EInfraArgumentError.Create('Configuration in PersistenceEngine.Create');
  FConfiguration := pConfiguration;
  FConnnectionProvider := TConnectionProvider.Create(pConfiguration);
  FParse := TParseParams.Create;
end;

{*

  @param pSqlCommand   ParameterDescription
  @return ResultDescription
}

function TPersistenceEngine.GetReader: ITemplateReader;
var
  vReaderClassName: string;
  vReaderTypeInfo: IClassInfo;
begin
  vReaderClassName := FConfiguration.GetValue(cCONFIGKEY_TEMPLATETYPE, EmptyStr);
  if vReaderClassName = EmptyStr then
    raise EPersistenceTemplateError.Create(cErrorTemplateTypeInvalid);
  vReaderTypeInfo := TypeService.GetType(vReaderClassName, True);
  Result := TypeService.CreateInstance(vReaderTypeInfo) as ITemplateReader;
  Result.Configuration := FConfiguration;
end;

{
  carregar a sql usando um reader com base no Name do pSqlCommand vReader.Read(pSqlCommand.Name)
  preencher os params da sql com base nos Params do pSqlCommand
  pegar o connection no connectionprovider
  executa a sql  e retornar  a quantidade de registros afetados
}

{*

  @param pSqlCommand   ParameterDescription
  @return ResultDescription
}

function TPersistenceEngine.Execute(const pSqlCommand: ISqlCommand): Integer;
var
  vReader: ITemplateReader;
  vSQL: string;
  vStatement: IZPreparedStatement;
  vConnection: IZConnection;
begin
  vReader := GetReader;
  vSQL := vReader.Read(pSqlCommand.Name);
  FParse.Parse(vSQL);
  // *** 1) Acho que os par�metros macros de FParse devem ser substituidos aqui antes de chamar o PrepareStatementWithParams
  // *** 2) Acho que poderia chamar o PrepareStatementWithParams passando o FParse.Params.GetParams
  vConnection := FConnnectionProvider.GetConnection;
  vStatement := vConnection.PrepareStatementWithParams(vSQL, FParse.GetParams);
  SetParameters(vStatement, pSqlCommand);
  // *** 3) Acho que pode retornar um simples Integer.
  Result := vStatement.ExecuteUpdatePrepared;
end;

{**

  @param pST   ParameterDescription
  @param pSqlCommand   ParameterDescription
  @param pList   ParameterDescription
  @return ResultDescription
}

procedure TPersistenceEngine.DoLoad(const pST: IZPreparedStatement;
  const pSqlCommand: ISQLCommandQuery; const pList: IInfraList);
var
  vResultSet: IZResultSet;
  vObject: IInfraObject;
begin
  vResultSet := pST.ExecuteQueryPrepared;
  try
    while vResultSet.Next do
    begin
      vObject :=
        GetRowFromResultSet(pSqlCommand, vResultSet);
      pList.Add(vObject);
    end;
  finally
    vResultSet.Close;
  end;
end;

{ carregar a sql usando um reader com base no Name do pSqlCommand
  preencher os params da sql com base nos Params do pSqlCommand
  executa a sql e pega um IZStatement
  Faz um la�o para pegar cada registro
  cria um objeto com base no ClassType do pSqlCommand,
  Seta o estado persistent e clean ao objeto criado
  faz a carga dos atributos com base no registro
  Adiciona o novo objeto em pList retorna a lista }

{**

  @param pSqlCommand   ParameterDescription
  @param pList   ParameterDescription
  @return ResultDescription
}

procedure TPersistenceEngine.Load(const pSqlCommand: ISQLCommandQuery;
  const pList: IInfraList);
var
  vReader: ITemplateReader;
  vSQL: string;
  vStatement: IZPreparedStatement;
  vConnection: IZConnection;
begin
  vReader := GetReader;
  vSQL := vReader.Read(pSqlCommand.Name);
  // *** 1) se a SQL est� vazia aqui deveria gerar exce��o ou deveria ser dentro
  // do vReader.Read????
  FParse.Parse(vSQL);
  // *** 2) Acho que os par�metros macros de FParse devem ser substituidos aqui
  // antes de chamar o PrepareStatementWithParams
  try
    vConnection := FConnnectionProvider.GetConnection;
    vStatement := vConnection.PrepareStatementWithParams(vSQL, FParse.GetParams);
    SetParameters(vStatement, pSqlCommand);
    DoLoad(vStatement, pSqlCommand, pList);
  finally
    vStatement.Close;
  end;
end;

{**

  @param pConnection   ParameterDescription
  @return ResultDescription
}

procedure TPersistenceEngine.SetConnection(const pConnection: IZConnection);
begin
  // preencher o connection provider com o pConnection
end;

// *** 1) Como poderiamos carregar Objetos/Listas relacionados ao objeto atual a
// ***    partir de colunas vindos no resultset frutos de um join?
{**

  @param pSqlCommand   ParameterDescription
  @param pResultSet   ParameterDescription
  @return ResultDescription
}

function TPersistenceEngine.GetRowFromResultSet(
  const pSqlCommand: ISQLCommandQuery;
  const pResultSet: IZResultSet): IInfraObject;
var
  vIndex: integer;
  vAttribute: IInfraType;
  vZeosType: IZTypeAnnotation;
  vAliasName: string;
begin
  // *** Ser� que isso deveria estar aqui?????
  if IsEqualGUID(pSqlCommand.GetClassID, NullGUID) then
    Raise EPersistenceEngineError.Create(
      cErrorPersistenceEngineObjectIDUndefined);
  Result := TypeService.CreateInstance(pSqlCommand.GetClassID) as IInfraObject;
  if Assigned(Result) then
  begin
    // A lista de colunas do ResultSet.GetMetadata do Zeos come�a do 1.
    for vIndex := 1 to pResultSet.GetMetadata.GetColumnCount do
    begin
      vAliasName := pResultSet.GetMetadata.GetColumnLabel(vIndex);
      vAttribute :=
        Result.TypeInfo.GetProperty(Result, vAliasName) as IInfraType;
      if not Assigned(vAttribute) then
        Raise EPersistenceEngineError.CreateFmt(
          cErrorPersistenceEngineAttributeNotFound,
          [vAliasName, pResultSet.GetMetadata.GetColumnName(vIndex)]);
      if Supports(vAttribute.TypeInfo, IZTypeAnnotation, vZeosType) then
        vZeosType.NullSafeGet(pResultSet, vIndex, vAttribute)
      else
        Raise EPersistenceEngineError.CreateFmt(
          cErrorPersistenceEngineCannotMapAttribute, [vAttribute.TypeInfo.Name]);
    end;
  end;
end;

// *** o que acontece caso tenhamos um template com nomes de parametros repetidos?
{**

  @param pStatement   ParameterDescription
  @param pSqlCommand   ParameterDescription
  @return ResultDescription
}
procedure TPersistenceEngine.SetParameters(
  const pStatement: IZPreparedStatement; const pSqlCommand: ISqlCommand);
var
  vIndex: integer;
  vParamValue: IInfraType;
  vParams: TStrings;
  vZeosType: IZTypeAnnotation;
begin
  vParams := pStatement.GetParameters;
  for vIndex := 0 to vParams.Count-1 do
  begin
    vParamValue := pSqlCommand.Params[vParams[vIndex]];
    if Assigned(vParamValue)
      and Supports(vParamValue.TypeInfo, IZTypeAnnotation, vZeosType) then
      // Aumenta o vIndex por que no Zeos as colunas come�am de 1
      vZeosType.NullSafeSet(pStatement, vIndex+1, vParamValue)
    else
      raise EPersistenceEngineError.CreateFmt(
        cErrorPersistenceEngineParamNotFound, [vParams[vIndex]]);
  end;
end;

{ TInfraPersistenceService }

{**
  Permite acesso as configura��es do Framework
  Chame GetConfiguration para obter uma interface de acesso aos par�metros de
  configura��o do framework.
  Ele assegura que seja retornado sempre a mesma inst�ncia.
  
  @return Retorna uma interface do tipo IConfiguration
*}

function TInfraPersistenceService.GetConfiguration: IConfiguration;
begin
  if not Assigned(FConfiguration) then
    FConfiguration := TConfiguration.Create;
  Result := FConfiguration;
end;

{**
  Permite acesso ao PersistenceEngine.
  Chame GetPersistenceEngine para obter uma interface de acesso ao PersistenceEngine.
  Ele assegura que seja retornado sempre a mesma inst�ncia.
  
  @return Retorna uma interface do tipo IPersistenceEngine
}

function TInfraPersistenceService.GetPersistenceEngine: IPersistenceEngine;
begin
  if not Assigned(FPersistenceEngine) then
    FPersistenceEngine := TPersistenceEngine.Create(FConfiguration);
  Result := FPersistenceEngine;
end;

{**
  Cria uma nova Session
  Chame OpenSession para criar uma nova instancia de Session.

  @return Retorna uma interface do tipo ISession
}

function TInfraPersistenceService.OpenSession: ISession;
begin
  Result := TSession.Create(GetPersistenceEngine);
end;

{**
  Permite setar um Connection ao PersistenceEngine
  Chame SetConnection se quiser facilitar a migra��o para o Infra.

  @param pConnection Qualquer objeto que implemente a interface IZConnection.
                     � a conexao com o banco de dados
}

procedure TInfraPersistenceService.SetConnection(
  const pConnection: IZConnection);
begin
  GetPersistenceEngine.SetConnection(pConnection);
end;

{ TTemplateReader }

{**
  Contructor de TTemplateReader. Por ser uma classe abstrata, n�o pode ser instanciada
}

constructor TTemplateReader.Create;
begin
  raise EPersistenceTemplateError.Create(cErrorTemplateTryCreateClassBase);
end;

{**

  @return ResultDescription
}

function TTemplateReader.GetConfiguration: IConfiguration;
begin
  Result := FConfiguration;
end;

{**

  @param Value   ParameterDescription
}

procedure TTemplateReader.SetConfiguration(
  const Value: IConfiguration);
begin
  FConfiguration := Value;
end;

{**

  @param pTemplateName   ParameterDescription
  @return ResultDescription
}

function TTemplateReader.Read(const pTemplateName: string): string;
begin
  Result := '';
end;

{ TParseParams }

///  Cria uma nova inst�ncia de TParseParams

constructor TParseParams.Create;
begin
  inherited;
  FParams := TStringList.Create;
  FMacroParams := TStringList.Create;
end;

///  Destr�i o objeto

destructor TParseParams.Destroy;
begin
  FParams.Free;
  FMacroParams.Free;
  inherited;
end;

{ **
  Parse analisa a instru��o SQL � procura de par�metros no formato :<nome_param>
  e macros no formato #<nome_da_macro>. Os par�metros encontrados s�o colocados
  numa lista e podem ser recuperados atrav�s da fun��o GetParams.
  As macros encontradas s�o colocadas numa lista e podem ser recuperados atrav�s
  da fun��o GetMacroParams.
  
  @param pSql instru��o SQL que ser� analisada
}

procedure TParseParams.Parse(const pSQL: string);
const
  cExpRegCommentsML = '(\/\*(.*?)\*\/)'; // comentarios no formato /* ... */
  cExpRegCommentsInLine = '--(.*?)$'; // comentarios no formato -- ...
  cExpRegInvalidMacros = '##\w+'; // macros no formato ##<nome> s�o inv�lidas
  cExpRegInvalidParams = '::\w+'; // params no formato ::<nome> s�o inv�lidos
var
  vSql: string;
  vRegEx: TRegExpr;
begin
  FParams.Clear;
  FMacroParams.Clear;

  vRegEx := TRegExpr.Create;
  try
    // Elimina do texto tudo que deve ser ignorado: coment�rios,
    // parametros e macros inv�lidas
    vRegEx.Expression := cExpRegCommentsML+'|'+cExpRegInvalidMacros+'|'+
      cExpRegInvalidParams+'|'+cExpRegCommentsInline;
    vRegEx.ModifierM := True;
    vSql := vRegEx.Replace(pSQL, '', False)+' ';

    // Verifica se existe algum(a) param/macro sem nome
    vRegEx.Expression := '[:#]$|\s[:#]\s';
    if vRegEx.Exec (vSql) then
      raise EInfraParserError.Create('Par�metro inv�lido');

    // Depois de remover do texto as partes a serem ignoradas,
    // procuramos por parametros e macros v�lidos
    vRegEx.Expression := '[\s\(]:(\w+)[^w]|[\s\(]#(\w+)[^w]|^#(\w+)[^w]';
    if vRegEx.Exec (vSql) then
    repeat
      if vRegEx.MatchPos[1] > 0 then
        FParams.Add (System.Copy (vSql, vRegEx.MatchPos[1], vRegEx.MatchLen[1]));
      if vRegEx.MatchPos[2] > 0 then
        FMacroParams.Add (System.Copy (vSql, vRegEx.MatchPos[2], vRegEx.MatchLen[2]));
      if vRegEx.MatchPos[3] > 0 then
        FMacroParams.Add (System.Copy (vSql, vRegEx.MatchPos[3], vRegEx.MatchLen[3]));
    until not vRegEx.ExecNext;
  finally
    vRegEx.Free;
  end;
end;

{**

  @return ResultDescription  
}

function TParseParams.GetMacroParams: TStrings;
begin
  Result := FMacroParams;
end;

{**

  @return ResultDescription  
}

function TParseParams.GetParams: TStrings;
begin
  Result := FParams;
end;

// N�o entendi, mas se p�r direto no Initialization acontece Access Violations.
// ATEN��O: Vc n�o deve atribuir PersistenceService para uma vari�vel de
// instancia nem global sem que no final da aplica��o atribuia nil a ela explicitamente,
// sob pena de acontecer um AV no final da aplica��o
procedure InjectPersistenceService;
begin
  (ApplicationContext as IBaseElement).Inject(
    IInfraPersistenceService, TInfraPersistenceService.Create);
end;

initialization
  InjectPersistenceService;

end.
