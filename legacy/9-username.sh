
# ██╗    ██╗██╗  ██╗ ██████╗ ██╗███████╗
# ██║    ██║██║  ██║██╔═══██╗██║██╔════╝
# ██║ █╗ ██║███████║██║   ██║██║███████╗
# ██║███╗██║██╔══██║██║   ██║██║╚════██║
# ╚███╔███╔╝██║  ██║╚██████╔╝██║███████║
#  ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝╚══════╝                                                                  

if [ "$1" = "username" ] || [ "$1" = "lookup" ] || [ "$1" = "find" ] || [ "$1" = "whois" ] || [ "$1" = "search" ] || [ "$1" = "name" ] || [ "$1" = "-w" ] || [ "$1" = "-f" ]; then

    if [[ $2 == "" ]] || [[ "$3" == "--help" ]] ; then
cat <<EOF
Usage:
  $ n2 $1 @fosse
  $ n2 $1 @moon --json
  $ n2 $1 @moon --claim
  $ n2 $1 @moon --set website "James"
  $ n2 $1 @moon --set name "James"
EOF
        exit 0
    fi

    ACCOUNT=$(curl -s "https://nano.to/cloud/account" \
        -H "Accept: application/json" \
        -H "session: $(cat $DIR/.n2/session)" \
        -H "Content-Type:application/json" \
        --request GET)

    if [[ $(jq -r '.code' <<< "$ACCOUNT") == "401" ]]; then
        rm $DIR/.n2/session
        # echo
        echo "==============================="
        echo "    LOGGED OUT FOR SECURITY    "
        echo "==============================="
        echo "Use 'n2 login' to log back in. "
        echo "==============================="
        echo
        exit 0
    fi

    if [[ "$3" == "qrcode" ]] || [[ "$3" == "--qrcode" ]] || [[ "$3" == "qr" ]] || [[ "$3" == "-qr" ]] || [[ "$3" == "--qr" ]]; then
        OACCOUNT=$(curl -s "https://nano.to/$2/account" \
        -H "Accept: application/json" \
        -H "session: $(cat $DIR/.n2/session)" \
        -H "Content-Type:application/json" \
        --request GET)
        address=$(jq -r '.address' <<< "$OACCOUNT")
        username=$(jq -r '.username' <<< "$OACCOUNT")
        echo "==========================================="
        echo "                  @$username               "
        echo "==========================================="
        echo "ADDRESS: ${CYAN}$address${NC}"
        echo "BROWSER: https://nanolooker.com/account/"$address
        echo "==========================================="
        GET_QRCODE=$(curl -s "https://nano.to/cloud/qrcode?address=$address" \
        -H "Accept: application/json" \
        -H "session: $(cat $DIR/.n2/session)" \
        -H "Content-Type:application/json" \
        --request GET)
        QRCODE=$(jq -r '.acii' <<< "$GET_QRCODE")
        cat <<EOF
