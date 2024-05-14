

function local_send() {

    if [[ $(cat $DIR/.n2/node 2>/dev/null) == "" ]]; then
        NODE_URL='[::1]:7076'
        echo $NODE_URL > $DIR/.n2/node
    else
      NODE_URL=$(cat $DIR/.n2/node)
    fi

    if curl -sL --fail $NODE_URL -o /dev/null; then
        echo -n ""
    else
        echo "${RED}Error:${NC} ${CYAN}Node offline.${NC} Use 'n2 setup' for more information."
        exit 0
    fi

    if [[ $2 == "" ]]; then
        echo "${CYAN}Node${NC}: Missing Params. Usage 'n2 send [to] [amount] [from]'"
        exit 0
    fi
    
    if [[ $3 == "" ]]; then
        echo "${CYAN}Node${NC}: Missing Params. Use 'all' to send entire balance."
        exit 0
    fi

    if [[ $(cat $DIR/.n2/wallet 2>/dev/null) == "" ]]; then
        WALLET_ID=$(docker exec -it nano-node /usr/bin/nano_node --wallet_list | grep 'Wallet ID' | awk '{ print $NF}' | tr -d '[:space:]' )
        echo $WALLET_ID > $DIR/.n2/wallet
    else
        WALLET_ID=$(cat $DIR/.n2/wallet)
    fi

    UUID=$(uuidgen)
    accounts_on_file=$(get_accounts)

    if [[ -z "$4" ]] || [[ "$4" == "--json" ]]; then

        if [[ $(cat $DIR/.n2/main 2>/dev/null) == "" ]]; then
            SRC=$(jq '.accounts[0]' <<< "$accounts_on_file" | tr -d '"') 
            echo $SRC > $DIR/.n2/main
        else
            SRC=$(cat $DIR/.n2/main)
        fi
        
    else

        if [ -n "$4" ] && [ "$4" -eq "$4" ] 2>/dev/null; then
           
            if [[ -z "$4" ]]; then
              ACCOUNT_INDEX="0"
            else
              ACCOUNT_INDEX=$(expr $4 - 1)
            fi

            SRC=$(jq ".accounts[$ACCOUNT_INDEX]" <<< "$accounts_on_file" | tr -d '"') 

        else
            
            SRC=$4

        fi

        # TODO Code: Find item in JQ array via BASH. Why is it so hard?!

    fi

    if [[ "$3" == "all" ]]; then

        ACCOUNT=$(curl -s $NODE_URL \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        --request POST \
        --data @<(cat <<EOF
{
    "action": "account_info",
    "account": "$SRC",
    "representative": "true",
    "pending": "true",
    "receivable": "true"
}
EOF
  ))

        AMOUNT_FINAL=$(jq -r '.balance' <<< "$ACCOUNT")

        if [[ $AMOUNT_FINAL == "0" ]]; then
            echo "${RED}Error:${NC} Balance is 0."
            exit 0
        fi
        
    else
        AMOUNT_FINAL=$(nano_to_raw $3)
    fi

    if [ -n "$2" ] && [ "$2" -eq "$2" ] 2>/dev/null; then
           
      if [[ -z "$2" ]]; then
        ACCOUNT_INDEX="0"
      else
        ACCOUNT_INDEX=$(expr $2 - 1)
      fi

      DEST=$(jq ".accounts[$ACCOUNT_INDEX]" <<< "$accounts_on_file" | tr -d '"') 

    else

        if [[ "$2" == *"nano_"* ]]; then
            DEST=$2
        else
            NAME_DEST=$(echo $2 | sed -e "s/\@//g")
            SRC_ACCOUNT=$(curl -s https://raw.githubusercontent.com/fwd/nano-to/master/known.json | jq '. | map(select(.name == "'$NAME_DEST'"))' | jq '.[0]')
            DEST=$(jq -r '.address' <<< "$SRC_ACCOUNT")
            if [[ "$DEST" == "null" ]]; then
                echo "${RED}Error:${NC} Invalid or Expired Username."
                exit 0
            fi
        fi
        
    fi


    ACCOUNT=$(curl -s $NODE_URL \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
{
    "action": "account_info",
    "account": "$SRC"
}
EOF
    ))

    CURRENT_BALANCE=$(jq -r '.balance' <<< "$ACCOUNT")

    if [[ "$5" == "--json" ]]; then
        echo -n ""
    else    
        SEND_CONFIRM=$(cat <<EOF
==================================
          ${GREEN}CONFIRM SEND${NC}
==================================
${GREEN}AMOUNT:${NC} $(raw_to_nano $AMOUNT_FINAL)
${GREEN}TO:${NC} $DEST
${GREEN}FROM:${NC} $SRC
${GREEN}BALANCE:${NC} $(raw_to_nano $CURRENT_BALANCE)
==================================
Press 'Y' to continue:
EOF
)
        read -p "$SEND_CONFIRM " SEND_CONFIRM_YES
        if [[ $SEND_CONFIRM_YES != 'y' ]] && [[ $SEND_CONFIRM_YES != 'Y' ]]; then
          echo "Canceled."
          exit 0
        fi
    fi

    SEND_ATTEMPT=$(curl -s $NODE_URL \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
{
    "action": "send",
    "wallet": "$WALLET_ID",
    "source": "$SRC",
    "destination": "$DEST",
    "amount": "$AMOUNT_FINAL",
    "id": "$UUID"
}
EOF
    ))

    if [[ "$5" == "--json" ]]; then
        echo $SEND_ATTEMPT
        exit 0
    fi

    if [[ "$(jq -r '.block' <<< "$SEND_ATTEMPT")" == "null" ]]; then
        # echo
        echo "================================"
        echo "             ${RED}ERROR${NC}              "
        echo "================================"
        echo "$(jq -r '.error' <<< "$SEND_ATTEMPT") "
        echo "================================"
        echo
        exit 0
    fi

    echo "==============================="
    echo "         ${GREEN}NANO RECEIPT${NC}          "
    echo "==============================="
    echo "${GREEN}AMOUNT${NC}: "$(raw_to_nano $AMOUNT_FINAL)
    echo "${GREEN}TO${NC}: "$DEST
    echo "${GREEN}FROM${NC}: "$SRC
    # echo "${GREEN}HASH${NC}: "$(jq -r '.block' <<< "$SEND_ATTEMPT")
    echo "--------------------------------"
    echo "https://nanolooker.com/block/$(jq -r '.block' <<< "$SEND_ATTEMPT")"
    echo "==============================="

    exit 0
    
}


