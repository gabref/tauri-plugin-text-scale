use tauri::{AppHandle, Runtime, command};
use tracing::{debug, warn};

use crate::{Result, TextScaleExt};

/// Returns the current operating system text scale.
#[command]
pub(crate) async fn get_text_scale<R: Runtime>(app: AppHandle<R>) -> Result<f64> {
   match app.text_scale().scale_async().await {
      Ok(scale) => {
         debug!(scale, "returning the text scale to the frontend");
         Ok(scale)
      }
      Err(error) => {
         warn!(%error, "failed to read the text scale");
         Err(error)
      }
   }
}
