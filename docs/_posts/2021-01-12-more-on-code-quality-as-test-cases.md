---
layout: post
title:  "More on Code Quality as Test Cases"
author: "h0bb3"
comments_id: 10
description: "now with added code... creamy..."
tags: "java testing code-quality findbugs stylechecker"
---
Just committed the final(?) version of my [buildpipeline for handling code quality issues (via checkstyle and spotbugs) as test cases](https://github.com/tobias-dv-lnu/log/tree/main/code/gitlab-code-quality-as-unit-tests) . In this commit, you find the build pipleine, the `build.gradle` and the test case code for converting the reports to JUnit XML. Currently, it is optimized for display in the GitLab build pipeline report view. But it is also printed to std-out for easier viewing on the local dev environment.

Indeed changing the `build.gradle` was a key step and I managed to fix a serious problem - tests always failed when issuing `gradlew build`  as the reports where generate after the execution of the unit tests. I actually did not realize the problem as I mostly build in IntelliJ and then using the build pipe on gitlab and in that, there was a separate step for generating the reports first and then running the tests. Not being able to run `gradlew build`  is a major downside so I'm glad I manage to fix it. As you may know, the Gradle tasks can specify dependencies so basically I needed to get a dependency to run the report building tasks before the main test cases when run. Pretty easy when you know but anyway code:

```java
test {
    // make sure we run the code quality stuff first
    // we need the generated reports when testing
    dependsOn checkstyleMain
    dependsOn spotbugsMain

    // also some verbose output so we get some info in the console when we run tests
    testLogging {
        outputs.upToDateWhen {false}
        showStandardStreams = true
    }
}
```

I stumbled upon some different ways to do this bug as I understand you should do it via dependencies. I just hate when there are many ways to do things. Design mantra: *"det ska vara lätt att göra rätt"* - *"It should be easy to do the right thing"*... sounds better in Swedish... I promise.

Anyway, I hope you find some use for this in your future projects.
