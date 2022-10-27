(*
   Shared.pas - Shared functionality

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

unit Shared;

interface

type
  PTextFile = ^TextFile;
  TLogEntry = record
    offset : int64;
    length : int64;
    status : char;
  end;

  TRescueStatus = record
    devicesize : int64;
    pos : int64;
    rescued : int64;
    nontried : int64;
    bad : int64;
    nonsplit : int64;
    nontrimmed : int64;
    errors : int64;
    curOperation : Char;
    strCurOperation : String;
  end;

const
  VERSION_MAJOR = '0';
  VERSION_MINOR = '3';
  emptyRescueStatus : TRescueStatus =
  (devicesize : 0; pos : 0; rescued : 0; nontried : 0; bad : 0; nonsplit : 0;
   nontrimmed : 0; errors : 0; curOperation : #0; strCurOperation : '');


var useDecimalUnits : boolean = true;


function BlockStatusToString(status: char) : String;
function SizeStr(sizeInBytes : int64): String;

implementation
uses SysUtils;

function BlockStatusToString(status: char) : String;
begin
  case status of
    '?': result := 'Non-tried';
    '*': result := 'Non-trimmed';
    '/': result := 'Non-split';
    '-': result := 'Bad sector(s)';
    '+': result := 'Rescued';
  else
    result := 'Unknown status';
  end;
end;

function SizeStr(sizeInBytes : int64): String;
begin
  if useDecimalUnits then begin
     if sizeInBytes < 0 then SizeStr := 'invalid size?'
     else if sizeInBytes < 100000 then SizeStr := IntToStr(sizeInBytes)+ ' Byte'
     else if sizeInBytes < 100000000 then SizeStr := IntToStr(sizeInBytes div 1000)+ ' KB'
     else if sizeInBytes < 100000000000 then SizeStr := IntToStr(sizeInBytes div 1000000)+ ' MB'
     else if sizeInBytes < 100000000000000 then SizeStr := IntToStr(sizeInBytes div 1000000000)+ ' GB'
     else if sizeInBytes < 100000000000000000 then SizeStr := IntToStr(sizeInBytes div 1000000000000)+ ' TB'
     else SizeStr := IntToStr(sizeInBytes div 1000000000000000)+ ' PB';
  end else begin
     if sizeInBytes < 0 then SizeStr := 'invalid size?'
     else if sizeInBytes < 102400 then SizeStr := IntToStr(sizeInBytes)+ ' Byte'
     else if sizeInBytes < 104857600 then SizeStr := IntToStr(sizeInBytes div 1024)+ ' KiB'
     else if sizeInBytes < 107374182400 then SizeStr := IntToStr(sizeInBytes div 1048576)+ ' MiB'
     else if sizeInBytes < 109951162777600 then SizeStr := IntToStr(sizeInBytes div 1073741824)+ ' GiB'
     else if sizeInBytes < 112589990684262400 then SizeStr := IntToStr(sizeInBytes div 1099511627776)+ ' TiB'
     else SizeStr := IntToStr(sizeInBytes div 1125899906842624)+ ' PiB';
  end;
end;

end.
