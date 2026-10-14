@echo off
rem run via: wine cmd /c Z:\home\clone\3dsmax-wine\scripts\install-max-msi.bat
rem (a .bat keeps the PROPERTY="value with spaces" quoting intact; wine's msiexec mangles "PROP=value" argv quoting)
msiexec /i "Z:\home\clone\3dsmax-setup\x64\3dsmax\3dsMax.msi" /qn /l*v "C:\3dsmax-msi.log" INSTALLDIR="C:\Program Files\Autodesk\3ds Max 2027\\" ADLM_PRODKEY=128S1 ADLM_EULA_COUNTRY=US ALLUSERS=1 REBOOT=ReallySuppress
echo msiexec exit %ERRORLEVEL%
