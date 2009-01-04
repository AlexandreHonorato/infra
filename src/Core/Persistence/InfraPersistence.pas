// xxx
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
  InfraPersistenceIntf,
  InfraPersistenceAnnotationIntf;
  
type  
  TConfiguration = class(TBaseElement, IConfiguration)
    FProperties: TStrings;
  protected
    function GetProperties: TStrings;
    function GetPropertyItem(const pName: string): string;
    function GetAsInteger(const pName: string): Integer; overload;
    function GetAsDouble(const pName: string): Double; overload;
    function GetAsString(const pName: string): string; overload;
    function GetValue(const pName: string; const pDefaultValue: Integer): Integer; overload;
    function GetValue(const pName: string; const pDefaultValue: Double): Double; overload;
    function GetValue(const pName: string; const pDefaultValue: string): string; overload;
    procedure SetValue(const pName: string; const Value: Integer); overload;
    procedure SetValue(const pName: string; const Value: Double); overload;
    procedure SetValue(const pName: string; const Value: string); overload;
    procedure SetPropertyItem(const pName: string; const Value: string);
    procedure Clear;
    property Properties: TStrings read GetProperties;
    property PropertyItem[const pName: string]: string read GetPropertyItem write SetPropertyItem;
  public
    constructor Create; override;
    destructor Destroy; override;
  end;

  /// Classe respons�vel por prover conex�es com o SGDB
  TConnectionProvider = class(TBaseElement, IConnectionProvider)
  private
    FConfiguration: IConfiguration;
    FSlots: array of IZConnection; // O pool
    FCriticalSection: TCriticalSection;
    function BuildConnectionString(pConfiguration: IConfiguration): string;
    procedure CloseConnections; // CriticalSection usado para evitar conflitos em aplica��es multi-thread
  protected
    function GetFreeConnection: IZConnection; // Procura por uma conexao livre
    function CreateConnection: IZConnection; // Cria uma nova conexao
    function FindConnection(const pConnection: IZConnection): IZConnection; // Procura por uma conexao no pool
  public
    constructor Create(pConfiguration: IConfiguration); reintroduce;
    destructor Destroy; override;
    function GetConnection: IZConnection; // Caso tenha conexoes dispon�veis no Pool bloqueia uma e retorna-a
    procedure Close; // Fecha todas as conex�es do pool
    procedure ReleaseConnection(const pConnection: IZConnection); // Devolve a conexao ao Pool
  end;

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

  TPersistenceEngine = class(TBaseElement, IPersistenceEngine)
  private
    FConfiguration: IConfiguration;
    FConnnectionProvider: IConnectionProvider;
    function GetReader: ITemplateReader;
    procedure SetParameters(const pStatement: IZPreparedStatement; 
      const pSqlCommand: ISqlCommand);
    function GetRowFromResultSet(
      const pSqlCommand: ISQLCommand; 
      const pResultSet: IZResultSet): IInfraObject;
    procedure SetPropertyFromResultSet(const pAttribute: IInfraType; 
      const pResultSet: IZResultSet; pIndex: Integer);
  protected
    procedure SetConnection(const pConnection: IZConnection);
    procedure Load(const pSqlCommand: ISqlCommand; const pList: IInfraList);
    function Execute(const pSqlCommand: ISqlCommand): IInfraInteger;
  public
    constructor Create(pConfiguration: IConfiguration); reintroduce;
  end;

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

  TParseParams = class(TBaseElement, IParseParams)
  private
    FParams: TStrings;
    FSQL: String;
    procedure Parse;
    function IsLiteral(CurChar: Char): Boolean;
    function NameDelimiter(CurChar: Char): Boolean;
    procedure StripChar(TempBuf: PChar; Len: Word);
    function StripLiterals(Buffer: PChar): string;
    function IsParameter(CurPos: PChar; Literal: Boolean): Boolean;
    function IsFalseParameter(CurPos: PChar; Literal: Boolean): Boolean;
  protected
    function GetParams: TStrings;
  public
    constructor Create(const pSQL: string); reintroduce;
    destructor Destroy; override;
  end;

implementation

