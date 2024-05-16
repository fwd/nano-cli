

## Compare two decimals
# FAUCET_BALANCE=$(n2 balance nano_1faucet7b6xjyha7m13objpn5ubkquzd6ska8kwopzf1ecbfmn35d1zey3ys --nano)
# if [ 1 -eq "$(echo "${FAUCET_BALANCE} >= 5" | bc)" ]; then
#         echo $FAUCET_BALANCE
# else
#         echo "Not enough."
# fi


function findAddress() {
  echo $1 | jq '.[] | select(contains("'$2'")) | .' | head -1
}


function get_accounts() {

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

  if [[ $(cat $DIR/.xno/wallet 2>/dev/null) == "" ]]; then
      WALLET_ID=$(docker exec -it nano-node /usr/bin/nano_node --wallet_list | grep 'Wallet ID' | awk '{ print $NF}' | tr -d '[:space:]' )
      echo $WALLET_ID > $DIR/.xno/wallet
  else
      WALLET_ID=$(cat $DIR/.xno/wallet)
  fi

  accounts=$(curl -s '[::1]:7076' \
  -H "Accept: application/json" \
  -H "Content-Type:application/json" \
  --request POST \
  --data @<(cat <<EOF
{
    "action": "account_list",
    "wallet": "$WALLET_ID",
    "json_block": "true"
}
EOF
    ))

    # COUNT="{ \"accounts\": \""$(jq -r '.accounts | length' <<< "$accounts")"\"  }"
    # COUNT="{ \"accounts\": \""$(jq -r '.accounts | length' <<< "$accounts")"\"  }"

    # echo $(jq -n "$COUNT") 
    echo $accounts
    # echo $(jq '.accounts[0]' <<< "") 
    # echo $(jq '.accounts[0]' <<< "$accounts") 

}

