(*
   Parser.pas - Log file parser unit

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

unit Parser;

interface
uses Shared;

var
  log : Array of TLogEntry;
  rescueStatus : TRescueStatus;

procedure parsefile;
function OperationToText(status : Char) : String;

implementation
uses SysUtils, Classes, GUI;

// returns true if a line is empty or a comment line
function isEmptyOrCommentLine(strLine : String) : boolean;
begin
  result:=false;
  strLine:=TrimLeft(strLine);
  if Length(strLine) = 0 then result:=true;
  if Copy(strLine, 1, 1) = '#' then result:=true;
end;

// parses the currently open file (logStream) and parses its contents
// to log[] and rescueStatus
procedure parsefile;
var
  line : string;
  token : array[0..2] of string;
  i, logEntry, lineIdx, idx : Integer;
begin
  if logStream=nil then exit;
  try
    logStream.Seek(0, soFromBeginning);
    logStrings := TStringList.Create;
    logStrings.LoadFromStream(logStream);
    MainForm.AppLog.Lines.Add('Parsing log file: ' +IntToStr(logStrings.Count) + ' lines.');
  except
    on E : Exception do begin
      MainForm.AppLog.Lines.Add('Error: Cannot read log file: '+E.Message+'('+E.ClassName+')');
      exit;
    end;
  end;

  device_block_size := 512;
  rescueStatus := emptyRescueStatus;
  lineIdx := -1;
  logEntry := 0;

  try
    repeat
      inc(lineIdx);
      line:=logStrings[lineIdx];
      if isEmptyOrCommentLine(line) then begin
        // process comment info
        if pos('Command line:', line) > 0 then begin
           while true do begin
               idx := pos(' -b', line);
               if idx <> 0 then idx := idx+3 // point to start of number
               else begin
                 idx := pos(' --block-size=', line);
                 if idx <> 0 then idx := idx+14 // point to start of number
                 else break; // jump over the rest
               end;
               token[0] :=TrimLeft(Copy(line, idx, Length(line)));
               idx := pos(' ', token[0]);
               if idx <> 0 then token[0] :=Copy(token[0], 1, idx-1);
               device_block_size := StrToIntDef(token[0], 512);
               MainForm.DSClick(MainForm); // have the menu update itself
               break;
           end;
        end;
      end else begin
         // split line into maximum of 3 tokens
         line:=Trim(line);
         for i:= 0 to 2 do begin
           idx:= Pos(' ', line);
           if idx = 0 then begin
             token[i] := line;
             line := '';
           end else begin
             token[i] := Copy(line, 1, idx-1);
             line := TrimLeft(Copy(line, idx, Length(line)-idx+1));
           end;
         end;
         if (token[0] <> '') and (token[1] <> '') then begin
           if token[2] <> '' then begin // standard block line (3 components)
             if Length(log) = logEntry then SetLength(log, logEntry+256); // allocate more space
             log[logEntry].offset:=StrToInt64(token[0]);
             log[logEntry].length:=StrToInt64(token[1]);
             log[logEntry].status:=token[2][1];
             case log[logEntry].status of
               '?' : inc(rescueStatus.nontried, log[logEntry].length);
               '+' : inc(rescueStatus.rescued, log[logEntry].length);
               '*' : inc(rescueStatus.nontrimmed, log[logEntry].length);
               '/' : inc(rescueStatus.nonsplit, log[logEntry].length);
               '-' : inc(rescueStatus.bad, log[logEntry].length);
             end;
             if log[logEntry].status in ['-', '*', '/'] then inc(rescueStatus.errors, 1);
             inc(logEntry);
           end else begin // found the status line (2 components)
             if rescueStatus.pos = 0 then begin
               rescueStatus.pos:=StrToInt64(token[0]);
               rescueStatus.curOperation:=token[1][1];
               rescueStatus.strCurOperation:=OperationToText(rescueStatus.curOperation);
             end else begin
               MainForm.AppLog.Lines.Add('Parser: found more than one line with 2 tokens.');
             end;
           end;
         end;
      end;
    until lineIdx = logStrings.Count-1;
    // calculate device's size from last block's offset and length
    rescueStatus.devicesize:=log[logEntry-1].offset+log[logEntry-1].length;
    SetLength(log, logEntry); // trim array to actually needed size
  except
    on E : Exception do MainForm.AppLog.Lines.Add('Error parsing log file: '+E.Message+'('+E.ClassName+')');
  end;

  FreeAndNil(logStrings);
end;

// status strings for the status line
function OperationToText(status: char) : string;
begin
  case status of
    '?': OperationToText := 'Copying non-tried';
    '*': OperationToText := 'Trimming failed blocks';
    '/': OperationToText := 'Splitting failed blocks';
    '-': OperationToText := 'Retrying bad sectors';
    'F': OperationToText := 'Filling blocks';
    'G': OperationToText := 'Generating logfile';
    '+': OperationToText := 'Finished';
  else
    OperationToText := 'Unknown operation';
  end;
end;

end.