if [[ "$1" = "--seed" ]] || [[ "$1" = "--secret" ]]; then
  WALLET_ID=$(docker exec -it nano-node /usr/bin/nano_node --wallet_list | grep 'Wallet ID' | awk '{ print $NF}')
  SEED=$(docker exec -it nano-node /usr/bin/nano_node --wallet_decrypt_unsafe --wallet=$WALLET_ID | grep 'Seed' | awk '{ print $NF}' | tr -d '\r')
  echo $SEED
fi


if [[ $1 == "send" ]] || [[ $1 == "--send" ]] || [[ $1 == "-s" ]]; then
    cat <<EOF
$(local_send $1 $2 $3 $4 $5)
EOF
    exit 0
fi

if [[ $1 == "add" ]] || [[ $1 == "create" ]] || [[ $1 == "account_create" ]]; then

    if [[ $(cat $DIR/.n2/node 2>/dev/null) == "" ]]; then
        NODE_URL='[::1]:7076'
        echo $NODE_URL > $DIR/.n2/node
    else
        NODE_URL=$(cat $DIR/.n2/node)
    fi

    if curl -sL --fail $NODE_URL -o /dev/null; then
        echo -n ""
    else
        echo "${RED}Error:${NC} ${CYAN}Node offline.${NC} Use 'n2 setup' for more information."
        exit 0
    fi

    if [[ $(cat $DIR/.n2/wallet 2>/dev/null) == "" ]]; then
        WALLET_ID=$(docker exec -it nano-node /usr/bin/nano_node --wallet_list | grep 'Wallet ID' | awk '{ print $NF}' | tr -d '[:space:]' )
        echo $WALLET_ID > $DIR/.n2/wallet
    else
        WALLET_ID=$(cat $DIR/.n2/wallet)
    fi

    if [[ "$2" == "--json" ]] || [[ "$3" == "--json" ]]; then
        echo -n ""
    else    
        read -p "${GREEN}Cloud${NC}: Add a new address? Enter 'y' to continue: " SANITY_CHECK
        if [[ $SANITY_CHECK != 'y' ]] && [[ $SANITY_CHECK != 'Y' ]]; then
          echo "Canceled."
          exit 0
        fi
    fi

  NEW_ACCOUNT=$(curl -s $NODE_URL \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
{
    "action": "account_create",
    "wallet": "$WALLET_ID"
}
EOF
  ))

    if [[ "$2" == "--json" ]] || [[ "$3" == "--json" ]]; then
        echo $NEW_ACCOUNT
        exit 0
    fi

    echo "============================="
    echo "      ${GREEN}ACCOUNT CREATED${NC}"
    echo "============================="
    echo $(jq '.account' <<< "$NEW_ACCOUNT" | tr -d '"')

    exit 0

