(*
   ddrescueview.lpr - main program of ddrescueview

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

program ddrescueview;

uses
  Forms, Interfaces,
  GUI in 'GUI.pas' {Form1},
  Parser in 'Parser.pas',
  Shared in 'Shared.pas',
  BlockInspector in 'BlockInspector.pas',
  About in 'About.pas' {AboutBox};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'ddrescue log viewer';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TBlockForm, BlockForm);
  Application.CreateForm(TAboutBox, AboutBox);
  Application.Run;
end.
