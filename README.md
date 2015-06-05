Interactive JudgeBooth
======================

This project provides a digital web-based version of the popular "Judge Booth" at bigger Magic: The Gathering(TM) events.

The booth wants to make a connection between judges and players by providing a diverse set of rules questions
and testing the player's knowledge in a fun environment. The questions are available in 3 levels of difficulty and more
than 5 different languages.

It is available online under [booth.mnt.me](http://booth.mnt.me) to everyone and supports all internet-ready devices
and screen sizes. If you discover a bug, please [open a ticket](https://github.com/bra1n/judgebooth/issues)!

![Judge Booth](http://booth.mnt.me/docs/booth1.jpg)

Usage
-----

Using the Judge Booth should be pretty self-explanatory. Once the website has loaded, you'll find a short introduction
and a button that lets you start with questions right away on the home screen. If you want to customize your experience,
there is a menu available on the left side of the booth. You can either open it by clicking on the left icon in the
title bar, or by swiping the screen from left to right.

### Sidebar options

In the sidebar menu you'll finde several options to customize the list of questions.

* You can select from one of the available languages
  (English, German, French, Russian, Traditional Chinese, Simplified Chinese)
* You can choose from which expansions the questions should be selected. If you only want to see Standard or Modern
  legal cards, there is a quick filter for both available at the top of the expansion list.
* Finally, you can choose which difficulty levels to include in your list of questions. 1 star is "easy", 2 is "medium"
  and 3 is "hard".

After you made your choices, the big button below the filters will tell you how many questions fit your criterias.
If there is at least 1 question available, you can click the "Select"-button and select these questions to use in the
booth.

### Questions

Once you're on the question page, you'll see a number of cards that are relevant for this question. If you want to see
the oracle text for any of the cards, just click on the card image and it will flip to the "oracle text" side.

**Note:** Some foreign cards don't have images available, yet. You will see the back of the card in this case. To show
the (English) Oracle text, just click on the card back.

Below the cards you will find the question number, the difficulty level (number of stars) and, if known, the author of
the question, next to the question text itself. Show this question to the player and once they are sure of their answer,
click on the "Show Answer" button to show the answer. Alternatively, you can also use the up/down arrow keys on your keyboard to show and hide the answer.

To go to the next question, click on the right arrow in the title bar, swipe the screen to the left or press the right
arrow key on your keyboard. To go to the previous question, click the "Back" button in your browser or press the left arrow key on your
keyboard.

### Offline mode

In case you don't have an internet connection where you want to set up the booth, there is an Offline Mode available.
To use it, you have to click on *Go Offline* in the sidebar menu while you still have internet. You will then be taken
to a slightly different URL, which you should bookmark for later when you're offline. After a couple of seconds, the
necessary files will be downloaded and disconnecting your internet should leave you with a still-usable booth, minus the
card images.


Administration
--------------



Development
-----------

If you want to contribute to the source code, feel free to fork the project and run your own version.

To get started, you need PHP and a MySQL database with the structure from backend/structure.sql.
Once that is in place, adjust the database configuration in backend/config.php and import the existing booth questions
via backend/import.php script from the command line.
You should import the data in this order: sets, cards, tokens, questions, translations

When the database is ready, you need to install the Gulp Node modules (`npm install`) and the Bower dependencies. (`bower install`)
This allows you to build the application files via running `gulp` or `gulp watch`.

License and Copyright
---------------------

Card images are all copyright Wizards of the Coast.

Card database is provided by [mtgjson.com](http://mtgjson.com) under public domain license.

This website is not affiliated with Wizards of the Coast in any way.