fi


if [[ "$1" = "add_vanity" ]] || [[ "$1" = "vanity_add" ]]; then

    if [[ $(cat $DIR/.n2/node 2>/dev/null) == "" ]]; then
        NODE_URL='[::1]:7076'
        echo $NODE_URL > $DIR/.n2/node
    else
        NODE_URL=$(cat $DIR/.n2/node)
    fi

    if curl -sL --fail $NODE_URL -o /dev/null; then
        echo -n ""
    else
        echo "${RED}Error:${NC} ${CYAN}Node offline.${NC} Use 'n2 setup' for more information."
        exit 0
    fi

    if [[ ! -f "$DIR/.cargo/bin/nano-vanity" ]]; then
        echo "Nano-Vanity not installed. Use 'n2 vanity' to setup."
        exit 0
    else 
        VANITY_PATH="$DIR/.cargo/bin/nano-vanity"
    fi

    if [[ $(cat $DIR/.n2/wallet 2>/dev/null) == "" ]]; then
        WALLET_ID=$(docker exec -it nano-node /usr/bin/nano_node --wallet_list | grep 'Wallet ID' | awk '{ print $NF}' | tr -d '[:space:]' )
        echo $WALLET_ID > $DIR/.n2/wallet
    else
        WALLET_ID=$(cat $DIR/.n2/wallet)
    fi

    GPU_INSTALLED=$(lspci -vnnn | perl -lne 'print if /^\d+\:.+(\[\S+\:\S+\])/' | grep VGA)

    if [[ $GPU_INSTALLED == *"paravirtual"* ]]; then
        THREAD_COUNT=$(grep ^cpu\\scores /proc/cpuinfo | uniq |  awk '{print $4}')
        USE_THREAD_COUNT=$(awk "BEGIN {print ($THREAD_COUNT - 1) }")
        VANITY_ADDRESS=$($VANITY_PATH $2 --no-progress --threads $USE_THREAD_COUNT --simple-output)
    else 
        VANITY_ADDRESS=$($VANITY_PATH $2 --no-progress --gpu-device 0 --gpu-platform 0 --simple-output)
    fi

    VANITY_ADDRESS_ARRAY=($VANITY_ADDRESS)
    
    if [[ ${VANITY_ADDRESS_ARRAY[1]} == *"nano_"* ]]; then
        
        NEW_ACCOUNT=$(curl -s $NODE_URL \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        --request POST \
        --data @<(cat <<EOF
{
  "action": "wallet_add",
  "wallet": "$WALLET_ID",
  "key": "${VANITY_ADDRESS_ARRAY[0]}"
}
EOF
  ))

    echo $NEW_ACCOUNT

    fi

    exit 0

fi


