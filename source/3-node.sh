
# Sorta working
if [[ "$1" = "vanity" ]]; then

    if [[ ! -f "$DIR/.cargo/bin/nano-vanity" ]]; then

        INSTALL_NOTE=$(cat <<EOF
==================================
    ${GREEN}@PlasmaPower/Nano-Vanity${NC}
==================================
Press 'Y' to install:
EOF
)
        read -p "$INSTALL_NOTE " YES
    
        # read -p ' not installed. Enter 'Y' to install: ' YES

        if [[ "$YES" = "y" ]] || [[ "$YES" = "Y" ]]; then

            if ! [ -x "$(command -v cargo)" ]; then
                sudo apt install ocl-icd-opencl-dev gcc make build-essential -y
                curl https://sh.rustup.rs -sSf | sh
                source $DIR/.cargo/env
            fi
            
            # cargo install nano-vanity
            git clone https://github.com/PlasmaPower/nano-vanity.git
            cargo install --path .
            rm -rf nano-vanity

            echo "=============================="
            echo "Done. You may need to restart SSH session."
            echo "=============================="

        else 
            echo "Canceled"
            exit 0
        fi

    fi

    if [[ -z "$2" ]]; then
        echo "${RED}Error:${NC} Missing Vanity Phrase."
        exit 0
    fi

    VANITY_PATH="$DIR/.cargo/bin/nano-vanity"

    if [[ "$3" == "--json" ]] || [[ "$4" == "--json" ]]; then

        GPU_INSTALLED=$(lspci -vnnn | perl -lne 'print if /^\d+\:.+(\[\S+\:\S+\])/' | grep VGA)

        if [[ $GPU_INSTALLED == *"paravirtual"* ]]; then
            THREAD_COUNT=$(grep ^cpu\\scores /proc/cpuinfo | uniq |  awk '{print $4}')
            USE_THREAD_COUNT=$(awk "BEGIN {print ($THREAD_COUNT - 1) }")
            VANITY_ADDRESS=$($VANITY_PATH $2 --no-progress --threads $USE_THREAD_COUNT --simple-output)
        else 
            VANITY_ADDRESS=$($VANITY_PATH $2 --no-progress --gpu-device 0 --gpu-platform 0 --simple-output)
        fi

        VANITY_ADDRESS_ARRAY=($VANITY_ADDRESS)

        if [[ ${VANITY_ADDRESS_ARRAY[1]} == *"nano_"* ]]; then
            VANITY_JSON="{ \"public\": \"${VANITY_ADDRESS_ARRAY[1]}\", \"private\": \"${VANITY_ADDRESS_ARRAY[0]}\"  }"
            echo $VANITY_JSON
        else
            echo "{ \"error\": \"$VANITY_PATH $2 --no-progress --threads $USE_THREAD_COUNT --simple-output\"  }"
        fi

    else 

        if [[ $GPU_INSTALLED == *"paravirtual"* ]]; then
            THREAD_COUNT=$(grep ^cpu\\scores /proc/cpuinfo | uniq |  awk '{print $4}')
            USE_THREAD_COUNT=$(awk "BEGIN {print ($THREAD_COUNT - 1) }")
            VANITY_ADDRESS=$($VANITY_PATH $2 --threads $USE_THREAD_COUNT)
        else 
            VANITY_ADDRESS=$($VANITY_PATH $2 --gpu-device 0 --gpu-platform 0)
        fi

        echo $VANITY_ADDRESS

    fi

    exit 0

fi

if [[ "$1" = "pow" ]]; then

    if [[ -z "$2" ]]; then
        echo "${RED}Error:${NC} Missing second paramerter. Fronteir Hash."
        exit 0
    fi

    if [[ $(cat $DIR/.xno/node 2>/dev/null) == "" ]]; then
        NODE_URL='[::1]:7076'
        echo $NODE_URL > $DIR/.xno/node
    else
        NODE_URL=$(cat $DIR/.xno/node)
    fi

    POW_ATTEMPT=$(curl -s $NODE_URL \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
{
    "action": "work_generate",
    "hash": "$2",
    "use_peers": "true"
}
EOF
  ))

    echo $POW_ATTEMPT
    
    exit 0

