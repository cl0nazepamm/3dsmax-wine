@echo off
rem run via install-max-msi.sh, which sets MAXMSI to the MSI's dos path
rem (a .bat keeps the PROPERTY="value with spaces" quoting intact; wine's msiexec mangles "PROP=value" argv quoting)
msiexec /i "%MAXMSI%" /qn /l*v "C:\3dsmax-msi.log" INSTALLDIR="C:\Program Files\Autodesk\3ds Max 2027\\" ADLM_PRODKEY=128S1 ADLM_EULA_COUNTRY=US ALLUSERS=1 REBOOT=ReallySuppress
echo msiexec exit %ERRORLEVEL%
