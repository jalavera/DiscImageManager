unit MacDragOut;

{
Dragging files and directories out of Disc Image Manager onto the Finder (or
any other app that accepts files), on macOS.

The LCL can only drag and drop within the application, so this starts a native
Cocoa drag session with the files that have already been extracted to a
temporary folder. The Finder then copies them to wherever they are dropped.

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
function StartFileDragOut(View: PtrUInt; const Paths: array of String): Boolean;
begin
 Result:=False;
end;
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
     DeleteFile(IncludeTrailingPathDelimiter(path)+Dir.Name);
  until FindNext(Dir)<>0;
  FindClose(Dir);
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
