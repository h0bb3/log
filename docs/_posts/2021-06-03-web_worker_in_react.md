---
layout: post
title:  "Web Worker in React and Jest"
author: "h0bb3"
comments_id: 15
description: "Two packages and three modules later"
tags: "react javascript jest"
---

I've been workgin on a tic tac toe game in React created using Create React App and following the standard tutorial. I wanted to add an ai and such computations can be lengthy. Not really a problem i the standard game, but if you run on a 7x7 grid or something like that the ai needs to recurse quite deeply. This takes several seconds leaving the browser locked as the queue is blocked.

## Transpiling Problem
This seems like the perfect case for using the web worker api, providing essentially the ai in a separate thread. However, this turned out to be pretty hard. The main problem is that React transpiles the source code using babel and bundles it using webpack. This is of course an advantage as the code is served to the browser more efficiently etc. The problem is that the web worker api requires basically a source code file (or blob) to work, and this is simply not available due to the transpilation. This can be remedied by simply putting the code in the public site and referencing it from there, but then it is hard to "hook" back into the normal code. In my case, notify my component that the ai had computed a move. It is also generally "ugly" to have part of the code not handled the normal way.

### Webpack Configuration with [`react-app-rewired`](https://www.npmjs.com/package/react-app-rewired) and[`worker loader`](https://www.npmjs.com/package/worker-loader)
Webpack can of course be configured to do this but this configuration is hidden by the Create React App way of doing things. I was also reluctant to "eject" my configuration as this would mean that I would be on my own. Fortunately there is a package that lets you customize specific aspects of the configuration: [`react-app-rewired`](https://www.npmjs.com/package/react-app-rewired). The next problem is to tell webpack what to actually do to handle web workers separately. Fortunately there is another package for this: [`worker loader`](https://www.npmjs.com/package/worker-loader).

After installing these two packages I could povide a module with the configuration override `configt-overrides/index.js`:

```javascript
module.exports = function override(config, env) {
  config.module.rules.push({
      test: /\.worker\.js$/,
      use: { loader: 'worker-loader' }
    })
  return config;
}
```

This basically tells webpack to handle files named ´.worker.js´ using worker-loader. I could now specify my [`ai web-worker`](https://github.com/tobias-dv-lnu/tictactoe_react/blob/main/src/components/game/tictactoe-ai.worker.js) provide the `onmessage` function and use this in my game to pass messages to the webworker (e.g. the current game) and recieve the message from the worker (e.g. the ai move).

### Passing Objects to Web Worker
One gotcha I ran into here was that you cannot pass "complex" data to the webworker (e.g. an object) so basically the game state needs to be serialized and then the game object reconstructed in the at the web worker side of things. This was further validation that splitting the game "model" from the react "view" was beneficial.

### Lifting the Level of Abstraction
Interestingly enough the ai-player more or less behaves like a human player and just calls the "board click" function on the game component. This is rather interesting and possibly the ai player could be lifted one level above the game itself... i.e. make the game totally oblivious to what is actually playing the game ai or human... _it is just clicks to me..._ The ai would then need to observe the game in some way to know when it is time to make a move. I find such things very interesting...

## Testing Web Woker using Jest
I use Jest for testing my react components and I though it would be interesting to test that thes web worker thing also actually works. E.g. the ai is called and makes a move. Unfortunately Jest does not support webworkers so this has to be mocked and then simulated. The easiest way I found to do this was to actually wrap the webworker in a new class and use this in both the Game components and then mock this in the tests. It seems that web-loader adds functions to the worker so mocking the worker module directly was not that easy. The advantage is that the mock can in itself use the ai and it sends and recieves the same messages. This provides a pretty good way to test that things are actually working to some degree.

Maybe there is a simpler way to do the testing mock but I found this way to be quite easy to understand and implement.

If you are interested feel free to check out the implementation: [tic tac toe react](https://github.com/tobias-dv-lnu/tictactoe_react) or leave a comment :)
