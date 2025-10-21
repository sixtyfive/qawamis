#!/bin/bash

cat doe.js.tpl > doe.js
i=20
while read line; do
  echo -e "/* $((i - 19)) */ doe[$i]='$line';" >> doe.js
  i=$((i + 1))
done < doe.txt
