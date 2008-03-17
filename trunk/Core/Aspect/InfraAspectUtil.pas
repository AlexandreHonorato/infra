// fix uses
unit InfraAspectUtil;

interface

{$I 'InfraAspect.Inc'}

uses
  {$IFDEF USE_GXDEBUG}DBugIntf, {$ENDIF}
  InfraCommonIntf;

type
  TStubArray = array of Pointer;

function CreateStub(var FStubs: TStubArray;
  pMethodInfo: IMethodInfo): integer;

const
  SIZE_OF_STUB = $3E;   // 62 (size of stub's instructions)

implementation

uses
  Types,
  Classes,
  Windows,
  SysUtils,
  InfraVMTUtil,
  InfraAspectIntf;

const
  METHOD_INDEX = 12;  // the position of MethodIndex on stub
  START_STACK = 32;   // the stack is 32 positions after actual stack's point
                      // because pushs on starting stub

type
  TByteArray = array[0..1024] of byte;
  TDwordArray = array[0..1024] of dword;
             
{
  Adiciona o parametro que corresponde ao Resultado de uma fun��o no final
  da mesma lista onde est�o os par�metros do m�todo.
}
procedure PackResult(const List: IInterfaceList; const Index: integer;
  const pMethodInfo: IMethodInfo; Param: Pointer);
var
  Count: integer;
begin
  if pMethodInfo.IsFunction then
    Count := pMethodInfo.Parameters.Count-1
  else
    Count := pMethodInfo.Parameters.Count;
  if Index >= Count then
    raise exception.Create('MethodMember index out of bounds');
  List.Add(IInterface(Param));
end;

{
  Empacota os registradores, pilha, e resultado (caso m�todo seja uma fun��o)
  em uma InterfaceList para poder passar isso para a chamada dos Advices.

  Quando m�todo � uma fun��o o numero de parametros tem de ser incrementado
  aqui por que o resultado deve ser adicionado a lista de interfaces.
}
function PackParams(const pMethodInfo: IMethodInfo; reg_edx,
  reg_ecx, reg_esp, reg_eax: Pointer): IInterfaceList;
var
  StackParams: PParams;
  i, j, ParamsPacked: integer;
  QtdParams: integer;
begin
  Result := nil;
  ParamsPacked := 0;
  QtdParams := pMethodInfo.Parameters.Count;
  j := 0;
  if Assigned(pMethodInfo.ReturnType) then
  begin
    Dec(QtdParams);
    Inc(j);
  end;
  if (QtdParams = 0) then
    Exit;
  if QtdParams > 0 then
  begin
    Result := TInterFaceList.Create;
    PackResult(Result, 0, pMethodInfo, reg_edx);
    Inc(ParamsPacked)
  end;
  if QtdParams > 1 then
  begin
    PackResult(Result, 1, pMethodInfo, reg_ecx);
    Inc(ParamsPacked);
  end;
  if QtdParams > 2 then
  begin
    StackParams := Pointer(Integer(reg_esp)+START_STACK);
    for i := QtdParams-ParamsPacked-1 downto 0 do
      PackResult(Result, i+ParamsPacked, pMethodInfo, Pointer(StackParams[i+j]))
  end;
end;

{
  Este m�todo � chamado pelo Stub quando um m�todo interceptado � alcancado
  pela execu��o da aplicacao.

  O Objetivo � encontrar o primeiro JointPoint compat�vel com o m�todo
  chamado pelo programador e chamar os Advices (Before, After e/ou Around)
  dos seus aspectos.

  Antes de chamar os Advices os parametros precisam ser empacotados em uma
  IInterfaceList. M�todos do tipo register guardam os parametros da seguinte
  forma:
  Primeiro Parametro:         Registrador EAX
  Segundo Parametro:          Registrador ECX
  Terceiro Parametro:         Registrador EDX
  Quarto Parametro em diante: na pilha, Registrador ESP aponta para o topo da
                              pilha.

  Quando o M�todo do tipo register chamado � uma fun��o, o retorno da fun��o
  tambem pode estar em diferentes lugares dependendo da quantidade de
  parametros dos m�todos. O resultado da fun��o estar� em:

  EDX:            caso a fun��o tenha 1 par�metro;
  ECX:            caso a fun��o tenha 2 par�metros;
  No topo de ESP: caso a fun��o tenha mais de 2 par�metros;

  Esta fun��o precisa retorna a quantidade de parametros definidos em
  MethodInfo (Method Metadata Information) para que o stub possa ser limpo
  corretamente.
}
function Call_Aspects(var pParamCount: Integer; pMethodIndex: integer;
  reg_esp, reg_edx, reg_ecx, reg_eax: Pointer): dword; stdcall;
var
  i: integer;
  MethodInfo: IMethodInfo;
  Params: IInterfaceList;
  MethodResult: IInterface;
  ResultAdr: Pointer;
