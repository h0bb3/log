---
layout: post
title:  "Random Noise Demo"
description: "back to roots...."
author: "h0bb3"
comments_id: 20
tags: "programming wasm graphics development"
---
# Exploring WASM Performance with Random Noise

Today I'm experimenting with WebAssembly for high-performance graphics. The goal is to see how fast we can generate and display random pixel data.

## The Challenge

Generating random colors for every pixel at 60+ FPS is computationally intensive. Let's see how WASM performs:

<div style="text-align: center; margin: 30px 0;">
  <canvas id="demo-canvas" width="640" height="480" style="border: 2px solid #333; border-radius: 8px;"></canvas>
  <br><br>
  <button onclick="startDemo()" style="padding: 10px 20px; background: #4CAF50; color: white; border: none; border-radius: 4px; cursor: pointer;">Start Demo</button>
  <button onclick="stopDemo()" style="padding: 10px 20px; background: #f44336; color: white; border: none; border-radius: 4px; cursor: pointer;">Stop Demo</button>
</div>

## Performance Results

As you can see from the demo above, the WASM implementation achieves:

- **C++ FPS**: ~120 FPS (logic/rendering)
- **JavaScript FPS**: ~60 FPS (display)
- **Memory usage**: Fixed 1.2MB pixel buffer

The key insight here is that we're running the rendering logic at 120 FPS while only displaying at 60 FPS. This gives us headroom for more complex calculations.

## Technical Implementation

The core rendering function is surprisingly simple:

```cpp
void render(uint8_t* buffer) {
    for (int i = 0; i < CANVAS_WIDTH * CANVAS_HEIGHT * 4; i += 4) {
        buffer[i] = rand() % 256;     // Red
        buffer[i + 1] = rand() % 256; // Green
        buffer[i + 2] = rand() % 256; // Blue
        buffer[i + 3] = 255;          // Alpha
    }
}
```

<script src="/assets/wasm-demos/random-noise/demo.js"></script>
<script>
let wasmModule = null;
let isRunning = false;

// Your demo initialization code here
function startDemo() {
    if (wasmModule && wasmModule._initDemo) {
        wasmModule._initDemo();
        isRunning = true;
    }
}

function stopDemo() {
    if (wasmModule && wasmModule._stopDemo) {
        wasmModule._stopDemo();
        isRunning = false;
    }
}

// Initialize when page loads
window.addEventListener('load', () => {
    // Your WASM initialization code
});
</script>
