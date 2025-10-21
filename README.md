_The website is running fine the way it is and I'm not likely to work it anymore in the foreseeable future. So if you wish for a new feature to be added to Qawamīs, I'll happily accept a PR, and possibly hand down maintainership after a while. For bugs, etc. you're still welcome to open an Issue._

What is this?
=============

Basically, _Qawamīs_ (Arabic for "dictionaries") is my attempt at recreating the [Mawrid Reader](https://github.com/ejtaal/mr) used by Abdurahman Erik Taal in his [Arabic Almanac](http://ejtaal.net/aa) project. I'm trying for a simpler and slightly more modern UI as well as root indices that are saved in a database instead of directly in the HTML.

How to use it?
==============

Easy, visit [the website](https://qms.weitnahbei.de), choose the dictionary you want to search in and enter a search term. Please note that when a dictionary uses Arabic roots instead of alphabetical sorting, then you will have to enter the root of the word you're looking for. I.e. if you're looking for كتاب (book), you would enter only the root consonants كتب into the search field. See e.g. [this Wikipedia page](https://en.wikipedia.org/wiki/Semitic_root) if you've never dealt with the concept of root letters before.

How to add new dictionaries?
============================

Please read `db/seeds.rb`. I'll happily accept PRs for additions to that, as well.

Author and license
==================

© 2014 and onwards, J. R. Schmid. The sources are licensed under GNU GPL v3 to remain compatible with Abdurahman's work wherever it might still be present.