$QRCODE
EOF
        echo "==========================================="
        exit
    fi

    if [[ "$3" == "url" ]] || [[ "$3" == "--url" ]] || [[ "$3" == "--website" ]] || [[ "$3" == "-u" ]] || [[ "$3" == "link" ]] ; then
        echo "==============================="
        echo "      STATIC WEBSITE URLS      "
        echo "==============================="
        echo "https://nano.to/$2"
        echo "https://xno.to/$2"
        echo "https://ӿ.to/$2"
        echo "==============================="
        exit 0
    fi

    if [[ "$3" == "--claim" ]] || [[ "$3" == "claim" ]] || [[ "$3" == "--verify" ]]  || [[ "$3" == "verify" ]]; then
        if [[ "$4" == "--check" ]]; then
            CHECK_CLAIM=$(curl -s "https://nano.to/cloud/verify?username=$2" \
            -H "Accept: application/json" \
            -H "session: $(cat $DIR/.n2/session)" \
            -H "Content-Type:application/json" \
            --request POST)
            echo $CHECK_CLAIM
            exit 0
        fi
    CLAIM_WHOIS=$(curl -s "https://nano.to/$2/account" \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request GET)
    ACCOUNT=$(curl -s "https://nano.to/cloud/account" \
    -H "Accept: application/json" \
    -H "session: $(cat $DIR/.n2/session)" \
    -H "Content-Type:application/json" \
    --request GET)

    AMOUNT_RAW_CONSP=$(curl -s "https://nano.to/cloud/convert/toRaw/1.133" \
    -H "Accept: application/json" \
    -H "session: $(cat $DIR/.n2/session)" \
    -H "Content-Type:application/json" \
    --request GET)

        echo "==============================="
        echo "   VERIFY USERNAME OWNERSHIP   "
        echo "==============================="
        echo "${RED}Allows Username usage via N2.${NC}"
        echo "${RED}Username Address is NOT changed.${NC}"
        echo "--------------------------------"
        echo "${GREEN}SEND: Ӿ 1.133"
        echo "FROM: "$(jq -r '.address' <<< $CLAIM_WHOIS)
        echo "TO: "$(jq -r '.address' <<< $ACCOUNT)${NC}
        echo "--------------------------------"
        echo "${CYAN}QRCODE: https://chart.googleapis.com/chart?cht=qr&chs=300x300&chl=nano:$(jq -r '.address' <<< $ACCOUNT)?amount=$(jq -r '.value' <<< "$AMOUNT_RAW_CONSP")"${NC}
        # echo "DLINK: nano:$(jq -r '.address' <<< $ACCOUNT)?amount=$(jq -r '.value' <<< "$AMOUNT_RAW_CONSP")"
        echo "--------------------------------"
        echo "NEXT: n2 $1 $2 $3 --check"
        echo "==============================="
        exit 0
    fi

    if [[ "$3" == "--data" ]] || [[ "$3" == "--lease" ]] || [[ "$3" == "lease" ]]  || [[ "$3" == "expires" ]] || [[ "$3" == "--exp" ]] ; then
        LEASE_INFO=$(curl -s "https://nano.to/$2/username" \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request GET)
        # echo $LEASE_INFO
        echo "==============================="
        echo "      USERNAME LEASE DATA      "
        echo "==============================="
        echo "USERNAME: @"$(jq -r '.namespace' <<< $LEASE_INFO)
        echo "ADDRESS: @"$(jq -r '.address' <<< $LEASE_INFO)
        echo "CREATED: @"$(jq -r '.created' <<< $LEASE_INFO)
        echo "EXPIRES: @"$(jq -r '.expires' <<< $LEASE_INFO)
        # echo "CHECKOUT: " $(jq -r '.checkout' <<< $CHECKOUT)
        # echo "MORE_INFO: https://docs.nano.to/username-api"
        
        exit 0
    fi

    WHOIS=$(curl -s "https://nano.to/$2/account" \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request GET)

    if [[ "$3" == "-c" ]] || [[ "$3" == "--config" ]] || [[ "$3" == "--set" ]] || [[ "$3" == "config" ]] || [[ "$3" == "set" ]] ; then

        # echo "\$2, $2"
        # echo "\$3, $3"
        # echo "\$4, $4"
        # echo "\$5, $5"

        # exit 0

        if [[ $4 == '--git' ]] || [[ $4 == '--github' ]] || [[ $4 == 'git' ]] || [[ $4 == 'github' ]] || [[ $4 == '-g' ]]; then
            
            ESD=$(curl -s "https://nano.to/cloud/username/$2" \
            -H "Accept: application/json" \
            -H "session: $(cat $DIR/.n2/session)" \
            -H "Content-Type:application/json" \
            --request POST \
            --data @<(cat <<EOF
{ "github": "$5" }
EOF
            ))

            # echo $ESD

        if [[ $(jq -r '.error' <<< "$ESD") == '429' ]]; then
            #statements
            echo "${RED}Error${NC}: $(jq -r '.message' <<< "$ESD")"
            exit 0
        fi

        # echo "${GREEN}Cloud${NC}: Github website updated."
        echo "==============================="
        echo "        ${GREEN}UPDATED${NC}      "
        echo "==============================="
        echo "https://xno.to/$2"
        echo "https://ӿ.to/$2"
        echo "==============================="
            exit 0
        fi

        if [[ $4 == '--website' ]] || [[ $4 == 'website' ]]; then


            if [[ $5 == '--git' ]] || [[ $5 == '--github' ]] || [[ $5 == 'git' ]] || [[ $5 == 'github' ]] || [[ $5 == '-g' ]]; then
                ESD=$(curl -s "https://nano.to/cloud/username/$2" \
                -H "Accept: application/json" \
                -H "session: $(cat $DIR/.n2/session)" \
                -H "Content-Type:application/json" \
                --request POST \
                --data @<(cat <<EOF
{ "github": "$6" }
EOF
                ))
                echo "${GREEN}Cloud${NC}: Website removed."
                exit 0
            fi

            if [[ $5 == 'remove' ]] || [[ $5 == '--remove' ]]; then
                ESD=$(curl -s "https://nano.to/cloud/username/$2" \
                -H "Accept: application/json" \
                -H "session: $(cat $DIR/.n2/session)" \
                -H "Content-Type:application/json" \
                --request POST \
                --data '{ "remove_website": "true" }')
                echo "${GREEN}Cloud${NC}: Website removed."
                exit 0
            fi

            if [[ $5 == 'file' ]] || [[ $5 == '--file' ]]; then
                # CONTENT=$()
                # echo $CONTENT
                EFD=$(curl -s "https://nano.to/cloud/username/$2" \
                -H "Accept: application/json" \
                -H "session: $(cat $DIR/.n2/session)" \
                -H "Content-Type:application/json" \
                --request POST \
                --data @<(cat <<EOF
{ "website": "BASE64:$(cat $6 | base64)" }
EOF
                ))
                # echo $(cat $6)
                echo "${GREEN}Cloud${NC}: Website uploaded."
                echo "BROWSER: https://xno.to/$2"
                exit 0
            fi

            # if [[ $5 == 'file' ]] || [[ $5 == '--file' ]]; then
                # CONTENT=$()
                # echo $CONTENT
                EFD=$(curl -s "https://nano.to/cloud/username/$2" \
                -H "Accept: application/json" \
                -H "session: $(cat $DIR/.n2/session)" \
                -H "Content-Type:application/json" \
                --request POST \
                --data @<(cat <<EOF
{ "website": "$5" }
EOF
                ))
            # echo $(cat $6)
            echo "==============================="
            echo "${GREEN}Cloud${NC}: Website uploaded."
            echo "==============================="
            echo "URL: https://xno.to/$2"
            echo "==============================="
            exit 0
            # fi


            exit 

        fi

        ODF=$(curl -s "https://nano.to/cloud/username/$2" \
-H "Accept: application/json" \
-H "session: $(cat $DIR/.n2/session)" \
-H "Content-Type:application/json" \
--request POST \
--data @<(cat <<EOF
{ "$4": "$5" }
EOF
))  
        if [[ $(jq -r '.error' <<< "$ODF") == '404' ]]; then
            #statements
            echo "${CYAN}Cloud${NC}: $(jq -r '.message' <<< "$ODF")"
            exit 0
        fi

        # echo "$ODF"

        echo "${GREEN}Cloud${NC}: Config updated."
        exit 0
    fi

    if [[ $3 == "--prices" ]] || [[ $3 == "--price" ]]; then
        PRICE_CHECK=$(curl -s "https://nano.to/lease/$2" \
        -H "Accept: application/json" \
        -H "session: $(cat $DIR/.n2/session)" \
        -H "Content-Type:application/json" \
        --request GET)
        PLANS=$(jq -r '.plans' <<< "$PRICE_CHECK")
   echo "======================================="
   echo "USERNAME: @"$2
   echo "======================================="
        for row in $(echo "${PLANS}" | jq -r '.[] | @base64'); do
            _jq() {
             echo ${row} | base64 --decode | jq -r ${1}
            }
           echo "$(_jq '.name') ---------------- Ӿ $(_jq '.amount') "
           # echo $(_jq '.amount')
        done
   echo "======================================="
   # echo "TIP: Use "
   # echo "======================================="
        exit 0
    fi

    if [[ $(jq -r '.error' <<< "$WHOIS") == "Username not registered." ]]; then

        if [[ "$2" == "--json" ]] || [[ "$3" == "--json" ]] || [[ "$4" == "--json" ]] || [[ "$5" == "--json" ]] || [[ "$6" == "--json" ]]; then
            echo $WHOIS
            exit 0
        fi
        

        if [[ "$3" == "buy" ]] || [[ "$3" == "lease" ]] || [[ "$3" == "purchase" ]]  || [[ "$3" == "--buy" ]] || [[ "$3" == "--purchase" ]]|| [[ "$3" == "--lease" ]] ; then
            
            if [[ $4 == "" ]]; then
                echo "${CYAN}Cloud${NC}: Missing duration."
