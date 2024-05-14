cat ./source/*.sh > ./xno.sh
file_size_kb=`du -k "./xno.sh" | cut -f1`
chmod +x ./xno.sh
echo "$(ls -1q ./source/* | wc -l | xargs) files in source. Combined: ($file_size_kb kb)"