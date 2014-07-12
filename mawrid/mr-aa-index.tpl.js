/* ------------------------------------------------- *
 * Index of last article on every page of book <...> *
 * Compiled by <...> (<...>).                        *
 * ------------------------------------------------- */

var articles = [
'',
'',
''
];

var <book name abbreviation> = [];
var offset = <first content page as counted from book cover>
for (i=0; i<=offset; i++) <book name abbreviation>[i] = '';
for (i=0; i<=articles.length; i++) <book name abbreviation>[i+offset+1] = articles[i];
