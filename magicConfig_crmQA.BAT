@echo off

:again
	cmd /C ant -Dcreds=crmqa magicConfig
	echo done.
    set /p runAgain=Run previous action again[y, n]?
if %runAgain%==y goto again
