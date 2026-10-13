package org.silvermine.plugin.textscale

import android.app.Activity
import android.content.res.Configuration
import android.webkit.WebView
import app.tauri.annotation.Command
import app.tauri.annotation.InvokeArg
import app.tauri.annotation.TauriPlugin
import app.tauri.plugin.Channel
import app.tauri.plugin.Invoke
import app.tauri.plugin.JSObject
import app.tauri.plugin.Plugin
import org.silvermine.textscale.AndroidTextScale
import org.silvermine.textscale.TextScaleChanges

@InvokeArg
class WatchArgs {
   lateinit var channel: Channel
}

// Rust registers this class with `register_android_plugin(..., "TextScalePlugin")`.
@TauriPlugin
class TextScalePlugin(private val activity: Activity) : Plugin(activity) {
   // `watch` runs on the thread that called it from Rust, and
   // `onConfigurationChanged` runs on the main thread.
   private val lock = Any()
   private var channel: Channel? = null
   private var changes: TextScaleChanges? = null

   // The WebView sets its text zoom from the font scale, so it multiplies all text by
   // the scale on its own. A text zoom of 100 turns that off, so that the app applies the
   // scale once, where it chooses.
   //
   // Tauri calls `load` only with the first WebView. When Android recreates the activity,
   // the new WebView needs the same setting from `onWebViewCreate` in the app's activity.
   // The README shows that app code.
   override fun load(webView: WebView) {
      webView.settings.textZoom = 100
   }

   @Command
   fun getTextScale(invoke: Invoke) {
      invoke.resolve(JSObject().put("value", currentScale()))
   }

   // Rust calls this once at setup with a channel that emits the change event.
   @Command
   fun watch(invoke: Invoke) {
      val args = invoke.parseArgs(WatchArgs::class.java)

      synchronized(lock) {
         changes = TextScaleChanges(currentScale())
         channel = args.channel
      }
      invoke.resolve()
   }

   // Android calls this when the host activity lists `fontScale` in its `configChanges`.
   // Otherwise Android recreates the activity and the page loads again. The new page
   // reads the new scale with `getTextScale`, so the plugin sends no event.
   override fun onConfigurationChanged(newConfig: Configuration) {
      val scale = AndroidTextScale.fromFontScale(newConfig.fontScale)

      synchronized(lock) {
         val changed = changes?.update(scale) ?: return

         channel?.send(JSObject().put("value", changed))
      }
   }

   // Android recreates the activity after some configuration changes, but the
   // application stays, so its configuration is always the current one.
   private fun currentScale(): Double {
      val configuration = activity.applicationContext.resources.configuration

      return AndroidTextScale.fromFontScale(configuration.fontScale)
   }
}
