# HiThere

Popup an image beside the cursor.

<p align="left"><img src="/demo.gif" width="550"></p>

Feel annoyed and shake your mouse crazily? Place something or someone that makes you smile.

## How to use

- [download](https://github.com/leavez/HiThere/issues/1) and run the app (no system authority required)
- shake your mouse rapidly ( more then 5 times )
- no step 3

Custom image is supported.

## How did you do that?

Actually it’s much easier than you may think. The key concept is that the view besides cursor is an application window.
- Make a floating window, so it can show above other windows even it's not active.
- Observe the position of cursor. Analyze the trace to detect a mouse shake. And move the window if triggered.


## License

MIT
