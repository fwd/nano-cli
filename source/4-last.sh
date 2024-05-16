
# ██╗  ██╗███████╗██╗     ██████╗ 
# ██║  ██║██╔════╝██║     ██╔══██╗
# ███████║█████╗  ██║     ██████╔╝
# ██╔══██║██╔══╝  ██║     ██╔═══╝ 
# ██║  ██║███████╗███████╗██║     
# ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝     

if [[ $1 == "" ]] || [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-help" ] || [ "$1" = "-h" ]; then
    echo "$DOCS"
    exit 0
fi

# ██╗   ██╗███████╗██████╗ ███████╗██╗ ██████╗ ███╗   ██╗
# ██║   ██║██╔════╝██╔══██╗██╔════╝██║██╔═══██╗████╗  ██║
# ██║   ██║█████╗  ██████╔╝███████╗██║██║   ██║██╔██╗ ██║
# ╚██╗ ██╔╝██╔══╝  ██╔══██╗╚════██║██║██║   ██║██║╚██╗██║
#  ╚████╔╝ ███████╗██║  ██║███████║██║╚██████╔╝██║ ╚████║
#   ╚═══╝  ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝                                      

if [[ "$1" = "v" ]] || [[ "$1" = "-v" ]] || [[ "$1" = "--version" ]] || [[ "$1" = "version" ]]; then

    if [[ $(cat $DIR/.xno/node 2>/dev/null) == "" ]]; then
         NODE_URL='[::1]:7076'
        echo $NODE_URL > $DIR/.xno/node
    else
        NODE_URL=$(cat $DIR/.xno/node)
    fi

    if curl -sL --fail $NODE_URL -o /dev/null; then
        
NODE_VERSION=$(curl -s $NODE_URL \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
{
    "action": "version"
}
EOF
  ))

    echo "${GREEN}NANO CLI:${NC} $VERSION"
    echo "${GREEN}NANO NODE:${NC} $(jq '.node_vendor' <<< "$NODE_VERSION" | tr -d '"')"

    else
        echo "${GREEN}NANO CLI:${NC} $VERSION"
    fi

    exit 0

fi

# ██╗   ██╗██████╗ ██████╗  █████╗ ████████╗███████╗
# ██║   ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
# ██║   ██║██████╔╝██║  ██║███████║   ██║   █████╗  
# ██║   ██║██╔═══╝ ██║  ██║██╔══██║   ██║   ██╔══╝  
# ╚██████╔╝██║     ██████╔╝██║  ██║   ██║   ███████╗
#  ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝

# if [[ $1 == "upgrade" ]] || [[ $1 == "--upgrade" ]]  || [[ $1 == "-upgrade" ]]; then
#     OLD_VERSION=$(grep -E '^VERSION=' /usr/local/bin/xno | awk -F '=' '{print $2}' | tr -d '"')
#     curl -sL "https://github.com/fwd/nano-cli/raw/main/xno.sh" -o /usr/local/bin/xno
#     sudo chmod +x /usr/local/bin/xno
#     NEW_VERSION=$(grep -E '^VERSION=' /usr/local/bin/xno | awk -F '=' '{print $2}' | tr -d '"')
#     echo "${GREEN}xno Upgraded${NC}: ${OLD_VERSION} -> ${NEW_VERSION}"
#     exit 0
# fi
                                                  
if [ "$1" = "u" ] || [ "$2" = "-u" ] || [ "$1" = "--update" ] || [ "$1" = "upgrade" ] || [ "$1" = "--upgrade" ] || [ "$1" = "update" ]; then
    
    if [ "$2" = "--dev" ] || [ "$2" = "dev" ]; then
        OLD_VERSION=$(grep -E '^VERSION=' /usr/local/bin/xno | awk -F '=' '{print $2}' | tr -d '"')
        curl -sL "https://github.com/fwd/nano-cli/raw/dev/xno.sh" -o /usr/local/bin/xno
        sudo chmod +x /usr/local/bin/xno
        NEW_VERSION=$(grep -E '^VERSION=' /usr/local/bin/xno | awk -F '=' '{print $2}' | tr -d '"')
        echo "${GREEN}NANO CLI Installed${NC}: DEV ${OLD_VERSION} -> ${NEW_VERSION}"
        exit 0
    fi

    if [ "$2" = "" ] || [ "$2" = "--prod" ] || [ "$2" = "prod" ]; then
        OLD_VERSION=$(grep -E '^VERSION=' /usr/local/bin/xno | awk -F '=' '{print $2}' | tr -d '"')
        curl -sL "https://github.com/fwd/nano-cli/raw/main/xno.sh" -o /usr/local/bin/xno
        sudo chmod +x /usr/local/bin/xno
        NEW_VERSION=$(grep -E '^VERSION=' /usr/local/bin/xno | awk -F '=' '{print $2}' | tr -d '"')
        echo "${GREEN}NANO CLI Installed${NC}: STABLE ${OLD_VERSION} -> ${NEW_VERSION}"
        exit 0
    fi
    exit 0
fi

# ██╗   ██╗███╗   ██╗██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     
# ██║   ██║████╗  ██║██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     
# ██║   ██║██╔██╗ ██║██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     
# ██║   ██║██║╚██╗██║██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     
# ╚██████╔╝██║ ╚████║██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
#  ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝

if [[ "$1" = "--uninstall" ]] || [[ "$1" = "-u" ]]; then
    sudo rm /usr/local/bin/xno
    rm $DIR/.xno/wallet
    rm $DIR/.xno/accounts
    rm $DIR/.xno/cache
    rm -rf $DIR/.xno/data
    echo "CLI removed. Hope to see you soon."
    exit 0
fi

# ██╗  ██╗██╗   ██╗██╗  ██╗
# ██║  ██║██║   ██║██║  ██║
# ███████║██║   ██║███████║
# ██╔══██║██║   ██║██╔══██║
# ██║  ██║╚██████╔╝██║  ██║
# ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝
                         
cat <<EOF
Commant not found. Use 'xno help' to list commands.
EOF

exit 0
