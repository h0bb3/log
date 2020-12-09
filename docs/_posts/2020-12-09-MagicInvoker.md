---
layout: post
title:  "MagicInvoker - a Helper to Invoke Private Methods in Java"
author: "h0bb3"
comments_id: 2
---

As I like procrastinating and programming I have spent a lot of time (well like a day) coding a helper class for magically invoking private methods in Java. It builds on the idea that outer classes have access to inner classes private methods. This gives us an elegant solution (imho) to the problem. Well we do need to use some reflexion and that is always messy, fortunately this can be all hidden away in the MagicInvoker class.

The basic use case is that you have a class with a private method and you want to test that method for some reason.

```
public class Foo {
  private String imPrivate(String a_s1, String a_s2) {
    return a_s1 + " " + a_s2;
  }
}
```

The test class itself will then look like this when using the [`MagicInvoker`](https://github.com/tobias-dv-lnu/s4rdm3x/blob/NBWeights/src/test/java/se/lnu/siq/s4rdm3x/MagicInvoker.java) helper.

```
public class FooTest {
  @Test
  public imPrivate_test(String a_s1, String a_s2) {
  
    // create an inner class so that we can call private methods from the outer class
    class SUT extends Foo {
    
      // override the method under test and forward the call to the magic invoker
      private String imPrivate(String a_s1, String a_s2) {
        MagicInvoker mi(this);
        return (String)mi.(a_s1, a_s2);
      }
    }
    
    SUT sut = new SUT();
    assertEquals("Hello World", sut.imPrivate("Hello", "World"));
  }
}
```
So the [`invokeMethodMagic`](https://github.com/tobias-dv-lnu/s4rdm3x/blob/e7ea12a24c348fe2842f302b10d34bb4c6fad7ed/src/test/java/se/lnu/siq/s4rdm3x/MagicInvoker.java#L76) method finds out the calling method name and the types of the arguments, finds the corresponding method in the parent class and then changes it's protection and calls it on the supplied object. This can all be done by inspecting the calls stack and using the reflexion classes provided in java. Pretty neat!

One gotcha is that you need to supply the object to call the method on (not that surprising) however there seem to be no way to get the calling object via reflexion (not that I have found at least, let me know if there is). I decided to inject this in the constructor as the [`invokeMethodMagic`](https://github.com/tobias-dv-lnu/s4rdm3x/blob/e7ea12a24c348fe2842f302b10d34bb4c6fad7ed/src/test/java/se/lnu/siq/s4rdm3x/MagicInvoker.java#L76) takes a vararg it is simply too easy to forget to add it and strange things will happen.

Another gothca is that while it may look like you are overriding the private method, this is not actually how it works and you can unfortunately not use the `@Override` annotation to make sure you are actually using the correct method signature.

[Check out the source of MagicInvoker](https://github.com/tobias-dv-lnu/s4rdm3x/blob/NBWeights/src/test/java/se/lnu/siq/s4rdm3x/MagicInvoker.java). 
