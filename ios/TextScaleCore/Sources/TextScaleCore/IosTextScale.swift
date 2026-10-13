/// Turns the iOS body font size into a text scale.
public enum IosTextScale {
   /// The text scale at the default text size.
   public static let defaultScale = 1.0

   /// Returns the text scale for a body font size, where the default size gives `1`.
   ///
   /// - Parameters:
   ///   - bodyTextSize: The body font size at the user's text size, in points.
   ///   - defaultBodyTextSize: The body font size at the default text size, in points.
   /// - Returns: The body font size divided by the default body font size.
   public static func scale(bodyTextSize: Double, defaultBodyTextSize: Double) -> Double {
      // A size that is not a positive number would hide or invert the app's text, so it
      // falls back to the default text size.
      guard isValidSize(bodyTextSize), isValidSize(defaultBodyTextSize) else {
         return defaultScale
      }

      return bodyTextSize / defaultBodyTextSize
   }

   private static func isValidSize(_ size: Double) -> Bool {
      size.isFinite && size > 0
   }
}
