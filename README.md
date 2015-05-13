Interactive JudgeBooth
======================

This project provides a digital web-based version of the popular "Judge Booth" at bigger Magic: The Gathering(TM) events.
It's currently being rewritten completely.

Setup
-----

To get started, you need PHP and a MySQL database with the structure from backend/structure.sql.
Once that is in place, adjust the database configuration in backend/config.php and import the existing booth questions
via backend/import.php script from the command line.
You should import the data in this order: sets, cards, tokens, questions, translations

When the database is ready, you need to install the Gulp Node modules (`npm install`) and the Bower dependencies. (`bower instal`)
This allows you to build the application files via running `gulp` or `gulp watch`.

License and Copyright
---------------------

Card images are all copyright Wizards of the Coast.

This website is not affiliated with Wizards of the Coast in any way.
