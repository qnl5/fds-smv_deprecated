@echo off
:: generate terrain with &GEOM
:: set option=-geom

set dem2fds=..\intel_win_64\dem2fds_win_64.exe
set dem2fds=dem2fds

%dem2fds% %option% -show -nobuffer -geom -dir %userprofile%\terrain\example1 example1.in 
%dem2fds% %option% -nobuffer -geom -dir %userprofile%\terrain\example1 example1a.in 
