---
layout: post
title:  "Flash Diet"
description: "a tale of shrinking binaries...."
author: "h0bb3"
comments_id: 19
tags: "programming esp32 flash optimization size development"
---

## My ESP32 Flash Went on a Diet: A Tale of Shrinking Binaries

I’ve been on a quest. A quest to shrink the flash size of my ESP32 application. After many hours of tweaking, compiling, and measuring, I’m excited to share my results. I managed to reduce my binary size from a hefty **1,256,240 bytes** down to a lean **973,024 bytes**, a saving of **283,216 bytes**!

Here's a breakdown of my journey, from the biggest wins to the final few bytes I could squeeze out. I've also researched the potential consequences of each optimization so you can decide if these trade-offs are right for your project.

### The Heavy Hitters: Where the Real Savings Are

These are the optimizations that made the biggest difference. If you're looking to make a serious dent in your flash usage, start here.

* **Minimal Build (69,408 bytes saved):** This was the single biggest saving. By enabling the "minimal build" option in the ESP-IDF, you're telling the compiler to strip out a lot of features that you might not be using.
    * **Consequences:** None really, performance may be suffering in some theoretical scenario. Just go for it!
* **Removing Major Components (49,664 bytes saved):** I ripped out MQTT, SPI Ethernet, and Soft AP support.
    * **Consequences:**
        * **MQTT:** You lose the ability to use this popular IoT protocol. If you're not using it, it's a no-brainer to remove it.
        * **SPI Ethernet:** If you're not using a wired Ethernet connection, this is safe to remove.
        * **Soft AP:** Your ESP32 can no longer act as a Wi-Fi access point. This is often used for initial configuration, so make sure you have an alternative provisioning method if you disable this.

* **Embrace the NanoLib (46,992 bytes saved):** I enabled the `newlib-nano` library. This is a smaller version of the standard C library.
    * **Consequences:** `newlib-nano` has some limitations. For example, it has limited support for floating-point operations in `printf`. You might also encounter issues with some libraries that expect the full `newlib`.

* **Goodbye IPv6 (29,120 bytes saved):** I disabled IPv6 support.
    * **Consequences:** Your device will not be able to communicate over IPv6 networks. In most home networks, this is not an issue, but if your application needs to work in an IPv6-only environment, this is not an option for you.

* **Downgrading Wi-Fi Security (19,968 bytes saved):** I disabled WPA3 Personal support.
    * **Consequences:** This is a security trade-off. WPA3 is the latest and most secure Wi-Fi security protocol. By disabling it, you are making your device less secure and more vulnerable to attacks. Only do this if you are on a private, trusted network.

### The Nitty-Gritty: Smaller Tweaks, Big Impact

These optimizations don't save as much space individually, but they add up.

* **BLE Diet (17,712 bytes, 15,808 bytes, 11,648 bytes, and 10,336 bytes saved):** I made several changes to the Bluetooth Low Energy stack:
    * **No BLE 5 features:** Disabling BLE 5 features.
    * **Removed BLE security feature:** This will make your BLE communication insecure.
    * **Removed nimble central role:** This may break the MTU (Maximum Transmission Unit) size negotiation.
    * **No nimble logs:** Disabling logs from the NimBLE stack.
    * **Consequences:** These changes will significantly impact your BLE functionality. You'll have a less secure, less feature-rich, and potentially less reliable BLE implementation.

* **ECC on a Diet (9,632 bytes saved):** I removed a lot of ECC (Elliptic Curve Cryptography) curve support.
    * **Consequences:** This will limit the types of TLS certificates your device can use. If you are connecting to a server that uses a certificate with an unsupported curve, the connection will fail.

### The Final Squeeze: Every Byte Counts

These are the smallest optimizations, but they still contributed to the final result.

* **Silent Asserts (2,208 bytes saved):** I enabled silent asserts.
    * **Consequences:** This will make debugging more difficult. When an assert fails, the device will simply crash without printing a message.

* **Less Wi-Fi Security (528 bytes saved):** I disabled enterprise WPA2.
    * **Consequences:** If you are not connecting to an enterprise Wi-Fi network that uses WPA2, this is safe to disable.

* **Certificate Pruning (272 bytes saved):** I enabled only PEM certificate reading.
    * **Consequences:** Your device will only be able to read certificates in the PEM format.

* **Wi-Fi AMPDU Tweaks (80 bytes saved):** I disabled `CONFIG_ESP_WIFI_AMPDU_TX_ENABLED`.
    * **Consequences:** This may slightly reduce Wi-Fi throughput.

### Was It Worth It?

That's the big question, isn't it? For my project, absolutely. The flash space I saved allows me to add more features and have more breathing room for future development. However, many of these optimizations come with significant trade-offs in terms of security, functionality, and ease of debugging.

Before you go on your own flash-shrinking adventure, carefully consider the consequences of each optimization and whether it's a price you're willing to pay. Happy optimizing!

Got some other ideas? Comments are open!
