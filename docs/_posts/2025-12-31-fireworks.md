---
layout: post
title:  "Fireworks Demo"
description: "New Year's Eve special"
author: "h0bb3"
comments_id: 22
tags: "programming wasm graphics development effects particles fireworks"
---

# Particle Systems: The Art of Making Things Go Boom

*Or: How I celebrated New Year's Eve by watching colored dots fall down*

## What's a Particle System Anyway?

If plasma effects are mathematical fever dreams, then particle systems are controlled chaos. Instead of computing fancy sine waves for every pixel, you throw a bunch of tiny objects into the world and let physics do the heavy lifting.

The basic idea is beautifully simple:
1. Spawn particles with position, velocity, and color
2. Apply forces (gravity, wind, whatever)
3. Update positions each frame
4. Kill particles when they're done
5. Repeat

It's like playing god with tiny colored dots. Very satisfying.

## The Demoscene Connection

Particle systems have been a demoscene staple since forever. Fire effects, star fields, explosions - they all use the same basic principle. What makes fireworks special is the combination of multiple particle types: rockets that climb upward, then explode into showers of sparks that fall with gravity.

The classic approach:

```c
struct Particle {
    float x, y;       // Position
    float vx, vy;     // Velocity
    float life;       // Time remaining
    uint8_t r, g, b;  // Color
    bool active;      // Is this slot in use?
};
```

Nothing fancy. No quaternions, no spatial partitioning, no GPU compute shaders. Just good old arrays and loops.

## The Implementation

The fireworks effect uses two types of objects:

**Rockets** - They launch from the bottom, travel upward with slight drift, and explode when they reach their target height.

**Particles** - Spawned in bursts when rockets explode. They inherit the rocket's color (with variation), spread in all directions, and fall with gravity while fading out.

```c
void explode(float x, float y, uint8_t r, uint8_t g, uint8_t b) {
    int numParticles = 40 + (rand() % 40);

    for (int i = 0; i < numParticles; i++) {
        float angle = randFloat() * 2.0f * M_PI;
        float speed = randRange(0.5f, 2.5f);

        particle.x = x;
        particle.y = y;
        particle.vx = cosf(angle) * speed;
        particle.vy = sinf(angle) * speed;
        particle.life = randRange(0.8f, 1.5f);
        // ... color assignment
    }
}
```

The key insight: randomness is your friend. Random spawn positions, random velocities, random lifetimes, random color variations. It all adds up to organic-looking chaos.

## The Old-School Color Palette

For that authentic retro vibe, I went with a fixed 12-color palette of bright, saturated colors:

```c
static uint8_t colorPalette[12][3] = {
    {255, 0, 0},       // Red
    {255, 128, 0},     // Orange
    {255, 255, 0},     // Yellow
    {0, 255, 0},       // Green
    {0, 255, 255},     // Cyan
    {0, 128, 255},     // Light Blue
    {128, 0, 255},     // Purple
    {255, 0, 255},     // Magenta
    {255, 0, 128},     // Pink
    {255, 255, 255},   // White
    {255, 200, 100},   // Gold
    {100, 255, 200},   // Mint
};
```

No subtle gradients, no HSL color space calculations. Just pure, punchy colors that would feel right at home on an Amiga 500.

## Explosion Styles

One thing that makes particle systems fun is how easy it is to create variations. The effect supports four explosion styles:

1. **Classic** - Random spherical burst with varied speeds
2. **Rings** - Evenly-spaced particles in a perfect circle
3. **Burst** - Multiple concentric rings with different colors
4. **Double** - Classic explosion with a white ring overlay

The code difference between them is minimal - just how you calculate the initial angles and speeds:

```c
// Ring explosion - evenly spaced
float angle = (float)i / numParticles * 2.0f * M_PI;
float speed = 2.0f;  // Fixed speed for clean circles

// Classic explosion - random
float angle = randFloat() * 2.0f * M_PI;
float speed = randRange(0.5f, 2.5f);
```

## The Trail Effect

The glowing trails come from a simple trick: instead of clearing the screen each frame, we *fade* it. Each pixel's RGB values get decremented by a small amount:

