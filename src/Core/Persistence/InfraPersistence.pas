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
  InfraOPFIntf,
  InfraOPFConfiguration;

type
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
  TInfraPersistenceService = class(TBaseElement, IInfraPersistenceService)
  private
    FConfiguration: IConfiguration;
    FPersistenceEngine: IPersistenceEngine;
    function GetPersistenceEngine: IPersistenceEngine;
  protected
    function GetConfiguration: IConfiguration;
    function OpenSession: ISession;
    procedure SetConnection(const pConnection: IZConnection);
    property Configuration: IConfiguration read GetConfiguration;
  end;

implementation

uses
  InfraOPFEngine,
  InfraOPFConsts,
  InfraConsts,
  InfraOPFConnectionProvider,
  InfraOPFParsers,
  InfraOPFSqlCommands,
  InfraOPFSession;

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
    FPersistenceEngine := TPersistenceEngine.Create(FConfiguration,
      ConnectionProviderFactory.CreateProvider(FConfiguration));
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

