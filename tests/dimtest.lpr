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
{Lists every directory and file, so two images can be compared}
function Listing(Img: TDiscImage): String;
var
 d,e: Integer;
begin
 Result:='';
 for d:=0 to Length(Img.Disc)-1 do
  if not Img.Disc[d].Deleted then
   for e:=0 to Length(Img.Disc[d].Entries)-1 do
    Result:=Result+Img.GetParent(d)+'\'+Img.Disc[d].Entries[e].Filename
           +' '+IntToStr(Img.Disc[d].Entries[e].Length)+LineEnding;
end;

{Does what the GUI defrag does: deletes everything in the root, then copies
 everything back in from a copy of the image}
function DefragTest(Image: TDiscImage): Boolean;
var
 Old, Check: TDiscImage;
 d,e,r     : Integer;
 entry     : TDirEntry;
 buffer    : TDIByteArray;
 name,par,
 attr,
 before    : String;
begin
 Result:=True;
 before:=Listing(Image);
 Old:=TDiscImage.Create(Image);
 Old.ProgressIndicator:=nil;
 Image.ProgressIndicator:=nil;
 WriteLn('Defrag: deleting ',Length(Image.Disc[0].Entries),' root entries');
 while(Length(Image.Disc[0].Entries)>0)and(Result)do
  Result:=Image.DeleteFile(Image.Disc[0].Entries[0].Parent+'\'
                          +Image.Disc[0].Entries[0].Filename);
 WriteLn('Defrag: delete ',Result,', directories left ',Length(Image.Disc),
         ', root entries left ',Length(Image.Disc[0].Entries));
 if Length(Image.Disc)<>1 then
 begin
  WriteLn('Defrag: FAIL - deleted directories are still listed');
  Result:=False;
 end;
 for d:=0 to Length(Old.Disc)-1 do
  for e:=0 to Length(Old.Disc[d].Entries)-1 do
  begin
   entry:=Old.Disc[d].Entries[e];
   par:=Old.GetParent(d);
   name:=entry.Filename;
   if entry.DirRef>=0 then
   begin
    attr:=entry.Attributes;
    r:=Image.CreateDirectory(name,par,attr);
   end
   else
   begin
    SetLength(buffer,0);
    Old.ExtractFile(par+'\'+name,buffer);
    entry.Parent:=par;
    r:=Image.WriteFile(entry,buffer);
   end;
   if r<0 then
   begin
    WriteLn('Defrag: FAIL writing ',par,'\',name,' (',r,')');
    Result:=False;
   end;
  end;
 //Read the result back from the raw data, as a fresh image
 Check:=TDiscImage.Create(Image);
 if Listing(Check)<>before then
 begin
  WriteLn('Defrag: FAIL - the defragged image is different');
  WriteLn('--- before'+LineEnding,before,'--- after'+LineEnding,Listing(Check));
  Result:=False;
 end
 else WriteLn('Defrag: OK, ',Length(Check.Disc),' directories match');
 Check.Free;
 Old.Free;
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
    if(ParamStr(2)='defrag')and(not DefragTest(Image))then ExitCode:=3;
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
