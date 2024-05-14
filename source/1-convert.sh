
function nano_to_raw() {
  if [ "$1" == "0" ]; then
    echo "0"
    exit 0
  fi
  amount=$1; before=$(echo $amount | sed 's/\..*//'); [[ $amount == *.* ]] && after=$(echo ${amount}000000000000000000000000000000 | cut -d "." -f2) || after=000000000000000000000000000000; after=${after:0:30}; full=$before$after; trimmed=$(echo $full | sed 's/^0*//'); echo $trimmed
}

function raw_to_nano() {
  if [ "$1" == "0" ]; then
    echo "0"
    exit 0
  fi
  raw=$1; raw="000000000000000000000000000000$raw"; before=$(echo $raw | sed 's/..............................$//'); after=${raw: -30}; trimmed=$(echo $before.$after | sed 's/^0*//' | sed 's/0*$//' | sed 's/\.$//'); if [[ ${trimmed:0:1} == '.' ]]; then echo "0$trimmed"; else echo $trimmed; fi
}

if [ "$1" = "nano_to_raw" ]; then
    nano_to_raw $2
    exit 0
fi

if [ "$1" = "raw_to_nano" ]; then
    raw_to_nano $2
    exit 0
fi