fi


if [[ "$1" = "receive" ]]; then

    if [[ $(cat $DIR/.xno/node 2>/dev/null) == "" ]]; then
        NODE_URL='[::1]:7076'
        echo $NODE_URL > $DIR/.xno/node
    else
        NODE_URL=$(cat $DIR/.xno/node)
    fi

    if curl -sL --fail $NODE_URL -o /dev/null; then
        echo -n ""
    else
        echo "${RED}Error:${NC} ${CYAN}Node offline.${NC} Use 'xno setup' for more information."
        exit 0
    fi

    # if [[ $(cat $DIR/.xno/path 2>/dev/null) == "" ]]; then
    #   echo "${RED}Error:${NC} ${CYAN}Node Path not setup.${NC} Use 'xno config path PATH'."
    #   exit 0
    # else
    #   NODE_PATH=$(cat $DIR/.xno/path)
    # fi

    if [[ $(cat $DIR/.xno/wallet 2>/dev/null) == "" ]]; then
        WALLET_ID=$(docker exec -it nano-node /usr/bin/nano_node --wallet_list | grep 'Wallet ID' | awk '{ print $NF}' | tr -d '[:space:]' )
        echo $WALLET_ID > $DIR/.xno/wallet
    else
        WALLET_ID=$(cat $DIR/.xno/wallet)
    fi

    accounts_on_file=$(get_accounts)

    if [[ -z "$2" ]]; then
        ACCOUNT_INDEX="0"
    else
        ACCOUNT_INDEX=$(expr $2 - 1)
    fi

    ACCOUNT=$(jq ".accounts[$ACCOUNT_INDEX]" <<< "$accounts_on_file" | tr -d '"') 

    RECEIVE_RPC=$(curl -s $NODE_URL \
    -H "Accept: application/json" \
    -H "Content-Type:application/json" \
    --request POST \
    --data @<(cat <<EOF
{
  "action": "receivable",
  "account": "$ACCOUNT",
  "count": "100"
}
EOF
  ))

#     RECEIVE_RPC=$(curl -s $NODE_URL \
#     -H "Accept: application/json" \
#     -H "Content-Type:application/json" \
#     --request POST \
#     --data @<(cat <<EOF
# {
#   "action": "receive",
#   "wallet": "$WALLET_ID",
#   "account": "$ACCOUNT",
#   "block": "1A6E00F7F68EA08236A00EC30E1B4C2DFDB5DD74FF6C6E59FE46D8DFF2DA6A11"
# }
# EOF
#   ))

   echo $RECEIVE_RPC

    exit 0

fi


if [[ "$1" = "node" ]]; then

    if [[ $(cat $DIR/.xno/node 2>/dev/null) == "" ]]; then
         NODE_URL='[::1]:7076'
        echo $NODE_URL > $DIR/.xno/node
    else
        NODE_URL=$(cat $DIR/.xno/node)
    fi

    if curl -sL --fail $NODE_URL -o /dev/null; then
        echo -n ""
    else
        echo "${RED}Error:${NC} ${CYAN}Node offline.${NC} Use 'xno setup' for more information."
        exit 0
    fi

    if [[ $(cat $DIR/.xno/path 2>/dev/null) == "" ]]; then
      echo "${RED}Error:${NC} ${CYAN}Node Path not setup.${NC} Use 'xno config path PATH'."
      exit 0
    else
      NODE_PATH=$(cat $DIR/.xno/path)
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

   echo $NODE_VERSION

  exit 0

fi


if [[ "$1" = "block_count" ]] || [[ "$1" = "count" ]] || [[ "$1" = "blocks" ]]; then

    if [[ $(cat $DIR/.xno/node 2>/dev/null) == "" ]]; then
         NODE_URL='[::1]:7076'
        echo $NODE_URL > $DIR/.xno/node
    else
        NODE_URL=$(cat $DIR/.xno/node)
    fi

    if curl -sL --fail $NODE_URL -o /dev/null; then
        echo -n ""
    else
        echo "${RED}Error:${NC} ${CYAN}Node offline.${NC} Use 'xno setup' for more information."
        exit 0
    fi

    if [[ $(cat $DIR/.xno/path 2>/dev/null) == "" ]]; then
      echo "${RED}Error:${NC} ${CYAN}Node Path not setup.${NC} Use 'xno config path PATH'."
      exit 0
    else
      NODE_PATH=$(cat $DIR/.xno/path)
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

  echo $NODE_SYNC

  exit 0