uses
  InfraPersistenceConsts,
  InfraBasicList,
  InfraConsts,
  List_SQLCommandList,
  List_SQLCommandParam,
  InfraValueType;

{ TConfiguration }

procedure TConfiguration.Clear;
begin
FProperties.clear;
end;

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

function TConfiguration.GetAsDouble(const pName: string): Double;
begin
  Result := StrToFloat(PropertyItem[pName]);
end;

function TConfiguration.GetAsInteger(const pName: string): Integer;
begin
  Result := StrToInt(PropertyItem[pName]);
end;

function TConfiguration.GetAsString(const pName: string): string;
begin
  Result := PropertyItem[pName];
end;

function TConfiguration.GetProperties: TStrings;
begin
  Result := FProperties;
end;

function TConfiguration.GetPropertyItem(const pName: string): string;
begin
  Result := FProperties.Values[pName]
end;

function TConfiguration.GetValue(const pName: string;
  const pDefaultValue: Integer): Integer;
begin
  if FProperties.IndexOfName(pName) <> -1 then
    Result := StrToIntDef(PropertyItem[pName], pDefaultValue)
  else
    Result := pDefaultValue;
end;

function TConfiguration.GetValue(const pName: string;
  const pDefaultValue: Double): Double;
begin
  if FProperties.IndexOfName(pName) <> -1 then
    Result := StrToFloatDef(PropertyItem[pName], pDefaultValue)
  else
    Result := pDefaultValue;
end;

function TConfiguration.GetValue(const pName,
  pDefaultValue: string): string;
begin
  if FProperties.IndexOfName(pName) <> -1 then
    Result := PropertyItem[pName]
  else
    Result := pDefaultValue;
end;

procedure TConfiguration.SetPropertyItem(const pName, Value: string);
begin
  FProperties.Values[pName] := Value;
end;

procedure TConfiguration.SetValue(const pName: string;
  const Value: Integer);
begin
  PropertyItem[pName] := IntToStr(Value);
end;

procedure TConfiguration.SetValue(const pName: string;
  const Value: Double);
begin
  PropertyItem[pName] := FloatToStr(Value);
end;

procedure TConfiguration.SetValue(const pName, Value: string);
begin
  PropertyItem[pName] := Value;
end;

{ TInfraConnectionProvider }

