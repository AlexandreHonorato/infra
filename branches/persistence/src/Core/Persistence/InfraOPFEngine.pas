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
  TPersistenceEngine = class(TBaseElement, IPersistenceEngine)
  private
    FCurrentConnection: IZConnection;
    FConnectionProvider: IConnectionProvider;
    /// Configura��o definida no session factory (imut�vel)
    FConfiguration: IConfiguration;
    /// Parser que procura por parametros e macros na instru��o SQL
    FParser: ISQLParamsParser;
    function GetReader: ITemplateReader;
    procedure SetParameters(const pStatement: IZPreparedStatement;
      const pParams: ISqlCommandParams);
    function GetRowFromResultSet(const pSqlCommand: ISQLCommandQuery;
      const pResultSet: IZResultSet): IInfraObject;
    procedure DoLoad(const pStatement: IZPreparedStatement;
      const pSqlCommand: ISQLCommandQuery; const pList: IInfraList);
    function ReadTemplate(const pSqlCommandName: string): string;
    function GetCurrentConnection: IZConnection;
  protected
    procedure Load(const pSqlCommand: ISQLCommandQuery;
      const pList: IInfraList);
    function Execute(const pSqlCommand: ISqlCommand): Integer;
    function ExecuteAll(const pSqlCommands: ISQLCommandList): Integer;
  public
    constructor Create(pConfiguration: IConfiguration); reintroduce;
  end;

implementation

uses
  SysUtils,
  Classes,
  InfraCommonIntf,
  InfraOPFParsers,
  InfraOPFConsts,
  InfraOPFConnectionProvider;

{ TPersistenceEngine }

{*
  Cria uma nova inst�ncia de TPersistenceEngine
  @param pConfiguration   ParameterDescription
}
constructor TPersistenceEngine.Create(pConfiguration: IConfiguration);
begin
  inherited Create;
  // O argumento pConfiguration sempre � requerido, visto que � dele que
  // o Framework obter� as suas configura��es
  if not Assigned(pConfiguration) then
    raise EInfraArgumentError.CreateFmt(cErrorPersistenceWithoutConfig,
      ['PersistenceEngine.Create']);
  FConfiguration := pConfiguration;
  FConnectionProvider := TConnectionProvider.Create(FConfiguration);
  FParser := TSQLParamsParser.Create;
end;

