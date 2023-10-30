---
layout: post
title:  "Hidden Dependencies"
description: "The Road to Hell is Paved with Good Intentions"
author: "h0bb3"
comments_id: 19
tags: "programming coding dev"
---

In general, when some part (A) of code needs some other part (B) to work, we have a dependency. In its simplest form A and B are functions and A simply calls B. This is a basic construction available in most programming languages. In this case, the dependency is quite explicit - we can easily see the call in the code, if we use a compiler it will check that B exists and that the call is valid (parameters, etc), if we are in an interpreted environment the interpreter will let us know if things did not work out well with the call. We can even use some tools to trace these explicit dependencies and reason about the structure of the code in some sense.

Having explicit dependencies is good for all the above reasons, and the general idea expands to classes (in OO), modules, packages, libraries, components, services, etc. We need to know what A requires to work and ultimately we want tools to tell us about possible flaws (compiler, interpreter). However, making dependencies explicit requires work and programmers are lazy hence entering the hidden dependency. The following reasoning is based on you writing your own code in your own codebase (for higher level constructs things can be different).

A common form of laziness is the idea of not using parameters to functions or return types. We can imagine that we have a function that needs 5 string values to work, these values each have a distinct meaning and do not represent the same concepts. For example:

```java
addBlogPost(Headline h, ShortText shortText, FullText longText, Name authorName, Email authorEmail) {
   ...
}
```

The lazy programmer does not use types (rather sees everything at the level of the lowest common denominator -  it is great everything can be represented as a string!) sends an array of arguments into the method instead, and relies on an index or proper naming if we have a dictionary-style parameter.

```java
addBlogPost(String [] data) {
   String headline = data[0]
}
```

This means that the client (caller) will need to know the order of things (or the name of things) for this to work. If for some reason the function changes you will need to _remember_ to change all callers of the function. Indeed this is the mark of the implicit dependency - the need to remember things: if B is changed A also needs to change and there is no tool to help us. In the example, we can imagine that if we simply switch the order of headline and author, the code will work (as in compile) but we will get a strange behavior.

Most programming languages support only one return type - this makes it tempting to return arrays of values instead of creating proper return objects. Just as above, returning an array of data where each position relates to some specific type of data is a bad idea and will create hidden dependencies where the client is implicitly dependent on the order of things in the return datatype. For example:

```java
String [] getBlogPostData() {
   String [] ret = new String[5];
   ret[0] = getAuthor();
   ...
   return ret;
}
```

The solution here would be to create a custom type for the return of this complex data, alternatively at least provide constant values (`const authorNameIx = 0`) to be used and not rely on hard-coded indexes to match.


Another common example of hidden dependencies is when input is required from the user and this is not converted to a type at the appropriate level of abstraction. We can imagine that one part of our codebase is responsible for showing an UI (we can think of it as a simple console menu) - another part is responsible for performing actions based on the choices of the user. It is tempting to just return what the user typed (as a primitive number or string) to the part performing the action - instead of raising the level of abstraction to e.g. the level of actions.

```java
String showMenu() {
   print("1. to create a new blogpost");

   return readInputLine();
}
```

Compared to

```java
Action showMenu() {
   print("1. to create a new blogpost");

   String line = readInputLine();
   Action ret = convertToAction(line);

  return ret;
}
```
In the first function, the client caller becomes dependent on the actual menu output. This makes the client not only dependent on the string values ("1") etc, but also on the method of input, i.e. not selecting a menu option graphically or clicking a button).

The basic hallmark of hidden dependencies in your codebase is hard-coded constants in different places that need to match for the application to work, and you are working at a low level of abstraction often using primitive datatypes instead of your own custom types. Combating hidden dependencies is thus a matter of not adding hard-coded constants (at least instead use a constant value) and working with arguments and types at the proper level of abstraction.

In some cases, hidden dependencies cannot be avoided. These situations often arise from external communication e.g. using networks or files. In these cases, the actual protocols or formats are meticulously documented and standardized. If the format or protocol changes it is a big deal and all clients would need to change if we do not support backwards compatibility. Given this, there is no need for you to add further hidden dependencies in code that you have control over.
