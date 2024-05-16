
function send_with_pow() {

    if [[ $(cat $DIR/.xno/node 2>/dev/null) == "" ]]; then
        NODE_URL='[::1]:7076'
        echo $NODE_URL > $DIR/.xno/node
    else
      NODE_URL=$(cat $DIR/.xno/node)
    fi

    if curl -sL --fail $NODE_URL -o /dev/null; then
        echo -n ""
    else
        echo "${RED}Error:${NC} ${CYAN}Node offline.${NC} Use 'n2 setup' for more information."
        exit 0
    fi

    if [[ $1 == "" ]]; then
        echo "${CYAN}Node${NC}: Missing To. Usage 'n2 send_with_pow [to] [amount_raw] [from] [work]'"
        exit 0
    fi
    
    if [[ $2 == "" ]]; then
        echo "${CYAN}Node${NC}: Missing Amount. Use 'all' to send entire balance."
        exit 0
    fi

    if [[ $3 == "" ]]; then
        echo "${CYAN}Node${NC}: Missing From. Usage 'n2 send_with_pow [to] [amount_raw] [from] [work]'"
        exit 0
    fi

    if [[ $(cat $DIR/.xno/wallet 2>/dev/null) == "" ]]; then
        WALLET_ID=$(docker exec -it nano-node /usr/bin/nano_node --wallet_list | grep 'Wallet ID' | awk '{ print $NF}' | tr -d '[:space:]' )
        echo $WALLET_ID > $DIR/.xno/wallet
    else
        WALLET_ID=$(cat $DIR/.xno/wallet)
    fi

    SEND_ATTEMPT=$(curl -s '[::1]:7076' \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
{
    "action": "send",
    "wallet": "$WALLET_ID",
    "source": "$3",
    "destination": "$1",
    "amount": "$2",
    "id": "$(uuidgen)",
    "work": "$4"
}
EOF
    ))

    echo $SEND_ATTEMPT

    exit 0
    
}


if [[ $1 == "send_with_pow" ]]; then
    cat <<EOF
$(send_with_pow $2 $3 $4 $5)
EOF
    exit 0
fi


