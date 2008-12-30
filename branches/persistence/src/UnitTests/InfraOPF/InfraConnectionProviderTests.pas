unit InfraConnectionProviderTests;

interface

uses SysUtils, Classes, TestFramework, InfraPersistenceIntf;

type
  TTestConnectionProvider = class(TTestCase)
  private
    FConnProvider: IConnectionProvider;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestCreate;
    procedure TestGetConnection;
    procedure TestGetConnectionObjAvailableInPool;
    procedure TestGetConnectionObjUnavailableInPool;
    procedure TestGetConnectionBeyoundMaxSize;
    procedure TestCloseConnection;
    procedure TestCloseConnectionAlreadyClosed;
    procedure TestCloseConnectionNotFound;
    procedure TestClose;
  end;

implementation

uses InfraPersistence, InfraMocks, ZDbcIntfs;

{ TTestConnectionProvider }

procedure TTestConnectionProvider.SetUp;
begin
  inherited;
  // Tamanho do Pool = 2
  // Objetos no Pool n�o expiram 
  FConnProvider := TInfraConnectionProvider.Create(2, -1, TDriverManagerMock.Create, TConfiguration.Create);
end;

procedure TTestConnectionProvider.TearDown;
begin
  FConnProvider := nil;
  inherited;
end;

procedure TTestConnectionProvider.TestCreate;
begin
  CheckNotNull(FConnProvider);
end;

procedure TTestConnectionProvider.TestGetConnection;
var
  lConnection: IZConnection;
begin
  lConnection := FConnProvider.GetConnection;
  CheckNotNull(lConnection, 'Falha no retorno da conex�o');
  CheckTrue(lConnection.IsClosed, 'Conexao est� aberta');
end;

procedure TTestConnectionProvider.TestGetConnectionObjAvailableInPool;
var
  lConnection1, lConnection2: IZConnection;
begin
  lConnection1 := FConnProvider.GetConnection;
  CheckNotNull(lConnection1, 'Falha no retorno da conex�o 1');

  lConnection2 := FConnProvider.GetConnection;
  CheckNotNull(lConnection2, 'Falha no retorno da conex�o 2');

  CheckTrue(lConnection1 = lConnection2, 'Deveria ter retornado a primeira conexao fechada dispon�vel');
end;

procedure TTestConnectionProvider.TestGetConnectionObjUnavailableInPool;
var
  lConnection1, lConnection2: IZConnection;
begin
  lConnection1 := FConnProvider.GetConnection;
  lConnection1.Open;

  lConnection2 := FConnProvider.GetConnection;
  CheckNotNull(lConnection2, 'Falha no retorno da conex�o 2');

  CheckTrue(lConnection1 <> lConnection2, 'Deveria ter criado uma nova conexao');
end;

procedure TTestConnectionProvider.TestGetConnectionBeyoundMaxSize;
var
  lConnection1, lConnection2, lConnection3: IZConnection;
begin
  lConnection1 := FConnProvider.GetConnection;
  lConnection1.Open;

  lConnection2 := FConnProvider.GetConnection;
  lConnection2.Open;

  ExpectedException := EInfraConnectionProviderError;
  lConnection3 := FConnProvider.GetConnection;
  ExpectedException := nil;
end;

procedure TTestConnectionProvider.TestCloseConnection;
var
  lConnection1: IZConnection;
begin
  lConnection1 := FConnProvider.GetConnection;
  lConnection1.Open;

  CheckFalse(lConnection1.IsClosed, 'A conex�o est� fechada');

  FConnProvider.ReleaseConnection(lConnection1);

  CheckTrue(lConnection1.IsClosed, 'A conex�o continua aberta');
end;

procedure TTestConnectionProvider.TestCloseConnectionNotFound;
var
  lConnection1: IZConnection;
begin
  // Esta conex�o n�o est� no Pool
  lConnection1 := TDriverManagerMock.Create.GetConnection('');
  lConnection1.Open;

  ExpectedException := EInfraConnectionProviderError;
  FConnProvider.ReleaseConnection(lConnection1);
  ExpectedException := nil;
end;

procedure TTestConnectionProvider.TestCloseConnectionAlreadyClosed;
var
  lConnection1: IZConnection;
begin
  lConnection1 := FConnProvider.GetConnection;
  lConnection1.Close; // S� pra ficar claro

  ExpectedException := EInfraConnectionProviderError;
  FConnProvider.ReleaseConnection(lConnection1);
  ExpectedException := nil;
end;

procedure TTestConnectionProvider.TestClose;
var
  lConnection1, lConnection2: IZConnection;
begin
  lConnection1 := FConnProvider.GetConnection;
  lConnection1.Open;

  lConnection2 := FConnProvider.GetConnection;
  lConnection2.Open;

  FConnProvider.Close;

  CheckTrue(lConnection1.IsClosed and lConnection2.IsClosed, 'Close falhou');
end;

initialization
  TestFramework.RegisterTest(TTestConnectionProvider.Suite);

end.
