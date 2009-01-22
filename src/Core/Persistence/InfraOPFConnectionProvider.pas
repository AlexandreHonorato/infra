unit InfraOPFConnectionProvider;

interface

uses
  SysUtils,
  Windows,
  Classes,
  {Infra}
  InfraCommon,
  InfraOPFIntf,
  {Zeos}
  ZDbcIntfs,
  SyncObjs;

type
  TCleanupThread = class;

  // classe que gerencia o pool de conex�es
  TConnectionProvider = class(TBaseElement, IConnectionProvider)
  private
    FConnections: array of IConnectionProviderItem;
    FPoolSize: Integer;
    FTimeout: Int64;
    FCleanupThread: TCleanupThread;
    FConnectionString: string;
    // Semaforo usado para limitar o numero de conex�es simult�neas.
    // Quando a enesima+1 conex�o � solicitada, ela ir� ser bloqueada at�
    // que uma conx�o esteja dispon�vel.
    FSemaphore: THandle;
    // Sess�o critica para sinconizar o acesso ao Pool.
    FCriticalSection: TCriticalSection;
    FInitialized: Boolean;
    FInternallEvent: TEvent;
    function BuildConnectionString(pConfiguration: IConfiguration): string;
    function GetActiveConnections: Integer;
    function GetPoolSize: Integer;
  protected
    //This function returns an object
    //that implements the IPoolConnection interface.
    //This object can be a data module, as was
    //done in this example.
    function GetConnection: IConnectionProviderItem;
    procedure Lock;
    procedure UnLock;
    property ActiveConnections: Integer read GetActiveConnections;
    property PoolSize: Integer read GetPoolSize;
  public
    // Este construtor pega 3 parametros.
    // 1 - Tamanho do pool (limite m�ximo de conex�es)
    // 2 - Por quanto tempo uma conex�o livre deve existir no pool
    // 3 - Quanto tempo alguem pode esperar por uma conex�o
    constructor Create(const pConfiguration: IConfiguration); reintroduce;
    destructor Destroy; override;
  end;

  // Esta thread � usada pelo pool de conex�es para limpar conex�es
  // que est�o expirando um periodo de tempo sem uso.
  TCleanupThread = class(TThread)
  private
    FCleanupDelay: Integer;
    FConnectionPool: TConnectionProvider;
  protected
    // Quando a thread � criada, o campo secao critica ir� ser definido para
    // a secao critica do pool. Esta secao critica � usada para sincronizar
    // acesso a contagem de referencia do conection.
    procedure Execute; override;
    constructor Create(CreateSuspended: Boolean;
      const CleanupDelayMinutes: Integer);
    property ConnectionPool: TConnectionProvider read FConnectionPool
      write FConnectionPool;
  end;

  /// Classe que implementa a interface IInfraDBConnection.
  TInfraDBConnection = class(TInterfacedObject, IInterface, IConnectionProviderItem)
  private
    { Private declarations }
    FConnection: IZConnection;
    FRefCount: Integer;
    FLastAccess: TDateTime;
    /// Quando esta classe � criada a se��o critica do pool � repassada para c�
    FCriticalSection: TCriticalSection;
    /// Este semaforo aponta para o sem�foro do pool. Ele ir� ser usado para chamar
    /// ReleaseSemaphore do m�todo _Release desta classe.
    FSemaphore: THandle;
  protected
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    { IInfraDBConnection }
    function GetLastAccess: TDateTime;
    function GetRefCount: Integer;
    function Connection: IZConnection;
  public
    { Public declarations }
    constructor Create(const pConnectionString: string;
      pCriticalSection: TCriticalSection; pSemaphore: THandle);
    destructor Destroy; override;
  end;

implementation

uses
  InfraCommonIntf,
  InfraOPFConsts,
  DateUtils;

{ TDBXConnectionPool }

constructor TConnectionProvider.Create(const pConfiguration: IConfiguration);
var
  vCleanupDelayMinutes: Integer;
