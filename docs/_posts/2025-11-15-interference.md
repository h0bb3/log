---
layout: post
title:  "Interference Patterns"
description: "Moiré magic"
author: "h0bb3"
comments_id: 23
tags: "programming wasm graphics development effects interference patterns"
---

# Wave Interference: When Sine Waves Collide

*Or: Making hypnotic patterns with basic trigonometry*

## The Beauty of Interference

Wave interference is one of those phenomena that's simple in concept but mesmerizing in practice. When two waves overlap, they can reinforce each other (constructive interference) or cancel each other out (destructive interference). The result? Those beautiful moiré patterns you see when two chain-link fences overlap, or when you look through two layers of sheer fabric.

In this demo, we create two circular wave patterns emanating from moving center points, then combine them in various ways to produce different visual effects.

## The Core Concept

Each wave pattern is essentially a series of concentric circles radiating from a center point. The brightness at any pixel depends on its distance from the center:

```c
float distance = getDistanceToCenter(x, y);
float wave = sin(distance * frequency + time);
```

The magic happens when you have *two* center points that move independently:

```c
// Two oscillating centers
int center_x1 = width/2 + sin(time * 0.5) * width/2;
int center_y1 = height/2 + sin(time * -0.2) * height/2;
int center_x2 = width/2 + sin(time * -0.7) * width/2;
int center_y2 = height/2 + sin(time * 0.1) * height/2;
```

Each center traces its own path across the screen, creating constantly shifting interference patterns.

## Seven Ways to Combine Waves

The interesting part is how you combine the two wave values. This demo offers seven different modes:

**Mode 0: Add** - Simply add the two wave values together. Where both are positive, you get white. Where both are negative, black. Mixed areas create the interference fringes.

**Mode 1: If Sum > 0** - Binary threshold on the sum. Creates sharp, high-contrast patterns.

**Mode 2: Average** - Takes the mean of both waves. Smoother than addition.

**Mode 3: Only Pattern 1** - Shows just the first wave source. Useful for understanding what each contributes.

**Mode 4: Only Pattern 2** - Shows just the second wave source.

**Mode 5: If Either > 0** - OR logic. White if either wave is positive. Creates denser patterns.

**Mode 6: Binary OR** - Bit manipulation on the sign bits. A fun hack that produces interesting results:

```c
uint32_t sign1 = (*(uint32_t*)&int1) >> 31;
uint32_t sign2 = (*(uint32_t*)&int2) >> 31;
uint8_t color = sign1 | sign2;
```

## The Black and White Aesthetic

Unlike the colorful plasma effect, interference patterns work best in stark black and white. The binary nature emphasizes the wave structure - you can clearly see the constructive and destructive interference zones. It's like looking at a physics textbook illustration, except it's moving and hypnotic.

```c
#define PALETTE_SIZE 2
static uint32_t palette[PALETTE_SIZE];

void initPalette() {
    palette[0] = 0xFF000000; // Black (ARGB)
    palette[1] = 0xFFFFFFFF; // White
}
```

## Performance: LUTs Strike Again

Just like with the plasma effect, we use lookup tables for performance:

1. **Distance LUT** - Pre-calculated distances from every pixel to every possible center position (at 2x resolution for smooth movement)
2. **Sine LUT** - 4096-entry table for fast sine approximation

The distance LUT is the expensive one - it needs to cover a range larger than the screen since the wave centers can move around:

```c
void initDistanceLUT() {
    int width = getCurrentCanvasWidth() * 2;
    int height = getCurrentCanvasHeight() * 2;

    distanceLUT = (float*)malloc(width * height * sizeof(float));

    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            distanceLUT[y * width + x] = getDistanceToCenter(x, y, width, height);
        }
    }
}
```

## Try It Yourself!

