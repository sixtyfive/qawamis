#!/bin/bash

cat hw5.tpl.txt > mr-aa-hw5-index.js
i=26
while read line; do
  echo -e "/* $((i - 25)) */ hw5[$i]='$line';" >> mr-aa-hw5-index.js
  i=$((i + 1))
done < hw5.txt