cat <<EOF
Usage:
  $ n2 $1 $2 $3 --day
  $ n2 $1 $2 $3 --month
  $ n2 $1 $2 $3 --year
  $ n2 $1 $2 $3 --decade
EOF
                exit 0
            fi
        
   echo "======================================="
   echo "              NEW LEASE                "
   echo "======================================="
   echo "USERNAME: "$2
   echo "======================================="
     read -p "${GREEN}Cloud${NC}: Set Nano Address (Default: Cloud): " ADDRESS_GIVEN

        # read -p "${GREEN}Cloud${NC}: Are you sure you want to lease '@$2' for a '$4'. Funds are payed from Cloud Wallet on Nano.to. Enter 'y' to continue:" SANITY_CHECK

        # if [[ $SANITY_CHECK != 'y' ]] && [[ $SANITY_CHECK != 'Y' ]]; then
        #   echo "Canceled."
        #   exit 0
        # fi

            # /usr/local/bin/n2 version
        ACCOUNT=$(curl -s "https://nano.to/cloud/account" \
        -H "Accept: application/json" \
        -H "session: $(cat $DIR/.n2/session)" \
        -H "Content-Type:application/json" \
        --request GET)

        POW=$(curl -s "https://nano.to/$(jq -r '.frontier' <<< "$ACCOUNT")/pow" \
            -H "Accept: application/json" \
            -H "Content-Type:application/json" \
            --request GET)

        # echo $POW

        # exit 0

        if [[ $(jq -r '.error' <<< "$POW") == "429" ]]; then
            echo
            echo "==============================="
            echo "       USED ALL CREDITS        "
            echo "==============================="
            echo "  Use 'n2 buy pow' or wait.    "
            echo "==============================="
            echo
            return
        fi

        WORK=$(jq -r '.work' <<< "$POW")

        # CHECKOUT=$(curl -s "https://nano.to/cloud/lease/$2/$4?work=$WORK" \
        #   -H "Accept: application/json" \
        #   -H "session: $(cat $DIR/.n2/session)" \
        #   -H "Content-Type:application/json" \
        #   --request GET)

        LEASE_ATTEMPT=$(curl -s "https://nano.to/cloud/lease/$2" \
        -H "Accept: application/json" \
    -H "session: $(cat $DIR/.n2/session)" \
        -H "Content-Type:application/json" \
        --request POST \
        --data @<(cat <<EOF
    { "duration": "$4", "address": "$ADDRESS_GIVEN" }
EOF
        ))

            if [[ "$4" == "--json" ]] || [[ "$5" == "--json" ]] || [[ "$6" == "--json" ]] || [[ "$7" == "--json" ]] || [[ "$8" == "--json" ]]; then
                # echo $WHOIS
                echo $LEASE_ATTEMPT
                exit 0
            fi

            if [[ $(jq -r '.error' <<< "$LEASE_ATTEMPT") == "400" ]]; then
                # RMESSAGE=
                echo "${CYAN}Cloud${NC}: $(jq -r '.message' <<< "$LEASE_ATTEMPT")"
                exit 0
            fi

            echo "${GREEN}Cloud${NC}: Username Purchased."

            exit 0
        fi

        echo "==============================="
        echo "${GREEN}      USERNAME AVAILABLE ${NC}"
        echo "==============================="
        echo "USERNAME: @"$(jq -r '.username' <<< $CHECKOUT)
        echo "CHECKOUT: " $(jq -r '.checkout' <<< $CHECKOUT)
        echo "MORE_INFO: https://docs.nano.to/username-api"
        
        exit 0

    fi

    # echo $CHECKOUT

    if [[ "$3" == "buy" ]] || [[ "$3" == "lease" ]] || [[ "$3" == "purchase" ]]  || [[ "$3" == "--buy" ]] || [[ "$3" == "--purchase" ]]|| [[ "$3" == "--lease" ]] ; then
        echo "${CYAN}Cloud${NC}: This domain is taken."
        exit 0
    fi


    if [[ "$2" == "--json" ]] || [[ "$3" == "--json" ]] || [[ "$4" == "--json" ]] || [[ "$5" == "--json" ]] || [[ "$6" == "--json" ]]; then
        echo $WHOIS
        exit 0
    fi

    WALLETS=$(jq -r '.accounts' <<< "$WHOIS")

    # echo
    echo "==============================="
    echo "          NANO LOOKUP          "
    echo "==============================="
    # echo "USERNAME: "$2
    echo "USERNAME: @"$(jq -r '.username' <<< $WHOIS) 
    # echo "BALANCE: "$(jq -r '.balance' <<< $WHOIS)
    echo "ADDRESS: "$(jq -r '.address' <<< $WHOIS)
    echo "HEIGHT: "$(jq -r '.height' <<< $WHOIS)
    echo "BROWSER: https://nanolooker.com/account/"$(jq -r '.address' <<< $WHOIS)
    echo "==============================="

    exit 0

