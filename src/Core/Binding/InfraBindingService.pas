unit InfraBindingService;

interface

uses
  Controls,
  InfraCommon,
  List_MappingControl,
  InfraBindingControl,
  InfraBindingIntf;

type
  /// Servi�o de Binding
  TInfraBindingService = class(TBaseElement, IInfraBindingService)
  private
    FMappingControls: IMappingControlList;
    function GetMappingControlList: IMappingControlList;
  protected
    function GetNewBindManager: IBindManager;
    procedure RegisterControl(pClass, pBindableClass: TClass);
    property MappingControls: IMappingControlList read GetMappingControlList;
  end;

implementation

uses
  InfraCommonIntf,
  InfraBindingManager;

{ TInfraBindingService }

function TInfraBindingService.GetMappingControlList: IMappingControlList;
begin
  if not Assigned(FMappingControls) then
    FMappingControls := TMappingControlList.Create;
  Result := FMappingControls;
end;

{**
  Cria um novo objeto BindManager
  Chame GetNewBindManager para obter um novo objeto BindManager, com o qual
  poder� fazer a liga��o entre controles de tela, ou entre controles de tela
  com infratypes.

  @return Retorna um objeto que implementa IBindManager
*}
function TInfraBindingService.GetNewBindManager: IBindManager;
begin
  Result := TBindManager.Create;
end;

procedure TInfraBindingService.RegisterControl(pClass, pBindableClass: TClass);
begin
  MappingControls.Add(pClass, pBindableClass)
end;

// N�o entendi, mas se p�r direto no Initialization acontece Access Violations.
// ATEN��O: Vc n�o deve atribuir BindingService para uma vari�vel de
// instancia nem global sem que no final da aplica��o atribuia nil a ela explicitamente,
// sob pena de acontecer um AV no final da aplica��o
procedure InjectBindingService;
begin
  (ApplicationContext as IBaseElement).Inject(
    IInfraBindingService, TInfraBindingService.Create);
end;

initialization
  InjectBindingService;
  
end.