```c
void fadeBuffer(uint8_t* buffer, int fadeAmount) {
    for (int i = 0; i < width * height * 4; i += 4) {
        buffer[i] = buffer[i] > fadeAmount ? buffer[i] - fadeAmount : 0;
        buffer[i+1] = buffer[i+1] > fadeAmount ? buffer[i+1] - fadeAmount : 0;
        buffer[i+2] = buffer[i+2] > fadeAmount ? buffer[i+2] - fadeAmount : 0;
    }
}
```

This creates persistence of vision - particles leave trails that slowly fade to black. It's computationally cheap and visually effective. Win-win.

## Try It Yourself!

For a [full screen version of the fireworks effect go here.](https://h0bb3.github.io/log/assets/wasm-demos/fireworks/)

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
        <p>Fireworks - Press 1-4 to switch styles (Current: Classic)</p>
    </div>

    <div class="render-mode-controls">
        <button id="classicBtn" class="render-mode-btn active">Classic</button>
        <button id="ringsBtn" class="render-mode-btn">Rings</button>
        <button id="burstBtn" class="render-mode-btn">Burst</button>
        <button id="doubleBtn" class="render-mode-btn">Double</button>
    </div>
</div>

Try the different explosion styles. "Rings" gives you clean geometric patterns, "Burst" is colorful chaos, and "Double" adds that extra pop with the white overlay.

## Performance Notes

With up to 2000 active particles and 8 rockets, we're still comfortably hitting 120 FPS on the C++ side. The particle update loop is simple enough that it barely registers:

```c
void updateParticles(float dt) {
    for (int i = 0; i < MAX_PARTICLES; i++) {
        if (!particles[i].active) continue;

        particles[i].x += particles[i].vx;
        particles[i].y += particles[i].vy;
        particles[i].vy += gravity * dt;  // Gravity
        particles[i].vx *= 0.99f;         // Air resistance
        particles[i].vy *= 0.99f;
        particles[i].life -= dt;

        if (particles[i].life <= 0) {
            particles[i].active = false;
        }
    }
}
```

No spatial partitioning needed. No quad trees. Just a flat array and a tight loop. Sometimes the simple solution is the right one.

## Lessons Learned

1. **Particle pools beat dynamic allocation** - Pre-allocate your particles and cycle through them
2. **Randomness creates life** - Small variations in speed, angle, and lifetime make everything feel organic
3. **Fade buffers are magic** - One simple trick gives you trails, glow, and motion blur all at once
4. **Keep it simple** - 2000 particles with basic physics looks better than 200 with complex behaviors

## What's Next?

This framework is begging for more effects. Snow, rain, fire, smoke... the particle system is infinitely extensible. Maybe I'll add mouse interaction - click to launch rockets. Or gravity wells that attract particles. Or...

*No, stop. Ship it. You can always add features later.*

Happy New Year! May your particles always fall gracefully and your frame rates stay high.

---

**Technical Summary:**
- **Particles**: Up to 2000 simultaneous
- **Rockets**: Up to 8 active
- **Colors**: 12-color retro palette
- **Explosion styles**: 4 (Classic, Rings, Burst, Double)
- **Physics**: Gravity + air resistance
- **Trail effect**: Frame fade at 15 units/frame



<script src="/log/assets/wasm-demos/fireworks/fireworks.js"></script>

<script>
    let wasmModule = null;
    let isRunning = false;
    let pixelBuffer = null;
    let imageData = null;
    const modeNames = ['Classic', 'Rings', 'Burst', 'Double'];

    window.addEventListener('load', async () => {
        console.log('Page loaded, setting up WASM module...');
        try {
            if (Module && Module._initDemo) {
                console.log('WASM module already initialized');
                setupDemo();
            } else {
                Module.onRuntimeInitialized = function() {
                    console.log('WASM module initialized');
                    setupDemo();
                };
            }

            function setupDemo() {
                console.log('Available functions:', Object.keys(Module).filter(key => key.startsWith('_')));

                const canvas = document.getElementById('canvas');
                const startBtn = document.getElementById('startBtn');
                const stopBtn = document.getElementById('stopBtn');
                const resetBtn = document.getElementById('resetBtn');
                const classicBtn = document.getElementById('classicBtn');
                const ringsBtn = document.getElementById('ringsBtn');
                const burstBtn = document.getElementById('burstBtn');
                const doubleBtn = document.getElementById('doubleBtn');
                const modeButtons = [classicBtn, ringsBtn, burstBtn, doubleBtn];

                startBtn.addEventListener('click', () => {
                    if (!isRunning) {
                        startDemo();
                    }
                });

                stopBtn.addEventListener('click', () => {
                    if (isRunning) {
                        stopDemo();
                    }
                });

                resetBtn.addEventListener('click', () => {
                    resetDemo();
                });

                modeButtons.forEach((btn, index) => {
                    btn.addEventListener('click', () => {
                        if (Module && Module._setRenderMode) {
                            Module._setRenderMode(index);
                            updateRenderModeDisplay();
                            updateRenderModeButtons(index);
                        }
                    });
                });

                document.addEventListener('keydown', (e) => {
                    const keyNum = parseInt(e.key);
                    if (keyNum >= 1 && keyNum <= 4) {
                        const modeIndex = keyNum - 1;
                        if (Module && Module._setRenderMode) {
                            Module._setRenderMode(modeIndex);
                            updateRenderModeDisplay();
                            updateRenderModeButtons(modeIndex);
                        }
                    }
                });

                console.log('WASM module loaded successfully');

                const ctx = canvas.getContext('2d');
                imageData = ctx.createImageData(canvas.width, canvas.height);

                console.log('Setup complete, ready for user to start demo');
            }

        } catch (error) {
            console.error('Failed to load WASM module:', error);
        }

        setTimeout(() => {
            if (!Module || !Module._initDemo) {
                console.error('WASM module not loaded after 5 seconds');
                const startBtn = document.getElementById('startBtn');
                if (startBtn) {
                    startBtn.disabled = false;
                    startBtn.addEventListener('click', () => {
                        alert('WASM module failed to load. Please check the console for errors.');
                    });
                }
            }
        }, 5000);
    });

    let renderingLoopId = null;

    function startRenderingLoop() {
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
                    console.warn('Error in rendering loop:', error);
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
        console.log('startDemo called, isRunning:', isRunning);

        if (Module && Module._initDemo) {
            try {
                Module._initDemo();
                isRunning = true;

                document.getElementById('startBtn').disabled = true;
                document.getElementById('stopBtn').disabled = false;

                console.log('Demo started successfully');
            } catch (error) {
                if (error === 'unwind') {
                    console.log('Main loop started (unwind is expected)');
                    isRunning = true;

                    document.getElementById('startBtn').disabled = true;
                    document.getElementById('stopBtn').disabled = false;

                    startRenderingLoop();
                    updateRenderModeDisplay();

                    if (Module && Module._getRenderMode) {
                        const currentMode = Module._getRenderMode();
                        updateRenderModeButtons(currentMode);
                    }

                } else {
                    console.error('Error starting demo:', error);
                    isRunning = false;
                    document.getElementById('startBtn').disabled = false;
                    document.getElementById('stopBtn').disabled = true;
                }
            }
        } else {
            console.error('Module or _initDemo not available');
        }
    }

    function stopDemo() {
        console.log('stopDemo called, isRunning:', isRunning);

        stopRenderingLoop();

        if (Module && Module._stopDemo) {
            try {
                Module._stopDemo();
            } catch (error) {
                console.error('Error stopping demo:', error);
            }
        }

        isRunning = false;

        document.getElementById('startBtn').disabled = false;
        document.getElementById('stopBtn').disabled = true;

        console.log('Demo stopped');
    }

    function resetDemo() {
        if (Module && Module._resetDemo) {
            Module._resetDemo();

            const canvas = document.getElementById('canvas');
            const ctx = canvas.getContext('2d');
            ctx.fillStyle = '#000';
            ctx.fillRect(0, 0, canvas.width, canvas.height);

            console.log('Demo reset');
        }
    }

    function updateRenderModeDisplay() {
        if (Module && Module._getRenderMode) {
            const mode = Module._getRenderMode();
            const modeText = modeNames[mode] || 'Classic';
            const infoElement = document.querySelector('.info p');
            if (infoElement) {
                infoElement.innerHTML = `Fireworks - Press 1-4 to switch styles (Current: ${modeText})`;
            }
        }
    }

    function updateRenderModeButtons(activeMode) {
        const buttons = ['classicBtn', 'ringsBtn', 'burstBtn', 'doubleBtn'];
        buttons.forEach((btnId, index) => {
            const btn = document.getElementById(btnId);
            if (btn) {
                btn.classList.toggle('active', index === activeMode);
            }
        });
    }
</script>
