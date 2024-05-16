

# ██████╗ ██████╗ ██╗ ██████╗███████╗
# ██╔══██╗██╔══██╗██║██╔════╝██╔════╝
# ██████╔╝██████╔╝██║██║     █████╗  
# ██╔═══╝ ██╔══██╗██║██║     ██╔══╝  
# ██║     ██║  ██║██║╚██████╗███████╗
# ╚═╝     ╚═╝  ╚═╝╚═╝ ╚═════╝╚══════╝                                  

if [ "$1" = "price" ] || [ "$1" = "--price" ] || [ "$1" = "-price" ] || [ "$1" = "p" ] || [ "$1" = "-p" ]; then

    if [[ -z "$2" ]]; then
        FIAT='usd'
    else  
        FIAT=$2
    fi

    if [[ $(cat $DIR/.xno/price-url 2>/dev/null) == "" ]]; then
        PRICE_URL="https://api.coingecko.com/api/v3/simple/price?ids=nano&vs_currencies="
        echo $PRICE_URL > $DIR/.xno/price-url
    else
        PRICE_URL=$(cat $DIR/.xno/price-url)
    fi

    PRICE=$(curl -s "$PRICE_URL"$FIAT \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request GET)

    echo $(jq -r '.nano' <<< "$PRICE")

    exit 0

fi

