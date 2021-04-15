---
layout: post
title:  "Code Quality as Test Cases"
author: "h0bb3"
comments_id: 12
description: "now battle hardened"
tags: "java testing code-quality findbugs stylechecker"
---
A while back I commited tha lastest(?) version of the [buildpipeline for handling code quality issues (via checkstyle and spotbugs) as test cases](https://github.com/tobias-dv-lnu/log/tree/main/code/gitlab-code-quality-as-unit-tests). In this commit, we have some improvements regarding setting correct build directories and also parsing of html entites in the findbugs xml as these would make the xml-parser crash.

This version has now been battle hardened in about 100 projects in our java OOP course, it should be farily stable by now but you never know.

Added a CC licence header to it.
