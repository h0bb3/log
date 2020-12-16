---
layout: post
title:  "You Need a dev Branch"
description: "I cannot believe how I managed without a branch dedicated for development."
author: "h0bb3"
comments_id: 7
tags: "git github development"
---
I'm working on a project with the ultimate goal to [automatically assign a source code file to an architectural module](https://tobias-dv-lnu.github.io/s4rdm3x/). This is a proper research project and currently it is under review for [the Journal of Open Source Software](https://joss.theoj.org/). Reviews for a scientific journal are a lenghty process normally and in the times of CoViD19 they are even longer. In addition I was not really sure about when reviewers would take a peek at my code and start messing around. Basically my master branch was locked and I was really hesitant to make any changes to it.

At the same time I had many new ideas I wanted to try and I did not want to create one big fat branch to work on everything in. I wanted one branch per feature/bug/idea (a.k.a. Feature Branching)so I can work on many things from fixes to entierly new ideas (that may turn out to be nothing). But as master was locked down what should I merge my feature branches to?!

This was a bit of a conundrum to me at first but then I realized I could simply create a dev branch and then work in separate branches from dev and merge to/from that one as needed, or issue pull requests in a team environment. Basically you should probably have one branch for every "stable" version you want i.e. a master for releases, a testing branch for more structured testing, a dev branch for development, or what not.

Of course this is not a new idea but has been around almost as long as git itself. But as my own path started in 1998 working in a PC environment with "manual: I move the file from the dev server" to "MS SourceSafe: I lock the file on the dev server" to "subversion: merge hell" to "git: headless wtf?!"... it takes a while to grokk :D Anyway, you can read more about [a successful Git branching model](https://nvie.com/posts/a-successful-git-branching-model/) and about [understanding the GitHub flow](https://guides.github.com/introduction/flow/). They have pretty pictures.

I must say that this has freed up my development mindset a lot, I just hope I can keep all the branches/merges correct. I will look into some form of visualization support for this. I tend to work in many small branches and it can indeed be a bit hard to know where you are....