fi





#  ██████╗██╗  ██╗███████╗ ██████╗██╗  ██╗ ██████╗ ██╗   ██╗████████╗
# ██╔════╝██║  ██║██╔════╝██╔════╝██║ ██╔╝██╔═══██╗██║   ██║╚══██╔══╝
# ██║     ███████║█████╗  ██║     █████╔╝ ██║   ██║██║   ██║   ██║   
# ██║     ██╔══██║██╔══╝  ██║     ██╔═██╗ ██║   ██║██║   ██║   ██║   
# ╚██████╗██║  ██║███████╗╚██████╗██║  ██╗╚██████╔╝╚██████╔╝   ██║   
#  ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝ ╚═════╝  ╚═════╝    ╚═╝                                                                 

if [ "$1" = "checkout" ] || [ "$1" = "--checkout" ] || [ "$1" = "-checkout" ] || [ "$1" = "c" ] || [ "$1" = "-c" ]; then


    if [[ $2 == "" ]]; then
        # read -p 'To (@Username or Address): ' $2
        echo "${CYAN}Cloud${NC}: Username, or Address missing."
cat <<EOF
Usage:
  $ n2 $1 @fosse 10
  $ n2 $1 @kraken 12.50 --json
EOF
        exit 0
    fi

    if [[ $3 == "" ]]; then
        echo "${CYAN}Cloud${NC}: Amount missing."
