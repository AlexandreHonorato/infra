unit InfraOPFService;

interface

uses
  {Infra}
  InfraCommon,
  InfraCommonIntf,
  InfraOPFIntf,
  InfraOPFConfiguration;

type
  /// Descri��o da classe
  TInfraPersistenceService = class(TBaseElement, IInfraPersistenceService)
  protected
    function GetConfiguration: IConfiguration;
  end;

implementation

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

