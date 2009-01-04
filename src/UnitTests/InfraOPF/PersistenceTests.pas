unit PersistenceTests;

interface

uses
  InfraPersistenceIntf,
  ZDbcInterbase6,
  TestFramework,
  PersistenceModelIntf;

type
  TPersistenceTests = class(TTestCase)
  private
    FConfiguration: IConfiguration;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestLoadObjectByOID;
    procedure TestParse;
  end;

implementation

uses
  Dialogs,
  SysUtils, 
  Forms, 
  Math,
  Classes,
  InfraValueType, 
  InfraValueTypeIntf,
  PersistenceModel, 
  InfraPersistence,
  InfraPersistenceConsts;

{ THibernateTests }

procedure TPersistenceTests.SetUp;
begin
  inherited;
  // Aqui � definido no Configuration algumas propriedades, para que o
  // InfraPersistence saiba algumas coisas necess�rias para configurar o
  // connection e outras coisas internas. Caso haja propriedades especificas
  // que precisam ser definidas, podem ser naturalmente colocados ai tambem
  // que o tipo de Connection espec�fico poderar ler sem problema.
  with PersistenceService.Configuration do
  begin
    PropertyItem[cCONFIGKEY_DRIVER] := 'firebird-2.0';
    PropertyItem[cCONFIGKEY_USERNAME] := 'SYSDBA';
    PropertyItem[cCONFIGKEY_PASSWORD] := 'masterkey';
    PropertyItem[cCONFIGKEY_HOSTNAME] := 'localhost';
    PropertyItem[cCONFIGKEY_DATABASENAME] :=
      ExtractFilePath(Application.ExeName) + 'Data\DBDEMOS.FDB';
    PropertyItem[cCONFIGKEY_TEMPLATETYPE] := 'TemplateReader_IO';
    PropertyItem[cCONFIGKEY_TEMPLATEPATH] :=
      ExtractFilePath(Application.ExeName) + 'Data';
  end;
end;

procedure TPersistenceTests.TearDown;
begin
  inherited;
end;

procedure TPersistenceTests.TestLoadObjectByOID;
var
  vSession: ISession;
  vObj: IAccount;
  vSQLCommand: ISQLCommandQuery;
begin
  // Abre uma nova sess�o a ser utilizada para carregar e popular o objeto
  vSession := PersistenceService.OpenSession;
  
  vObj := TAccount.Create;
  vObj.Id.AsInteger := 1;
  
  // carrega o objeto Account com base no oid fornecido.
  vSQLCommand := vSession.Load('LoadAccountbyId', vObj);
  vObj := vSQLCommand.GetResult as IAccount; 
  
  // verifica se o objeto realmente foi carregado.
  CheckNotNull(vObj, 'Objecto n�o foi carregado');
  CheckEquals('BB 1361', vObj.Name.AsString, 'Nome conta incompat�vel');
  CheckEquals('1361-2', vObj.AccountNumber.AsString, 'N�mero da conta incompat�vel');
  CheckTrue(SameValue(125.3, vObj.InitialBalance.AsDouble), 'Saldo inicial incompat�vel');
  CheckTrue(SameValue(1524.25, vObj.CurrentBalance.AsDouble), 'Saldo atual incompat�vel');
end;

procedure TPersistenceTests.TestParse;
var
  vP: IParseParams;
  sL: TStrings;
begin
  vP := TParseParams.Create('Select #MacroParam* ::Teste ##abc #:yyy #:xxx from teste where x = :teste1');
  sL := vP.GetParams;
  ShowMessage(Sl.Text);
  // CheckEquals('teste1', sL[0], 'N�o sao identicos');
end;

initialization
  TestFramework.RegisterTest('Persistence TestsSuite', TPersistenceTests.Suite);

end.
