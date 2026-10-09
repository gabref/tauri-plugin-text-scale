//! Calls the native Android `TextScalePlugin` through a `PluginHandle`.

use serde::Deserialize;
use serde::de::DeserializeOwned;
use tauri::Runtime;
use tauri::plugin::mobile::PluginInvokeError;
use tauri::plugin::{PluginApi, PluginHandle};

const PLUGIN_IDENTIFIER: &str = "org.silvermine.plugin.textscale";

const COMMAND_GET_TEXT_SCALE: &str = "getTextScale";

#[derive(Debug, Deserialize)]
struct MobileTextScale {
   value: f64,
}

fn read_error(error: PluginInvokeError) -> crate::Error {
   crate::Error::ReadFailed(error.to_string())
}

/// Registers the native plugin and returns the `PluginHandle` wrapper.
pub(crate) fn init<R: Runtime, C: DeserializeOwned>(
   api: PluginApi<R, C>,
) -> std::result::Result<TextScale<R>, PluginInvokeError> {
   let handle = api.register_android_plugin(PLUGIN_IDENTIFIER, "TextScalePlugin")?;

   Ok(TextScale(handle))
}

/// Access to the native text scale.
pub(crate) struct TextScale<R: Runtime>(PluginHandle<R>);

impl<R: Runtime> TextScale<R> {
   /// Returns the current text scale.
   pub(crate) fn scale(&self) -> crate::Result<f64> {
      // Calls the native `getTextScale` command of `TextScalePlugin`.
      let result: MobileTextScale = self
         .0
         .run_mobile_plugin(COMMAND_GET_TEXT_SCALE, ())
         .map_err(read_error)?;

      Ok(result.value)
   }

   /// Returns the current text scale without blocking an async worker thread while
   /// Kotlin replies.
   pub(crate) async fn scale_async(&self) -> crate::Result<f64> {
      let result: MobileTextScale = self
         .0
         .run_mobile_plugin_async(COMMAND_GET_TEXT_SCALE, ())
         .await
         .map_err(read_error)?;

      Ok(result.value)
   }
}
