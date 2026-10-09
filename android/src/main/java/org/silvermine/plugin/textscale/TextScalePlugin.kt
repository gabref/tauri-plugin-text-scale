package org.silvermine.plugin.textscale

import android.app.Activity
import app.tauri.annotation.Command
import app.tauri.annotation.TauriPlugin
import app.tauri.plugin.Invoke
import app.tauri.plugin.JSObject
import app.tauri.plugin.Plugin
import org.silvermine.textscale.AndroidTextScale

// Rust registers this class with `register_android_plugin(..., "TextScalePlugin")`.
@TauriPlugin
class TextScalePlugin(private val activity: Activity) : Plugin(activity) {
   @Command
   fun getTextScale(invoke: Invoke) {
      invoke.resolve(JSObject().put("value", currentScale()))
   }

   // Android recreates the activity after some configuration changes, but the
   // application stays, so its configuration is always the current one.
   private fun currentScale(): Double {
      val configuration = activity.applicationContext.resources.configuration

      return AndroidTextScale.fromFontScale(configuration.fontScale)
   }
}