begin
  FInitialized := False;
  if not Assigned(pConfiguration) then
    raise EInfraArgumentError.Create('pConfiguration');

  FConnectionString := BuildConnectionString(pConfiguration);
  FPoolSize := pConfiguration.GetValue(cCONFIGKEY_POOLSIZE, DefaultPoolSize);
  FTimeout := pConfiguration.GetValue(cCONFIGKEY_CONNECTTIMEOUT, DefaultGetConnTimeoutMS);
  vCleanupDelayMinutes := pConfiguration.GetValue(cCONFIGKEY_CLEANUPDELAYMINUTES, DefaultCleanupConnMIN);

  FSemaphore := CreateSemaphore(nil, FPoolSize, FPoolSize, '');
  FCriticalSection := TCriticalSection.Create;
  FInternallEvent := TEvent.Create(nil, False, False, '');
  
  // Define o tamanho do pool
  SetLength(FConnections, FPoolSize);
  // Cria e inicia a thread de limpeza
  FCleanupThread := TCleanupThread.Create(True, vCleanupDelayMinutes);
  with FCleanupThread do
  begin
    FreeOnTerminate := True;
    Priority := tpLower;
    FCleanupThread.ConnectionPool := Self;
    Resume;
  end;
  FInitialized := True;
end;

destructor TConnectionProvider.Destroy;
var
  i: Integer;
begin
  if Assigned(FCleanupThread) then
  begin
    // Termina a thread de limpeza
    FCleanupThread.Terminate;
    // Se a thread de limpeza esta esperando o timeout, o evento abaixo ir� for�ar
    FInternallEvent.SetEvent;

    // Aguarda a conclus�o da Thread
    WaitForSingleObject(FCleanupThread.Handle, 5000);
  end;

  if FInitialized then
  begin
    // Libera todas as connections modules restantes.
    Lock;
    try
      for i := Low(FConnections) to High(FConnections) do
        FConnections[i] := nil;
      SetLength(FConnections, 0);
    finally
      Unlock;
    end;
    // Libera a se��o cr�tica e o Sem�foro
    FInternallEvent.Free;
    FCriticalSection.Free;
    CloseHandle(FSemaphore);
  end;
  inherited;
end;

{*
  Constr�i a URL de conex�o com o banco
  @param pConfiguration Objeto com as configura��es de conex�o com o banco de dados
  @return Retorna uma string no formato
    zdbc:<driver>://<hostname>/<databasename>?username=<username>;password=<password>
*}
function TConnectionProvider.BuildConnectionString(pConfiguration:
    IConfiguration): string;
begin
  Result := 'zdbc:' + pConfiguration.GetAsString(cCONFIGKEY_DRIVER) +
    '://' + pConfiguration.GetAsString(cCONFIGKEY_HOSTNAME) +
    '/' + pConfiguration.GetAsString(cCONFIGKEY_DATABASENAME) +
    '?username=' + pConfiguration.GetAsString(cCONFIGKEY_USERNAME) +
    ';password=' + pConfiguration.GetAsString(cCONFIGKEY_PASSWORD);
end;

procedure TConnectionProvider.Lock;
begin
  FCriticalSection.Enter;
end;

procedure TConnectionProvider.UnLock;
begin
  FCriticalSection.Leave;
end;

function TConnectionProvider.GetConnection: IConnectionProviderItem;
var
  vI: Integer;
  vConnection: TInfraDBConnection;
  vWaitResult: Integer;
begin
  Result := nil;
  vWaitResult := WaitForSingleObject(FSemaphore, FTimeout);
  if vWaitResult <> WAIT_OBJECT_0 then
    raise EInfraConnPoolException.Create('Connection pool timeout. ' +
      'Cannot obtain a connection');
  Lock;
  try
    for vI := Low(FConnections) to High(FConnections) do
    begin
      // Se o FConnections[i] = nil, o IPoolConnection ainda nao foi criado. Ent�o
      // cria-se, inicializa e o retorna. Se FConnections[i] <> nil, ent�o
      // verifica se seu RefCount � 1 (somente o pool est� fazendo referencia a
      // ele).
      if FConnections[vI] = nil then
      begin
        vConnection := TInfraDBConnection.Create(FConnectionString,
          Self.FCriticalSection,
          Self.FSemaphore);
        vConnection.Connection.Open;
        FConnections[vI] := vConnection;
        Result := FConnections[vI];
        Break;
      end
      else
      // se FConnections[i].RefCount = 1 ent�o a conex�o est� dispon�vel para
      // retorn�-la.
      if FConnections[vI].RefCount = 1 then
      begin
        Result := FConnections[vI];
        Break;
      end;
    end; //for
  finally
    UnLock;
  end;
