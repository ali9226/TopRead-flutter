// ignore_for_file: constant_identifier_names, non_constant_identifier_names

/// Logical geometry parameters are independent of screen scale and decoration.
class TileQuestGeometryStyle {
  /// Ignore numerical slivers while retaining every intentional half-cell cover.
  /// The ratio is measured against the lower tile's full collision rectangle.
  static const double minimum_occlusion_area_ratio = .0001;

  /// Region identifiers remain compact, serializable template metadata.
  static const int maximum_region_id_length = 32;
  static final RegExp region_id_pattern = RegExp(r'^[a-z][a-z0-9_]*$');
}
