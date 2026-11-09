program dimtest;
{Opens a disc image with the TDiscImage class and lists what it finds.
 Used by the "Test images" workflow.}
{$mode objfpc}{$H+}
uses SysUtils, Classes, Math, DiscImage;
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
 //With short filenames only, the GUI first removes all the long names
 if SFN then
 begin
  Image.RemoveDOSLongFilenames;
  Check:=TDiscImage.Create(Image);
  r:=0;
  for d:=0 to Length(Check.Disc)-1 do
   for e:=0 to Length(Check.Disc[d].Entries)-1 do
    if Check.Disc[d].Entries[e].Filename<>Check.Disc[d].Entries[e].ShortFilename then
    begin
     WriteLn('Defrag: FAIL - long name left: ',Check.GetParent(d),'\',
             Check.Disc[d].Entries[e].Filename);
     inc(r);
    end;
  if r>0 then Result:=False
  else WriteLn('Defrag: all long names removed');
  Check.Free;
 end;
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
 //(a long name that only differs in case from the short name, e.g. no_log,
 //is written as the short name, which DOS does not mind)
 if(UpperCase(A.Text)<>UpperCase(B.Text))or(A.Count<>B.Count)then
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

{Renames one plain entry in the root, saves and reloads, and checks that
 nothing else changed (e.g. long names such as .Trashes must be kept)}
function RenameTest(filename: String;SFN: Boolean): Boolean;
var
 Img, Check: TDiscImage;
 A, B      : TStringList;
 e         : Integer;
 oldn,newn,
 tmp       : String;
