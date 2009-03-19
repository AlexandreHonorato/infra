unit InfraBindingType;

interface

uses
  InfraCommon, InfraBindingIntf, InfraValueTypeIntf, InfraCommonIntf;

type
  TBindable = class(TElement, IBindable)
  protected
    procedure Changed;
    function Support2Way: Boolean; virtual;
    function GetValue: IInfraType; virtual; abstract;
    procedure SetValue(const Value: IInfraType); virtual; abstract;    
  end;

  TBindableInfraType = class(TBindable, IBindableInfraType)
  private
    FInfraType: IInfraType;
  protected
    function Support2Way: Boolean; override;  
    function GetValue: IInfraType; override;
    procedure SetValue(const Value: IInfraType); override;
    procedure ValueChanged(const Event: IInfraEvent);
    function ValueChangedFilter(const Event: IInfraEvent): Boolean;
  public
    constructor Create(const pProperty: IProperty); reintroduce;
    class function GetBindable(pValue: IInfraType;
      const pPropertyPath: string): IBindable;
  end;

implementation

uses
  Forms, SysUtils, InfraBindingManager, InfraValueType;

{ TBindable }

procedure TBindable.Changed;
begin
  if not Application.Terminated then
    Publisher.Publish(TNotifyValueChanged.Create(Self) as INotifyValueChanged);
end;

function TBindable.Support2Way: Boolean;
begin
  Result := False;
end;

{ TBindableInfraType }

constructor TBindableInfraType.Create(const pProperty: IProperty);
begin
  inherited Create;
  FInfraType := pProperty;
  EventService.Subscribe(IInfraChangedEvent, Self as ISubscriber,
    ValueChanged, EmptyStr, ValueChangedFilter);
end;

class function TBindableInfraType.GetBindable(pValue: IInfraType;
  const pPropertyPath: string): IBindable;
var
  vObject: IInfraObject;
  vProperty: IProperty;
begin
  // *** E se o Value for uma lista, ou outro tipo de infratype? vai se criar um
  // *** bindable para cada tipo?
  if Supports(pValue, IInfraObject, vObject) then
  begin
    vProperty := vObject.GetProperty(pPropertyPath);
    // *** teria de gerar exce��o quando o infraobject nao possuir a propriedade?
    Result := TBindableInfraType.Create(vProperty);
  end;
end;

function TBindableInfraType.GetValue: IInfraType;
begin
  Result := FInfraType;
end;

procedure TBindableInfraType.SetValue(const Value: IInfraType);
begin
  FInfraType.Assign(Value);
end;

function TBindableInfraType.Support2Way: Boolean;
begin
  Result := True;
end;

procedure TBindableInfraType.ValueChanged(const Event: IInfraEvent);
begin
  Changed;
end;

function TBindableInfraType.ValueChangedFilter(const Event: IInfraEvent): Boolean;
var
  vSource: IInfraType;
begin
  vSource := Event.Source as IInfraType;
  Result := vSource = FInfraType;
end;

end.