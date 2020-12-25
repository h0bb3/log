---
layout: post
title:  "Code that Outputs Code"
author: "h0bb3"
comments_id: 8
description: "Lifting yourself by the hair."
tags: "java testing regression meta-programming"
---
I have always had a problem with regression testing in my [research project](https://tobias-dv-lnu.github.io/s4rdm3x/). In this project, I test different approaches to map a source code file to an architectural module. One important source of information on such mappings is a dependency graph (e.g., what calls are made between different files). The source code is actually a java class file (i.e., bytecode), and as they are from real "large"-projects like Ant and Lucene, there tend to be a few hundreds of them with quite a lot of different types of dependencies, e.g., this class inherits from that class, etc.

To assign a mapping, we can count dependencies within a module and to the outside of a module and make the assignment so that as few as possible dependencies are to the outside. This would reflect a basic high cohesion modular design. To compare different approaches, I use the precision and recall metrics and compare them using the f1-score. To put it simply, I perform different calculations and get a value from 0-1 that tells how good the approach was. Different approaches have different parameters that can be tweaked, and also the initial data used is of large importance.

To aid in refactoring, we, of course, need testing. However, there is a lot of functionality, and having small unit tests for everything is both cumbersome and may not catch problems at a larger scale; for this, we need regression testing. I.e., do we get the same f1-score when we rerun the approach on the same system with the same parameters?

The systems are basically released versions of open-source software, and as such, it would be problematic to distribute these as it would likely affect the oss-license of my project. Also, relying on external files or resources, in general, is problematic when testing.

So this was a "short" introduction to the problem at hand. Now for the solution. When running my analyses, I parse the bytecode and construct a graph of objects representing each file (with classes, methods, dependencies, etc.). A graph can, of course, also be constructed programmatically (i.e., creating objects). So I decided to create some code that could print the programmatic creation of a graph to a file, i.e., code that printed source-code. This was an interesting experience, and I encountered some gotchas in java: namely that a method cannot be huge (64k limit) and that you have a limited number of fields to use in a class. Basically, my generated source code became too large. As this is generated source code, it looks a bit strange compared to normal code; for example, my idea was to treat every node in the graph as a unique local variable to avoid looking up nodes via name in the graph. But this approach did not work as I soon ran out of space in my one big large method. To fix this, I had to resort to some lookups and splitting methods into smaller parts. This is not 100% perfect, but I guess it is good enough.

I found it beneficial to have a base class for my generated classes as they tend to have some basic properties and fields that are the same. Instead of generating these, it was nice to put them in a base class and use inheritance.

To avoid magic numbers for the scores (that would need changing as soon as a new source code version of a system is generated), I also generate these numbers when the source code is generated. The benefit is that the number is generated using the original system loaded from a file. This gives an increased chance that the generated code itself is correct. Speaking of that, if a regression test fails, it could also be because the generated code is wrong. To build even more confidence in the generated code, the code generator also generates a shadow-graph (using the same calls). This graph is checked so that it corresponds to the original graph itself.

I have not lived with this regression testing approach for very long, and it will be interesting to see how it pans out in the long run. If you are interested in source code, you can take a look at [examples of generated system dumps](https://github.com/tobias-dv-lnu/s4rdm3x/tree/dev_regressiontests/src/test/java/se/lnu/siq/s4rdm3x/experiments/regression/dumps), the [system dumper itself](https://github.com/tobias-dv-lnu/s4rdm3x/blob/dev_regressiontests/src/test/java/se/lnu/siq/s4rdm3x/experiments/regression/System2JavaDumper.java) and/or the [regression tests using generated code](https://github.com/tobias-dv-lnu/s4rdm3x/blob/dev_regressiontests/src/test/java/se/lnu/siq/s4rdm3x/experiments/regression/RegressionTests.java). 

I think it was a fascinating exercise in "meta"-programming.
