unit InfraBinding;

interface

uses
  InfraBindingIntf,
  InfraValueTypeIntf,
  InfraCommon;

type
  TBindable = class(TElement, IBindable)
  private
    FUpdateCount: integer;
  protected
    function GetUpdating: boolean;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure Changed;
    function Support2Way: Boolean; virtual;
    function GetValue: IInfraType; virtual; abstract;
    procedure SetValue(const Value: IInfraType); virtual; abstract;
    property Updating: boolean read GetUpdating;
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

procedure TBindable.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TBindable.Changed;
begin
  if not Application.Terminated then
    Publisher.Publish(TNotifyValueChanged.Create(Self) as INotifyValueChanged);
end;

procedure TBindable.EndUpdate;
begin
  Dec(FUpdateCount);
end;

function TBindable.GetUpdating: boolean;
begin
  Result := FUpdateCount > 0;
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
