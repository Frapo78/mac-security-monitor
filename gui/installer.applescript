display dialog "Install Mac Security Monitor?" buttons {"Cancel","Install"} default button "Install"

do shell script "cd ~/APPS/mac-security-monitor/installer && ./install.sh" with administrator privileges

display dialog "Installation complete!" buttons {"OK"}