{**
  Cria uma nova inst�ncia de TInfraConnectionProvider.
  @param MaxSize Tamanho m�ximo do Pool de conex�es
  @param ADriverManager Um objeto do tipo IZDriverManager que criar� as conex�es
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

procedure TConnectionProvider.CloseConnections;
var
  i: Integer;
begin
  for i := Low(FSlots) to High(FSlots) do
    if Assigned(FSlots[i]) then
      FSlots[i].Close;
end;

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

function TPersistentState.GetIsPersistent: Boolean;
begin
  Result := FIsPersistent;
end;

function TPersistentState.GetState: TPersistentStateKind;
begin
  Result := FState;
end;

procedure TPersistentState.SetIsPersistent(Value: Boolean);
begin
  FIsPersistent := Value;
end;

procedure TPersistentState.SetState(Value: TPersistentStateKind);
begin
  FState := Value;
end;

{ TSQLCommand }

constructor TSQLCommand.Create(pPersistenceEngine: IPersistenceEngine);
begin
  inherited Create;
  FPersistenceEngine := pPersistenceEngine;
  FParams := TSQLCommandParams.Create;
end;

function TSQLCommand.GetName: string;
begin
  Result := FName;
end;

procedure TSQLCommand.SetName(const Value: string);
begin
  if not AnsiSameText(FName, Value) then
    FName := Value;
end;

function TSQLCommand.GetParams: ISQLCommandParams;
begin
  Result := FParams;
end;

{ TSQLCommandQuery }

function TSQLCommandQuery.GetClassID: TGUID;
begin
  Result := FClassID;
end;

function TSQLCommandQuery.GetListID: TGUID;
begin
  Result := FListID;
end;

function TSQLCommandQuery.CreateList: IInfraList;
begin
  Result := TypeService.CreateInstance(FListID) as IInfraList;
end;

function TSQLCommandQuery.GetResult: IInfraType;
var
  vList: IInfraList;
begin
  vList := CreateList;
  FPersistenceEngine.Load(Self, vList);
  // *** deveria gerar exce��o caso o load acima retornar mais de um objeto na lista????
  Result := vList[0] as IInfratype;
end;

function TSQLCommandQuery.GetList: IInfraList;
begin
  Result := CreateList;
  FPersistenceEngine.Load(Self, Result);  
end;
    
procedure TSQLCommandQuery.SetClassID(const Value: TGUID);
begin
  FClassID := Value;
end;

procedure TSQLCommandQuery.SetListID(const Value: TGUID);
begin
  FListID := Value;
end;

{ TSession }

constructor TSession.Create(const pPersistenceEngine: IPersistenceEngine);
begin
  if not Assigned(pPersistenceEngine) then
    raise EInfraArgumentError.Create('PersistenceEngine in Session.Create');
  inherited Create;
  FPersistenceEngine := pPersistenceEngine;
  FCommandList := TSQLCommandList.Create;
end;

function TSession.Load(const pCommandName: string; const pClassID: TGUID): ISQLCommandQuery;
begin
  Result := TSQLCommandQuery.Create(FPersistenceEngine);
  Result.Name := pCommandName;
  Result.ListID := IInfraList;
  Result.ClassID := pClassID;
end;

function TSession.Load(const pCommandName: string; const pClassID, pListID: TGUID): ISQLCommandQuery;
begin
  Result := Load(pCommandName, pClassID);
  Result.ListID := pListID;
end;

function TSession.Load(const pCommandName: string; const pObj: IInfraObject = nil): ISQLCommandQuery;
begin
  Result := Load(pCommandName, pObj.TypeInfo.TypeID);
  if Assigned(pObj) then
    Result.Params.AddObject(pObj);
end;

function TSession.Load(const pCommandName: string; const pObj: IInfraObject; const pListID: TGUID): ISQLCommandQuery;
begin
  Result := Load(pCommandName, pObj.TypeInfo.TypeID, pListID);
  Result.Params.AddObject(pObj);
end;

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

function TSession.Flush: Integer;
var
  i: integer;
begin
  Result := 0;
  for i := 0 to FCommandList.Count - 1 do
    Result := Result + FPersistenceEngine.Execute(FCommandList[i]).AsInteger;
end;

{ TPersistenceEngine }

constructor TPersistenceEngine.Create(pConfiguration: IConfiguration);
begin
  inherited Create;
  if not Assigned(pConfiguration) then
    raise EInfraArgumentError.Create('Configuration in PersistenceEngine.Create');
  FConfiguration := pConfiguration;
  FConnnectionProvider := TConnectionProvider.Create(pConfiguration);
end;

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
function TPersistenceEngine.Execute(const pSqlCommand: ISqlCommand): IInfraInteger;
var
  vReader: ITemplateReader;
  vSQL: string;
  vST: IZPreparedStatement;

begin
  vReader := GetReader;
  vSQL := vReader.Read(pSqlCommand.Name);
  vST := FConnnectionProvider.GetConnection.PrepareStatement(vSQL);
  SetParameters(vST, pSqlCommand);
  Result := TInfraInteger.NewFrom(vST.ExecuteUpdatePrepared);
end;

{ carregar a sql usando um reader com base no Name do pSqlCommand
  preencher os params da sql com base nos Params do pSqlCommand
  executa a sql e pega um IZStatement
  Faz um la�o para pegar cada registro
  cria um objeto com base no ClassType do pSqlCommand,
  Seta o estado persistent e clean ao objeto criado
  faz a carga dos atributos com base no registro
  Adiciona o novo objeto em pList retorna a lista }
procedure TPersistenceEngine.Load(const pSqlCommand: ISqlCommand; 
  const pList: IInfraList);
var
  vReader: ITemplateReader;
  vSQL: string;
  vST: IZPreparedStatement;
  vRS: IZResultSet;
  vObject: IInfraObject;
begin
  vReader := GetReader;
  vSQL := vReader.Read(pSqlCommand.Name);
  // *** se a SQL est� vazia aqui deveria gerar exce��o ou deveria ser dentro do vReader.Read????
  try
    vST := FConnnectionProvider.GetConnection.PrepareStatementWithParams(vSQL, nil);
    SetParameters(vST, pSqlCommand);
    vRS := vST.ExecuteQueryPrepared;
    while vRS.Next do
    begin
      vObject := GetRowFromResultSet(pSqlCommand, vRS);
      pList.Add(vObject);
    end;
  finally
    vRs.Close;
    vST.Close;
  end;
end;

procedure TPersistenceEngine.SetConnection(const pConnection: IZConnection);
begin
  // preencher o connection provider com o pConnection
end;

function TPersistenceEngine.GetRowFromResultSet(const pSqlCommand: ISQLCommand; 
  const pResultSet: IZResultSet): IInfraObject;
var
  vIndex: integer;
  vAttribute: IInfraType;
begin
  Result := TypeService.CreateInstance((pSqlCommand as ISQLCommandQuery).GetClassID) as IInfraObject;
  if Assigned(Result) then
  begin
    for vIndex :=0 to pResultSet.GetMetadata.GetColumnCount-1 do 
    begin
      vAttribute := Result.TypeInfo.GetProperty(
        Result, pResultSet.GetMetadata.GetColumnName(vIndex)) as IInfraType;
      SetPropertyFromResultSet(vAttribute, pResultSet, vIndex);
    end;
  end;
end;

procedure TPersistenceEngine.SetPropertyFromResultSet(
  const pAttribute: IInfraType; const pResultSet: IZResultSet; pIndex: Integer);
begin
  // *** Teria de tratar o InfraType aqui se for um Object ou InfraList
  // *** por que provavelmente estar� apontando para outro objeto e 
  // *** talvez tem que carregar com base em colunas de um join no template.
  (pAttribute.TypeInfo as IZTypeAnnotation).NullSafeGet(pResultSet, 
    pIndex, pAttribute)
end;

procedure TPersistenceEngine.SetParameters(const pStatement: IZPreparedStatement; 
  const pSqlCommand: ISqlCommand);
var
  vIndex: integer;
  vTypeInfo: IClassInfo;
  vParamValue: IInfraType;
  vParams: TStrings;
begin
  vParams := pStatement.GetParameters;
  for vIndex := 0 to vParams.Count-1 do
  begin
    vParamValue := pSqlCommand.Params[vParams[vIndex]];
    if Assigned(vParamValue) then
      (vTypeInfo as IZTypeAnnotation).NullSafeSet(pStatement, vIndex,  vParamValue)
    else
      Raise EPersistenceengineError.CreateFmt(cErrorPersistenceEngineParamNotFound, [vParams[vIndex]]);
  end;
end;

{ TInfraPersistenceService }

function TInfraPersistenceService.GetConfiguration: IConfiguration;
begin
  if not Assigned(FConfiguration) then
    FConfiguration := TConfiguration.Create;
  Result := FConfiguration;
end;

function TInfraPersistenceService.GetPersistenceEngine: IPersistenceEngine;
begin
  if not Assigned(FPersistenceEngine) then
    FPersistenceEngine := TPersistenceEngine.Create(FConfiguration);
  Result := FPersistenceEngine;
end;

function TInfraPersistenceService.OpenSession: ISession;
begin
  Result := TSession.Create(GetPersistenceEngine);
end;

procedure TInfraPersistenceService.SetConnection(
  const pConnection: IZConnection);
begin
  GetPersistenceEngine.SetConnection(pConnection);
end;

{ TTemplateReader }

constructor TTemplateReader.Create;
begin
  raise EPersistenceTemplateError.Create(cErrorTemplateTryCreateClassBase);
end;

function TTemplateReader.GetConfiguration: IConfiguration;
begin
  Result := FConfiguration;
end;

procedure TTemplateReader.SetConfiguration(
  const Value: IConfiguration);
begin
  FConfiguration := Value;
end;

function TTemplateReader.Read(const pTemplateName: string): string;
begin
  Result := '';
end;

// N�o entendi mas se por direto no Initialization acontece Access Violations.
// ATEN��O: Vc n�o deve atribuir PersistenceService para uma vari�vel de
// instancia nem global sob pena de acontecer um AV no final da aplica��o
procedure InjectPersistenceService;
begin
  (ApplicationContext as IBaseElement).Inject(
    IInfraPersistenceService, TInfraPersistenceService.Create);
end;

{ TParseParams }

const
  Literals = ['''', '"', '`'];

constructor TParseParams.Create(const pSQL: string);
begin
  inherited Create;
  FParams := TStringList.Create;
  FSQL := pSQL;
end;

destructor TParseParams.Destroy;
begin
  FParams.Free;
  inherited;
end;

function TParseParams.GetParams: TStrings;
begin
  FParams.Clear;
  Parse;
  Result := FParams;
end;

function TParseParams.NameDelimiter(CurChar: Char): Boolean;
begin
  Result := CurChar in [' ', ',', ';', ')', '*', #13, #10];
end;

function TParseParams.IsLiteral(CurChar: Char): Boolean;
begin
  Result := CurChar in Literals;
end;

procedure TParseParams.StripChar(TempBuf: PChar; Len: Word);
begin
  if TempBuf^ in Literals then
    StrMove(TempBuf, TempBuf + 1, Len - 1);
  if TempBuf[StrLen(TempBuf) - 1] in Literals then
    TempBuf[StrLen(TempBuf) - 1] := #0;
end;

function TParseParams.StripLiterals(Buffer: PChar): string;
var
  Len: Word;
  TempBuf: PChar;
begin
  Len := StrLen(Buffer) + 1;
  TempBuf := AllocMem(Len);
  try
    StrCopy(TempBuf, Buffer);
    StripChar(TempBuf, Len);
    Result := StrPas(TempBuf);
  finally
    FreeMem(TempBuf, Len);
  end;
end;

function TParseParams.IsParameter(CurPos: PChar; Literal: Boolean): Boolean;
begin
  Result := not Literal and
    ( (CurPos^ in [':', '#']) and not ((CurPos + 1)^ in [':', '#']) )
end;

function TParseParams.IsFalseParameter(CurPos: PChar; Literal: Boolean): Boolean;
begin
  Result := not Literal and
    ( (CurPos^ in [':', '#']) and ((CurPos + 1)^ in [':', '#']) )
end;

procedure TParseParams.Parse;
var
  Value, CurPos, StartPos: PChar;
  CurChar: Char;
  Literal: Boolean;
  EmbeddedLiteral: Boolean;
  Name: string;
begin
  Value := PChar(FSQL);
  FParams.Clear;
  CurPos := Value;
  Literal := False;
  EmbeddedLiteral := False;
  repeat
    while (CurPos^ in LeadBytes) do Inc(CurPos, 2);
    CurChar := CurPos^;
    if IsParameter(CurPos, Literal) then
    begin
      StartPos := CurPos;
      while (CurChar <> #0) and (Literal or not NameDelimiter(CurChar)) do
      begin
        Inc(CurPos);
        while (CurPos^ in LeadBytes) do Inc(CurPos, 2);
        CurChar := CurPos^;
        if IsLiteral(Curchar) then
        begin
          Literal := Literal xor True;
          if CurPos = StartPos + 1 then EmbeddedLiteral := True;
        end;
      end;
      CurPos^ := #0;
      if EmbeddedLiteral then
      begin
        Name := StripLiterals(StartPos + 1);
        EmbeddedLiteral := False;
      end
      else Name := StrPas(StartPos + 1);
      FParams.Add(Name);
      CurPos^ := CurChar;
      StartPos^ := '?';
      Inc(StartPos);
      StrMove(StartPos, CurPos, StrLen(CurPos) + 1);
      CurPos := StartPos;
    end
    else if IsFalseParameter(CurPos, Literal) then
      StrMove(CurPos, CurPos + 1, StrLen(CurPos) + 1)
    else if IsLiteral(CurChar) then
      Literal := Literal xor True;
    Inc(CurPos);
  until CurChar = #0;
end;

initialization
  InjectPersistenceService;
  
end.