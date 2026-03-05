#!/bin/zsh

echo "Installing Mac Security Monitor..."

BASE="$HOME/.mac-security-monitor"

mkdir -p "$BASE/bin"
mkdir -p "$BASE/baseline"
mkdir -p "$BASE/docs"

cp ../src/* "$BASE/bin/"

chmod +x "$BASE/bin/"*

cp ../docs/* "$BASE/docs/"

echo "Creating baseline..."

"$BASE/bin/maccheck" > "$BASE/baseline/current"

echo "Installing launchd service..."

cp ../launchd/com.fra.securitycheck.plist ~/Library/LaunchAgents/

launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.fra.securitycheck.plist

echo "Installing CLI commands..."

sudo ln -sf "$BASE/bin/securitycheck-status" /usr/local/bin/security-monitor

sudo tee /usr/local/bin/security-monitor-update > /dev/null <<EOF
#!/bin/zsh
$BASE/bin/maccheck > $BASE/baseline/current
security-monitor
EOF

sudo chmod +x /usr/local/bin/security-monitor-update

echo "Installation complete."
