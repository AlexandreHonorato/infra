unit InfraPersistence;

interface

uses
  {Infra}
  InfraCommon,
  InfraCommonIntf,
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
  protected
    function GetConfiguration: IConfiguration;
  end;

implementation

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
  Cria um novo objeto Configuration
  Chame GetConfiguration para obter um novo objeto configuration, com o qual
  poder� construir uma nova SessionFactory.
  
  @return Retorna um objeto que implementa IConfiguration
*}
function TInfraPersistenceService.GetConfiguration: IConfiguration;
begin
  Result := TConfiguration.Create;
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

