program dimtest;
{Opens a disc image with the TDiscImage class and lists what it finds.
 Used by the "Test images" workflow.}
{$mode objfpc}{$H+}
uses SysUtils, Classes, DiscImage;
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
 everything back in from a copy of the image. With SFN set, it is done with
 "No long filenames on DOS images" turned on, so names may change and only the
 number of entries is compared.}
function DefragTest(Image: TDiscImage;SFN: Boolean): Boolean;
var
 Old, Check: TDiscImage;
 A, B      : TStringList;
 d,e,r,i   : Integer;
 entry     : TDirEntry;
 buffer    : TDIByteArray;
 name,par,
 attr,
 before    : String;
 MapFrom,
 MapTo     : array of String;
 function Map(path: String): String;
 var
  k: Integer;
 begin
  Result:=path;
  for k:=Length(MapFrom)-1 downto 0 do
   if(Result=MapFrom[k])or(Copy(Result,1,Length(MapFrom[k])+1)=MapFrom[k]+'\')then
    Result:=MapTo[k]+Copy(Result,Length(MapFrom[k])+1);
 end;
begin
 Result:=True;
 SetLength(MapFrom,0);
 SetLength(MapTo,0);
 before:=Listing(Image);
 Old:=TDiscImage.Create(Image);
 Old.ProgressIndicator:=nil;
 Image.ProgressIndicator:=nil;
 Image.DOSUseSFN:=SFN;
 WriteLn('Defrag (short filenames ',SFN,'): deleting ',Length(Image.Disc[0].Entries),' root entries');
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
   par:=Map(Old.GetParent(d));
   name:=entry.Filename;
   if entry.DirRef>=0 then
   begin
    attr:=entry.Attributes;
    r:=Image.CreateDirectory(name,par,attr);
    //The name may have changed, so its contents need to follow it
    if r>=0 then
     if Image.Disc[Length(Image.Disc)-1].Directory<>entry.Filename then
     begin
      i:=Length(MapFrom);
      SetLength(MapFrom,i+1);
      SetLength(MapTo,i+1);
      MapFrom[i]:=Old.GetParent(d)+'\'+entry.Filename;
      MapTo[i]:=par+'\'+Image.Disc[Length(Image.Disc)-1].Directory;
      WriteLn('Defrag: ',MapFrom[i],' is now ',MapTo[i]);
     end;
   end
   else
   begin
    SetLength(buffer,0);
    if not Old.ExtractFile(Old.GetParent(d)+'\'+name,buffer) then
    begin
     WriteLn('Defrag: FAIL reading ',Old.GetParent(d),'\',name);
     Result:=False;
    end;
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
 A:=TStringList.Create; B:=TStringList.Create;
 A.Text:=before; B.Text:=Listing(Check);
 //The order may change, which does not matter
 A.Sort; B.Sort;
 if((not SFN)and(A.Text<>B.Text))or(A.Count<>B.Count)then
 begin
  WriteLn('Defrag: FAIL - the defragged image is different');
  for d:=0 to A.Count-1 do if B.IndexOf(A[d])<0 then WriteLn('  missing: ',A[d]);
  for d:=0 to B.Count-1 do if A.IndexOf(B[d])<0 then WriteLn('  extra  : ',B[d]);
  WriteLn('  ',A.Count,' entries before, ',B.Count,' after');
  Result:=False;
 end
 else WriteLn('Defrag: OK, ',Length(Check.Disc),' directories, ',B.Count,' entries');
 if SFN then Write(B.Text);
 A.Free; B.Free;
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
    if(ParamStr(2)='defrag')and(not DefragTest(Image,False))then ExitCode:=3;
    //Again, on a fresh copy, with short filenames only
    if ParamStr(2)='defrag' then
    begin
     Image.Free;
     Image:=TDiscImage.Create;
     if Image.LoadFromFile(ParamStr(1)) then
      if not DefragTest(Image,True) then ExitCode:=3;
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
