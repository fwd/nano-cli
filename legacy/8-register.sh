function cloud_register() {

        if [[ $(cat $DIR/.n2/session 2>/dev/null) != "" ]]; then
            echo "${CYAN}Cloud${NC}: You're already logged in. Use 'n2 logout' to logout."
            exit 0
        fi

        # echo
        # echo "========================"
        # echo "    NANO.TO REGISTER    "
        # echo "========================"
        # echo

        # echo 'Create New Account'

        # echo 

RWELCOME=$(cat <<EOF

========================
☁️      REGISTER       ☁️ 
========================

Welcome to the Cloud

Email:
EOF
)
         
        if [[ $USERNAME == "" ]]; then
            read -p "$RWELCOME " USERNAME
        fi

        if [[ $PASSWORD == "" ]]; then
            echo
            read -sp 'Password: ' PASSWORD
        fi
         
        echo 
        # echo "Thank you $username for showing interest in learning with www.tutorialkart.com"

        REGISTER_ATTEMPT=$(curl -s "https://nano.to/register" \
        -H "Accept: application/json" \
        -H "Content-Type:application/json" \
        --request POST \
        --data @<(cat <<EOF
    { "username": "$USERNAME", "password": "$PASSWORD" }
EOF
        ))

        if [[ $(jq '.session' <<< "$REGISTER_ATTEMPT") == null ]]; then
            echo
            echo "${CYAN}Cloud${NC}:" $(jq -r '.message' <<< "$REGISTER_ATTEMPT")
            exit 0
        fi

        rm $DIR/.n2/session 2>/dev/null

        echo $(jq -r '.session' <<< "$REGISTER_ATTEMPT") >> $DIR/.n2/session

        # echo
        # sleep 0.1

        ACCOUNT=$(curl -s "https://nano.to/cloud/account" \
        -H "Accept: application/json" \
        -H "session: $(cat $DIR/.n2/session)" \
        -H "Content-Type:application/json" \
        --request GET)

        if [[ $(jq -r '.error' <<< "$ACCOUNT") != "433" ]]; then
            echo "${CYAN}Cloud${NC}: $(jq -r '.message' <<< "$ACCOUNT")"
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
            -H "session: $(cat $DIR/.n2/session)" \
            -H "Content-Type:application/json" \
            --request POST)

            echo $VERIFY_ATTEMPT

            exit 0

        fi
    
    exit 0

}

