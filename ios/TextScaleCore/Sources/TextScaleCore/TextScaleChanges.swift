/// Keeps the last scale, so that only a new scale is a change to report.
public struct TextScaleChanges {
   /// The last scale, or `nil` before the plugin reads the first one.
   public private(set) var scale: Double?

   public init() {}

   /// Keeps a scale that differs from the last one.
   ///
   /// The first scale is not a change, because the app reads it with `getTextScale`.
   ///
   /// - Parameter newScale: The scale that iOS reports now.
   /// - Returns: The new scale when it differs from the last one, or `nil` when it does
   ///   not or when it is the first scale.
   public mutating func update(_ newScale: Double) -> Double? {
      guard let lastScale = scale else {
         scale = newScale
         return nil
      }

      guard newScale != lastScale else {
         return nil
      }

      scale = newScale
      return newScale
   }
}
