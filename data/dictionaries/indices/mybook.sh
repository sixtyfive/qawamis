#!/bin/bash

BOOK_NAME=mybook
PRE_CONTENT_PAGES=20 # Or whatever...

cat $BOOK_NAME.js.tpl > $BOOK_NAME.js
i=$PRE_CONTENT_PAGES
while read line; do
  echo -e "/* $((PRE_CONTENT_PAGES - 1)) */ doe[$i]='$line';" >> $BOOK_NAME.js
  i=$((i + 1))
done < $BOOK_NAME.txt