cat <<EOF
Usage:
  $ n2 $1 @fosse 10
  $ n2 $1 @kraken 12.50 --json
EOF
        exit 0
    fi

    CHECKOUT=$(curl -s "https://nano.to/$2?cli=$3" \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request GET | jq -r '.qrcode')

    echo 

cat <<EOF
$CHECKOUT
EOF

    echo 

    exit 0

fi


#  █████╗ ██████╗ ██╗    ██╗  ██╗███████╗██╗   ██╗
# ██╔══██╗██╔══██╗██║    ██║ ██╔╝██╔════╝╚██╗ ██╔╝
# ███████║██████╔╝██║    █████╔╝ █████╗   ╚████╔╝ 
# ██╔══██║██╔═══╝ ██║    ██╔═██╗ ██╔══╝    ╚██╔╝  
# ██║  ██║██║     ██║    ██║  ██╗███████╗   ██║   
# ╚═╝  ╚═╝╚═╝     ╚═╝    ╚═╝  ╚═╝╚══════╝   ╚═╝                                       

if [[ "$1" = "key" ]] || [[ "$1" = "k" ]] || [[ "$1" = "-key" ]] || [[ "$1" = "-api" ]] || [[ "$1" = "--api" ]] || [[ "$2" = "-k" ]]; then

    if [[ $(cat $DIR/.n2/session 2>/dev/null) == "" ]]; then
        echo "${CYAN}Cloud${NC}: You're not logged in. Use 'n2 login' or 'n2 register' first."
        exit 0
    fi

    ACCOUNT=$(curl -s "https://nano.to/cloud/account" \
    -H "Accept: application/json" \
    -H "session: $(cat $DIR/.n2/session)" \
    -H "Content-Type:application/json" \
    --request GET)

    # echo $ACCOUNT

    echo "==============================="
    echo "         CLI API KEY           "
    echo "==============================="
    echo "==============================="
    echo "Docs: https://docs.nano.to/pow "
    echo "==============================="

    # echo $(jq -r '.api_key' <<< "$ACCOUNT")

    exit 0