if [[ "$1" = "adhoc_account" ]] || [[ "$1" = "adhoc_add" ]]; then

    if [[ $2 == "" ]]; then
        echo "${CYAN}Node${NC}: Missing Private Seed."
        exit 0
    fi

    if [[ $(cat $DIR/.n2/node 2>/dev/null) == "" ]]; then
        NODE_URL='[::1]:7076'
        echo $NODE_URL > $DIR/.n2/node
    else
        NODE_URL=$(cat $DIR/.n2/node)
    fi

    if curl -sL --fail $NODE_URL -o /dev/null; then
        echo -n ""
    else
        echo "${RED}Error:${NC} ${CYAN}Node offline.${NC} Use 'n2 setup' for more information."
        exit 0
    fi

    if [[ $(cat $DIR/.n2/wallet 2>/dev/null) == "" ]]; then
        WALLET_ID=$(docker exec -it nano-node /usr/bin/nano_node --wallet_list | grep 'Wallet ID' | awk '{ print $NF}' | tr -d '[:space:]' )
        echo $WALLET_ID > $DIR/.n2/wallet
    else
        WALLET_ID=$(cat $DIR/.n2/wallet)
    fi

    # VANITY_ADDRESS=$(nano-vanity $2 --no-progress --gpu-device 0 --gpu-platform 0 --simple-output)
    # VANITY_ADDRESS_ARRAY=($VANITY_ADDRESS)
    
    NEW_ACCOUNT=$(curl -s $NODE_URL \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
{
  "action": "wallet_add",
  "wallet": "$WALLET_ID",
  "key": "$2"
}
EOF
  ))

    echo $NEW_ACCOUNT

    exit 0

fi


if [[ $1 == "remove" ]] || [[ $1 == "rm" ]]; then

    if [[ $(cat $DIR/.n2/node 2>/dev/null) == "" ]]; then
        NODE_URL='[::1]:7076'
        echo $NODE_URL > $DIR/.n2/node
    else
      NODE_URL=$(cat $DIR/.n2/node)
    fi

    if curl -sL --fail $NODE_URL -o /dev/null; then
        echo -n ""
    else
        echo "${RED}Error:${NC} ${CYAN}Node offline.${NC} Use 'n2 setup' for more information."
        exit 0
    fi

    if [[ $2 == "" ]]; then
        echo "${CYAN}Node${NC}: Missing Address to remove."
        exit 0
    fi

    if [[ $(cat $DIR/.n2/wallet 2>/dev/null) == "" ]]; then
        WALLET_ID=$(docker exec -it nano-node /usr/bin/nano_node --wallet_list | grep 'Wallet ID' | awk '{ print $NF}' | tr -d '[:space:]' )
        echo $WALLET_ID > $DIR/.n2/wallet
    else
        WALLET_ID=$(cat $DIR/.n2/wallet)
    fi

    accounts_on_file=$(get_accounts)

    if [ -n "$2" ] && [ "$2" -eq "$2" ] 2>/dev/null; then
        if [[ -z "$2" ]]; then
          ACCOUNT_INDEX="0"
        else
          ACCOUNT_INDEX=$(expr $2 - 1)
        fi
        SRC=$(jq ".accounts[$ACCOUNT_INDEX]" <<< "$accounts_on_file" | tr -d '"') 
    else  
        SRC=$2
    fi

    if [[ "$3" == "--json" ]] || [[ "$4" == "--json" ]]; then
        echo -n ""
    else    
        read -p "${GREEN}Cloud${NC}: Remove '$SRC' from wallet? Enter 'y' to continue: " SANITY_CHECK
        if [[ $SANITY_CHECK != 'y' ]] && [[ $SANITY_CHECK != 'Y' ]]; then
          echo "Canceled."
          exit 0
        fi
    fi

    REMOVE=$(curl -s $NODE_URL \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
{
    "action": "account_remove",
    "wallet": "$WALLET_ID",
    "account": "$SRC"
}
EOF
    ))

    echo $REMOVE

    exit 0

fi


