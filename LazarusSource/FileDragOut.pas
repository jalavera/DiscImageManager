unit FileDragOut;

{
Dragging files and directories out of Disc Image Manager onto the Finder or
Explorer (or any other app that accepts files), on macOS and Windows.

The LCL can only drag and drop within the application, so this starts a native
drag with the files that have already been extracted to a temporary folder:
a Cocoa drag session on macOS, and an OLE DoDragDrop on Windows (with the
shell's own data object for the files, so Explorer treats them as normal
files). The Finder/Explorer then copies them to wherever they are dropped.

On other platforms StartFileDragOut does nothing and returns False.
}

{$mode objfpc}{$H+}
{$IFDEF DARWIN}{$modeswitch objectivec1}{$ENDIF}

interface

uses
 SysUtils;

//Start dragging these files/directories, from the given NSView handle
function StartFileDragOut(View: PtrUInt; const Paths: array of String): Boolean;
//An empty temporary folder to extract the dragged files into
function DragOutFolder: String;
//Is the (left) mouse button still held down? (always True on macOS)
function DragButtonDown: Boolean;

implementation

{$IFDEF DARWIN}
uses
 CocoaAll;

type
 //The source of the drag - only needs to say what it allows
 TDIMDragSource = objcclass(NSObject, NSDraggingSourceProtocol)
  function draggingSession_sourceOperationMaskForDraggingContext(
   session: NSDraggingSession; context: NSDraggingContext): NSDragOperation;
   message 'draggingSession:sourceOperationMaskForDraggingContext:';
 end;

var
 DragSource: TDIMDragSource=nil;

function TDIMDragSource.draggingSession_sourceOperationMaskForDraggingContext(
 session: NSDraggingSession; context: NSDraggingContext): NSDragOperation;
begin
 //Only copy, and only to other applications (e.g. the Finder)
 if context=NSDraggingContextOutsideApplication then
  Result:=NSDragOperationCopy
 else
  Result:=NSDragOperationNone;
end;

function DragButtonDown: Boolean;
begin
 Result:=True;
end;

function StartFileDragOut(View: PtrUInt; const Paths: array of String): Boolean;
var
 v    : NSView;
 ev   : NSEvent;
 items: NSMutableArray;
 item : NSDraggingItem;
 url  : NSURL;
 path : NSString;
 icon : NSImage;
 pt   : NSPoint;
 i    : Integer;
begin
 Result:=False;
 if(View=0)or(Length(Paths)=0)then exit;
 v:=NSView(View);
 //The mouse event that is dragging
 ev:=NSApp.currentEvent;
 if ev=nil then exit;
 if DragSource=nil then DragSource:=TDIMDragSource.alloc.init;
 //Where the mouse is, in the view
 pt:=v.convertPoint_fromView(ev.locationInWindow,nil);
 items:=NSMutableArray.alloc.init;
 for i:=0 to High(Paths) do
 begin
  path:=NSString.stringWithUTF8String(PChar(Paths[i]));
  url :=NSURL.fileURLWithPath(path);
  item:=NSDraggingItem.alloc.initWithPasteboardWriter(NSPasteboardWritingProtocol(url));
  //Show the Finder's icon for it under the mouse
  icon:=NSWorkspace.sharedWorkspace.iconForFile(path);
  item.setDraggingFrame_contents(NSMakeRect(pt.x-16+i*4,pt.y-16+i*4,32,32),icon);
  items.addObject(item);
  item.release;
 end;
 v.beginDraggingSessionWithItems_event_source(items,ev,DragSource);
 items.release;
 Result:=True;
end;
{$ELSE}
{$IFDEF WINDOWS}
uses
 Windows, ActiveX, ShlObj;

const
 //From winerror.h
 DRAGDROP_S_DROP              = HResult($00040100);
 DRAGDROP_S_CANCEL            = HResult($00040101);
 DRAGDROP_S_USEDEFAULTCURSORS = HResult($00040102);
 LeftButton                   = $0001; //MK_LBUTTON

type
 //The source of the drag - says when to drop or cancel
 TDIMDropSource = class(TInterfacedObject, IDropSource)
  function QueryContinueDrag(fEscapePressed: BOOL; grfKeyState: DWORD): HResult; stdcall;
  function GiveFeedback(dwEffect: DWORD): HResult; stdcall;
 end;