fi

if [[ "$1" = "sync" ]] || [[ "$1" = "status" ]]; then

    if [[ $(cat $DIR/.xno/node 2>/dev/null) == "" ]]; then
         NODE_URL='[::1]:7076'
        echo $NODE_URL > $DIR/.xno/node
    else
        NODE_URL=$(cat $DIR/.xno/node)
    fi


    if curl -sL --fail $NODE_URL -o /dev/null; then
        echo -n ""
    else
        if [[ "$2" = "--text" ]]; then
            echo "off"
        else
            echo "${RED}Error:${NC} ${CYAN}Node offline.${NC} Use 'xno setup' for more information."
        fi
        exit 0
    fi

    if [[ $(cat $DIR/.xno/path 2>/dev/null) == "" ]]; then
      echo "${RED}Error:${NC} ${CYAN}Node Path not setup.${NC} Use 'xno config path PATH'."
      exit 0
    else
      NODE_PATH=$(cat $DIR/.xno/path)
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

  echo "{ \"sync\": \"$SYNC_PERCENT%\", \"block_count\": \"$NODE_BLOCK_COUNT\", \"unchecked\": \"$NODE_BLOCK_UNCHECKED\", \"cemented\": \"$NODE_BLOCK_CEMENTED\" }"

  exit 0

fi

if [[ "$1" = "node" ]] && [[ "$2" = "start" ]] || [[ "$1" = "start" ]] || [[ "$1" = "up" ]]; then
    
    if [[ $(cat $DIR/.xno/path 2>/dev/null) == "" ]]; then
      echo "${RED}Error:${NC} ${CYAN}Node Path not setup.${NC} Use 'xno config path PATH'."
      exit 0
    else
      NODE_PATH=$(cat $DIR/.xno/path)
    fi

    cd $NODE_PATH && docker-compose start nano-node > /dev/null

    exit 0

fi

if [[ "$1" = "unlock" ]]; then
    
    if [[ $(cat $DIR/.xno/path 2>/dev/null) == "" ]]; then
      echo "${RED}Error:${NC} ${CYAN}Node Path not setup.${NC} Use 'xno config path PATH'."
      exit 0
    else
      NODE_PATH=$(cat $DIR/.xno/path)
    fi

    sed -i 's/enable_control = false/enable_control = true/g' "$NODE_PATH/nano-node/Nano/config-rpc.toml"

    exit 0

fi

if [[ "$1" = "lock" ]]; then
    
    if [[ $(cat $DIR/.xno/path 2>/dev/null) == "" ]]; then
      echo "${RED}Error:${NC} ${CYAN}Node Path not setup.${NC} Use 'xno config path PATH'."
      exit 0
    else
      NODE_PATH=$(cat $DIR/.xno/path)
    fi

    sed -i 's/enable_control = true/enable_control = false/g' "$NODE_PATH/nano-node/Nano/config-rpc.toml"

    exit 0

fi


if [[ "$1" = "node" ]] && [[ "$2" = "stop" ]] || [[ "$1" = "stop" ]] || [[ "$1" = "down" ]]; then
    
    if [[ $(cat $DIR/.xno/path 2>/dev/null) == "" ]]; then
      echo "${RED}Error:${NC} ${CYAN}Node Path not setup.${NC} Use 'xno config path PATH'."
      exit 0
    else
      NODE_PATH=$(cat $DIR/.xno/path)
    fi

    cd $NODE_PATH && docker-compose stop nano-node > /dev/null

    exit 0

fi