function get_balance() {

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

  if [ -z "$1" ]; then
        
      # all_accounts=$(get_accounts) 
      ALL_ACCOUNTS=$(get_accounts) 
      THE_ADDRESS=$(jq '.accounts[0]' <<< "$ALL_ACCOUNTS" | tr -d '"') 
      # _ADDRESS=$(jq '.accounts[0]' <<< "$all_accounts" | tr -d '"') 

  else
      
      if [[ "$1" == *"nano_"* ]]; then
          THE_ADDRESS=$1
      else
          THE_NAME=$(echo $1 | sed -e "s/\@//g")
          THE_ACCOUNT=$(curl -s https://raw.githubusercontent.com/fwd/nano-to/master/known.json | jq '. | map(select(.name == "'$THE_NAME'"))' | jq '.[0]')
          THE_ADDRESS=$(jq -r '.address' <<< "$THE_ACCOUNT")
      fi

  fi

  if curl -sL --fail '[::1]:7076' -o /dev/null; then
    echo -n ""
  else
    echo "${RED}Error:${NC} ${CYAN}Node offline.${NC} Use 'n2 setup' for more information."
    exit 0
  fi

  if [[ $(cat $DIR/.xno/node 2>/dev/null) == "" ]]; then
      NODE_URL='[::1]:7076'
      echo $NODE_URL > $DIR/.xno/node
  else
      NODE_URL=$(cat $DIR/.xno/node)
  fi

ACCOUNT=$(curl -s $NODE_URL \
  -H "Accept: application/json" \
  -H "Content-Type:application/json" \
  --request POST \
  --data @<(cat <<EOF
{
    "action": "account_info",
    "account": "$THE_ADDRESS",
    "representative": "true",
    "pending": "true",
    "receivable": "true"
}
EOF
))

  echo $ACCOUNT


}

function list_accounts() {

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
  
  accounts_on_file=$(get_accounts)

  if [[ "$1" == "--json" ]]; then
      echo $(jq '.accounts' <<< "$accounts_on_file")
      exit 0
  fi

  readarray -t my_array < <(jq '.accounts' <<< "$accounts_on_file")
  
  index=1

  for item in "${my_array[@]}"; do
    if [[ "$item" == *"nano_"* ]]; then
      
      if [[ "$1" == "--show" ]] || [[ "$2" == "--show" ]]; then
        
        echo "[$index]:" $item | tr -d '"'

      elif [[ "$1" == "--balance" ]] || [[ "$1" == "-b" ]]; then

        CLEAN_ADDRESS=$(echo $item | tr -d '"' | tr -d ',')

        # CLEAN_ADDRESS2=$()
        
        ITEM_ACCOUNT=$(curl -s $NODE_URL \
  -H "Accept: application/json" \
  -H "Content-Type:application/json" \
  --request POST \
  --data @<(cat <<EOF
{
    "action": "account_info",
    "account": "$CLEAN_ADDRESS",
    "representative": "true",
    "pending": "true",
    "receivable": "true"
}
EOF
))
      ADDRESSS_BALANCE=$(jq '.balance' <<< "$ITEM_ACCOUNT" | tr -d '"')

      echo "[$index]:" $(echo $CLEAN_ADDRESS | cut -c1-20 ) "[$(raw_to_nano $ADDRESSS_BALANCE | cut -c1-6)]"

      else
        echo "[$index]:" $item | tr -d '"' | cut -c1-20
      fi

      let "index++"
    fi
  done

}

function print_address() {

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

  accounts_on_file=$(get_accounts)

  if [[ -z "$1" ]]; then
    ACCOUNT_INDEX="0"
  else
    ACCOUNT_INDEX=$(expr $1 - 1)
  fi

  # total_accounts=$(jq '.accounts | length' <<< "$accounts_on_file")  

  # if [[ "$2" == "--hide" ]] || [[ "$2" == "-hide" ]]; then
    # first_account=$(jq ".accounts[$ACCOUNT_INDEX]" <<< "$accounts_on_file" | tr -d '"') 
  # else
  the_account=$(jq ".accounts[$ACCOUNT_INDEX]" <<< "$accounts_on_file" | tr -d '"') 
  # fi

  echo $the_account

}


function print_balance() {

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

  accounts_on_file=$(get_accounts)

  total_accounts=$(jq '.accounts | length' <<< "$accounts_on_file") 

  if [[ -z "$1" ]] || [[ "$1" == "--hide" ]] || [[ "$1" == "-hide" ]]; then
    first_account=$(jq '.accounts[0]' <<< "$accounts_on_file" | tr -d '"') 
  else
    first_account=$1
  fi

  if [ -n "$1" ] && [ "$1" -eq "$1" ] 2>/dev/null; then
           
      if [[ -z "$1" ]]; then
        ACCOUNT_INDEX="0"
      else
        ACCOUNT_INDEX=$(expr $1 - 1)
      fi

      first_account=$(jq ".accounts[$ACCOUNT_INDEX]" <<< "$accounts_on_file" | tr -d '"') 

  else
      
    first_account=$1

  fi

  account_info=$(get_balance "$first_account")

  if [[ "$2" == "--raw" ]]; then
      echo $(jq -r '.balance' <<< "$account_info")
      exit 0
  fi

  if [[ "$2" == "--nano" ]] || [[ "$2" == "--text" ]]; then
      raw_to_nano $(jq -r '.balance' <<< "$account_info")
      exit 0
  fi

  if [[ "$2" == "--json" ]]; then
      echo $account_info
      exit 0
  fi

  if [[ "$(jq -r '.balance' <<< "$account_info")" == "null" ]]; then
    # echo
    echo "================================"
    echo "             ${RED}ERROR${NC}              "
    echo "================================"
    echo "$(jq -r '.error' <<< "$account_info") "
    echo "================================"
    echo
    exit 0
  fi

  account_balance=$(jq '.balance' <<< "$account_info" | tr -d '"') 

  account_pending=$(jq '.pending' <<< "$account_info" | tr -d '"') 

  if [[ $account_balance == "0" ]]; then
    balance_in_decimal_value=$account_balance
  else
    balance_in_decimal_value=$(raw_to_nano $account_balance)
  fi

  if [[ $account_pending == "0" ]]; then
    echo -n ""
    pending_in_decimal_value="0"
  else 
    pending_in_decimal_value=$(raw_to_nano $account_pending)
  fi

  mkdir -p $DIR/.xno/data
  metadata=$(find $DIR/.xno/data -maxdepth 1 -type f | wc -l | xargs)

  if [[ $(cat $DIR/.xno/title 2>/dev/null) == "" ]]; then
      CLI_TITLE="        NANO CLI (N2)"
  else
      CLI_TITLE=$(cat $DIR/.xno/title)
  fi

  if [[ "$3" == "--json" ]] || [[ "$4" == "--json" ]] || [[ "$5" == "--json" ]]; then
      echo "{ \"address\": \""first_account"\", \"balance\": \""balance_in_decimal_value"\", \"pending\": \""pending_in_decimal_value"\", \"accounts\": \""total_accounts"\", \"metadata\": \""metadata"\"   }"
      exit 0
  fi

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

  NODE_SYNC=$(curl -s $NODE_URL \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
{
    "action": "block_count"
}
EOF
  ))

  NODE_BLOCK_COUNT=$(jq '.count' <<< "$NODE_SYNC" | tr -d '"') 
  NODE_BLOCK_UNCHECKED=$(jq '.unchecked' <<< "$NODE_SYNC" | tr -d '"') 
  NODE_BLOCK_CEMENTED=$(jq '.cemented' <<< "$NODE_SYNC" | tr -d '"') 

  INT_NODE_BLOCK_COUNT=$(expr $NODE_BLOCK_COUNT + 0)
  INT_NODE_BLOCK_UNCHECKED=$(expr $NODE_BLOCK_UNCHECKED + 0)
  INT_NODE_BLOCK_CEMENTED=$(expr $NODE_BLOCK_CEMENTED + 0)

  SYNC_PERCENT=$(awk "BEGIN {print  (($INT_NODE_BLOCK_COUNT - $INT_NODE_BLOCK_UNCHECKED) / $INT_NODE_BLOCK_COUNT) * 100 }")

  if [[ $SYNC_PERCENT == *"99.9999"* ]]; then
    FINAL_SYNC_PERCENT="100"
  else
    FINAL_SYNC_PERCENT=$SYNC_PERCENT
  fi

  echo "============================="
  echo "           ${GREEN}BALANCE${NC}"
  echo "============================="
  if [[ "$1" == "--hide" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "hide" ]]; then
    echo "${PURP}Address:${NC} $(echo "$first_account" | cut -c1-17)***"
  else
    echo "${PURP}Address:${NC} $(echo "$first_account" | cut -c1-17)***"
    echo "${PURP}Balance:${NC} $balance_in_decimal_value"
    echo "${PURP}Pending:${NC} $pending_in_decimal_value"
  fi
  echo "============================="
  echo "${PURP}Node:${NC} ${GREEN}$(jq '.node_vendor' <<< "$NODE_VERSION" | tr -d '"') @ $FINAL_SYNC_PERCENT%${NC}"
  echo "============================="
DOCS=$(cat <<EOF
${GREEN}$ n2 [ balance | send | address ]${NC}
EOF
)
cat <<EOF
$DOCS
EOF
  # else
  #   echo -n ""
  # fi

}



