import Foundation
import Tauri
import TextScaleCore
import UIKit
import WebKit

private struct WatchArgs: Decodable {
   let channel: Channel
}

// Rust registers this class with `register_ios_plugin(init_plugin_text_scale)`.
class TextScalePlugin: Plugin {
   // Tauri runs the commands on its IPC queue, and `refresh` runs on the main thread. The
   // queue guards the state between them.
   private let stateQueue = DispatchQueue(label: "org.silvermine.plugin.textscale.state")
   private var changes = TextScaleChanges()
   private var channel: Channel?

   // Tauri creates the plugin before UIKit starts the app, so the plugin reads the text
   // size later, in `load` and when the text size changes.
   override init() {
      super.init()
      NotificationCenter.default.addObserver(
         self,
         selector: #selector(contentSizeCategoryDidChange),
         name: UIContentSizeCategory.didChangeNotification,
         object: nil
      )
   }

   // Tauri calls this on the main thread with a WebView, before the page can call a
   // command.
   override func load(webview: WKWebView) {
      refresh()
   }

   // The command returns the scale that the main thread keeps. It does not wait for the
   // main thread, because a Rust caller on the main thread would then wait forever.
   @objc public func getTextScale(_ invoke: Invoke) {
      guard let scale = stateQueue.sync(execute: { changes.scale }) else {
         invoke.reject("the text scale is not available before the app creates a WebView")
         return
      }

      invoke.resolve(["value": scale])
   }

   // Rust calls this once at setup with a channel that emits the change event.
   @objc public func watch(_ invoke: Invoke) throws {
      let args = try invoke.parseArgs(WatchArgs.self)

      stateQueue.sync {
         channel = args.channel
      }
      invoke.resolve()
   }

   // UIKit posts the notification on the main thread when the user changes the text size,
   // for every app or for this app only.
   @objc private func contentSizeCategoryDidChange() {
      refresh()
   }

   // Reads the text size on the main thread and sends a new scale on the channel.
   private func refresh() {
      let scale = Self.currentScale()
      let change = stateQueue.sync { () -> (scale: Double, channel: Channel)? in
         guard let changed = changes.update(scale), let channel else {
            return nil
         }

         return (changed, channel)
      }

      // The send runs Rust listeners on this thread. A listener that reads the scale
      // waits for `getTextScale`, which needs the state queue, so the send happens after
      // the queue is free.
      if let change {
         change.channel.send(["value": change.scale] as JsonObject)
      }
   }

   // The scale is the body font size at the app's content size category, divided by the
   // body font size at the default category, `large`. `UIFontMetrics` is not used,
   // because its scaled value differs from the body font: 22.33 points at
   // `extraExtraExtraLarge`, where the body font is 23 points.
   private static func currentScale() -> Double {
      let category = UIApplication.shared.preferredContentSizeCategory

      return IosTextScale.scale(
         bodyTextSize: bodyTextSize(at: category),
         defaultBodyTextSize: bodyTextSize(at: .large)
      )
   }

   private static func bodyTextSize(at category: UIContentSizeCategory) -> Double {
      let traits = UITraitCollection(preferredContentSizeCategory: category)
      let bodyFont = UIFont.preferredFont(forTextStyle: .body, compatibleWith: traits)

      return Double(bodyFont.pointSize)
   }
}

@_cdecl("init_plugin_text_scale")
func initPlugin() -> Plugin {
   return TextScalePlugin()
}
