@Echo off
cls

Title ObfuscateBatch 1.0 - Demo - www.thebateam.org
Set "Path=%Path%;%cd%;%cd%\files"
Color 0a

Echo. Trying to Get Demo.txt File...
Call ObfuscateBatch Demo.txt
Echo.
Echo. 
ren Demo_obfuscated.txt Demo_obfuscated.bat
Echo. A Demo_obfuscated.bat file in the same folder - Done!
Pause
exit