fi


#  █████╗ ██████╗ ██████╗ ██████╗ ███████╗███████╗███████╗
# ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝
# ███████║██║  ██║██║  ██║██████╔╝█████╗  ███████╗███████╗
# ██╔══██║██║  ██║██║  ██║██╔══██╗██╔══╝  ╚════██║╚════██║
# ██║  ██║██████╔╝██████╔╝██║  ██║███████╗███████║███████║
# ╚═╝  ╚═╝╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝                                                        

if [[ "$2" = "address" ]] || [[ "$2" = "-address" ]] || [[ "$2" = "--address" ]] || [[ "$2" = "-a" ]]; then

    if [[ $(cat $DIR/.n2/session 2>/dev/null) == "" ]]; then
        echo "${CYAN}Cloud${NC}: You're not logged in. Use 'n2 login' or 'n2 register' first."
        exit 0
    fi

    ACCOUNT=$(curl -s "https://nano.to/cloud/account" \
    -H "Accept: application/json" \
    -H "session: $(cat $DIR/.n2/session)" \
    -H "Content-Type:application/json" \
    --request GET)

    echo $(jq -r '.address' <<< "$ACCOUNT")

    exit 0

fi


# ██╗      ██████╗  ██████╗  ██████╗ ██╗   ██╗████████╗
# ██║     ██╔═══██╗██╔════╝ ██╔═══██╗██║   ██║╚══██╔══╝
# ██║     ██║   ██║██║  ███╗██║   ██║██║   ██║   ██║   
# ██║     ██║   ██║██║   ██║██║   ██║██║   ██║   ██║   
# ███████╗╚██████╔╝╚██████╔╝╚██████╔╝╚██████╔╝   ██║   
# ╚══════╝ ╚═════╝  ╚═════╝  ╚═════╝  ╚═════╝    ╚═╝   
                                                     

if [[ "$1" = "logout" ]]; then
    if [[ $(cat $DIR/.n2/session 2>/dev/null) == "" ]]; then
        echo "${CYAN}Cloud${NC}: You're not logged in. Use 'n2 login' or 'n2 register'."
        exit 0
    else
        rm $DIR/.n2/session 2> /dev/null
        # echo "Ok:  of Nano.to."
        echo "${GREEN}Cloud${NC}: You logged out."
        exit 0
    fi
fi



# ███████╗███╗   ███╗ █████╗ ██╗██╗     
# ██╔════╝████╗ ████║██╔══██╗██║██║     
# █████╗  ██╔████╔██║███████║██║██║     
# ██╔══╝  ██║╚██╔╝██║██╔══██║██║██║     
# ███████╗██║ ╚═╝ ██║██║  ██║██║███████╗
# ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚══════╝                          

if [[ "$2" = "email" ]] || [[ "$2" = "-email" ]] || [[ "$2" = "--email" ]] || [[ "$2" = "-e" ]]; then

    if [[ $(cat $DIR/.n2/session 2>/dev/null) == "" ]]; then
        echo "${CYAN}Cloud${NC}: You're not logged in. Use 'n2 login' or 'n2 register' first."
        exit 0
    fi

    ACCOUNT=$(curl -s "https://nano.to/cloud/account" \
    -H "Accept: application/json" \
    -H "session: $(cat $DIR/.n2/session)" \
    -H "Content-Type:application/json" \
    --request GET)

    echo $(jq -r '.username' <<< "$ACCOUNT")

    exit 0

fi

