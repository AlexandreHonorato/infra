unit InfraBinding;

interface

uses
  InfraBindingIntf,
  InfraValueTypeIntf,
  InfraCommon;

type
  TBindable = class(TElement, IBindable)
  private
    FUpdating: boolean;
  protected
    function IsUpdating: boolean;
    procedure Changed;
    function Support2Way: Boolean; virtual;
    function GetValue: IInfraType; virtual; abstract;
    procedure SetValue(const Value: IInfraType); virtual; abstract;    
  end;

  /// Servi�o de Binding
  TInfraBindingService = class(TBaseElement, IInfraBindingService)
  protected
    function GetNewBindManager: IBindManager;
  end;

implementation

uses
  Forms,
  InfraCommonIntf,
  InfraBindingManager;

{ TBindable }

procedure TBindable.Changed;
begin
  FUpdating := True;
  try
    if not Application.Terminated then
      Publisher.Publish(TNotifyValueChanged.Create(Self) as INotifyValueChanged);
  finally
    FUpdating := False;
  end;
end;

function TBindable.IsUpdating: boolean;
begin
  Result := FUpdating;
end;

function TBindable.Support2Way: Boolean;
begin
  Result := False;
end;

{ TInfraBindingService }

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
