
function setup_2fa() {
    if [[ $(cat $DIR/.n2/session 2>/dev/null) == "" ]]; then
        echo "${CYAN}Cloud${NC}: Not logged in. Use 'n2 login' or 'n2 register' first."
        exit 0
    fi

    HAS_TWO_FACTOR=$(curl -s "https://nano.to/cloud/account" \
        -H "Accept: application/json" \
        -H "session: $(cat $DIR/.n2/session)" \
        -H "Content-Type:application/json" \
    --request GET | jq '.two_factor')

    if [[ $HAS_TWO_FACTOR == "true" ]]; then
        echo "2-factor already enabled. Use 'n2 2f-remove' to change 2-factor."
        exit 0
    fi

    NEW_SETUP=$(curl -s "https://nano.to/user/two-factor" \
        -H "Accept: application/json" \
        -H "session: $(cat $DIR/.n2/session)" \
        -H "Content-Type:application/json" \
    --request GET)

    OTP_ID=$(jq -r '.id' <<< "$NEW_SETUP")
    QR=$(jq -r '.qr' <<< "$NEW_SETUP")
    KEY=$(jq -r '.key' <<< "$NEW_SETUP")

    echo "==============================="
    echo "        ENABLE 2-FACTOR        "
    echo "==============================="
    echo "Copy the 'KEY' or scan the provided QR."
    echo "==============================="
    echo "NAME: Nano.to"
    echo "KEY:" $KEY
    echo "QR:" $QR
    echo "==============================="
    read -p 'First OTP Code: ' FIRST_OTP

    if [[ $FIRST_OTP == "" ]]; then
        echo "${CYAN}Cloud${NC}: No code. Try again, but from scratch."
        exit 0
    fi

    OTP_ATTEMPT=$(curl -s "https://nano.to/user/two-factor" \
    -H "Accept: application/json" \
    -H "session: $(cat $DIR/.n2/session)" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
{ "id": "$OTP_ID", "code": "$FIRST_OTP" }
EOF
    ))

    echo 

    echo "$OTP_ATTEMPT"
}

function remove_2fa() {
    HAS_TWO_FACTOR=$(curl -s "https://nano.to/cloud/account" \
        -H "Accept: application/json" \
        -H "session: $(cat $DIR/.n2/session)" \
        -H "Content-Type:application/json" \
    --request GET | jq '.two_factor')

    if [[ $HAS_TWO_FACTOR == "false" ]]; then
        echo "${CYAN}Cloud${NC}: You don't have 2f enabled. Use 'n2 2f' to enable it."
        exit 0
    fi

    echo "========================"
    echo "    REMOVE 2-FACTOR     "
    echo "========================"
    echo
    echo "Please provide an existing OTP code."
    echo

    read -p 'Enter OTP Code: ' REMOVE_OTP

    if [[ $REMOVE_OTP == "" ]]; then
        echo "${CYAN}Cloud${NC}: No code. Try again, but from scratch."
        exit 0
    fi

REMOVE_OTP_ATTEMPT=$(curl -s "https://nano.to/user/two-factor/disable" \
-H "Accept: application/json" \
-H "session: $(cat $DIR/.n2/session)" \
-H "Content-Type:application/json" \
--request POST \
--data @<(cat <<EOF
{ "code": "$REMOVE_OTP" }
EOF
    ))

        echo 

        echo "$REMOVE_OTP_ATTEMPT"

        exit 0
}

