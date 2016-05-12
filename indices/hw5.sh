#!/bin/bash

cat hw5.js.tpl > hw5.js
i=26
while read line; do
  echo -e "/* $((i - 25)) */ hw5[$i]='$line';" >> hw5.js
  i=$((i + 1))
done < hw5.txt