For a [full screen version of the interference effect go here.](https://h0bb3.github.io/log/assets/wasm-demos/interference/)

<div style="text-align: center; margin: 30px 0;">
    <canvas id="canvas" width="512" height="320"></canvas>

    <div class="controls">
        <button id="startBtn">Start</button>
        <button id="stopBtn" disabled>Stop</button>
        <button id="resetBtn">Reset</button>
    </div>

    <div class="fps-display" id="fpsDisplay">
        <div>C++ FPS: 0</div>
    </div>

    <div class="info">
        <p>Interference - Press 1-7 to switch modes (Current: Add)</p>
    </div>

    <div class="render-mode-controls">
        <button id="mode0Btn" class="render-mode-btn active">Add</button>
        <button id="mode1Btn" class="render-mode-btn">If Sum > 0</button>
        <button id="mode2Btn" class="render-mode-btn">Average</button>
        <button id="mode3Btn" class="render-mode-btn">Pattern 1</button>
        <button id="mode4Btn" class="render-mode-btn">Pattern 2</button>
        <button id="mode5Btn" class="render-mode-btn">Either > 0</button>
        <button id="mode6Btn" class="render-mode-btn">Binary OR</button>
    </div>
</div>

Try switching between modes to see how different combination methods produce dramatically different patterns. Mode 1 and Mode 6 give you the sharpest contrast, while Mode 2 is the smoothest.

## The Physics Connection

What we're simulating here is analogous to real wave interference - the same phenomenon that creates:

- **Moiré patterns** in overlapping grids
- **Newton's rings** in optics
- **Interference fringes** in the famous double-slit experiment
- **Beat frequencies** in audio

The math is the same whether you're dealing with light, sound, or pixels on a screen. Two periodic functions, when combined, create these emergent patterns that seem far more complex than their simple origins would suggest.

## Conclusion

Interference patterns demonstrate how complexity can emerge from simplicity. Two sine waves, two moving points, and some basic arithmetic - that's all it takes to create endlessly fascinating visuals. The seven combination modes show that even with the same input waves, the *method* of combination dramatically affects the output.

Sometimes constraints breed creativity. A two-color palette forces you to think about the fundamental wave structure rather than hiding imperfections behind color gradients. And honestly, there's something timeless about black and white graphics - they could run on a 1980s computer or a 2025 browser, and they'd look equally striking on both.

---

**Technical Summary:**
- **Wave sources**: 2 independently moving center points
- **Combination modes**: 7 different methods
- **Palette**: Binary (black and white)
- **Optimizations**: Distance LUT (2x resolution), Sine LUT (4096 entries)
- **Resolution**: Supports multiple aspect ratios (4:3, 16:10, 10:16)



<script src="/log/assets/wasm-demos/interference/interference.js"></script>

<script>
    let isRunning = false;
    let imageData = null;
    const modeNames = ['Add', 'If Sum > 0', 'Average', 'Pattern 1', 'Pattern 2', 'Either > 0', 'Binary OR'];

    window.addEventListener('load', () => {
        try {
            if (Module && Module._initDemo) {
                console.log('WASM module already initialized');
                setupDemo();
            } else {
                Module.onRuntimeInitialized = function() {
                    console.log('WASM runtime ready');
                    setupDemo();
                };
            }
        } catch (error) {
            console.error('Error initializing WASM:', error);
        }

        setTimeout(() => {
            if (!Module || !Module._initDemo) {
                console.error('WASM module failed to initialize');
            }
        }, 5000);
    });

    function setupDemo() {
        const canvas = document.getElementById('canvas');
        const startBtn = document.getElementById('startBtn');
        const stopBtn = document.getElementById('stopBtn');
        const resetBtn = document.getElementById('resetBtn');

        startBtn.addEventListener('click', () => {
            if (!isRunning) startDemo();
        });

        stopBtn.addEventListener('click', () => {
            if (isRunning) stopDemo();
        });

        resetBtn.addEventListener('click', () => {
            if (Module && Module._resetDemo) Module._resetDemo();
        });

        // Mode buttons
        for (let i = 0; i < 7; i++) {
            const btn = document.getElementById(`mode${i}Btn`);
            if (btn) {
                btn.addEventListener('click', () => {
                    if (Module && Module._setRenderMode) {
                        Module._setRenderMode(i);
                        updateModeButtons(i);
                        updateModeDisplay(i);
                    }
                });
            }
        }

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            const keyNum = parseInt(e.key);
            if (keyNum >= 1 && keyNum <= 7) {
                const modeIndex = keyNum - 1;
                if (Module && Module._setRenderMode) {
                    Module._setRenderMode(modeIndex);
                    updateModeButtons(modeIndex);
                    updateModeDisplay(modeIndex);
                }
            }
        });

        const ctx = canvas.getContext('2d');
        imageData = ctx.createImageData(canvas.width, canvas.height);

        console.log('Setup complete');
    }

    function updateModeButtons(activeMode) {
        for (let i = 0; i < 7; i++) {
            const btn = document.getElementById(`mode${i}Btn`);
            if (btn) {
                btn.classList.toggle('active', i === activeMode);
            }
        }
    }

    function updateModeDisplay(mode) {
        const infoElement = document.querySelector('.info p');
        if (infoElement) {
            infoElement.innerHTML = `Interference - Press 1-7 to switch modes (Current: ${modeNames[mode]})`;
        }
    }

    let renderingLoopId = null;

    function startRenderingLoop() {
        const canvas = document.getElementById('canvas');

        function renderFrame() {
            if (!isRunning) return;

            if (Module && Module._getPixelBuffer && imageData) {
                try {
                    const bufferPtr = Module._getPixelBuffer();
                    if (bufferPtr) {
                        const buffer = new Uint8Array(Module.HEAPU8.buffer, bufferPtr, 512 * 320 * 4);
                        imageData.data.set(buffer);

                        const ctx = canvas.getContext('2d');
                        ctx.putImageData(imageData, 0, 0);

                        const fpsDisplay = document.getElementById('fpsDisplay');
                        const cppFps = Module._getCppFps ? Module._getCppFps() : 0;
                        fpsDisplay.innerHTML = `<div>C++ FPS: ${Math.round(cppFps)}</div>`;
                    }
                } catch (error) {
                    console.warn('Render error:', error);
                }
            }

            renderingLoopId = requestAnimationFrame(renderFrame);
        }

        renderingLoopId = requestAnimationFrame(renderFrame);
    }

    function stopRenderingLoop() {
        if (renderingLoopId) {
            cancelAnimationFrame(renderingLoopId);
            renderingLoopId = null;
        }
    }

    function startDemo() {
        if (Module && Module._initDemo) {
            try {
                Module._initDemo();
                isRunning = true;
                document.getElementById('startBtn').disabled = true;
                document.getElementById('stopBtn').disabled = false;
            } catch (error) {
                if (error === 'unwind') {
                    isRunning = true;
                    document.getElementById('startBtn').disabled = true;
                    document.getElementById('stopBtn').disabled = false;
                    startRenderingLoop();
                } else {
                    console.error('Start error:', error);
                }
            }
        }
    }

    function stopDemo() {
        stopRenderingLoop();
        if (Module && Module._stopDemo) {
            try {
                Module._stopDemo();
            } catch (error) {
                console.error('Stop error:', error);
            }
        }
        isRunning = false;
        document.getElementById('startBtn').disabled = false;
        document.getElementById('stopBtn').disabled = true;
    }
</script>
