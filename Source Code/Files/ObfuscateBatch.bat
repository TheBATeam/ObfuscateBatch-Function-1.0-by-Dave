:: ObfuscateBatch.bat  [/M]  SourceFile  [OutputFile]
::
::  Create obfuscated batch file OutputFile from SourceFile.
::
::  Note - This script requires JREPL.BAT v6.7 or higher.
::
::  If OutputFile is undefined, then the output file is named the same as
::  the base name of SourceFile, with _obfuscated appended, and the extension
::  is preserved.
::
::  For example:
::
::    obfuscate MyFile.cmd
::  
::  creates:
::
::    MyFile_obfuscated.cmd
::
::  There are two steps to the obfuscation:
::
::    Step 1)
::
::      - Text of the form {:Preserved} is preserved
::      - Text of the form {ROT13ObfuscatedText} has the ROT13 cipher applied
::        to alpha characters A-Z and a-z
::      - All other text is preserved
::
::    Step 2)       
::
::      - Text of the form {:Preserved} is preserved
::      - Text of the form {<Preserved} is preserved
::      - Labels :label are preserved
::      - Escaped percents %% are preserved
::      - "All arguments" %* is preserved
::      - Numbered arguments like %2 are preserved (including modifiers)
::      - All remaining lone percents % are preserved
::      - All remaining characters between \x20-\x7E are encoded as %HiByte%,
::        where HiByte represents an extended ASCII character between \xA1-\xFF
::
::    If the /M option is in effect, then text between { and }, or {: and },
::    or {< and } can span multiple lines.
::
::  The source file should consist of pure ASCII - no extended ASCII allowed.
::
::  For optimal obfuscation, the source code should adhere to these rules:
::
::    - Labels should be enclosed in braces:
::        :{Label}
::        goto {Label}
::        call :{Label}
::
::    - User defined variable names should be enclosed in braces:
::        set "{VarName}=value"
::        echo %{VarName}% or %{VarName}:find=replace%  etc.
::        echo !{VarName}! or !{VarName}:find=replace!  etc.
::
::    - Standard "variable" names like %comspec%, %random%, etc. should NOT be
::      enclosed in braces. Such variables will not be obfuscated. If possible,
::      use delayed  expansion instead. For eample - !comspec!, !random!, etc.
::      Variable names within delayed expansion are obfuscated.
::
::    - Text that should remain human readable within the resultant code should
::      be enclosed in {: }
::        {:This text is not obfuscated}
::
::    - Text that should have the ROT13 cipher applied, but not encoded as
::      %HiByte%, should be enclosed in {< }
::        {< This text has the ROT13 cipher applied only }
::
::    - Comments of the form %=Comment=% should be enclosed within braces
::        %={ ROT13 will be applied to this comment }=%
::
::    - Remember to use /M if text between braces spans multiple lines
::
::  When the obfuscated code is run, the current code page is stored, and the
::  code executes within a child cmd.exe process using code page 708. Any
::  command line arguments are passed without changes as long as all poison
::  characters are quoted. The use of escaped poison characters on the command
::  line is complicated and therefore discouraged.
::
::  Upon termination, the code page is restored to the original value and the
::  original environment is restored.
::
::  The use of code page 708 is somewhat arbitrary, except it is critical that
::  there not exist any extended ASCII character pairs that are recognized by
::  cmd.exe as upper/lower case pairs. Code page 708 happens to be the first
::  encoding I tested that passes this test.
::
::  ObfuscateBatch.bat v1.0 was written by Dave Benham and originally posted at
::  http://www.dostips.com/forum/viewtopic.php?f=3&t=7990&start=15#p53278

@echo off
setlocal disableDelayedExpansion
if /i "%~1" equ "/m" set "/m=/m" & shift /1
set "in=%~1"
if not defined in echo Error: Missing inputFile>&2&exit /b
set "out=%~2"
if not defined out set "out=%~dpn1_obfuscated%~x1"
set "find={[:<][^}]*}|^[^:\r\n]?[ \t=,;\xFF]*:[^ \t:\r\n+]*[ \t:\r\n+]?|%%%%|%%\*|%%(?:~[fdpnxsatz]*(?:\$[^:\r\n]+:)?)?[0-9]|%%[^%%\r\n]+%%|%%@[\x20-\x24\x26-\x7E]"
set "repl=$txt=$0@$txt='%%'+String.fromCharCode($0.charCodeAt(0)+129)+'%%'"

setlocal enableDelayedExpansion
set "str1="
set "x=x"
for %%A in (2 3 4 5 6 7) do @for %%B in (0 1 2 3 4 5 6 7 8 9 A B C D E F) do set "str1=!str1!\x%%A%%B"
set "str1=%str1:~0,-4%"
set "str1=%str1:\x22=%\x22"
set "str1=%str1:\x24\x25=DDDD%"
call jrepl x str1 /m /x /v /s x /rtn lo
set "lo=!lo:DDDD=$!"

set "str2="
for %%A in (A B C D E F) do @for %%B in (0 1 2 3 4 5 6 7 8 9 A B C D E F) do set "str2=!str2!\x%%A%%B"
set "str2=%str2:~4%"
set "str2=%str2:\xA3=%\xA3"
set "str2=%str2:\xA6=%"
call jrepl x str2 /m /x /v /s x /rtn hi

call :write <"!in!" >"!out!"
exit /b

:write
echo @echo off^&(if defined @lo@ goto !hi:~0,1!)^&setlocal disableDelayedExpansion^&for /f "delims=: tokens=2" %%%%A in ('chcp') do set "@chcp@=chcp %%%%A>nul"^&chcp 708^>nul^&set ^^^^"@args@=%%*"
echo set "@lo@=!lo!"
echo set "@hi@=!hi!"
echo (setlocal enableDelayedExpansion^&for /l %%%%N in (0 1 93) do set "^!@hi@:~%%%%N,1^!=^!@lo@:~%%%%N,1^!")^&cmd /c ^^^^^""%%~f0" ^^!@args@^^!"
echo %%@chcp@%%^&exit /b
echo :!hi:~0,1!
jrepl "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"^
      "nopqrstuvwxyzabcdefghijklmNOPQRSTUVWXYZABCDEFGHIJKLM"^
      %/m% /t "" /p "{[^:}][^}]*}" | jrepl find repl %/m% /t @ /v /x /jq
exit /b