if [[ "$1" = "setup" ]] || [[ "$1" = "--setup" ]] || [[ "$1" = "install" ]] || [[ "$1" = "i" ]]; then

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -n ""
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "${RED}Error${NC}: OS not supported (Mac OS). Use Ubuntu VM instead."
        exit 0
    else
        echo "${RED}Error${NC}: Operating system not supported."
        exit 0
    fi

    if [[ -z "$2" ]]; then
        echo "${GREEN}Available Packages${NC}:"
        echo "$ xno $1 node"
        echo "$ xno $1 vanity"
        echo "$ xno $1 pow-server"
        echo "$ xno $1 gpu-driver"
        exit 0
    fi

    if [[ $(cat $DIR/.xno/path 2>/dev/null) == "" ]]; then
      echo "${RED}Error:${NC} ${CYAN}Node Path not provided.${NC} Use 'xno config path PATH'. You will need ~200GB of space."
      exit 0
    else
      NODE_PATH=$(cat $DIR/.xno/path)
    fi

    # Coming soon
    if [[ "$2" = "pow" ]] || [[ "$2" = "--pow" ]] || [[ "$2" = "pow-proxy" ]] || [[ "$2" = "pow-server" ]]; then
        read -p 'Setup Nano PoW Server: Enter 'y': ' YES
        if [[ "$YES" = "y" ]] || [[ "$YES" = "Y" ]]; then
            # TODO
            # @reboot ~/nano-work-server/target/release/nano-work-server --gpu 0:0
            # $DIR/nano-work-server/target/release/nano-work-server --cpu 2
            # $DIR/nano-work-server/target/release/nano-work-server --gpu 0:0
            exit 0
        fi
        echo "Canceled"
        exit 0
    fi

    # Sorta working
    if [[ "$2" = "work-server" ]] || [[ "$2" = "work" ]]; then
        
        read -p 'Setup Nano Work Server. Enter 'y' to continue: ' YES

        if [[ "$YES" = "y" ]] || [[ "$YES" = "Y" ]]; then

            if ! [ -x "$(command -v cargo)" ]; then
                sudo apt install ocl-icd-opencl-dev gcc build-essential -y
                curl https://sh.rustup.rs -sSf | sh
                source $DIR/.cargo/env
            fi
            
            git clone https://github.com/nanocurrency/nano-work-server.git $DIR/nano-work-server
            cd $DIR/nano-work-server && cargo build --release

            sudo crontab -l > cronjob
            #echo new cron into cron file
            echo "@reboot $DIR/nano-work-server/target/release/nano-work-server --gpu 0:0 -l [::1]:7078" >> cronjob
            #install new cron file
            sudo crontab cronjob
            rm cronjob

            exit 0
        fi

        echo "Canceled"
        exit 0

    fi

    if [[ "$2" = "gpu" ]] || [[ "$2" = "gpu-driver" ]] || [[ "$2" = "gpu-drivers" ]]; then
        
        read -p 'Setup NVIDIA Drivers. Enter 'Y' to continue: ' YES

        if [[ "$YES" = "y" ]] || [[ "$YES" = "Y" ]]; then
            
            # GPU
            apt install ubuntu-drivers-common
            sudo apt-get purge nvidia*
            sudo ubuntu-drivers autoinstall

            exit 0
        fi

        echo "Canceled"
        exit 0

    fi


    if [[ "$2" = "" ]] || [[ "$2" = "node" ]]; then
        INSTALL_NOTE=$(cat <<EOF
==================================
         ${GREEN}Setup New Node${NC}
==================================
${GREEN}CPU${NC}:>=4${GREEN} RAM${NC}:>=4GB${GREEN} SSD${NC}:>=500GB
==================================
Press 'Y' to continue:
EOF
)
        read -p "$INSTALL_NOTE " YES
        if [[ "$YES" = "y" ]] || [[ "$YES" = "Y" ]]; then
            echo "${RED}xno${NC}: 1-Click Nano Node Coming Soon."
            # https://github.com/fwd/nano-docker
            # curl -L "https://github.com/fwd/nano-docker/raw/main/install.sh" | sh
            # cd $DIR && git clone https://github.com/fwd/nano-docker.git
            # LATEST=$(curl -sL https://api.github.com/repos/nanocurrency/nano-node/releases/latest | jq -r ".tag_name")
            # cd $DIR/nano-docker && sudo ./setup.sh -s -t $LATEST
            exit 0
        fi
        echo "Canceled"
        exit 0
    fi

fi