begin
  Result := 0;
  with AspectService do
  begin
    for i := 0 to JointPoints.Count-1 do
    begin
      MethodInfo := JointPoints[i].MethodInfo;
      if (MethodInfo.DeclaringType.ImplClass = TObject(reg_eax).ClassType) and
        (JointPoints[i].MethodIndex = pMethodIndex) then
      begin
        pParamCount := JointPoints[i].ParamsCount;
        Params := PackParams(MethodInfo, reg_edx, reg_ecx, reg_esp,
          reg_eax);
        MethodResult := CallAdvices(JointPoints[i], reg_eax, Params);
        if MethodInfo.IsFunction then
        begin
          case pParamCount of
            1: ResultAdr := reg_edx;
            2: ResultAdr := reg_ecx;
          else
            ResultAdr := Pointer(PParams(Integer(reg_esp)+START_STACK)[0]);
          end;
          Pointer(ResultAdr^) := Pointer(MethodResult);
          IInterface(ResultAdr^)._AddRef;
        end;
        Break;
      end;
    end;
  end;
end;

var
  ADDR_CALLASPECTS: Pointer = @Call_Aspects;

{
  Aten��o !!!
  Se houver altera��es entre o primeiro push e o call, os seguintes par�metros
  dever�o ser alterados:
  - SIZE_OF_STUB: O tamanho, contado de 2 em 2, das instru��es exibidas na
    CPU Window;
  - METHOD_INDEX: O quantidade de instru��es, contado de 2 em 2, at� se chegar
    ao segundo push$ 00;
  - START_STACK: A quantidade de parametro de Call_aspect * 4;

  O SIZE_OF_STUB provavelmente ser� alterada sempre que houver alguma
  mudan�a no stub;
}
procedure stub;
asm
  push esi         // armazena ESI
  push edi         // armazena EDI
  push ebx         // armazena EBX
  push $00         // variavel local para guarda a quantidade de parametros
  mov ebx, esp     // EBX = @qtd_params
  push eax         // reg_eax, contar START_STACK at� aqui (quantidade de bytes das instru��es)
  push ecx         // reg_ecx
  push edx         // reg_edx
  push esp         // reg_esp
  push $00         // pmethodIndex (substituido na cria��o do stub), METHOD_INDEX at� aqui (quantide de instru��es)
  push ebx         // joga qtdParams (nossa vari�vel local) na pilha
  // Este call remove todos os parametros colocados na pilha voltando
  // para a posi��o onde foi dada o primeiro push $00
  call [ADDR_CALLASPECTS]
  pop ecx           // joga qtdParams em ECX
  mov esi, esp      // move posi��o da pilha para esi para recupera��o dos registradores no final
  add esp, 16       // move ponteiro da pilha para posi��o do primeiro par�metro empilhado (se houve empilhamento)
  mov edi, eax      // guarda o resultado da fun��o em EDI (quando resultado de callaspects � primitivo)
  sub ecx, 2        // calcula a quantidade de par�metros empilhados
  cmp ecx, 1        // Se for menor que 1
  jl @skip          // ent�o pula essa parte
  mov eax, 4        // coloca 4 em eax para poder corrigir a pilha
  mul eax, ecx      // multiplica EAX pela quantidade de par�metros
  add esp, eax      // posiciona a pilha ap�s o par�metros empilhados quando na entrada do stub
@skip:
  mov eax, edi      // restaura o result (quando resultado de callaspects � primitivo)
  mov ecx, esi      // poe em ECX a posi��o da pilha onde est�o os registradores
  mov ebx, [ecx]    // Restaura EBX
  mov edi, [ecx+4]  // restaura EDI
  mov esi, [ecx+8]  // restaura ESI
  mov ecx, [ecx+12] // restautra endere�o de retorno
  jmp ecx           // pula para o endere�o de retorno e continua a execu��o
end;

function CreateStub(var FStubs: TStubArray;
  pMethodInfo: IMethodInfo): integer;
var
  stub_buf: Pointer;
  i: byte;
  mbi: TMemoryBasicInformation;
  old: cardinal;
  VMT: TClass;
begin
  VMT := pMethodInfo.DeclaringType.ImplClass;
  GetMem(stub_buf, SIZE_OF_STUB);
  SetLength(FStubs, Length(FStubs)+1);
  FStubs[Length(FStubs)-1] := stub_buf;
  CopyMemory(stub_buf, @stub, SIZE_OF_STUB);
  {$IFDEF USE_DEBUG_STUB}
  stub_buf := @stub;
  {$ENDIF}
  i := GetVirtualMethodCount(VMT);
  while i > 0 do
    if GetVirtualMethod(VMT, i) = pMethodInfo.MethodPointer then
      Break
    else
      Dec(i);
  if i = 0 then
    Exception.Create('Virtual Method "'+pMethodInfo.Name+'" not Found!');
  VirtualQueryEx(GetCurrentProcess, Pointer(vmt), mbi, sizeof(mbi));
  VirtualProtect(Pointer(integer(VMT)+i*4), 4, PAGE_EXECUTE_READWRITE, old);
  if (mbi.Protect and PAGE_READWRITE) <> 0 then
    Exception.Create('Bad Read/Write Page');
  if IsBadReadPtr(Pointer(VMT),4) then
    raise Exception.Create('Bad Read Ptr');
  TDwordArray(Pointer(VMT)^)[i] := dword(stub_buf);
  {$IFDEF USE_DEBUG_STUB}
  VirtualProtect(stub_buf, SIZE_OF_STUB, PAGE_EXECUTE_READWRITE, old);
  {$ENDIF}
  TByteArray(stub_buf^)[METHOD_INDEX] := dword(i);
  FlushInstructionCache(GetCurrentProcess, stub_buf, SIZE_OF_STUB);
  Result := i;
end;

end.
