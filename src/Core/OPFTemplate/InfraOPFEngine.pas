unit InfraOPFEngine;

interface

uses
  {Infra}
  InfraCommon,
  InfraOPFIntf,
  InfraValueTypeIntf,
  {Zeos}
  ZDbcIntfs;

type
  /// Descri��o da classe
  TPersistenceEngine = class(TBaseElement, IPersistenceEngine, ITransaction)
  private
    FSQLGenerator: ITemplateReader_Build;
    FConnectionProvider: IConnectionProvider;
    /// Configura��o definida no session factory (imut�vel)
    FConfiguration: IConfiguration;
    /// Parser que procura por parametros e macros na instru��o SQL
    FParser: ISQLParamsParser;
    /// Item de Conex�o atual
    FConnectionItem: IConnectionItem;
    function GetReader: ITemplateReader;overload;
    function GetReader(
      const pSqlCommand : ISQLCommand): ITemplateReader_Build; overload;
    procedure SetParameters(const pStatement: IZPreparedStatement;
      const pParams: ISqlCommandParams);
    function GetRowFromResultSet(const pSqlCommand: ISQLCommandQuery;
      const pResultSet: IZResultSet): IInfraObject;
    procedure DoLoad(const pStatement: IZPreparedStatement;
      const pSqlCommand: ISQLCommandQuery; const pList: IInfraList);
    function ReadTemplate(const pSqlCommand: ISQLCommand): string;
    function InternallExecute(const pSqlCommand: ISqlCommand;
      const pConnection: IZConnection): Integer;
    function GetSQLFromCache(const pSqlCommand: ISQLCommand): string;
    procedure AddSQLToCache(const pSqlCommand: ISQLCommand; pValue: string);
    procedure CheckInTransaction;
    function InTransaction: Boolean;
    function GetCurrentConnectionItem: IConnectionItem;
  protected
    { IPersistenceEngine }
    procedure Load(const pSqlCommand: ISQLCommandQuery;
      const pList: IInfraList);
    function Execute(const pSqlCommand: ISqlCommand): Integer;
    function ExecuteAll(const pSqlCommands: ISQLCommandList): Integer;
    { ITransaction }
    procedure BeginTransaction(
      pIsolationLevel: TIsolationLevel = tilReadCommitted);
    procedure Commit;
    procedure Rollback;
  public
    constructor Create(const pConfiguration: IConfiguration;
      const pConnectionProvider: IConnectionProvider); reintroduce;
  end;

implementation

uses
  SysUtils,
  Classes,
  InfraCommonIntf,
  InfraOPFParsers,
  InfraOPFConsts,
  List_SQLCache, InfraOPFTemplates;

{ TPersistenceEngine }

{**
  Cria uma nova inst�ncia de TPersistenceEngine
  @param pConfiguration   ParameterDescription
}

constructor TPersistenceEngine.Create(const pConfiguration: IConfiguration;
  const pConnectionProvider: IConnectionProvider);
begin
  inherited Create;
  FConfiguration := pConfiguration;
  FConnectionProvider := pConnectionProvider;
  FParser := TSQLParamsParser.Create;
end;