begin
 Result:=True;
 Img:=TDiscImage.Create;
 Img.DOSUseSFN:=SFN;
 Img.LoadFromFile(filename);
 Img.ProgressIndicator:=nil;
 //Find the last root entry with no long name
 oldn:='';
 for e:=0 to Length(Img.Disc[0].Entries)-1 do
  if Img.Disc[0].Entries[e].Filename=Img.Disc[0].Entries[e].ShortFilename then
   oldn:=Img.Disc[0].Entries[e].Filename;
 if oldn='' then begin Img.Free; exit; end;
 newn:=oldn;
 if newn[Length(newn)]='Z' then newn[Length(newn)]:='Y' else newn[Length(newn)]:='Z';
 tmp:=newn;
 A:=TStringList.Create; B:=TStringList.Create;
 A.Text:=StringReplace(Listing(Img),'A:\'+oldn,'A:\'+newn,[rfReplaceAll]);
 if Img.RenameFile('A:\'+oldn,tmp)<0 then
 begin
  WriteLn('Rename: FAIL renaming ',oldn);
  Result:=False;
 end;
 Check:=TDiscImage.Create(Img);
 B.Text:=Listing(Check);
 A.Sort; B.Sort;
 if A.Text<>B.Text then
 begin
  WriteLn('Rename (short filenames ',SFN,'): FAIL - other names changed');
  for e:=0 to A.Count-1 do if B.IndexOf(A[e])<0 then WriteLn('  missing: ',A[e]);
  for e:=0 to B.Count-1 do if A.IndexOf(B[e])<0 then WriteLn('  extra  : ',B[e]);
  Result:=False;
 end
 else WriteLn('Rename (short filenames ',SFN,'): OK, ',oldn,' -> ',tmp);
 A.Free; B.Free;
 Check.Free;
 Img.Free;
end;

{Sorts every directory, reads the image back in, and checks that nothing was
 lost and that the files are in the order asked for (system files first in the
 root, then directories, then files)}
function SortTest(filename: String;code: Integer): Boolean;
var
 Img, Check: TDiscImage;
 A, B      : TStringList;
 d, e      : Integer;
 prev, cur : TDirEntry;
 bad       : Boolean;
 function IsSys(const X: TDirEntry): Boolean;
 begin
  Result:=Pos('S',X.Attributes)>0;
 end;
begin
 Result:=True;
 Img:=TDiscImage.Create;
 Img.LoadFromFile(filename);
 Img.ProgressIndicator:=nil;
 A:=TStringList.Create; B:=TStringList.Create;
 A.Text:=Listing(Img);
 Img.SortDOSDirectories(code div 2,Odd(code));
 Check:=TDiscImage.Create(Img);
 B.Text:=Listing(Check);
 A.Sort; B.Sort;
 if A.Text<>B.Text then
 begin
  WriteLn('Sort ',code,': FAIL - entries changed');
  for e:=0 to A.Count-1 do if B.IndexOf(A[e])<0 then WriteLn('  missing: ',A[e]);
  for e:=0 to B.Count-1 do if A.IndexOf(B[e])<0 then WriteLn('  extra  : ',B[e]);
  Result:=False;
 end;
 //Check the order in every directory
 bad:=False;
 for d:=0 to Length(Check.Disc)-1 do
  for e:=1 to Length(Check.Disc[d].Entries)-1 do
  begin
   prev:=Check.Disc[d].Entries[e-1];
   cur :=Check.Disc[d].Entries[e];
   if(Check.Disc[d].Parent=-1)and(IsSys(prev) or IsSys(cur))then
   begin
    if IsSys(cur) and not IsSys(prev) then bad:=True;
    continue;
   end;
   if(prev.DirRef>=0)<>(cur.DirRef>=0)then
   begin
    if(cur.DirRef>=0)then bad:=True;
    continue;
   end;
   if(code div 2=0)and(cur.DirRef<0)then
    if((code=0)and(CompareText(prev.Filename,cur.Filename)>0))
    or((code=1)and(CompareText(prev.Filename,cur.Filename)<0))then bad:=True;
   if(code div 2=2)and(cur.DirRef<0)then
    if((code=4)and(prev.Length>cur.Length))
    or((code=5)and(prev.Length<cur.Length))then bad:=True;
   if bad then
   begin
    WriteLn('Sort ',code,': FAIL - wrong order at ',Check.GetParent(d),'\',cur.Filename);
    break;
   end;
  end;
 if bad then Result:=False;
 if Result then WriteLn('Sort ',code,': OK');
 for e:=0 to Min(9,Length(Check.Disc[0].Entries)-1) do
  WriteLn('   ',Check.Disc[0].Entries[e].Filename,' ',Check.Disc[0].Entries[e].Length);
 A.Free; B.Free;
 Check.Free;
 Img.Free;
end;

{Copies and moves a whole directory around (as the GUI does when one is
 dragged), with and without 8.3 names only, and checks that no entry ends up
 with a path in its name}
function PathNameTest(filename: String;SFN: Boolean): Boolean;
var
 Img, Check: TDiscImage;
 d, e, n   : Integer;
 src       : String;
 procedure Step(what: String;res: Integer);
 begin
  WriteLn('PathName: ',what,' = ',res);
 end;
 function BadNames(I: TDiscImage): Integer;
 var
  dd, ee: Integer;
 begin
  Result:=0;
  for dd:=0 to Length(I.Disc)-1 do
   if not I.Disc[dd].Deleted then
    for ee:=0 to Length(I.Disc[dd].Entries)-1 do
     if(Pos('\',I.Disc[dd].Entries[ee].Filename)>0)
     or(Pos(':',I.Disc[dd].Entries[ee].Filename)>0)then
     begin
      if Result<5 then
       WriteLn('PathName: FAIL - ',I.GetParent(dd),' has "',
               I.Disc[dd].Entries[ee].Filename,'"');
      inc(Result);
     end;
 end;
begin
 Result:=True;
 Img:=TDiscImage.Create;
 Img.DOSUseSFN:=SFN;
 Img.LoadFromFile(filename);
 Img.ProgressIndicator:=nil;
 //Find a directory with files in it, below the root
 src:='';
 for d:=0 to Length(Img.Disc)-1 do
  if(src='')and(Img.Disc[d].Parent>0)and(Length(Img.Disc[d].Entries)>2)then
   src:=Img.GetParent(d);
 if src='' then begin Img.Free; exit; end;
 WriteLn('PathName (8.3 only ',SFN,'): using ',src);
 Step('copy to root as COPYDIRX',Img.CopyFile(src,'A:','COPYDIRX'));
 Step('copy COPYDIRX into the source',Img.CopyFile('A:\COPYDIRX',src));
 Step('copy to root as LONGCOPYNAME',Img.CopyFile(src,'A:','LONGCOPYNAME'));
 Step('move COPYDIRX into the last directory',
      Img.MoveFile('A:\COPYDIRX',Img.GetParent(Length(Img.Disc)-1)));
 n:=BadNames(Img);
 Img.SortDOSDirectories(0,False);
 n:=n+BadNames(Img);
 Check:=TDiscImage.Create(Img);
 n:=n+BadNames(Check);
 if n>0 then Result:=False else WriteLn('PathName (8.3 only ',SFN,'): OK');
 Check.Free;
 Img.Free;
end;

{Creates directories inside new directories, copies and moves them, and
 checks that all of it is there after reading the image back in, and that it
 can still be defragged}
function NestTest(filename: String): Boolean;
var
 Img, Check: TDiscImage;
 A, B      : TStringList;
 r         : Integer;
 ok        : Boolean;
 attr,n,p  : String;
 entry     : TDirEntry;
 buffer    : TDIByteArray;
 procedure Step(what: String;res: Integer);
 begin
  if res<0 then
  begin
   WriteLn('Nest: FAIL ',what,' (',res,')');
   ok:=False;
  end;
 end;
 procedure AddFile(parent,name: String);
 var
  i: Integer;
 begin
  ResetDirEntry(entry);
  entry.Parent:=parent;
  entry.Filename:=name;
  entry.Attributes:='';
  SetLength(buffer,100);
  for i:=0 to 99 do buffer[i]:=i;
  entry.Length:=100;
  Step('writing '+parent+'\'+name,Img.WriteFile(entry,buffer));
 end;
begin
 ok:=True;
 Img:=TDiscImage.Create;
 Img.LoadFromFile(filename);
 Img.ProgressIndicator:=nil;
 attr:='D';
 n:='NEST1'; p:='A:';         Step('creating NEST1',Img.CreateDirectory(n,p,attr));
 n:='NEST2'; p:='A:\NEST1';   Step('creating NEST2',Img.CreateDirectory(n,p,attr));
 n:='NEST3'; p:='A:\NEST1\NEST2'; Step('creating NEST3',Img.CreateDirectory(n,p,attr));
 AddFile('A:\NEST1\NEST2\NEST3','DEEP.TXT');
 AddFile('A:\NEST1\NEST2','MID.TXT');
 AddFile('A:\NEST1','TOP.TXT');
 //Copy a directory with a directory in it up to the root
 Step('copying NEST2 to the root',Img.CopyFile('A:\NEST1\NEST2','A:'));
 //Move a directory up one level
 Step('moving NEST3 to NEST1',Img.MoveFile('A:\NEST1\NEST2\NEST3','A:\NEST1'));
 //Copy with a new name that is too long for 8.3, with 8.3 names only: the
 //copy gets a shorter name, and its contents must still go into it
 Img.DOSUseSFN:=True;
 Step('copying NEST2 as NEST2COPY',Img.CopyFile('A:\NEST1\NEST2','A:\NEST1','NEST2COPY'));
 Img.DOSUseSFN:=False;
 //Read it back in and compare
 A:=TStringList.Create; B:=TStringList.Create;
 A.Text:=Listing(Img);
 Check:=TDiscImage.Create(Img);
 B.Text:=Listing(Check);
 A.Sort; B.Sort;
 if A.Text<>B.Text then
 begin
  WriteLn('Nest: FAIL - the image read back in is different');
  for r:=0 to A.Count-1 do if B.IndexOf(A[r])<0 then WriteLn('  missing: ',A[r]);
  for r:=0 to B.Count-1 do if A.IndexOf(B[r])<0 then WriteLn('  extra  : ',B[r]);
  ok:=False;
 end
 else WriteLn('Nest: OK, ',B.Count,' entries');
 for r:=0 to B.Count-1 do if Pos('NEST',B[r])>0 then WriteLn('  ',B[r]);
 if B.IndexOf('A:\NEST1\NEST2COP\MID.TXT 100')<0 then
 begin
  WriteLn('Nest: FAIL - the contents of the renamed copy are missing');
  ok:=False;
 end;
 //Refresh Image (read again from memory) must give the same
 if Img.ReloadFromData then
 begin
  A.Text:=Listing(Img);
  A.Sort;
  if A.Text<>B.Text then
  begin
   WriteLn('Nest: FAIL - refreshing the image gives something different');
   ok:=False;
  end
  else WriteLn('Nest: refresh OK');
 end
 else
 begin
  WriteLn('Nest: FAIL - could not refresh the image');
  ok:=False;
 end;
 A.Free; B.Free;
 //And it can still be defragged
 if not DefragTest(Check,False) then ok:=False;
 Check.Free;
 Img.Free;
 Result:=ok;
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
    if(ParamStr(2)='defrag')then
    begin
     if not RenameTest(ParamStr(1),False) then ExitCode:=3;
     if not RenameTest(ParamStr(1),True) then ExitCode:=3;
     if not NestTest(ParamStr(1)) then ExitCode:=3;
     if not SortTest(ParamStr(1),1) then ExitCode:=3;
     if not SortTest(ParamStr(1),4) then ExitCode:=3;
     if not PathNameTest(ParamStr(1),False) then ExitCode:=3;
     if not PathNameTest(ParamStr(1),True) then ExitCode:=3;
    end;
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
