

function disburse() {

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

    if [[ $2 == "" ]]; then
        echo "${CYAN}Node${NC}: Missing Params. Usage 'n2 $1 [to] [amount] [from]'"
        exit 0
    fi
    
    if [[ $3 == "" ]]; then
        echo "${CYAN}Node${NC}: Missing Params. Use 'all' to disburse entire balance."
        exit 0
    fi

    if [[ $(cat $DIR/.xno/wallet 2>/dev/null) == "" ]]; then
        WALLET_ID=$(docker exec -it nano-node /usr/bin/nano_node --wallet_list | grep 'Wallet ID' | awk '{ print $NF}' | tr -d '[:space:]' )
        echo $WALLET_ID > $DIR/.xno/wallet
    else
        WALLET_ID=$(cat $DIR/.xno/wallet)
    fi

    UUID=$(uuidgen)
    accounts_on_file=$(get_accounts)

    if [[ -z "$4" ]]; then

        if [[ $(cat $DIR/.xno/main 2>/dev/null) == "" ]]; then
            SRC=$(jq '.accounts[0]' <<< "$accounts_on_file" | tr -d '"') 
            echo $SRC > $DIR/.xno/main
        else
            SRC=$(cat $DIR/.xno/main)
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
        fi
        
    fi

    if [ -f "$2" ]; then
        ADDRESS_LIST=$(cat $2)
    else
        ADDRESS_LIST=$(curl -s "https://api.nano.to/list/$2")
    fi

    if [[ "$ADDRESS_LIST" == *"Cannot GET"* ]]; then
      echo "${RED}Error:${NC} Invalid List. Public Lists: Names, Reps"
      exit 0
    fi

    if [ $(jq '.[]' <<< "$ADDRESS_LIST" > /dev/null 2>&1; echo $?) -eq 0 ]; then
      echo -n ""
    else
      echo "${RED}Error:${NC} Invalid JSON array. Fix and try again. $3"
      exit 0
    fi

    SRC_ACCOUNT_DATA=$(curl -s '[::1]:7076' \
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

    CURRENT_BALANCE=$(jq -r '.balance' <<< "$SRC_ACCOUNT_DATA")
    CURRENT_BALANCE_NANO=$(raw_to_nano $CURRENT_BALANCE)

    if (( $(awk "BEGIN { print $CURRENT_BALANCE_NANO < $3 }") == "1" )); then
        echo "${RED}Error:${NC} Insufficient Balance: $CURRENT_BALANCE_NANO"
        exit 0
    fi

    readarray -t my_array < <(jq '.[]' <<< "$ADDRESS_LIST")

    COUNT=$(jq 'length' <<< "$ADDRESS_LIST")

    AMOUNT_PER=$(awk "BEGIN{ print $3 / $COUNT }")

    if [[ "$4" == "--json" ]] || [[ "$5" == "--json" ]]; then
        echo -n ""
    else    
        SEND_CONFIRM=$(cat <<EOF
==================================
         ${GREEN}CONFIRM DISBURSE${NC}
==================================
${GREEN}RECIPIENTS:${NC} $COUNT
${GREEN}AMOUNT PER:${NC} $AMOUNT_PER
${GREEN}FROM:${NC} $SRC
----------------------------------
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

    index=1

    for item in "${my_array[@]}"; do

        if [[ "$item" == *"nano_"* ]]; then

            ACCOUNT=$(curl -s '[::1]:7076' \
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

            POW=$(curl -s '[::1]:7090' \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            --request POST \
            --data @<(cat <<EOF
{
    "action": "work_generate",
    "hash": "$(jq -r '.frontier' <<< "$ACCOUNT")"
}
EOF
))

            WORK=$(jq -r '.work' <<< "$POW")

            SEND_ATTEMPT=$(curl -s '[::1]:7076' \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            --request POST \
            --data @<(cat <<EOF
{
    "action": "send",
    "wallet": "$WALLET_ID",
    "source": "$SRC",
    "destination": "$(echo "$item" | tr -d '"')",
    "amount": "$(nano_to_raw $AMOUNT_PER)",
    "id": "$(uuidgen)",
    "work": "$WORK"
}
EOF
))          

            sleep 0.1s

            let "index++"

        fi

    done

    exit 0
    
}


if [[ $1 == "disburse" ]] || [[ $1 == "faucet" ]] || [[ $1 == "distribute" ]]; then

    disburse $1 $2 $3 $4 $5

    exit 0

fi


