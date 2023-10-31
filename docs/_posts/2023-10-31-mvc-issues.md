---
layout: post
title:  "MVC Problems"
description: "Model View Controller and common issues"
author: "h0bb3"
comments_id: 20
tags: "programming coding dev archtecture MVC"
---

The model-view-controller (MVC) architectural pattern comes in many flavors and each implementation of it has its own specific structure. This discussion is geared towards a quite strict interpretation where the view is passive, and we have a supervising controller. In the end, I hope that you may find some ideas and pointers to take home though your particulars may indeed be different.

To lay some groundwork lets briefly state the major responsibilities of these architectural modules. The model encapsulates business requirements, you should essentially be able to reuse the whole model and just write a new user-interface and not need to reimplement any requirement from a business standpoint. The view encapsulates a particular, low-level user interaction technology, in essence, the view acts as an application-specific layer for some more general UI api. The api may be as simple as printing and reading to the console, or as advanced as voice recognition, with hand gestures and vr. Now for the controller - the most confusing aspect of the triad. The controller manages the interaction at a high level by running user scenarios, i.e. it uses the functionality of the model and the view to help the user fulfill some goal/task. E.g. the user wants to see a list over all X - the controller fetches all X from the model and tells the view to visualize the X objects. The controller typically also manages some state of the user interface particularly if it is oriented towards user scenarios - e.g. what menu is active, what is the next step for the user etc.

In my experience the most MVC problems arise from the somewhat confusing role of the controller.

## Model responsibility in the controller (or view)
A business rule or requirement is implemented in the controller/view when it should be part of the model. Think of the reuse scenario - do you need to remember to reimplement stuff in the new controller/view not good. The major purpose of the model is reuse of behavior - not just a simple collection of some data classes. The model needs to maintain the state of itself so it does not violate the requirements.

This is likely the most common error. Typically the controller becomes complex and adopts the model functionality - the model becomes simple data classes with only getters and setters and no real behavior.

### Business rules not encapsulated in the model
This means that while you have implemented behavior in the model that fulfills the business rules, these rules are not "mandatory" i.e. it is up to the caller (controller) to make sure that it does not do anything that potentially puts the model in a bad state. This can be seen as a variant of the above. This can easily happen if you return internal model objects (to the controller/view) that then can be manipulated in ways that are not good. In some cases it is even easier to the wrong thing than to find some elaborate combination of methods in the model that should be called. This is not good as at some point someone will forget, or simply not know. The application then risks getting into a state that is not allowed and this can cause serious problems as there is a high chance that some assumption is violated.

It is important to remember that we are talking about code and what you can possibly do with the objects in the model, not about how the end user can actually interact with the system. It may be perfectly fine for the user as the controller currently does what it should in the way that it should do it. 

## View responsibility in the model (or controller).
Things related to the view, typically related to language or layout have crept into the model/controller. Typically you can see this in the form of message strings, or formated output. If we need to change language or layout only the view should need to change. Another problem could be adding convenience classes or functionality in the model, e.g. classes or functionality that really only used by the view. Be wary of highly specific parts of the model that is geared to a particular type of view.

## Controller responsibility in the model
This is rather unusual - it means that the state of the controller has crept into the model. E.g. what object is worked on currently by the user etc. We can imagine the model supporting multiple concurrent users then this would be a problem. In some cases this is maybe not clear cut, we can imagine the model encapsulating a turn-based game. Then it would be part of the model to track what player is currently active and the order of the players - as this is an integral part of the game rules thus the model.

## Granulatiry of controller viewe communication
While maybe not a problem per se but often an area where questions arise is the level of abstraction in the communication between view and controller. Typically the view manages low level interaction (e.g. mouse clicks, message output, keyboard input), as such it shields the rest of the code from the particualrs of the technology platform.

As such the view would in some way convey "system events" to the controller i.e. what the user wants to do now. This system event may originate in the user clicking a button or selecting some menu option. The next issue is how will the controller get input data from the view - should every small piece of information be asked for, or should one adopt something I like to call "form" thinking. I.e it asks for some larger chunk of data that we can think of the user adding in a form like way. In my experience this form-thinking creates a better balance of the code between view and controller, the view also have a higher chance of managing the form interface in a user friendly way depending on the actual implementation technology.