if [[ $1 == "wallet" ]]; then


    if [[ $(cat $DIR/.n2/node 2>/dev/null) == "" ]]; then
        NODE_URL='[::1]:7076'
        echo $NODE_URL > $DIR/.n2/node
    else
      NODE_URL=$(cat $DIR/.n2/node)
    fi

    if curl -sL --fail $NODE_URL -o /dev/null; then
        echo -n ""
    else
        echo "${RED}Error:${NC} ${CYAN}Node offline.${NC} Use 'n2 setup' for more information."
        exit 0
    fi

    if [[ $(cat $DIR/.n2/wallet 2>/dev/null) == "" ]]; then
        WALLET_ID=$(docker exec -it nano-node /usr/bin/nano_node --wallet_list | grep 'Wallet ID' | awk '{ print $NF}' | tr -d '[:space:]' )
        echo $WALLET_ID > $DIR/.n2/wallet
    else
        WALLET_ID=$(cat $DIR/.n2/wallet)
    fi

    WALLET=$(curl -s $NODE_URL \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
{
    "action": "wallet_info",
    "wallet": "$WALLET_ID",
    "json_block": "true"
}
EOF
    ))

    echo $WALLET

    exit 0

fi

if [[ $1 == "address" ]]; then

    print_address $2 $3

    exit 0

fi

if [[ $1 == "history" ]]; then

    print_history $2 $3 $4

    exit 0

fi

if [[ $1 == "pending" ]]; then

    print_pending $2 $3 $4

    exit 0

fi

if [[ $1 == "b" ]] || [[ $1 == "balance" ]] || [[ $1 == "account" ]]; then

    accounts_on_file=$(get_accounts)

    if [ -n "$2" ] && [ "$2" -eq "$2" ] 2>/dev/null; then
        if [[ -z "$2" ]]; then
          ACCOUNT_INDEX="0"
        else
          ACCOUNT_INDEX=$(expr $2 - 1)
        fi
        SRC=$(jq ".accounts[$ACCOUNT_INDEX]" <<< "$accounts_on_file" | tr -d '"') 
    else
        SRC=$2
    fi

    print_balance $SRC $3 $4

    exit 0

fi

if [[ $1 == "clear-cache" ]]; then
    rm -rf "$DIR/.n2"
    echo "${RED}N2${NC}: Cache cleared."
    exit 0
fi

if [[ $1 == "upgrade" ]] || [[ $1 == "--upgrade" ]]  || [[ $1 == "-upgrade" ]]; then
    OLD_VERSION=$(grep -E '^VERSION=' /usr/local/bin/n2 | awk -F '=' '{print $2}' | tr -d '"')
    curl -sL "https://github.com/fwd/n2/raw/master/n2.sh" -o /usr/local/bin/n2
    sudo chmod +x /usr/local/bin/n2
    NEW_VERSION=$(grep -E '^VERSION=' /usr/local/bin/n2 | awk -F '=' '{print $2}' | tr -d '"')
    echo "${GREEN}N2 Upgraded${NC}: ${OLD_VERSION} -> ${NEW_VERSION}"
    exit 0
fi

if [[ $1 == "set" ]] || [[ $1 == "--set" ]]  || [[ $1 == "--config" ]]|| [[ $1 == "config" ]]; then
    echo $3 > "$DIR/.n2/$2"
    exit 0
fi

if [[ $1 == "save" ]]; then
    if [[ $2 == "" ]]; then
        echo "${RED}Error${NC}: Missing Hash" 
        exit 0
    fi
    if [[ $3 == "" ]]; then
        echo "${RED}Error${NC}: Missing JSON Metadata" 
        exit 0
    fi
    if jq -e . >/dev/null 2>&1 <<<"$3"; then
        echo $3 > "$DIR/.n2/$2"
    else
        echo "Failed to parse JSON"
    fi
    exit 0
fi


if [[ $1 == "list" ]] || [[ $1 == "ls" ]] || [[ $1 == "l" ]]; then

    list_accounts $2 $3

    exit 0

fi

