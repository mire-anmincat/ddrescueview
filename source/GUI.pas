(*
   GUI.pas - Main GUI unit

   Copyright (C) 2013 Martin Bittermann (martinbittermann@gmx.de)

   This file is part of ddrescueview.

   ddrescueview is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   ddrescueview is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with ddrescueview.  If not, see <http://www.gnu.org/licenses/>.
*)

unit GUI;

interface

uses
  SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ExtCtrls, ComCtrls, StdCtrls, Shared, Parser;

type
  TDwordArray = array[0..32767] of DWORD;
  PDWordArray = ^TDwordArray;

  { TMainForm }
  TMainForm = class(TForm)
    BICheckBox: TCheckBox;
    DevSectSize: TMenuItem;
    DS512: TMenuItem;
    DS2048: TMenuItem;
    DSCustom: TMenuItem;
    DS4096: TMenuItem;
    PieImage: TImage;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Openlogfile1: TMenuItem;
    Exit1: TMenuItem;
    BlockImage: TImage;
    OpenDialog1: TOpenDialog;
    StatusBar1: TStatusBar;
    AppLog: TMemo;
    Closefile1: TMenuItem;
    Options1: TMenuItem;
    Parse1: TMenuItem;
    Automatc1: TMenuItem;
    N5sec1: TMenuItem;
    N10sec1: TMenuItem;
    N30sec1: TMenuItem;
    N1min1: TMenuItem;
    off1: TMenuItem;
    N2mins1: TMenuItem;
    N5mins1: TMenuItem;
    updateTimer: TTimer;
    GridPanel: TPanel;
    BlockInfo: TGroupBox;
    ShapeFinished: TShape;
    ShapeNonTried: TShape;
    ShapeBad: TShape;
    ShapeNonSplit: TShape;
    ShapeNonTrimmed: TShape;
    lblRescued: TLabel;
    lblNonTried: TLabel;
    lblBad: TLabel;
    lblNonSplit: TLabel;
    lblNonTrimmed: TLabel;
    ShapeActive: TShape;
    lblActive: TLabel;
    Prefixes1: TMenuItem;
    BinaryKiBMiB1: TMenuItem;
    DecimalKBMB1: TMenuItem;
    Extras1: TMenuItem;
    About1: TMenuItem;
    Gridsize1: TMenuItem;
    N4px1: TMenuItem;
    N6px1: TMenuItem;
    N8px1: TMenuItem;
    N10px1: TMenuItem;
    N12px1: TMenuItem;
    N14px1: TMenuItem;
    N16px1: TMenuItem;
    N20px1: TMenuItem;
    N24px1: TMenuItem;
    posLabel: TLabel;
    lblBlockPos: TLabel;
    SaveDialog1: TSaveDialog;
    Clearlog1: TMenuItem;
    ApplicationEvents1: TApplicationProperties;
    procedure BICheckBoxChange(Sender: TObject);
    procedure BlockImageMouseDown(Sender: TObject; {%H-}Button: TMouseButton;
      {%H-}Shift: TShiftState; X, Y: Integer);
    procedure DSClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
    procedure updateStatusTexts;
    procedure imgResize;
    procedure buildBlocks;
    procedure drawBlocks;
    procedure DisplayBlockInfo(block : integer);
    procedure FormResize(Sender: TObject);
    procedure OpenFile(filename : String);
    procedure Openlogfile1Click(Sender: TObject);
    procedure Closelogfile(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure Parse1Click(Sender: TObject);
    procedure autoParseClick(Sender: TObject);
    procedure UnitFormatClick(Sender: TObject);
    procedure setGridSize(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure Clearlog1Click(Sender: TObject);
    function getImgBlockFrameRect(imgBlock : integer):TRect;
    function getImgBlockRect(imgBlock : integer):TRect;
    function ColorizeBlockMask(mask: Longint) : Longint;
    procedure ApplicationEvents1ShowHint(var HintStr: String; var {%H-}CanShow: Boolean; var HintInfo: THintInfo);
    function BlockStatusToMask(status: char) : Longword;
  private
    { Private declarations }
  public
    { Public declarations }
    function GridXYToBlock(X, Y : integer) : integer;
  end;


const
      // block type masks for each block flag.
      // The upper 8 bits of each block contain these flags,
      // the lower 24 bits contain the color used for display.
      // The color is blended together from the flags in the upper 8 bits
      // by ColorizeBlockMask
      MASK_NON_TRIED = $01000000;
      MASK_NON_TRIMMED = $02000000;
      MASK_NON_SPLIT = $04000000;
      MASK_BAD_SECT = $08000000;
      MASK_FINISHED = $10000000;
      MASK_ALL_STATUSES = $1F000000;
      MASK_ACTIVE = $20000000;
      // color constants for the block statuses
      COLOR_NON_TRIED = $404040;
      COLOR_NON_TRIMMED = $00e0ff;
      COLOR_NON_SPLIT = $ff2020;
      COLOR_BAD_SECT = $0000ff;
      COLOR_FINISHED = $20e020;
      COLOR_UNDEFINED = clGray;
      COLOR_ACTIVE = $ffff00;
      // color weights to be used by ColorizeBlockMask for blending
      WEIGHT_NON_TRIED = 1;
      WEIGHT_FINISHED = 2;
      WEIGHT_NON_TRIMMED = 4;
      WEIGHT_NON_SPLIT = 10;
      WEIGHT_BAD_SECT = 40;
      // color primary masks
      MASK_B = $ff0000;
      MASK_G = $00ff00;
      MASK_R = $0000ff;
      // arrays containing the above constants for easier looping
      MASKS : array[0..4] of longint =
        (MASK_NON_TRIED, MASK_FINISHED, MASK_NON_TRIMMED, MASK_NON_SPLIT, MASK_BAD_SECT);
      COLORS : array[0..4] of longint =
        (COLOR_NON_TRIED, COLOR_FINISHED, COLOR_NON_TRIMMED, COLOR_NON_SPLIT, COLOR_BAD_SECT);
      WEIGHTS : array[0..4] of longint =
        (WEIGHT_NON_TRIED, WEIGHT_FINISHED, WEIGHT_NON_TRIMMED, WEIGHT_NON_SPLIT, WEIGHT_BAD_SECT);
      PROGRAM_TITLE = 'ddrescue log viewer';

var
  MainForm: TMainForm;
  logStream: TStream;
  device_block_size : integer; // 2048 for optical media, 512 for everything else
  logStrings: TStringList;
  imgBlocks: Array of Longword; // lower 24 bits : color, upper 8 bits: status mask
  bytesPerBlock : int64;
  hblocks, vblocks : integer;
  gridSize : integer = 8;




implementation
uses Math, BlockInspector, About;
{$R *.lfm}

// initialization on program start
procedure TMainForm.FormCreate(Sender: TObject);
begin
  DoubleBuffered:=true;
  GridPanel.DoubleBuffered:=true;
  AppLog.DoubleBuffered:=true;
  ShapeFinished.Brush.Color:=COLOR_FINISHED;
  ShapeNonTried.Brush.Color:=COLOR_NON_TRIED;
  ShapeBad.Brush.Color:=COLOR_BAD_SECT;
  ShapeNonSplit.Brush.Color:=COLOR_NON_SPLIT;
  ShapeNonTrimmed.Brush.Color:=COLOR_NON_TRIMMED;
  ShapeActive.Pen.Color:=COLOR_ACTIVE;
  
  device_block_size := 512;

  PieImage.Picture.Bitmap.Width:=PieImage.Width;
  PieImage.Picture.Bitmap.Height:=PieImage.Height;
  PieImage.Picture.Bitmap.PixelFormat:=pf32Bit;

  imgResize;
  buildBlocks;
  drawBlocks;
  updateStatusTexts;

  // open file specified in command line
  if (ParamCount > 0) then OpenFile(ParamStr(1));
end;

procedure TMainForm.FormDropFiles(Sender: TObject;
  const FileNames: array of String);
begin
  OpenFile(FileNames[0]);
end;


// fits the image into the form, makes sure it's width and height are always (x*gridSize)+1
procedure TMainForm.imgResize;
const GridPanelBorder = 4;
begin
  BlockImage.Width:=GridPanel.Width - GridPanelBorder - ((GridPanel.Width - GridPanelBorder-1) mod gridSize);
  BlockImage.Height:=GridPanel.Height - GridPanelBorder - ((GridPanel.Height - GridPanelBorder-1) mod gridSize);
  BlockImage.Picture.Bitmap.SetSize(BlockImage.Width, BlockImage.Height);
  BlockImage.Picture.Bitmap.PixelFormat:=pf32bit;
  hblocks := BlockImage.Width div gridSize;  // number of horizontal blocks in display
  vblocks := BlockImage.Height div gridSize; // same for vertical
  if BlockForm <> nil then BlockForm.Block:=0; // reset Block to 0, makes no sense to keep block # on resize
end;

procedure TMainForm.updateStatusTexts;
begin
  if Length(log) > 0 then begin
    StatusBar1.Panels.Items[0].Text:=OperationToText(rescueStatus.curOperation);
    StatusBar1.Hint:='Rescued: '+ IntToStr(rescueStatus.rescued) + ' Byte';
    StatusBar1.Panels.Items[1].Text:='Input size: '+ SizeStr(rescueStatus.devicesize);
    StatusBar1.Panels.Items[2].Text:='Position: ' + SizeStr(rescueStatus.pos);
    StatusBar1.Panels.Items[3].Text:='Rescued: '+ SizeStr(rescueStatus.rescued);
    StatusBar1.Panels.Items[4].Text:='Error size: '+ SizeStr(rescueStatus.bad + rescueStatus.nonsplit + rescueStatus.nontrimmed);
  end else begin
    StatusBar1.Panels.Items[0].Text:='No file loaded';
    StatusBar1.Panels.Items[1].Text:='';
    StatusBar1.Panels.Items[2].Text:='';
    StatusBar1.Panels.Items[3].Text:='';
    StatusBar1.Panels.Items[4].Text:='';
  end;
end;

// constructs a TRect containing the requested Image Block
function TMainForm.getImgBlockRect(imgBlock : integer):TRect;
var hblock, vblock: integer;
begin
   vblock := imgBlock div hblocks;
   hblock := imgBlock mod hblocks;
   result.Left:=1+hblock*gridSize;
   result.Top:=1+vblock*gridSize;
   result.Right:=result.Left+gridSize-1;
   result.Bottom:=result.Top+gridSize-1;
end;

// constructs a TRect containing the requested Image Block, including border
function TMainForm.getImgBlockFrameRect(imgBlock : integer):TRect;
begin
   result:=getImgBlockRect(imgBlock);
   result.Left:=result.Left-1;
   result.Top:=result.Top-1;
   result.Right:=result.Right+1;
   result.Bottom:=result.Bottom+1;
end;

procedure TMainForm.drawBlocks;
var imgBlock :integer;
    blockRect : TRect;
    angle, alength: extended;
begin
  BlockImage.Canvas.Brush.Color := COLOR_UNDEFINED;
  BlockImage.Canvas.FillRect(Rect(0, 0, BlockImage.Width, BlockImage.Height));
  for imgBlock := 0 to Length(imgBlocks)-1 do begin
    BlockImage.Canvas.Brush.Color:=imgBlocks[imgBlock] and $ffffff; //extract color
    if LongBool(imgBlocks[imgBlock] and MASK_ACTIVE) then begin
      blockRect:=getImgBlockFrameRect(imgBlock);
      BlockImage.Canvas.Pen.Color := COLOR_ACTIVE;
      BlockImage.Canvas.Rectangle(blockRect);
    end else begin
      blockRect:=getImgBlockRect(imgBlock);
      BlockImage.Canvas.FillRect(blockRect);
    end;
  end;

  // Build Pie image
  // todo: make own procedure
  blockRect:=Rect(0, 0, PieImage.Width, PieImage.Height);
  PieImage.Canvas.Brush.Color := clBtnFace;
  PieImage.Canvas.FillRect(blockRect);
  if rescueStatus.devicesize > 0 then begin
    PieImage.Canvas.Brush.Color := COLOR_FINISHED;
    alength:=5760*rescueStatus.rescued/rescueStatus.devicesize;
    PieImage.Canvas.RadialPie(1, 1, 63, 63, 0, round(alength));
    angle:=alength;

    PieImage.Canvas.Brush.Color := COLOR_NON_TRIED;
    alength:=5760*rescueStatus.nontried/rescueStatus.devicesize;
    PieImage.Canvas.RadialPie(1, 1, 63, 63, round(angle), round(alength));
    angle:=angle+alength;

    PieImage.Canvas.Brush.Color := COLOR_BAD_SECT;
    alength:=5760*rescueStatus.bad/rescueStatus.devicesize;
    PieImage.Canvas.RadialPie(1, 1, 63, 63, round(angle), round(alength));
    angle:=angle+alength;

    PieImage.Canvas.Brush.Color := COLOR_NON_SPLIT;
    alength:=5760*rescueStatus.nonsplit/rescueStatus.devicesize;
    PieImage.Canvas.RadialPie(1, 1, 63, 63, round(angle), round(alength));
    angle:=angle+alength;

    PieImage.Canvas.Brush.Color := COLOR_NON_TRIMMED;
    alength:=5760*rescueStatus.nontrimmed/rescueStatus.devicesize;
    PieImage.Canvas.RadialPie(1, 1, 63, 63, round(angle), round(alength));
  end;
end;

// Calculate image blocks from log for fast drawing.
// Blocks will be stored in the imgBlocks[] array.
// Blocks contain type information and a color derived from the mix of types.
// Each block spans a multiple of the device block size.
// This can lead to some unused blocks at the end of the grid.
procedure TMainForm.buildBlocks;
var logLen, logBlock, imgBlock, imgStartBlock, imgEndBlock: integer;
begin
  logLen := Length(log);
  SetLength(imgBlocks, hblocks*vblocks);
  if logLen = 0 then begin // empty log, gray out all blocks and exit
    for imgBlock := 0 to Length(imgBlocks)-1 do begin
      imgBlocks[imgBlock]:=COLOR_NON_TRIED;
    end;
    exit;
  end else begin // nonempty log, black out all blocks
    for imgBlock := 0 to Length(imgBlocks)-1 do begin
      imgBlocks[imgBlock]:=clBlack;
    end;
  end;

  // calculate the number of bytes per image block
  bytesPerBlock := ceil(rescueStatus.deviceSize / (hblocks*vblocks) / device_block_size) * int64(device_block_size);

  // go through log and collect block info
  for logBlock := 0 to logLen-1 do begin
    imgStartBlock := log[logBlock].offset div bytesPerBlock;
    imgEndBlock := (log[logBlock].offset+log[logBlock].length-1) div bytesPerBlock;
    for imgBlock := imgStartBlock to imgEndBlock do begin
      imgBlocks[imgBlock]:=imgBlocks[imgBlock] or BlockStatusToMask(log[logBlock].status);
    end;
  end;

  // mark active block, i.e. block of current input read position
  imgBlock := rescueStatus.pos div bytesPerBlock;
  imgBlocks[imgBlock]:=imgBlocks[imgBlock] or MASK_ACTIVE;

  // go through blocks and build colors
  for imgBlock := 0 to Length(imgBlocks)-1 do begin
    imgBlocks[imgBlock]:=ColorizeBlockMask(imgBlocks[imgBlock]);
  end;
end;

// returns a bit mask for each known block type
function TMainForm.BlockStatusToMask(status: char) : Longword;
begin
  case status of
    '?': result := MASK_NON_TRIED;
    '*': result := MASK_NON_TRIMMED;
    '/': result := MASK_NON_SPLIT;
    '-': result := MASK_BAD_SECT;
    '+': result := MASK_FINISHED;
  else
    result := 0;
    AppLog.Lines.Add('Error: Mask request for unknown block status: ' + status);
  end;
end;

// computes a color for a block, depending on whick block types exist in
// this block. The percentage of sectors of a specific block type does not matter.
// The weight of a color (block type) is determined by the following order:
// (least) non-tried, finished, non-trimmed, non-split, bad (highest)
// Each of these types influences the block color depending in its weight.
// This way, blocks of bad status are easy to notice over good ones.
function TMainForm.ColorizeBlockMask(mask: Longint) : Longint;
var i, b, g, r, colorcount : Integer;
begin
  b:=0; g:=0; r:=0; colorcount:=0;
  if not LongBool(mask and MASK_ALL_STATUSES) then begin
    result := mask or COLOR_UNDEFINED;
    exit;
  end;
  for i:= 0 to Length(MASKS)-1 do begin
    if LongBool(mask and MASKS[i]) then begin
    b := b + WEIGHTS[i]*((COLORS[i] and MASK_B) shr 16);
    g := g + WEIGHTS[i]*((COLORS[i] and MASK_G) shr 8);
    r := r + WEIGHTS[i]*(COLORS[i] and MASK_R);
    inc(colorcount, WEIGHTS[i]);
  end;
  end;
  b := b div colorcount;
  g := g div colorcount;
  r := r div colorcount;
  result := mask or (b shl 16) or (g shl 8) or r;
end;

procedure TMainForm.DisplayBlockInfo(block : integer);
var mask: Longint;
begin
  mask := imgBlocks[block];
  lblNonTried.Enabled:=LongBool(mask and MASK_NON_TRIED);
  lblNonTrimmed.Enabled:=LongBool(mask and MASK_NON_TRIMMED);
  lblNonSplit.Enabled:=LongBool(mask and MASK_NON_SPLIT);
  lblBad.Enabled:=LongBool(mask and MASK_BAD_SECT);
  lblRescued.Enabled:=LongBool(mask and MASK_FINISHED);
  lblActive.Enabled:=LongBool(mask and MASK_ACTIVE);

  lblBlockPos.Caption:=SizeStr(block*bytesPerBlock) + ' - '
    + SizeStr(min(rescueStatus.deviceSize, (int64(block)+1)*bytesPerBlock));

  // Block Inpector initialization
  if BICheckBox.Checked and (BlockForm <> nil) then begin
    BlockForm.Block:=block;
    if not BlockForm.Visible then BlockForm.Show;
  end;
end;


procedure TMainForm.FormResize(Sender: TObject);
var WidthBefore, HeightBefore : integer;
begin
  WidthBefore := BlockImage.Width;
  HeightBefore := BlockImage.Height;
  imgResize;
  if (WidthBefore <> BlockImage.Width) or (HeightBefore <> BlockImage.Height) then begin
    buildBlocks;
    drawBlocks;
    if BlockForm <> nil then BlockForm.DoUpdate(true); // previous block will contain different sectors
  end;
end;

procedure TMainForm.BICheckBoxChange(Sender: TObject);
begin
  if (not BICheckBox.Checked) then BlockForm.Hide;
end;

procedure TMainForm.OpenFile(filename : String);
begin
  try
    Closelogfile(self); // close already open file
    // open the log file using shared read access. ddrescue can still write to it ;-)
    logStream := TFileStream.Create(filename, fmOpenRead or fmShareDenyNone);
    MainForm.Caption := PROGRAM_TITLE + ' [' + Copy(filename, LastDelimiter('\/:', filename)+1, 128) + ']';
    imgResize; // sometimes needed for block adjustment on first file
    Parse1Click(self);  // start parsing after opening
  except
    on E: Exception do MessageDlg(E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TMainForm.Openlogfile1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then OpenFile(OpenDialog1.FileName);
end;

procedure TMainForm.Closelogfile(Sender: TObject);
begin
  if logStream<>nil then begin // takes no effect if no file is open
    FreeAndNil(logStream); // closes the file handle
    BlockForm.Hide;
    Setlength(log, 0);   // set the dynamic array containing the parsed log to zero-length
    buildBlocks;   // builds the blocks, i.e. empty gray grid
    drawBlocks;    // draws all the gray blocks
    updateStatusTexts;
    MainForm.Caption := PROGRAM_TITLE;
  end; 
end;

// user clicked exit from the menu
procedure TMainForm.Exit1Click(Sender: TObject);
begin
   Closelogfile(self);
   Application.Terminate;
end;

// log parsing requested, either from the menu or programmatically
procedure TMainForm.Parse1Click(Sender: TObject);
begin
  Parser.parsefile;
  updateStatusTexts;
  buildBlocks;
  drawBlocks;
  if BlockForm <> nil then BlockForm.DoUpdate(false);
end;

// maps a X,Y pixel location on the block image to a block number
function TMainForm.GridXYToBlock(X, Y : integer) : integer;
begin
  result := (Y div gridSize)*hblocks + X div gridSize;
end;


// user clicked the Block Grid
procedure TMainForm.BlockImageMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var imgBlock: integer;
begin
  if (X mod gridSize = 0) or (Y mod gridSize = 0) then exit; // user clicked gridlines
  if Length(log) = 0 then exit;  // empty log, no file opened
  imgBlock := GridXYToBlock(X, Y); // calculate clicked block
  DisplayBlockInfo(imgBlock);
end;

// user selected a device sector size from the menu
procedure TMainForm.DSClick(Sender: TObject);
var strSize : string;
    itemID : integer;
begin
  DSCustom.Checked:=true; // initially select the custom entry

  // determine the size from the clicked item
  if Sender is TMenuItem then begin
    TMenuItem(Sender).Checked:=true;
    if Sender = DSCustom then begin
      strSize := InputBox('Custom sector size', 'Enter custom sector size in Bytes:',
        inttostr(device_block_size));
      device_block_size := strToIntDef(strSize, 512);
      if device_block_size < 1 then device_block_size := 512;
    end else device_block_size:=TMenuItem(Sender).Tag; // size is stored in .Tag
  end;

  // depending on the size, determine which item has to be selected
  for itemID := 0 to DevSectSize.Count-1 do begin
    if DevSectSize.Items[itemID].Tag = device_block_size then begin
      DevSectSize.Items[itemID].Checked:=true;
      break;
    end;
  end;
  if DSCustom.Checked then DSCustom.Caption :=
    'Custom ('+inttostr(device_block_size) + ') ...'
    else DSCustom.Caption := 'Custom...';

  if Sender is TMenuItem then begin
    buildBlocks;
    drawBlocks;
    BlockForm.DoUpdate(true); // previous block may contain different sectors
  end;
end;

// user selected an automatic parse time interval from the menu
procedure TMainForm.autoParseClick(Sender: TObject);
var interval : integer;
begin
  Parse1Click(self);
  if Sender is TMenuItem then begin
    TMenuItem(Sender).Checked := true;
    interval := TMenuItem(Sender).Tag * 1000;
    updateTimer.Enabled := interval <> 0;
    updateTimer.Interval := interval;
  end;
end;

// user selected a unit system from the menu
procedure TMainForm.UnitFormatClick(Sender: TObject);
begin
  if Sender is TMenuItem then TMenuItem(Sender).Checked := true;
  useDecimalUnits := DecimalKBMB1.Checked;
  updateStatusTexts;
  if BlockForm.Visible then BlockForm.DoUpdate(false);
end;

// user selected a grid size from the menu
procedure TMainForm.setGridSize(Sender: TObject);
begin
  if Sender is TMenuItem then begin
    TMenuItem(Sender).Checked := true;
    gridSize:=TMenuItem(Sender).Tag; // size stored in tag field
  end;
  imgResize;
  buildBlocks;
  drawBlocks;
  if BlockForm.Visible then BlockForm.Block:=0;
end;

// shows the about box
procedure TMainForm.About1Click(Sender: TObject);
begin
  AboutBox.Version.Caption := 'Version ' + VERSION_MAJOR + '.' + VERSION_MINOR;
  AboutBox.ShowModal;
end;

// clears the log
procedure TMainForm.Clearlog1Click(Sender: TObject);
begin
  AppLog.Lines.Clear;
end;

// modify mouse-over Hint time on a string length basis
procedure TMainForm.ApplicationEvents1ShowHint(var HintStr: String; var CanShow: Boolean; var HintInfo: THintInfo);
begin
  HintInfo.HideTimeout:=2000+Length(HintStr)*100;
end;

end.
