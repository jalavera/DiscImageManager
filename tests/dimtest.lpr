program dimtest;
{Opens a disc image with the TDiscImage class and lists what it finds.
 Used by the "Test images" workflow.}
{$mode objfpc}{$H+}
uses SysUtils, DiscImage;
type
 TProgress = class
  procedure Show(Fupdate: String);
 end;
procedure TProgress.Show(Fupdate: String);
begin
 WriteLn('  progress: ',Fupdate);
 Flush(Output);
end;
var
 Image   : TDiscImage;
 Progress: TProgress;
 d,e,p   : Integer;
begin
 Image:=TDiscImage.Create;
 Progress:=TProgress.Create;
 Image.ProgressIndicator:=@Progress.Show;
 try
  try
   WriteLn('Loading ',ParamStr(1));
   Flush(Output);
   if Image.LoadFromFile(ParamStr(1)) then
   begin
    WriteLn('Format         : ',Image.FormatString);
    WriteLn('DOS partitions : ',Image.DOSPartitionCount);
    for p:=0 to Image.DOSPartitionCount-1 do
     WriteLn('  ',p,': ',Image.DOSPartitionDescription(p));
    WriteLn('Directories    : ',Length(Image.Disc));
    for d:=0 to Length(Image.Disc)-1 do
    begin
     WriteLn('[',Image.Disc[d].Directory,'] ',Length(Image.Disc[d].Entries),' entries');
     if d=0 then
      for e:=0 to Length(Image.Disc[d].Entries)-1 do
       WriteLn('   ',Image.Disc[d].Entries[e].Filename);
    end;
   end
   else
   begin
    WriteLn('FAILED to open the image: ',Image.LoadErrorMessage);
    ExitCode:=1;
   end;
  except
   on E: Exception do
   begin
    WriteLn('EXCEPTION: ',E.ClassName,': ',E.Message);
    DumpExceptionBackTrace(Output);
    ExitCode:=2;
   end;
  end;
 finally
  Image.Free;
  Progress.Free;
 end;
end.
