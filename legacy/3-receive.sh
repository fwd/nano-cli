function cloud_receive() {

  if [[ $(cat $DIR/.n2/session 2>/dev/null) == "" ]]; then
    echo "${CYAN}Cloud${NC}: You're not logged in. Use 'n2 login' or 'n2 register' first."
    exit 0
  fi

  re='^[0-9]+$'

  if [[ $1 =~ $re ]] || [[ $1 == "" ]] ; then
    ACCOUNT=$(curl -s "https://nano.to/cloud/account" \
    -H "Accept: application/json" \
    -H "session: $(cat $DIR/.n2/session)" \
    -H "Content-Type:application/json" \
    --request GET)
    account=$(jq -r '.email' <<< "$ACCOUNT")
    address=$(jq -r '.address' <<< "$ACCOUNT")
  else
    ACCOUNT=$(curl -s "https://nano.to/$1/account" \
    -H "Accept: application/json" \
    -H "session: $(cat $DIR/.n2/session)" \
    -H "Content-Type:application/json" \
    --request GET)
    account=$1
    address=$(jq -r '.address' <<< "$ACCOUNT")
  fi

  if [[ $1 =~ $re ]] || [[ $1 == "" ]] ; then
    GET_QRCODE=$(curl -s "https://nano.to/cloud/qrcode?address=$address&amount=$1" \
    -H "Accept: application/json" \
    -H "session: $(cat $DIR/.n2/session)" \
    -H "Content-Type:application/json" \
    --request GET)
  else
    GET_QRCODE=$(curl -s "https://nano.to/cloud/qrcode?address=$address&amount=$2" \
      -H "Accept: application/json" \
      -H "session: $(cat $DIR/.n2/session)" \
      -H "Content-Type:application/json" \
      --request GET)
  fi

  QRCODE=$(jq -r '.acii' <<< "$GET_QRCODE")

  # echo
  if [[ $1 =~ $re ]] || [[ $1 == "" ]] ; then
  echo "======================="
  echo "      DEPOSIT NANO     "
  echo "======================="
  else
  echo "======================="
  echo "        SEND NANO      "
  echo "======================="
  fi

  if [[ $1 =~ $re ]] || [[ $2 =~ $re ]] ; then
    echo "AMOUNT: $1 NANO"
    #statements
  fi
  echo "ADDRESS: $address"
  # if [[ "$4" != "--no-account" ]] && [[ "$5" != "--no-account" ]]; then
  # echo "USERNAME: $account"
  # fi
  echo "======================="
  if [[ "$2" != "--no-qr" ]] && [[ "$3" != "--no-qr" ]]; then
    cat <<EOF
$QRCODE
EOF
  fi

  exit 0
}