{**
  Obtem o leitor de template definido no configuration
  @return Retorna um leitor de templates
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

function TPersistenceEngine.GetCurrentConnectionItem: IConnectionItem;
begin
  if not Assigned(FConnectionItem) then
    FConnectionItem := FConnectionProvider.Acquire;
  Result := FConnectionItem;
end;

{**
  Executa uma instru��o SQL (Insert/Update/Delete) numa dada uma conexao.
  @param pSqlCommand Objeto com as informa��es sobre o que e como executar a instru��o.
  @param pConnection Conex�o na qual os comandos ser�o executados
  @return Retorna a quantidade de registros afetados pela atualiza��o.
}

function TPersistenceEngine.InternallExecute(const pSqlCommand: ISqlCommand;
  const pConnection: IZConnection): Integer;
var
  vSQL: string;
  vStatement: IZPreparedStatement;
begin
  // Carrega a SQL e extrai os par�metros
  vSQL := ReadTemplate(pSqlCommand);
  vSQL := FParser.Parse(vSQL);
  // *** 1) Acho que os par�metros macros de FParse devem ser substituidos aqui
  //   antes de chamar o PrepareStatementWithParams
  // Solicita um connection e prepara a SQL
  vStatement := pConnection.PrepareStatementWithParams(
    vSQL, FParser.GetParams);
  // Seta os parametros e executa
  SetParameters(vStatement, pSqlCommand.Params);
  Result := vStatement.ExecuteUpdatePrepared;
end;

{**
  Executa uma instru��o SQL (Insert/Update/Delete)
  Executa contra o banco baseado nas informa��es contidas no par�metro SqlCommand.
  @param pSqlCommand Objeto com as informa��es sobre o que e como executar a instru��o.
  @return Retorna a quantidade de registros afetados pela atualiza��o.
}

function TPersistenceEngine.Execute(const pSqlCommand: ISqlCommand): Integer;
begin
  if not Assigned(pSqlCommand) then
    raise EInfraArgumentError.CreateFmt(cErrorPersistEngineWithoutSQLCommand,
      ['TPersistenceEngine.Execute']);

  Result := InternallExecute(pSqlCommand, GetCurrentConnectionItem.Connection);
end;

{**
  Executa todas as instru��es SQL (Insert/Update/Delete) contidas na lista
  Executa contra o banco baseado nas informa��es contidas na lista de SqlCommands.
  @param pSqlCommands Lista com as informa��es sobre as instru��es e como execut�-las
  @return Retorna a quantidade de registros afetados pela atualiza��o.
}

function TPersistenceEngine.ExecuteAll(
  const pSqlCommands: ISQLCommandList): Integer;
var
  vI: Integer;
  vConnection: IZConnection;
begin
  if not Assigned(pSqlCommands) then
    raise EInfraArgumentError.Create(cErrorPersistEngineWithoutSQLCommands);
  Result := 0;
  vConnection := GetCurrentConnectionItem.Connection;
  for vI := 0 to pSqlCommands.Count - 1 do
    Result := Result + InternallExecute(pSqlCommands[vI], vConnection);
end;

{**

  @param pStatement   ParameterDescription
  @param pSqlCommand   ParameterDescription
  @param pList   ParameterDescription
}

procedure TPersistenceEngine.DoLoad(const pStatement: IZPreparedStatement;
  const pSqlCommand: ISQLCommandQuery; const pList: IInfraList);
var
  vResultSet: IZResultSet;
  vObject: IInfraObject;
begin
  vResultSet := pStatement.ExecuteQueryPrepared;
  try
    while vResultSet.Next do
    begin
      vObject := GetRowFromResultSet(pSqlCommand, vResultSet);
      pList.Add(vObject);
    end;
  finally
    vResultSet.Close;
    vResultSet := nil;
  end;
end;

{ carregar a sql usando um reader com base no Name do pSqlCommand
  preencher os params da sql com base nos Params do pSqlCommand
  executa a sql e pega um IZStatement
  Faz um la�o para pegar cada registro
  cria um objeto com base no ClassType do pSqlCommand,
  Seta o estado persistent e clean ao objeto criado
  faz a carga dos atributos com base no registro
  Adiciona o novo objeto em pList retorna a lista
}

{**
  Carrega uma lista de objetos do banco de dados usando um SQLCommandQuery

  @param pSqlCommand SqlCommandQuery que ser� usado para efetuar a consulta no banco de dados
  @param pList Lista que ser� preenchida com os objetos lidos
}

procedure TPersistenceEngine.Load(const pSqlCommand: ISQLCommandQuery;
  const pList: IInfraList);
var
  vSQL: string;
  vStatement: IZPreparedStatement;
  vConnection: IConnectionItem;
begin
  if not Assigned(pSqlCommand) then
    raise EInfraArgumentError.CreateFmt(cErrorPersistEngineWithoutSQLCommand,
      ['TPersistenceEngine.Load']);
  if not Assigned(pList) then
    raise EInfraArgumentError.Create(cErrorPersistEngineWithoutList);
  // Acho q o Sql deveria j� estar no SqlCommand neste momento
  vSQL := ReadTemplate(pSqlCommand);
  // *** 1) se a SQL est� vazia aqui deveria gerar exce��o ou deveria ser dentro
  // do vReader.Read????
  vSQL := FParser.Parse(vSQL);
  // *** 2) Acho que os par�metros macros de FParse devem ser substituidos aqui
  // antes de chamar o PrepareStatementWithParams
  vConnection := GetCurrentConnectionItem;
  vStatement := nil;
  try
    vStatement := vConnection.Connection.PrepareStatementWithParams(
      vSQL, FParser.GetParams);
    SetParameters(vStatement, pSqlCommand.Params);
    DoLoad(vStatement, pSqlCommand, pList);
  finally
    if Assigned(vStatement) then
      vStatement.Close;
  end;
end;

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
  vTypeInfo: IClassInfo;
  vMetadata: IZResultSetMetadata;
begin
  // *** Ser� que isso deveria estar aqui?????
  //  if IsEqualGUID(pSqlCommand.GetClassID, InfraConsts.NullGUID) then
  //    Raise EPersistenceEngineError.Create(
  //      cErrorPersistEngineObjectIDUndefined);
  Result := TypeService.CreateInstance(
    pSqlCommand.ClassTypeInfo) as IInfraObject;
  if Assigned(Result) then
  begin
    vMetadata := pResultSet.GetMetadata;
    vTypeInfo := Result.TypeInfo;
    // A lista de colunas do ResultSet.GetMetadata do Zeos come�a do 1.
    for vIndex := 1 to pResultSet.GetMetadata.GetColumnCount do
    begin
      vAliasName := vMetadata.GetColumnLabel(vIndex);
      vAttribute := vTypeInfo.GetProperty(Result, vAliasName) as IInfraType;
      if not Assigned(vAttribute) then
        raise EPersistenceEngineError.CreateFmt(
          cErrorPersistEngineAttributeNotFound,
          [vAliasName, vMetadata.GetColumnName(vIndex)]);
      if Supports(vAttribute.TypeInfo, IZTypeAnnotation, vZeosType) then
        vZeosType.NullSafeGet(pResultSet, vIndex, vAttribute)
      else
        raise EPersistenceEngineError.CreateFmt(
          cErrorPersistEngineCannotMapAttribute, [vAttribute.TypeInfo.Name]);
    end;
  end;
end;

function TPersistenceEngine.ReadTemplate(
  const pSqlCommand: ISQLCommand): string;
var
  vReader: ITemplateReader;
begin
  Result := GetSQLFromCache(pSqlCommand);
  if Result = EmptyStr then
  begin
    if Pos('#',pSQLCommand.Name) > 0 then
      vReader := GetReader(pSQLCommand)
    else
      vReader := GetReader;
    Result := vReader.Read(pSqlCommand);
    AddSQLToCache(pSqlCommand, Result);
  end;
end;

{**
  Efetua a substitui��o dos parametros por seus respectivos valores
  @param pStatement Este parametro representa o comando SQL no qual se efetuar�
                    a substui��o de par�metros
  @param pParams Lista de parametros do tipo ISqlCommandParams
}

procedure TPersistenceEngine.SetParameters(
  const pStatement: IZPreparedStatement; const pParams: ISqlCommandParams);
var
  vIndex: integer;
  vParamValue: IInfraType;
  vParams: TStrings;
  vZeosType: IZTypeAnnotation;
begin
  vParams := pStatement.GetParameters;
  for vIndex := 0 to vParams.Count - 1 do
  begin
    vParamValue := pParams[vParams[vIndex]];
    if Assigned(vParamValue)
      and Supports(vParamValue.TypeInfo, IZTypeAnnotation, vZeosType) then
      // Aumenta o vIndex por que no Zeos as colunas come�am de 1
      vZeosType.NullSafeSet(pStatement, vIndex + 1, vParamValue)
    else
      raise EPersistenceEngineError.CreateFmt(
        cErrorPersistEngineParamNotFound, [vParams[vIndex]]);
  end;
end;

{**
  Chame GetInTransaction para verificar se h� uma transa��o em andamento
  @return Retorna True se houver uma transa��o sendo executada
}

function TPersistenceEngine.InTransaction: Boolean;
begin
  Result := not GetCurrentConnectionItem.Connection.GetAutoCommit;
end;

{**
  Caso nenhuma transa��o esteja em aberto, levanta ma exce��o
}

procedure TPersistenceEngine.CheckInTransaction;
begin
  if not InTransaction then
    raise EPersistenceTransactionError.Create(cErrorNotInTransaction);
end;

{**
  Inicia uma nova transa��o com o n�vel de Isolamento especificado
  Se uma transa��o j� estiver em andamento, resultar� numa mensagem de erro
  @param pIsolationLevel N�vel de isolamento da transa�ao
}

procedure TPersistenceEngine.BeginTransaction(
  pIsolationLevel: TIsolationLevel);
begin
  if InTransaction then
    raise EPersistenceTransactionError.Create(cErrorAlreadyInTransaction);
  GetCurrentConnectionItem.Configure(pIsolationLevel);
end;

{**
  Efetiva a transa��o sendo executada
  Caso nenhuma transa��o esteja em aberto, resultar� numa mensagem de erro
}

procedure TPersistenceEngine.Commit;
begin
  CheckInTransaction;
  GetCurrentConnectionItem.Connection.Commit;
end;

{**
  Desfaz a transa��o corrente
  fazendo com que todas as modifica��es realizadas pela transa��o sejam rejeitadas.
  Caso nenhuma transa��o esteja em aberto, resultar� numa mensagem de erro
}

procedure TPersistenceEngine.Rollback;
begin
  CheckInTransaction;
  GetCurrentConnectionItem.Connection.Rollback;
end;

procedure TPersistenceEngine.AddSQLToCache(
  const pSqlCommand: ISQLCommand; pValue: string);
var
  vSqlCache: ISQLCacheList;
begin
  if Supports(pSqlCommand.ClassTypeInfo, ISQLCacheList, vSqlCache) then
    vSqlCache.Items[pSqlCommand.Name] := pValue;
end;

function TPersistenceEngine.GetSQLFromCache(
  const pSqlCommand: ISQLCommand): string;
var
  vSqlCache: ISQLCacheList;
begin
  Result := EmptyStr;
  if not Supports(pSqlCommand.ClassTypeInfo, ISqlCacheList, vSqlCache) then
  begin
    vSqlCache := TInfraSQLCache.Create;
    pSqlCommand.ClassTypeInfo.Inject(ISqlCacheList, vSqlCache);
  end
  else
    Result := vSqlCache.Items[pSqlCommand.Name]
end;

function TPersistenceEngine.GetReader(
  const pSqlCommand : ISQLCommand): ITemplateReader_Build;
begin
  if not Assigned(FSQLGenerator) then
    FSQLGenerator := TTemplateReader_Build.Create;
  Result := FSQLGenerator;
  Result.Configuration := FConfiguration;
end;

end.
