---
layout: post
title:  "How to Test Private and Protected Methods in Java"
author: "h0bb3"
comments_id: 1
tags: "java magicinvoker testing reflection"
---

When writing automatic tests for code I often find myself wanting to create test cases for protected or private methods. While this can be considered a "test smell" I find it somewhat common in practice.

Making the method public could be an option but this has always bugged me a bit as it requires change of the original code and of course a larger public interface. The other way is to use some funky reflexion type code i.e. `class.getDeclaredMethod()` which is also a bit wonky imho. I recently stumbled on another way you can do this. Simply create an inner class inheriting from the class under test. Inner class methods are all visible to the outer class and protected methods will therefore be accessible as ususal. You can create the class in the method or in the class declaration itself.

```
public class SUTClass {

  protected boolean sutMethod() {
    return true;
  }
}
```

```
public class SUTClass_Test {

  public sutMethod_test() {
  
    class SUT extends SUTClass {}
    
    sut = new SUT();
    
    assertTrue(sut.sutMethod());
  }
}
```

I found this quite elegant and removes the need for clunky wrapper methods. If you have `private` methods you have to do the funky reflexion style thing. Possibly the inner `class SUT` provides a nice spot to add this and not pollute the test method:

```
public class SUTClass {

  protected boolean sutMethod() {
    return true;
  }
  
  private boolean privateSutMethod() {
    return true;
  }
}
```

```
public class SUTClass_Test {
  private static class SUT extends SUTClass {
    private boolean privateSutMethod() {
      try {
        Method sutMethod = SUTClass.class.getDeclaredMethod("privateSutMethod");
        sutMethod.setAccessible(true);
        return (String)sutMethod.invoke(this, a_to, a_froms);
      } catch (Exception e) {
        assertEquals(true, false);
      }
      return null;
    }
  }

  public sutMethod_test() {
    sut = new SUT();  
    assertTrue(sut.sutMethod());
  }
  
  public privateSutMethod_test() {
    sut = new SUT();
    assertTrue(sut.privateSutMethod());
  }
}
```

Care must be taken so that the correct class is used for the `getDeclaredMethod()`. This is especially important if the method is declared in a subclass. You could probably make this code more generic and funky to reduce further duplication in the codebase, i.e. some recursive search of parents.
For a real example using this method in testing check out [some test cases in s4rdm3x](https://github.com/tobias-dv-lnu/s4rdm3x/blob/NBWeights/src/test/java/se/lnu/siq/s4rdm3x/model/cmd/mapper/NBMapperTests.java)
