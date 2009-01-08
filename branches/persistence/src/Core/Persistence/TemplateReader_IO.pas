unit TemplateReader_IO;

interface

uses
  Classes,
  InfraCommon,
  InfraPersistenceIntf,
  InfraPersistence;

type
  TTemplateReader_IO = class(TTemplateReader, ITemplateReader)
  protected
    function GetFilename(const pTemplateName: string): string;
    function Read(const pTemplateName: string): string;
  public
    constructor Create; override;
  end;

implementation

uses
  SysUtils,
  InfraPersistenceConsts,
  InfraCommonIntf;

{ TTemplateReader }

constructor TTemplateReader_IO.Create;
begin

end;

function TTemplateReader_IO.GetFilename(const pTemplateName: string): string;
begin
  with Configuration do
    Result := IncludeTrailingPathDelimiter(
      GetValue(cCONFIGKEY_TEMPLATEPATH, ExtractFilePath(ParamStr(0))))+
      pTemplateName+'.'+
      GetValue(cCONFIGKEY_TEMPLATEEXT, 'sql');
end;

function TTemplateReader_IO.Read(const pTemplateName: string): string;
var
  vFileName: string;
  vStream: TFileStream;
  vFileSize: Integer;
begin
  // *** tem de gerar uma exce��o caso o arquivo nao exista, acho que tem de
  // *** procurar o arquivo com findfirst ou tratar o Result = Emptystr.
  vFileName := GetFilename(pTemplateName);
  vStream := TFileStream.Create(vFileName, fmOpenRead or fmShareDenyWrite);
  try
    Result := ReadFromStream(vStream);
  finally
    vStream.Free;
  end;
end;

end.