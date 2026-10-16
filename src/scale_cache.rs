//! The text scale that the Windows module keeps for readers on any thread.
//!
//! The module lives apart from the Windows API, so its tests run on every host.

use std::sync::atomic::{AtomicU64, Ordering};

/// The text scale at Windows' default text size, which is also the scale that the plugin
/// reports when it cannot read the setting.
pub(crate) const DEFAULT_TEXT_SCALE: f64 = 1.0;

/// The bits of `0.0`, which [`valid_scale`] rejects, so no stored scale can match them.
const UNSET: u64 = 0;

/// Returns `raw` when it can be a text scale: a finite number above zero.
///
/// Windows documents the scale as a value from `1` to `2.25`. The check does not enforce
/// that range, so a later Windows version that widens it still reaches the app. It only
/// rejects a value that would break an app's text sizes, such as `NaN` or `0`.
pub(crate) fn valid_scale(raw: f64) -> Option<f64> {
   (raw.is_finite() && raw > 0.0).then_some(raw)
}

/// The latest text scale, shared between the threads that read it and the thread that
/// receives the changes.
///
/// The cache starts unset and returns [`DEFAULT_TEXT_SCALE`] until a scale is stored.
#[derive(Debug)]
pub(crate) struct ScaleCache(AtomicU64);

impl ScaleCache {
   /// Creates an unset cache.
   pub(crate) fn new() -> Self {
      Self(AtomicU64::new(UNSET))
   }

   /// Returns the latest scale, or [`DEFAULT_TEXT_SCALE`] if no scale is stored.
   pub(crate) fn get(&self) -> f64 {
      match self.0.load(Ordering::Acquire) {
         UNSET => DEFAULT_TEXT_SCALE,
         bits => f64::from_bits(bits),
      }
   }

   /// Stores the first read, unless the change handler already stored a newer scale.
   pub(crate) fn store_initial(&self, scale: f64) {
      let _ = self
         .0
         .compare_exchange(UNSET, scale.to_bits(), Ordering::AcqRel, Ordering::Acquire);
   }

   /// Stores `scale` and returns whether it differs from the scale that the cache held.
   pub(crate) fn replace(&self, scale: f64) -> bool {
      self.0.swap(scale.to_bits(), Ordering::AcqRel) != scale.to_bits()
   }
}

#[cfg(test)]
mod tests {
   use super::*;

   #[test]
   fn accepts_a_finite_scale_above_zero() {
      assert_eq!(valid_scale(1.0), Some(1.0));
      assert_eq!(valid_scale(2.25), Some(2.25));
      assert_eq!(valid_scale(0.5), Some(0.5));
   }

   #[test]
   fn rejects_a_scale_that_breaks_text_sizes() {
      assert_eq!(valid_scale(0.0), None);
      assert_eq!(valid_scale(-1.5), None);
      assert_eq!(valid_scale(f64::NAN), None);
      assert_eq!(valid_scale(f64::INFINITY), None);
   }

   #[test]
   fn returns_the_default_scale_before_any_store() {
      assert_eq!(ScaleCache::new().get(), DEFAULT_TEXT_SCALE);
   }

   #[test]
   fn holds_the_initial_scale() {
      let cache = ScaleCache::new();

      cache.store_initial(1.5);
      assert_eq!(cache.get(), 1.5);
   }

   #[test]
   fn keeps_a_change_that_arrives_before_the_initial_scale() {
      let cache = ScaleCache::new();

      assert!(cache.replace(2.25));
      cache.store_initial(1.5);
      assert_eq!(cache.get(), 2.25);
   }

   #[test]
   fn reports_a_change_to_the_default_scale_before_the_initial_scale() {
      let cache = ScaleCache::new();

      assert!(cache.replace(DEFAULT_TEXT_SCALE));
      cache.store_initial(1.5);
      assert_eq!(cache.get(), DEFAULT_TEXT_SCALE);
   }

   #[test]
   fn replaces_the_scale_and_reports_a_change() {
      let cache = ScaleCache::new();

      cache.store_initial(1.0);

      assert!(cache.replace(2.25));
      assert_eq!(cache.get(), 2.25);
   }

   #[test]
   fn reports_no_change_for_the_same_scale() {
      let cache = ScaleCache::new();

      cache.store_initial(1.5);

      assert!(!cache.replace(1.5));
      assert_eq!(cache.get(), 1.5);
   }
}