end;

function TConnectionProvider.GetActiveConnections: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := Low(FConnections) to High(FConnections) do
    if Assigned(FConnections[i]) then
      Inc(Result);
end;

function TConnectionProvider.GetPoolSize: Integer;
begin
  Result := Length(FConnections);
end;

{ TCleanupThread }

constructor TCleanupThread.Create(CreateSuspended: Boolean;
  const CleanupDelayMinutes: Integer);
begin
  // sempre cria suspensa
  inherited Create(True);
  FCleanupDelay := CleanupDelayMinutes;
  if not CreateSuspended then
    Resume;
end;

procedure TCleanupThread.Execute;
var
  i: Integer;
  WaitMinutes: Integer;
  vActiveConnection: Boolean;
  vNoMoreReferences: Boolean;
  vElapsedTime: Integer;
begin
  WaitMinutes := FCleanupDelay * 60 * 1000;
  while not Terminated do
  begin
    // espera pelo periodo definido em FCleanupDelay
    // InternalEvent foi assinalado, est� em erro, ou abandonado,
    // s�o situa��es nas quais a thread deveria terminar.
    if FConnectionPool.FInternallEvent.WaitFor(WaitMinutes) <> wrTimeout then
      Exit;

    if Terminated then
      Exit;

    // WaitForSingleObject tem expirado. Procura limpar as conec��es.
    with FConnectionPool do
    begin
      Lock;
      try
        for i := Low(FConnections) to High(FConnections) do
        begin
          // Libera a conex�o se ela existir, nao tem referencias externas e nao
          // foi recentemente usada.
          vActiveConnection := FConnections[i] <> nil;
          if vActiveConnection then
          begin
            vNoMoreReferences := FConnections[i].RefCount = 1;
            vElapsedTime := MinutesBetween(FConnections[i].LastAccess, Now);

            if (vNoMoreReferences) and (vElapsedTime >= FCleanupDelay) then
              // Fecha a conexao
              FConnections[i] := nil;
          end;
        end;
      finally
        Unlock;
      end; // try
    end; // with
  end; // while
end;

{ TConnectionModule }

function TInfraDBConnection._AddRef: Integer;
begin
  // increment a contagem de referencias
  FCriticalSection.Enter;
  try
    Inc(FRefCount);
    Result := FRefCount;
  finally
    FCriticalSection.Leave;
  end;
end;

function TInfraDBConnection._Release: Integer;
var
  tmpCriticalSection: TCriticalSection;
  tmpSemaphore: THandle;
begin
  // Guarda referencias locais a sess�o critica e ao semaforo
  // Isto � necess�rio por que estes membros seriam inv�lidados durante
  // a destrui��o do ConnectionModule, e s� podemos liberar o sem�foro ap�s o
  // Destroy que vai acontecer dentro do inherited _Release.
  tmpCriticalSection := FCriticalSection;
  tmpSemaphore := FSemaphore;
  Result := FRefCount;
  // dencrementa a contagem de referencias
  FCriticalSection.Enter;
  try
    Dec(FRefCount);
    Result := FRefCount;
    // se n�o h� mais referencias, chama Destroy
    if Result = 0 then
      Destroy
    else
      Self.FLastAccess := Now;
  finally
    tmpCriticalSection.Leave;
    if Result = 1 then
      ReleaseSemaphore(tmpSemaphore, 1, nil);
  end;
end;

function TInfraDBConnection.Connection: IZConnection;
begin
  Result := FConnection;
end;

function TInfraDBConnection.GetRefCount: Integer;
begin
  FCriticalSection.Enter;
  Result := FRefCount;
  FCriticalSection.Leave;
end;

function TInfraDBConnection.GetLastAccess: TDateTime;
begin
  FCriticalSection.Enter;
  Result := FLastAccess;
  FCriticalSection.Leave;
end;

constructor TInfraDBConnection.Create(const pConnectionString: string;
  pCriticalSection: TCriticalSection; pSemaphore: THandle);
begin
  inherited Create;
  FCriticalSection := pCriticalSection;
  FSemaphore := pSemaphore;
  FConnection := DriverManager.GetConnection(pConnectionString);
end;

destructor TInfraDBConnection.Destroy;
begin
  FConnection := nil;
  inherited;
end;

end.
