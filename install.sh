curl -sL "https://raw.githubusercontent.com/nano-currency/nano-node-cli/main/xno.sh" -o /usr/local/bin/xno
sudo chmod +x /usr/local/bin/xno
VERSION=$(grep -E '^VERSION=' /usr/local/bin/xno | awk -F '=' '{print $2}' | tr -d '"')
echo "NANO CLI ${VERSION} is now installed."