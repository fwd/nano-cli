

function cloud_login() {

    if [[ $(cat $DIR/.xno/session 2>/dev/null) != "" ]]; then
      echo "${CYAN}Cloud${NC}: You're already logged in. Use 'n2 logout' to logout."
      exit 0
    fi



    echo "Welcome back"

    echo

    USERNAME=$3
    PASSWORD=$4

WELCOME=$(cat <<EOF

========================
      NANO.TO LOGIN      
========================

Welcome Back

Email:
EOF
)

    if [[ $USERNAME == "" ]]; then
      read -p "$WELCOME " USERNAME
    fi

    if [[ $PASSWORD == "" ]]; then
      echo
      read -sp 'Password: ' PASSWORD
    fi

    LOGIN_ATTEMPT=$(curl -s "https://nano.to/login" \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
  { "username": "$USERNAME", "password": "$PASSWORD" }
EOF
    ))

    if [[ $(jq -r '.two_factor' <<< "$LOGIN_ATTEMPT") == "true" ]]; then

      # echo 
      # echo 
      # echo "========================"
      # echo "   2-FACTOR REQUIRED    "
      # echo "========================"
      # echo

OTP_REQUIRED=$(cat <<EOF


OTP Code:
EOF
)

      echo 

      read -sp "$OTP_REQUIRED " OTP_CODE

      echo
      # read -sp 'Enter OTP Code: ' OTP_CODE

    LOGIN_ATTEMPT=$(curl -s "https://nano.to/login" \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
  { "username": "$USERNAME", "password": "$PASSWORD", "code": "$OTP_CODE" }
EOF
    ))

    fi

    if [[ $(jq '.session' <<< "$LOGIN_ATTEMPT") == null ]]; then
      echo
      echo "${CYAN}Cloud${NC}:" $(jq -r '.message' <<< "$LOGIN_ATTEMPT")
      exit 0
    fi

    rm $DIR/.xno/session 2>/dev/null

    echo $(jq -r '.session' <<< "$LOGIN_ATTEMPT") >> $DIR/.xno/session

    # echo

    echo "${GREEN}Cloud${NC}: Logged in. "
    
    exit 0
}

if [[ $1 == "cloud" ]] || [[ $1 == "c" ]]; then

    if [[ "$2" = "ls" ]] || [[ "$2" = "--account" ]] || [[ "$2" = "account" ]] || [[ "$2" = "wallet" ]] || [[ "$2" = "balance" ]] || [[ "$2" = "a" ]] || [[ "$2" = "--balance" ]]; then
cat <<EOF
$(cloud_balance $1 $2 $3 $4 $5)
EOF
    exit 0
    fi

fi

