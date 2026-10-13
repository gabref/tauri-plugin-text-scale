# iOS text scale manual testing

Manual iOS scenarios for the native iOS code under `ios/Sources`.

The plugin reads the app's content size category. That is, the text size that the user
chose in Settings, as one of twelve named steps. The scale is the body font size at that
category, divided by the body font size at the default category, `large`. That size is
17 points. When the text size changes, iOS posts
`UIContentSizeCategory.didChangeNotification`. The plugin then sends the new scale to
Rust, which emits `tauri-plugin-text-scale:changed`.

The iOS WebView does not scale text by itself, so an iOS app needs only iOS 15 or later
as its minimum version. See the [iOS app setup](../README.md#ios-app-setup) in the
README.

## Reference links

| Item | Link |
| ---- | ---- |
| Tauri iOS prerequisites | <https://v2.tauri.app/start/prerequisites/> |
| Tauri mobile plugin development | <https://v2.tauri.app/develop/plugins/develop-mobile/> |
| `UIFont.preferredFont(forTextStyle:compatibleWith:)` | <https://developer.apple.com/documentation/uikit/uifont/preferredfont(fortextstyle:compatiblewith:)> |
| `preferredContentSizeCategory` | <https://developer.apple.com/documentation/uikit/uiapplication/preferredcontentsizecategory> |
| `didChangeNotification` | <https://developer.apple.com/documentation/uikit/uicontentsizecategory/didchangenotification> |
| Font size for each category | <https://developer.apple.com/design/human-interface-guidelines/typography#Specifications> |

## Scenario coverage

| Scenario | Status | Expected result |
| -------- | ------ | --------------- |
| Default text size at start | Tested on a simulator | `Current scale` shows `1` |
| Larger text size at start | Tested on a simulator | `Current scale` shows the scale of the category |
| Change while the app runs | Tested on a simulator | One new entry in `Changes` with the new scale |
| Every category | Tested on a simulator | One entry for each category, with its scale from the table |
| Change while the app is in the background | Tested on a simulator | One new entry in `Changes` |
| WebView text size | Tested on a simulator | Text without the scale keeps its size |
| Text size for this app only | Not tested | One new entry in `Changes` with the new scale |

The tests ran on 2026-10-13 on an iPhone Air simulator with iOS 26.5, built with Xcode
27. No test ran on a physical device yet.

## Base test setup

Install the iOS requirements from the Tauri prerequisites: Xcode, its iOS simulator and
the Rust iOS targets.

Build the plugin's JavaScript bindings in the repository root:

```sh
npm install
npm run build
```

## Example app

Install the example's dependencies and create its iOS project:

```sh
cd examples/tauri-app
npm install
npm run tauri ios init
```

Run the example app on a simulator:

```sh
npm run tauri ios dev "iPhone Air"
```

### Xcode 27

With Xcode 27, the Tauri CLI shows the simulator as a connected physical device. The
CLI then builds for a device, and the build fails because it needs a development team.
Use these steps instead:

1. Start the development server, which also opens the project in Xcode:

   ```sh
   npm run tauri ios dev -- --open
   ```

2. In a second terminal, boot the simulator:

   ```sh
   xcrun simctl boot "iPhone Air"
   ```

3. Build the app for the simulator in `src-tauri/gen/apple`. The build needs no
   signing:

   ```sh
   xcodebuild -project tauri-app.xcodeproj -scheme tauri-app_iOS \
      -configuration debug -sdk iphonesimulator \
      -destination "platform=iOS Simulator,name=iPhone Air" \
      -derivedDataPath build ARCHS=arm64 CODE_SIGNING_ALLOWED=NO build
   ```

4. Install and start the app:

   ```sh
   xcrun simctl install booted build/Build/Products/debug-iphonesimulator/text-scale-example.app
   xcrun simctl launch booted com.silvermine.text-scale-example
   ```

## Change the text size

Use the Settings app, or set the value directly with `simctl`.

In the Settings app, open:

```text
Settings > Accessibility > Display & Text Size > Larger Text
```

To set the content size category with `simctl`:

```sh
xcrun simctl ui booted content_size extra-extra-extra-large
xcrun simctl ui booted content_size
```

This table gives the scale for each category, as the example app shows it:

| `simctl` value | Body font size | Scale |
| -------------- | -------------- | ----- |
| `extra-small` | 14 | `0.823529411764706` |
| `small` | 15 | `0.8823529411764706` |
| `medium` | 16 | `0.9411764705882352` |
| `large` | 17 | `1` |
| `extra-large` | 19 | `1.1176470588235294` |
| `extra-extra-large` | 21 | `1.2352941176470589` |
| `extra-extra-extra-large` | 23 | `1.3529411764705883` |
| `accessibility-medium` | 28 | `1.6470588235294117` |
| `accessibility-large` | 33 | `1.9411764705882353` |
| `accessibility-extra-large` | 40 | `2.3529411764705883` |
| `accessibility-extra-extra-large` | 47 | `2.764705882352941` |
| `accessibility-extra-extra-extra-large` | 53 | `3.1176470588235294` |

Two values differ from the exact division in the last digit: `extra-small` and `medium`.
Rust's JSON parser, `serde_json`, reads those numbers one bit off. The difference is
0.0000000000000001, far below one pixel.

In the Settings app, the five `accessibility-` categories need `Larger Accessibility
Sizes`. `simctl` sets them directly.

Reset the text size after testing:

```sh
xcrun simctl ui booted content_size large
```

## Useful observation commands

The example app logs each change at the `debug` level, from the
`tauri_plugin_text_scale` target. To show the log of the app on the simulator:

```sh
xcrun simctl spawn booted log stream --level debug --style compact \
   --predicate 'process == "text-scale-example" AND eventMessage CONTAINS "tauri_plugin_text_scale"'
```

## Manual scenarios

### Default text size at start

1. Set the content size category to `large`.
2. Start the example app.

Expected result: `Current scale` shows `1`, and `Changes` shows `No changes yet`.

### Larger text size at start

1. Stop the example app.
2. Set the content size category to `extra-extra-extra-large`.
3. Start the example app.

Expected result: `Current scale` shows `1.3529411764705883`, that is, 23 divided by 17.

### Change while the app runs

1. Start the example app at the `large` category.
2. Set the content size category to `extra-extra-extra-large`.

Expected result: `Changes` shows one new entry with `1.3529411764705883`, and
`Current scale` shows the same value. The sample line grows.

### Every category

1. Start the example app.
2. Set each category in the table, from `extra-small` to
   `accessibility-extra-extra-extra-large`.

Expected result: each category adds one entry with its scale from the table.

### Change while the app is in the background

1. Start the example app at the `large` category.
2. Open the Settings app, so that the example app goes to the background:

   ```sh
   xcrun simctl launch booted com.apple.Preferences
   ```

3. Set the content size category to `extra-large`.
4. Return to the example app:

   ```sh
   xcrun simctl launch booted com.silvermine.text-scale-example
   ```

Expected result: `Changes` shows one new entry with `1.1176470588235294`, and only one.
On the simulator, the entry arrived while the app was still in the background.

### WebView text size

This scenario makes sure that the WebView does not scale text by itself. The heading,
the labels and the list in the example app do not use the scale in their CSS.

1. Set the content size category to `large` and take a screenshot:

   ```sh
   xcrun simctl io booted screenshot text-size-large.png
   ```

2. Set the content size category to `accessibility-extra-extra-extra-large` and take a
   second screenshot:

   ```sh
   xcrun simctl io booted screenshot text-size-largest.png
   ```

3. Compare the two screenshots.

Expected result: the heading `Tauri Plugin Text Scale` has the same size in both
screenshots. Only the sample line, `This line is 16px times the current scale.`, is
larger in the second screenshot.

### Text size for this app only

iOS can set a text size for one app, from the `Text Size` control in Control Center.
This scenario needs a device.

1. Add `Text Size` to Control Center in the Settings app.
2. Open the example app, then open Control Center.
3. Press `Text Size`, choose the example app only, and set a larger size.
4. Return to the example app.

Expected result: `Changes` shows one new entry with the new scale.