function print_history() {

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

  accounts_on_file=$(get_accounts)

  if [[ -z "$1" ]] || [[ "$1" == "--hide" ]] || [[ "$1" == "-hide" ]]; then
    first_account=$(jq '.accounts[0]' <<< "$accounts_on_file" | tr -d '"') 
  else
    first_account=$1
  fi

  if [[ -z "$2" ]]; then
    count='100'
  else
    count=$2
  fi

  ADDRESS_HISTORY=$(curl -s $NODE_URL \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
{
  "action": "account_history", 
  "account": "$first_account",
  "count": "$count"
}
EOF
  ))

  echo $ADDRESS_HISTORY

}


function print_pending() {

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

  accounts_on_file=$(get_accounts)

  if [[ -z "$1" ]] || [[ "$1" == "--hide" ]] || [[ "$1" == "-hide" ]]; then
    first_account=$(jq '.accounts[0]' <<< "$accounts_on_file" | tr -d '"') 
  else
    first_account=$1
  fi

  if [[ -z "$2" ]]; then
    count='100'
  else
    count=$2
  fi

  ADDRESS_HISTORY=$(curl -s $NODE_URL \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
{
  "action": "pending", 
  "account": "$first_account",
  "count": "$count",
  "source": "true"
}
EOF
  ))

  echo $ADDRESS_HISTORY

}


