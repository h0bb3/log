---
layout: post
title:  "Retro Article: Detecting if a game pad is plugged in"
author: "h0bb3"
comments_id: 18
description: "Old retro C++ article from my game dev days..."
tags: "work"
---

_This is an old post from my days as an indie game dev. I post it here as I have no other copy of it than finding it on the internet archive. Enjoy :)_

In the latest download of our [shoot em up PC game TWTPB](https://spellofplay.com/games/twtpb/), iteration 23, I implemented basic game controller support. There are a number of issues with this implementation maybe the most prominent one being that it does not handle plugging in and out the game pad during play. I think that it is probably a common scenario to plug in a game controller after the game has started.

This is a short tutorial on how to get your game to react when a USB device, such as a gamepad, is plugged in or removed from the computer. This is handy when using the DirectInput API. XInput handles this in a transparent way which is nice, but alas there are many game controls that are not XInput compatible so when developing a PC game you probably need support for both plain DirectInput devices and XInput devices. This tutorial is Windows-specific and in the C++ language.

It is not that hard to get a message when a device is added or removed, but it involves some rarely used win32 code that I spent a good few hours trying to get to work.

To start things off Windows sends you the handy `WM_DEVICECHANGE` Windows message message when a device is plugged in or removed from the PC. So in your window message handling function, you should have something like this:

```c++
WndProc(HWND a_hWnd, UINT a_msg, WPARAM a_wparam, LPARAM a_lparam) {
   switch (a_msg) {
       ...
       case WM_DEVICECHANGE:
           if (a_wparam == DBT_DEVICEARRIVAL) {
               // Device plugged in code goes here
           } else if (a_wparam == DBT_DEVICEREMOVECOMPLETE) {
              // Device removed
           }
       break;
       ...
   }
   ...
}
```

There are also a number of other messages sent in the wparam parameter. So the tricky part here is that you won't get the `DBT_DEVICEARRIVAL` or `DBT_DEVICEREMOVECOMPLETE` as a default. You will only get a number of `DBT_DEVNODES_CHANGED` messages whether a device is plugged in or removed and this is obviously not what we want in our game code.

You will have to tell Windows that you want additional information when a device is added. You can do this with the RegisterDeviceNotification function. This function is quite complicated and takes a number of strange parameters. I for one love it when a function has a void pointer as a parameter, it's great, you can just send anything down there ;)

Anyway, the thing we want, is to listen to in our game is the device broadcast messages. The following code sets that up. I added this to my window creation function since you need a window handle to the main window, declared as m_hWnd in the code below. The setup is actually much easier than you think by looking at the docs.

```c++
DEV_BROADCAST_DEVICEINTERFACE notificationFilter;
ZeroMemory(&notificationFilter, sizeof(notificationFilter));
 
notificationFilter.dbcc_devicetype = DBT_DEVTYP_DEVICEINTERFACE;
notificationFilter.dbcc_size = sizeof(notificationFilter);
 
HDEVNOTIFY hDevNotify;
hDevNotify = RegisterDeviceNotification(m_hWnd, &notificationFilter,
   DEVICE_NOTIFY_WINDOW_HANDLE |
   DEVICE_NOTIFY_ALL_INTERFACE_CLASSES);
 
if(hDevNotify == NULL) {
   // do some error handling
}
```

By using the handy `DEVICE_NOTIFY_ALL_INTERFACE_CLASSES` flag we can skip most parameters in the notificationFilter parameter except type and size.

Also for this code to even compile you also need to have `WINVER defined >= 0x0500` like

```c++
#define WINVER 0x0500
```
Now Windows will send you all messages when a gamepad is attached or removed from the pc and you can take the appropriate action in your game code.

Hope you'll find this short article/tutorial handy! Feel free to comment or suggest improvements.
