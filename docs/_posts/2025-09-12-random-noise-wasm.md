---
layout: post
title:  "Random Noise Demo"
description: "back to roots...."
author: "h0bb3"
comments_id: 20
tags: "programming wasm graphics development"
---
# Exploring WASM Performance with Random Noise

Today I'm experimenting with WebAssembly for high-performance graphics. The goal is to see how fast we can generate and display random pixel data and in general how to get this onto a webpage.

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

<script src="/log/assets/wasm-demos/random-noise/demo.js"></script>

<script>
let wasmModule = null;
let isRunning = false;
let canvas = null;
let ctx = null;
let pixelBuffer = null;
let imageData = null;
let fpsCounter = 0;
let lastTime = 0;
let animationId = null;

// Initialize when page loads
window.addEventListener('load', () => {
    canvas = document.getElementById('demo-canvas');
    ctx = canvas.getContext('2d');
    
    // Check if Module is already available and initialized
    if (typeof Module !== 'undefined') {
        if (Module.calledRun) {
            // Module is already initialized
            wasmModule = Module;
            initializeDemo();
        } else {
            // Module exists but not yet initialized
            Module.onRuntimeInitialized = function() {
                wasmModule = Module;
                initializeDemo();
            };
        }
    } else {
        console.error('WASM module not found');
    }
});

function initializeDemo() {
    console.log('WASM module ready');
    
    // Initialize the pixel buffer and image data
    imageData = ctx.createImageData(640, 480);
    
    // Start the rendering loop immediately
    startRenderingLoop();
}

function startRenderingLoop() {
    function renderFrame() {
        if (wasmModule && wasmModule._getPixelBuffer) {
            try {
                // Get the pixel buffer from WASM
                const bufferPtr = wasmModule._getPixelBuffer();
                const buffer = new Uint8Array(wasmModule.HEAPU8.buffer, bufferPtr, 640 * 480 * 4);
                
                // Copy to image data
                imageData.data.set(buffer);
                
                // Draw to canvas
                ctx.putImageData(imageData, 0, 0);
                
                // Update FPS counter
                fpsCounter++;
                const currentTime = performance.now();
                if (currentTime - lastTime >= 1000) {
                    const jsFps = fpsCounter * 1000 / (currentTime - lastTime);
                    const cppFps = wasmModule._getCppFps ? wasmModule._getCppFps() : 0;
                    console.log(`JS FPS: ${jsFps.toFixed(1)}, C++ FPS: ${cppFps.toFixed(1)}`);
                    fpsCounter = 0;
                    lastTime = currentTime;
                }
            } catch (e) {
                console.error('Error in render frame:', e);
            }
        }
        
        // Continue the loop
        animationId = requestAnimationFrame(renderFrame);
    }
    
    renderFrame();
}

function startDemo() {
    if (wasmModule && wasmModule._initDemo) {
        try {
            wasmModule._initDemo();
            isRunning = true;
            console.log('Demo started');
        } catch (e) {
            // The "unwind" exception is expected - it's how Emscripten starts the main loop
            if (e === "unwind") {
                isRunning = true;
                console.log('Demo started (unwind caught)');
            } else {
                console.error('Error starting demo:', e);
            }
        }
    } else {
        console.error('WASM module not ready');
    }
}

function stopDemo() {
    if (wasmModule && wasmModule._stopDemo) {
        try {
            wasmModule._stopDemo();
            isRunning = false;
            console.log('Demo stopped');
        } catch (e) {
            console.error('Error stopping demo:', e);
        }
    }
}
</script>
