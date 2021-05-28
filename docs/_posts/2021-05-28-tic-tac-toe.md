---
layout: post
title:  "TicTacToe React"
author: "h0bb3"
comments_id: 14
description: "baby steps"
tags: "react javascript"
---
Lately, I've been dabbling in learning some more js in general and focusing on front-end development. I've previously tried out js but to put it frankly I was not that impressed. This was probably more due to my own favoritism of strictly typed compiled languages like c++ etc. Also, the usefulness of js has increased vastly in the last few years with more language features (with more things looking like a standard language), and also the tooling for the language has matured. VSCode debugging, npm and the whole node runtime makes things a lot easier. It is also likely that I have matured a bit myself and not approaching the language with the 'my cup is full' attitude.

Anyway, I took a fresh start and I must say I have enjoyed this very much! JS is fun and a surprising language, I like! Just being able to solve things like the "is a square a rectangle" LSP problem with just a - well we can just swap the prototype and presto - that is pure awesomeness!

So after getting the basics out of the way I started to look at react, which seems to be one of the more popular front-end libraries for building dom-based UIs. I guess the dom and browser being what they are it is an interesting environment to work in. Personally, I have never really liked the "component" heavy declarative UIs stemming from win32 API - MFC. In the last years (like 15) I have always gravitated towards immediate mode UIs and that is what I use in [v3xt](https://github.com/tobias-dv-lnu/s4rdm3x) for example. But basically, I took some time to do the official(?) react tutorial and created a simple tic-tac-toe game. However, I could not let things stay there so I refactored a lot of the code (most importantly separating the game part from the UI and creating a negimax AI player). This also let me push the AI part to execute as a web worker (and this proved to be quite a challenge but I probably need to do a write-up of my experiences from that in a separate post). To top things off I added a high score based on how long you can stand your ground against the ai-player) I also added tests of the game using mocha/chai and tests for the react components using jest. Finally, I also made an automatic CI/CD pipeline using GitHub actions/pages.

It is all available on GitHub of course so go check out [tictactoe react](https://github.com/tobias-dv-lnu/tictactoe_react)

Some things come to mind when doing the tic-tac-toe tutorial.
* mixing the game into the UI-code is _not_ a good idea: having model UI separation makest things easier to work with, allows for easier testing, it is easier to add features (like the ai-player, high scores) and separate deployment (i.e. ai-player as a web worker - which needs the game functionality to work)
* Testing using jest for the react components worked really well, would have been nice to have this included in the tutorial.
* Under the hood react is quite complicated, the webpack transpilation is not easy to understand and if you need to do something special it can be quite daunting. For example, adding the web-worker and getting things to actually work took the better part of a whole day and involved two additions to the project.

I'm not really sure on how to progress this project (for example adding multiplayer/server high sores) or to start a new project? I'm thinking of implementing the game of life.
