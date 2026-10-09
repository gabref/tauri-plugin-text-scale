# Android text scale manual testing

Manual Android scenarios for the native Android code under `android/src/main/java`.

The plugin reads `Configuration.fontScale` from the activity. When the font scale
changes, Android calls the plugin's `onConfigurationChanged`. The plugin then sends the
new scale to Rust, which emits `tauri-plugin-text-scale:changed`. When the plugin
loads, it sets the WebView's `textZoom` to `100`, so that the WebView does not scale
text by itself. The app sets the same value on each later WebView, as the
[Android app setup](../README.md#android-app-setup) in the README asks.

## Reference links

| Item | Link |
| ---- | ---- |
| Tauri Android prerequisites | <https://v2.tauri.app/start/prerequisites/> |
| Tauri mobile plugin development | <https://v2.tauri.app/develop/plugins/develop-mobile/> |
| `Configuration.fontScale` | <https://developer.android.com/reference/android/content/res/Configuration#fontScale> |
| Handle configuration changes | <https://developer.android.com/guide/topics/resources/runtime-changes> |
| `WebSettings.setTextZoom` | <https://developer.android.com/reference/android/webkit/WebSettings#setTextZoom(int)> |

## Scenario coverage

| Scenario | Status | Expected result |
| -------- | ------ | --------------- |
| Default font size at start | Tested on an emulator | `Current scale` shows `1` |
| Larger font size at start | Tested on an emulator | `Current scale` shows the font scale, for example `1.3` |
| Change while the app runs | Tested on an emulator | One new entry in `Changes` with the new scale |
| Rotation | Tested on an emulator | No new entry in `Changes` |
| Smallest and largest font size | Tested on an emulator | The scale matches `font_scale`, for example `0.85` and `2` |
| WebView text zoom | Tested on an emulator | Text without the scale keeps its size at every font size |
| Activity recreation | Tested on an emulator | Text without the scale keeps its size in the new WebView |

The tests ran on 2026-10-12 on an Android 17 (API 37) emulator. No test ran on a
physical device yet.

## Base test setup

Install the Android requirements from the Tauri prerequisites: Android Studio, the
Android SDK, the NDK, JDK 17 and the Rust Android targets.

Build the plugin's JavaScript bindings in the repository root:

```sh
npm install
npm run build
```

Make sure that `adb` can see the test device:

```sh
adb devices
```

The device must show the `device` state:

```text
List of devices attached
90859562    device
```

## Example app

Install the example's dependencies and create its Android project:

```sh
cd examples/tauri-app
npm install
npm run tauri android init
```

The generated project does not have the two changes from the
[Android app setup](../README.md#android-app-setup) in the README. The project is not
in version control, so make both changes after each `tauri android init`:

1. Open `src-tauri/gen/android/app/src/main/AndroidManifest.xml` and add `fontScale` to
   `android:configChanges` on the main activity:

   ```xml
   android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|smallestScreenSize|screenLayout|uiMode|fontScale"
   ```

2. Open `MainActivity.kt` in
   `src-tauri/gen/android/app/src/main/java/com/silvermine/text_scale_example/` and add
   the `onWebViewCreate` override to the class:

   ```kotlin
   override fun onWebViewCreate(webView: android.webkit.WebView) {
      webView.settings.textZoom = 100
   }
   ```

Run the example app on the device:

```sh
npm run tauri android dev
```

## Change the font size

Use the Settings app, or set the value directly with `adb`.

In the Settings app, open:

```text
Settings > Display > Display size and text > Font size
```

The path to the setting can be different on each Android vendor.

To set the font scale with `adb`:

```sh
adb shell settings put system font_scale 1.3
adb shell settings get system font_scale
```

Reset the font scale after testing:

```sh
adb shell settings put system font_scale 1.0
```

## Useful observation commands

```sh
adb logcat -s RustStdoutStderr Tauri
```

The example app logs each change at the `debug` level, from the
`tauri_plugin_text_scale` target.

## Manual scenarios

### Default font size at start

1. Set the font scale to `1.0`.
2. Start the example app.

Expected result: `Current scale` shows `1`, and `Changes` shows `No changes yet`.

### Larger font size at start

1. Stop the example app.
2. Set the font scale to `1.3`.
3. Start the example app.

Expected result: `Current scale` shows `1.3`, not `1.2999999523162842`.

### Change while the app runs

1. Start the example app at a font scale of `1.0`.
2. Set the font scale to `1.3`.
3. Return to the example app.

Expected result: `Changes` shows one new entry with `1.3`, and `Current scale` shows
`1.3`. The sample line grows. Android did not recreate the activity: entries from
before the change are still in the list.

Press `Read again`. `Current scale` still shows `1.3`.

### Rotation

1. Start the example app.
2. Turn the device a quarter turn, then turn it back.

Expected result: `Changes` shows no new entry.

### Smallest and largest font size

1. Set the font scale to the smallest value in the Settings app, for example `0.85`.
2. Set the font scale to the largest value in the Settings app, for example `2.0`.

Expected result: each change adds one entry with the same value as
`adb shell settings get system font_scale`.

### WebView text zoom

This scenario makes sure that the WebView does not scale text by itself. The heading,
the labels and the list in the example app do not use the scale in their CSS.

1. Set the font scale to `1.0` and take a screenshot:

   ```sh
   adb exec-out screencap -p > font-scale-1.png
   ```

2. Set the font scale to `2.0` and take a second screenshot:

   ```sh
   adb exec-out screencap -p > font-scale-2.png
   ```

3. Compare the two screenshots.

Expected result: the heading `Tauri Plugin Text Scale` has the same size in both
screenshots. Only the sample line, `This line is 16px times the current scale.`, is
larger in the second screenshot, at twice its first size.

If the heading also grows, the WebView still scales text by itself.

### Activity recreation

This scenario checks the text zoom in the new WebView after Android recreates the
activity. A change to the display size recreates it, because the example does not list
`density` in `configChanges`.

1. Set the font scale to `2.0` and start the example app.
2. Take a screenshot:

   ```sh
   adb exec-out screencap -p > recreate-1.png
   ```

3. Change the display size and set it back. Android recreates the activity each time,
   and the page loads again:

   ```sh
   adb shell wm density 480
   adb shell wm density reset
   ```

4. Take a second screenshot:

   ```sh
   adb exec-out screencap -p > recreate-2.png
   ```

5. Compare the two screenshots.

Expected result: the heading `Tauri Plugin Text Scale` has the same size in both
screenshots, and `Current scale` shows `2`.

If the heading is larger in the second screenshot, the new WebView scales text by
itself. Make sure that `MainActivity` has the `onWebViewCreate` override.
