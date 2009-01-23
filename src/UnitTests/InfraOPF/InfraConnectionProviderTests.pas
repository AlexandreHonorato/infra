unit InfraConnectionProviderTests;

interface

uses
  SysUtils,
  Classes,
  TestFramework,
  InfraOPFIntf;

type
  TTestConnectionProvider = class(TTestCase)
  private
    FConnProvider: IConnectionProvider;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestCreateWithoutConnectionString;
    procedure TestGetConnection;
    procedure TestGetConnectionObjAvailableInPool;
    procedure TestGetConnectionObjUnavailableInPool;
    procedure TestGetConnectionBeyoundMaxSize;
  end;

implementation

uses
  InfraOPFConnectionProvider,
  InfraOPFConsts,
  InfraMocks,
  ZDbcIntfs,
  InfraCommonIntf,
  InfraTestsUtil;

{ TTestConnectionProvider }

procedure TTestConnectionProvider.SetUp;
begin
  inherited;
  FConnProvider := TConnectionProvider.Create(TTestsUtil.GetNewConfiguration);
end;

procedure TTestConnectionProvider.TearDown;
begin
  FConnProvider := nil;
  inherited;
end;

procedure TTestConnectionProvider.TestCreateWithoutConnectionString;
begin
  inherited;
  ExpectedException := EInfraArgumentError;
  TConnectionProvider.Create(nil);
  ExpectedException := nil;
end;

procedure TTestConnectionProvider.TestGetConnection;
var
  vConnection1, vConnection2: IConnectionItem;
begin
  vConnection1 := FConnProvider.Acquire;
  CheckNotNull(vConnection1, 'Falha no retorno da conex�o #1');
  CheckEquals(1, FConnProvider.ActiveConnections);

  vConnection2 := FConnProvider.Acquire;
  CheckNotNull(vConnection2, 'Falha no retorno da conex�o #2');
  CheckEquals(2, FConnProvider.ActiveConnections);
end;

procedure TTestConnectionProvider.TestGetConnectionObjAvailableInPool;
var
  vConnection1, vConnection2: IConnectionItem;
begin
  vConnection1 := FConnProvider.Acquire;
  CheckNotNull(vConnection1, 'Falha no retorno da conex�o #1');
  CheckEquals(1, FConnProvider.ActiveConnections);
  vConnection1 := nil; // A conex�o foi liberada mas deve permanecer no Pool

  vConnection2 := FConnProvider.Acquire;
  CheckNotNull(vConnection2, 'Falha no retorno da conex�o #2');
  CheckEquals(1, FConnProvider.ActiveConnections);
end;

procedure TTestConnectionProvider.TestGetConnectionObjUnavailableInPool;
var
  vConnection1, vConnection2: IConnectionItem;
begin
  vConnection1 := FConnProvider.Acquire;
  CheckNotNull(vConnection1, 'Falha no retorno da conex�o #1');

  vConnection2 := FConnProvider.Acquire;
  CheckNotNull(vConnection2, 'Falha no retorno da conex�o #2');

  CheckFalse(vConnection1 = vConnection2, 'O ConnectionProvider retornou a mesma conex�o');
  CheckEquals(2, FConnProvider.ActiveConnections, 'N�mero de conex�es errado');
end;

procedure TTestConnectionProvider.TestGetConnectionBeyoundMaxSize;
var
  vConnections: array of IConnectionItem;
  vAnotherConnection: IConnectionItem;
  i: Integer;
begin
  SetLength(vConnections, FConnProvider.PoolSize);
  for i := Low(vConnections) to High(vConnections) do
  begin
    vConnections[i] := FConnProvider.Acquire;
    CheckNotNull(vConnections[i], 'Falha no retorno da conex�o #'+IntToStr(i+1));
  end;

  ExpectedException := EPersistenceConnectionProviderError;
  vAnotherConnection := FConnProvider.Acquire;
  ExpectedException := nil;
end;

initialization
  TestFramework.RegisterTest('Persistence Testes Caixa-Cinza',
    TTestConnectionProvider.Suite);
    
end.



