/// Measurements for a dress order. Captured as a single free-text note the
/// tailor fills however they like (e.g. "Chest 34, Waist 28 · Pant: Length
/// 38 · boat neck") and can edit later — much faster than fixed numeric
/// fields, and flexible across very different garments.
class Measurement {
  final String? notes;

  const Measurement({this.notes});

  bool get isEmpty => notes == null || notes!.trim().isEmpty;

  Measurement copyWith({String? notes}) => Measurement(notes: notes ?? this.notes);
}
