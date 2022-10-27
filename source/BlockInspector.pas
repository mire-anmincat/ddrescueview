unit BlockInspector;

{$mode delphi}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Grids, Spin, ExtCtrls;

type

  { TBlockForm }

  TBlockForm = class(TForm)
    BlockEdit: TSpinEdit;
    posLabel: TLabel;
    Panel2: TPanel;
    TrackActiveCheckBox: TCheckBox;
    CloseBIButton: TButton;
    BlockHeadline: TLabel;
    BlockGrid: TStringGrid;
    procedure BlockEditChange(Sender: TObject);
    procedure CloseBIButtonClick(Sender: TObject);
  private
    { private declarations }
    FBlock : integer;
    procedure SetBlock(block : integer);
  public
    { public declarations }
    property Block : integer read FBlock write SetBlock;
    procedure DoUpdate(clearSel : boolean);
  end; 

var
  BlockForm: TBlockForm;

implementation
uses Shared, Parser, GUI, Math;

{$R *.lfm}

{ TBlockForm }

function activeBlock : integer;
begin
  result:= rescueStatus.pos div bytesPerBlock;
end;

procedure TBlockForm.SetBlock(block : integer);
begin
  if block <> FBlock then begin
    FBlock := min(block, Length(imgBlocks)-1);
    if FBlock <> activeBlock then TrackActiveCheckBox.Checked:=false;
    DoUpdate(true);
  end;
end;

// updates the Block Inspector window. If the TrackActiveCheckBox is checked,
// it will change FBlock accordingly and display the active block instead.
// Uncheck it before calling Update if this is not desired.
procedure TBlockForm.DoUpdate(clearSel : boolean);
var imgStartBlock, imgEndBlock, logBlock, logLen, entries : integer;
begin
  if TrackActiveCheckBox.Checked then FBlock := activeBlock;

  BlockEdit.MaxValue:=Length(ImgBlocks)-1;
  BlockEdit.Value:=FBlock;

  logLen := length(log);

  if logLen = 0 then begin // no file opened
    BlockGrid.RowCount:=1; // clear BlockGrid
    Hide;  // close BI window
    exit;
  end;

  // go through log and make list entries
  entries := 0;
  for logBlock := 0 to logLen-1 do begin
    imgStartBlock := log[logBlock].offset div bytesPerBlock;
    imgEndBlock := (log[logBlock].offset+log[logBlock].length-1) div bytesPerBlock;
    if imgStartBlock > FBlock then break; // this and all following entries start after FBlock
    if (imgEndBlock >= FBlock) then begin // this entry ends in or after FBlock
      if BlockGrid.RowCount = entries+1 then BlockGrid.RowCount:=entries+2; // need more space
      BlockGrid.Cells[0, entries+1]:=BlockStatusToString(log[logBlock].status);
      if (rescueStatus.pos >= log[logBlock].offset) and
         (rescueStatus.pos < log[logBlock].offset+log[logBlock].length) then
           BlockGrid.Cells[0, entries+1]:='> '+BlockGrid.Cells[0, entries+1];
      BlockGrid.Cells[1, entries+1]:=inttostr(log[logBlock].offset)+' B ('+SizeStr(log[logBlock].offset)+')';
      BlockGrid.Cells[2, entries+1]:=inttostr(log[logBlock].length)+' B ('+SizeStr(log[logBlock].length)+')';
      inc(entries);
    end;
  end;
  BlockGrid.RowCount:=entries+1;
  if clearSel then BlockGrid.Row:=1;

  posLabel.Caption:='> Current position: '+inttostr(rescueStatus.pos)+' B ('+
    SizeStr(rescueStatus.pos)+')';
end;

procedure TBlockForm.CloseBIButtonClick(Sender: TObject);
begin
  Hide;
end;

procedure TBlockForm.BlockEditChange(Sender: TObject);
begin
  if BlockEdit.Value <> activeBlock then TrackActiveCheckBox.Checked:=false;
  SetBlock(BlockEdit.Value);
end;


end.