{*
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

{*
  Define a conex�o a ser usada para processar o SQLCommand
  @return Retorna a conex�o atual quando trabalhando em bloco ou uma nova conex�o do pool;
}
function TPersistenceEngine.GetCurrentConnection: IZConnection;
begin
  Result := FCurrentConnection;
  if not Assigned(Result) then
    Result := FConnectionProvider.GetConnection;
end;

{*
  Executa uma instru��o SQL (Insert/Update/Delete) contra o banco baseado nas informa��es contidas no par�metro SqlCommand.
  @param pSqlCommand Objeto com as informa��es sobre o que e como executar a instru��o.
  @return Retornar a quantidade de registros afetados pela atualiza��o.
}
function TPersistenceEngine.Execute(const pSqlCommand: ISqlCommand): Integer;
var
  vSQL: string;
  vStatement: IZPreparedStatement;
begin
  if not Assigned(pSqlCommand) then
    raise EInfraArgumentError.CreateFmt(cErrorPersistEngineWithoutSQLCommand,
      ['TPersistenceEngine.Execute']);
  // Carrega a SQL e extrai os par�metros
  vSQL := ReadTemplate(pSqlCommand.Name);
  vSQL := FParser.Parse(vSQL);
  // *** 1) Acho que os par�metros macros de FParse devem ser substituidos aqui
  //   antes de chamar o PrepareStatementWithParams
  // Solicita um connection e prepara a SQL
  vStatement := GetCurrentConnection.PrepareStatementWithParams(
    vSQL, FParser.GetParams);
  // Seta os parametros e executa
  SetParameters(vStatement, pSqlCommand.Params);
  Result := vStatement.ExecuteUpdatePrepared;
end;

{*
  Executa todas as instru��es SQL (Insert/Update/Delete) contra o banco baseado nas informa��es contidas na lista de SqlCommands.
  @param pSqlCommands Lista com as informa��es sobre as instru��es e como execut�-las
  @return Retorna a quantidade de registros afetados pela atualiza��o.
}
function TPersistenceEngine.ExecuteAll(
  const pSqlCommands: ISQLCommandList): Integer;
var
  i: integer;
begin
  if not Assigned(pSqlCommands) then
    raise EInfraArgumentError.Create(cErrorPersistEngineWithoutSQLCommands);
  Result := 0;
  FCurrentConnection := FConnectionProvider.GetConnection;
  try
    for i := 0 to pSqlCommands.Count - 1 do
      Result := Result + Execute(pSqlCommands[i]);
  finally
    FCurrentConnection := nil;
  end;
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
begin
  if not Assigned(pSqlCommand) then
    raise EInfraArgumentError.CreateFmt(cErrorPersistEngineWithoutSQLCommand,
      ['TPersistenceEngine.Load']);
  if not Assigned(pList) then
    raise EInfraArgumentError.Create(cErrorPersistEngineWithoutList);
  // Acho q o Sql deveria j� estar no SqlCommand neste momento
  vSQL := ReadTemplate(pSqlCommand.Name);
  // *** 1) se a SQL est� vazia aqui deveria gerar exce��o ou deveria ser dentro
  // do vReader.Read????
  vSQL := FParser.Parse(vSQL);
  // *** 2) Acho que os par�metros macros de FParse devem ser substituidos aqui
  // antes de chamar o PrepareStatementWithParams
  vStatement := GetCurrentConnection.PrepareStatementWithParams(vSQL,
    FParser.GetParams);
  try
    SetParameters(vStatement, pSqlCommand.Params);
    DoLoad(vStatement, pSqlCommand, pList);
  finally
    vStatement.Close;
  end;
end;

{**

  @param pSqlCommand   ParameterDescription
  @param pResultSet   ParameterDescription
  @return ResultDescription
}
function TPersistenceEngine.GetRowFromResultSet(const pSqlCommand: ISQLCommandQuery;
  const pResultSet: IZResultSet): IInfraObject;
var
  vIndex: integer;
  vAttribute: IInfraType;
  vZeosType: IZTypeAnnotation;
  vAliasName: string;
begin
  // *** Ser� que isso deveria estar aqui?????
  //  if IsEqualGUID(pSqlCommand.GetClassID, InfraConsts.NullGUID) then
  //    Raise EPersistenceEngineError.Create(
  //      cErrorPersistEngineObjectIDUndefined);
  Result := TypeService.CreateInstance(pSqlCommand.GetClassID) as IInfraObject;
  if Assigned(Result) then
  begin
    // A lista de colunas do ResultSet.GetMetadata do Zeos come�a do 1.
    for vIndex := 1 to pResultSet.GetMetadata.GetColumnCount do
    begin
      vAliasName := pResultSet.GetMetadata.GetColumnLabel(vIndex);
      vAttribute := Result.TypeInfo.GetProperty(Result, vAliasName) as IInfraType;
      if not Assigned(vAttribute) then
        Raise EPersistenceEngineError.CreateFmt(
          cErrorPersistEngineAttributeNotFound,
          [vAliasName, pResultSet.GetMetadata.GetColumnName(vIndex)]);
      if Supports(vAttribute.TypeInfo, IZTypeAnnotation, vZeosType) then
        vZeosType.NullSafeGet(pResultSet, vIndex, vAttribute)
      else
        raise EPersistenceEngineError.CreateFmt(
          cErrorPersistEngineCannotMapAttribute, [vAttribute.TypeInfo.Name]);
    end;
  end;
end;

function TPersistenceEngine.ReadTemplate(const pSqlCommandName: string): string;
var
  vReader: ITemplateReader;
begin
  vReader := GetReader;
  Result := vReader.Read(pSqlCommandName);
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
  for vIndex := 0 to vParams.Count-1 do
  begin
    vParamValue := pParams[vParams[vIndex]];
    if Assigned(vParamValue)
      and Supports(vParamValue.TypeInfo, IZTypeAnnotation, vZeosType) then
      // Aumenta o vIndex por que no Zeos as colunas come�am de 1
      vZeosType.NullSafeSet(pStatement, vIndex+1, vParamValue)
    else
      raise EPersistenceEngineError.CreateFmt(
        cErrorPersistEngineParamNotFound, [vParams[vIndex]]);
  end;
end;

end.