function TDIMDropSource.QueryContinueDrag(fEscapePressed: BOOL; grfKeyState: DWORD): HResult; stdcall;
begin
 if fEscapePressed then
  Result:=DRAGDROP_S_CANCEL
 else
  if(grfKeyState and LeftButton)=0 then
   Result:=DRAGDROP_S_DROP //Mouse button let go
  else
   Result:=S_OK;
end;

function TDIMDropSource.GiveFeedback(dwEffect: DWORD): HResult; stdcall;
begin
 Result:=DRAGDROP_S_USEDEFAULTCURSORS;
end;

function DragButtonDown: Boolean;
begin
 //The primary button, which is the right one if they have been swapped
 if GetSystemMetrics(SM_SWAPBUTTON)<>0 then
  Result:=(GetAsyncKeyState(VK_RBUTTON) and $8000)<>0
 else
  Result:=(GetAsyncKeyState(VK_LBUTTON) and $8000)<>0;
end;

function StartFileDragOut(View: PtrUInt; const Paths: array of String): Boolean;
var
 desktop,
 folder    : IShellFolder;
 pidlFolder: PItemIDList;
 pidls     : array of PItemIDList;
 eaten,
 attr      : ULONG;
 data      : IDataObject;
 src       : IDropSource;
 effect    : DWORD;
 ws        : WideString;
 i         : Integer;
begin
 Result:=False;
 if Length(Paths)=0 then exit;
 OleInitialize(nil);
 if Failed(SHGetDesktopFolder(desktop)) then exit;
 //The folder they are all in
 ws:=UTF8Decode(ExcludeTrailingPathDelimiter(ExtractFilePath(Paths[0])));
 attr:=0;
 pidlFolder:=nil;
 if Failed(desktop.ParseDisplayName(0,nil,PWideChar(ws),eaten,pidlFolder,attr)) then exit;
 try
  if Failed(desktop.BindToObject(pidlFolder,nil,IShellFolder,folder)) then exit;
  //And each of the files/directories in it
  SetLength(pidls,0);
  for i:=0 to High(Paths) do
  begin
   ws:=UTF8Decode(ExtractFileName(Paths[i]));
   attr:=0;
   SetLength(pidls,Length(pidls)+1);
   pidls[High(pidls)]:=nil;
   if Failed(folder.ParseDisplayName(0,nil,PWideChar(ws),eaten,pidls[High(pidls)],attr)) then
    SetLength(pidls,Length(pidls)-1);
  end;
  //Ask the shell for a data object for them, and drag it
  if Length(pidls)>0 then
   if Succeeded(folder.GetUIObjectOf(HWND(View),Length(pidls),pidls[0],
                                     IID_IDataObject,nil,data)) then
   begin
    src:=TDIMDropSource.Create;
    effect:=DROPEFFECT_NONE;
    DoDragDrop(data,src,DROPEFFECT_COPY,@effect);
    Result:=True;
   end;
  for i:=0 to High(pidls) do CoTaskMemFree(pidls[i]);
 finally
  CoTaskMemFree(pidlFolder);
 end;
end;
{$ELSE}
function DragButtonDown: Boolean;
begin
 Result:=True;
end;

function StartFileDragOut(View: PtrUInt; const Paths: array of String): Boolean;
begin
 Result:=False;
end;
{$ENDIF}
{$ENDIF}

//Delete a folder and everything in it
procedure DeleteTree(const path: String);
var
 Dir: TSearchRec;
begin
 if FindFirst(IncludeTrailingPathDelimiter(path)+'*',faAnyFile or faDirectory,Dir)=0 then
 begin
  repeat
   if(Dir.Name<>'.')and(Dir.Name<>'..')then
    if(Dir.Attr and faDirectory)=faDirectory then
     DeleteTree(IncludeTrailingPathDelimiter(path)+Dir.Name)
    else
     SysUtils.DeleteFile(IncludeTrailingPathDelimiter(path)+Dir.Name);
  until FindNext(Dir)<>0;
  SysUtils.FindClose(Dir);
 end;
 RemoveDir(path);
end;

function DragOutFolder: String;
begin
 //One folder, emptied each time, so they do not pile up
 Result:=IncludeTrailingPathDelimiter(GetTempDir(False))+'DIMDragOut';
 if DirectoryExists(Result) then DeleteTree(Result);
 ForceDirectories(Result);
 Result:=IncludeTrailingPathDelimiter(Result);
end;

end.
