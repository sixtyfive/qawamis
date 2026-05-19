[x] search is off in books: hw3, lane
[x] search fails to produce any results other than "1" in: mgf
[x] can't close flash messages (not that there are many, or indeed, any, at the moment ... ?)
[x] add these again (where?):
  [x] `flash[:notice] = t(:nosuchentry_in_selectedbook)`
  [x] `flash[:notice] = t(:nosearchresults_in_selectedbook, book: t("books.#{@page.book.slug}"))`
  [x] `flash[:warn] = t(:nosearchresults)`