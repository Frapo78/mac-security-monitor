set scriptPath to POSIX path of (path to me)
set guiDir to do shell script "dirname " & quoted form of scriptPath
set projectRoot to do shell script "cd " & quoted form of guiDir & " && cd .. && pwd"
set installScript to projectRoot & "/installer/install.sh"

try
	display dialog "Install Mac Security Monitor?" buttons {"Cancel", "Install"} default button "Install" with title "Mac Security Monitor"
	
	do shell script quoted form of installScript with administrator privileges
	
	display dialog "Installation complete." buttons {"OK"} default button "OK" with title "Mac Security Monitor"
on error errMsg
	display dialog "Installation failed: " & errMsg buttons {"OK"} default button "OK" with title "Mac Security Monitor"
end try
