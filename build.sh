#!/bin/sh
# shellcheck disable=2086
PARAMS="-Mobjfpc -Scghi -Cg -O1 -g -gl -l
-Fux86_64-linux/fpcsrc/packages/fcl-xml/src 
-Fux86_64-linux/lcl/nonwin32 -Fux86_64-linux/lcl/forms 
-Fux86_64-linux/fpcsrc/packages/gtk2/src/gtkext 
-Fux86_64-linux/lcl/units/x86_64-linux/gtk2 
-Fux86_64-linux/fpcsrc/packages/gtk2/src/gtk+/gtk 
-Fux86_64-linux/fpcsrc/packages/gtk2/src/glib 
-Fux86_64-linux/fpcsrc/packages/gtk2/src/gtk2x11 
-Fux86_64-linux/lcl/interfaces/gtk2 
-Fux86_64-linux/lcl/units/x86_64-linux/gtk2 
-Fux86_64-linux/fpcsrc/packages/chm/src 
-Fux86_64-linux/fpcsrc/packages/fcl-process/src 
-Fux86_64-linux/lcl/widgetset 
-Fux86_64-linux/fpcsrc/packages/rtl-objpas/src/common 
-Fux86_64-linux/fpcsrc/packages/pasjpeg/src 
-Fux86_64-linux/fpcsrc/packages/paszlib/src 
-Fux86_64-linux/fpcsrc/packages/fcl-image/src 
-Fux86_64-linux/fpcsrc/packages/rtl-objpas/src/inc 
-Fux86_64-linux/lazutils 
-Fux86_64-linux/fpcsrc/packages/fcl-base/src 
-Fux86_64-linux/lcl
-Fix86_64-linux/lcl/include
-Fix86_64-linux/fpcsrc/packages/fcl-process/src/unix 
-Fix86_64-linux/fpcsrc/packages/rtl-objpas/src/inc 
-v"

fpc $PARAMS source/ddrescueview.lpr

strip --strip-debug source/ddrescueview
strip --strip-unneeded source/ddrescueview
