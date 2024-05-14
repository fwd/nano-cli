                                          
if [[ $1 == "purchase" ]] || [[ $1 == "store" ]] || [[ $1 == "buy" ]] || [[ $1 == "add" ]] || [[ $1 == "shop" ]] || [[ $1 == "--store" ]] || [[ $1 == "--shop" ]] || [[ $1 == "-s" ]]; then

    if [[ $2 == "" ]]; then
cat <<EOF

███████╗██╗  ██╗ ██████╗ ██████╗ 
██╔════╝██║  ██║██╔═══██╗██╔══██╗
███████╗███████║██║   ██║██████╔╝
╚════██║██╔══██║██║   ██║██╔═══╝ 
███████║██║  ██║╚██████╔╝██║     
╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝                                                  
EOF

        echo "================================="
        echo "          NANO.TO SHOP           "
        echo "================================="
        # echo "address ------------------- Ӿ 0.1"
        echo "pow ---------------------- Ӿ 0.01"
        echo "================================="
        echo "Usage: 'n2 shop [name] [amount]'"
        echo "================================="

        echo 

        exit 0
    fi

    # if [[ $2 == "address" ]] || [[ $2 == "addresses" ]] || [[ $2 == "wallets" ]] || [[ $2 == "accounts" ]]; then
    #   echo "================================="
    #   echo "       UNDER CONSTRUCTION        "
    #   echo "================================="
    #   echo "Yeah, I bet you want multiple addresses with a single account. Imagine all the things you can build. Tweet @nano2dev and remind me to get it done."
    #   echo "================================="
    #   echo "https://twitter.com/nano2dev"
    #   echo "================================="
    #   exit 0
    # fi

    if [[ $2 == "address" ]] || [[ $2 == "addresses" ]] || [[ $2 == "wallets" ]] || [[ $2 == "accounts" ]]; then
        if [[ $3 == "" ]]; then
            echo "Missing amount to purchase. Usage: 'n2 add address 2'"
            exit 0
        fi
curl -s "https://nano.to/cloud/shop/address" \
    -H "Accept: application/json" \
    -H "session: $(cat $DIR/.n2/session)" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
{ "amount": "$3" }
EOF
    )
        echo
        exit 0
    fi

    if [[ $2 == "pow" ]]; then
        if [[ $3 == "" ]]; then
            echo "Missing amount to purchase. Usage: 'n2 add pow 5'"
            exit 0
        fi
curl -s "https://nano.to/cloud/shop/pow" \
    -H "Accept: application/json" \
    -H "session: $(cat $DIR/.n2/session)" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
{ "amount": "$3" }
EOF
    )
        echo
        exit 0
    fi

    echo "We don't sell that. Use 'n2 shop' to see list."

    exit 0

fi


