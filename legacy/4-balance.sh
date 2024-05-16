function cloud_balance() {

  if [[ $(cat $DIR/.xno/session 2>/dev/null) == "" ]]; then
    echo "${CYAN}Cloud${NC}: You're not logged in. Use 'n2 login' or 'n2 register' first."
    exit 0
  fi

  ACCOUNT=$(curl -s "https://nano.to/cloud/account" \
  -H "Accept: application/json" \
  -H "session: $(cat $DIR/.xno/session)" \
  -H "Content-Type:application/json" \
  --request GET)

  # echo "as" $ACCOUNT

  if [[ $(jq -r '.error' <<< "$ACCOUNT") == "429" ]]; then
    echo "==============================="
    echo "       TOO MANY REQUESTS       "
    echo "==============================="
    echo "Wait a few seconds.            "
    echo "==============================="
    echo
    exit 0
  fi

  if [[ $(jq -r '.code' <<< "$ACCOUNT") == "401" ]]; then
    rm $DIR/.xno/session
    # echo
    echo "==============================="
    echo "    LOGGED OUT FOR SECURITY    "
    echo "==============================="
    echo "Use 'n2 login' to log back in. "
    echo "==============================="
    echo
    exit 0
  fi

  if [[ $(jq -r '.error' <<< "$ACCOUNT") == "433" ]]; then

  RMESSAGE=$(jq -r '.message' <<< "$ACCOUNT")

WELCOME=$(cat <<EOF

===============================
      VERIFY EMAIL ADDRESS      
===============================
$RMESSAGE
===============================
Enter Code: 
EOF
)


  read -p "$WELCOME" EMAIL_OTP

  # echo $EMAIL_OTP

  # exit 0

  VERIFY_ATTEMPT=$(curl -s "https://nano.to/cloud/verify?code=$EMAIL_OTP" \
    -H "Accept: application/json" \
    -H "session: $(cat $DIR/.xno/session)" \
    -H "Content-Type:application/json" \
    --request POST)

  echo $VERIFY_ATTEMPT

  exit 0
fi

  # echo $ACCOUNT

  #   # echo 
  #   # echo 
  #   # echo "========================"
  #   # echo "   2-FACTOR REQUIRED    "
  #   # echo "========================"
  #   # echo

  #   # read -sp 'Enter OTP Code: ' OTP_CODE

  # exit 0

  if [[ "$2" == "--json" ]] || [[ "$3" == "--json" ]] || [[ "$4" == "--json" ]]; then
    echo $ACCOUNT
    exit 0
  fi

  email=$(jq -r '.email' <<< "$ACCOUNT")
  username=$(jq -r '.username' <<< "$ACCOUNT")
  usernames=$(jq -r '.usernames' <<< "$ACCOUNT")
  address=$(jq -r '.address' <<< "$ACCOUNT")
  api_key=$(jq -r '.api_key' <<< "$ACCOUNT")
  balance=$(jq -r '.balance' <<< "$ACCOUNT")
  pending=$(jq -r '.pending' <<< "$ACCOUNT")
  frontier=$(jq -r '.frontier' <<< "$ACCOUNT")
  two_factor=$(jq -r '.two_factor' <<< "$ACCOUNT")
  pow_usage=$(jq -r '.pow_usage' <<< "$ACCOUNT")
  pow_limit=$(jq -r '.pow_limit' <<< "$ACCOUNT")
  wallets=$(jq -r '.accounts' <<< "$ACCOUNT")

  # echo $ACCOUNT

  # echo
  echo "==============================="
  echo "         ${CYAN}CLOUD ACCOUNT${NC}       "
  echo "==============================="
  # echo "WALLETS: " $wallets
  # echo "==============================="
  if [[ "$2" != "--hide" ]] && [[ "$2" != "-h" ]] && [[ "$2" != "--h" ]] && [[ "$2" != "-p" ]]; then
    echo "BALANCE: "$balance
    echo "PENDING: "$pending
  fi
  echo "ADDRESS: "$address
  echo "ACCOUNT: "$email
  if [[ $two_factor == "TRUE" ]]; then
    echo "2FAUTH: ${GREEN}"$two_factor "${NC}"
  else
    echo "2FAUTH: ${RED}"$two_factor "${NC}"
  fi
  echo "POW_API: " $pow_limit
  # echo "==============================="
  echo "============DOMAINS============"
  echo $usernames
  # echo "===========POW CREDITS============"
  # echo $pow_limit
  echo "==========NANOLOOKER==========="
  echo "https://nanolooker.com/account/"$address
  echo "==============================="

  exit 0

}

if [[ $1 == "balance" ]]; then

  if curl -s --fail -X POST '[::1]:7076' || [[ $2 == '--local' ]]; then
    echo ""
    # $(cloud_balance $1 $2 $3 $4 $5)
cat <<EOF
${GREEN}Local${NC}: Non-custodial local Wallet is in-development. 

Github: https://github.com/fwd/nano-cli
Twitter: https://twitter.com/nano2dev

EOF
    exit 0
  else
    cat <<EOF
$(cloud_balance $1 $2 $3 $4 $5)
EOF
  fi;
  
  exit 0

fi


