/// Shared crop names for Profile interests and Discover filter chips.
const List<String> discoverCropFilters = [
  'Maize',
  'Cassava',
  'Beans',
  'Groundnuts',
  'Rice',
];

/// Lowercase aliases → canonical English vocabulary keys.
///
/// Includes common English variants/misspellings and French labels so typed
/// input resolves to the same stored id across locales.
const Map<String, String> cropAliases = {
  // Maize
  'maize': 'Maize',
  'corn': 'Maize',
  'mealie': 'Maize',
  'mealies': 'Maize',
  'maïs': 'Maize',
  'mais': 'Maize',
  // Cassava
  'cassava': 'Cassava',
  'manioc': 'Cassava',
  'yuca': 'Cassava',
  // Beans
  'bean': 'Beans',
  'beans': 'Beans',
  'haricot': 'Beans',
  'haricots': 'Beans',
  // Groundnuts
  'groundnut': 'Groundnuts',
  'groundnuts': 'Groundnuts',
  'peanut': 'Groundnuts',
  'peanuts': 'Groundnuts',
  'arachide': 'Groundnuts',
  'arachides': 'Groundnuts',
  // Rice
  'rice': 'Rice',
  'riz': 'Rice',
};

/// Whether [crop] is in the shared Discover vocabulary (exact match).
bool isKnownCrop(String crop) => discoverCropFilters.contains(crop);

/// Trims, collapses whitespace, and title-cases words for stable custom ids.
String normalizeCropDisplayName(String input) {
  final collapsed = input.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (collapsed.isEmpty) return '';
  return collapsed
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        final lower = word.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

/// Case-insensitive membership for interest lists.
bool interestContains(List<String> interests, String crop) {
  final key = crop.toLowerCase();
  return interests.any((c) => c.toLowerCase() == key);
}

/// Exact vocabulary or alias match → canonical id; otherwise null.
String? matchCanonicalCrop(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  final lower = trimmed.toLowerCase();
  for (final crop in discoverCropFilters) {
    if (crop.toLowerCase() == lower) return crop;
  }

  final alias = cropAliases[lower];
  if (alias != null) return alias;

  // Normalized form may differ only by casing/spacing from a canonical key.
  final normalized = normalizeCropDisplayName(trimmed);
  if (normalized.isEmpty) return null;
  final normalizedLower = normalized.toLowerCase();
  for (final crop in discoverCropFilters) {
    if (crop.toLowerCase() == normalizedLower) return crop;
  }
  return cropAliases[normalizedLower];
}

/// Close non-exact match against vocabulary (typos / near-duplicates).
///
/// Returns null when [input] already matches a canonical/alias exactly, or
/// when no candidate is close enough.
String? suggestCanonicalCrop(String input) {
  if (matchCanonicalCrop(input) != null) return null;

  final normalized = normalizeCropDisplayName(input);
  if (normalized.isEmpty) return null;
  final query = normalized.toLowerCase();

  String? best;
  var bestDistance = 1 << 30;

  for (final crop in discoverCropFilters) {
    final candidate = crop.toLowerCase();
    if (candidate.startsWith(query) || query.startsWith(candidate)) {
      final distance = (candidate.length - query.length).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = crop;
      }
      continue;
    }
    final distance = _levenshtein(query, candidate);
    final maxLen =
        query.length > candidate.length ? query.length : candidate.length;
    // Allow small typos; scale threshold with length (min 1, max 2).
    final threshold = maxLen <= 4 ? 1 : 2;
    if (distance <= threshold && distance < bestDistance) {
      bestDistance = distance;
      best = crop;
    }
  }
  return best;
}

/// Prefers canonical when known; otherwise a normalized custom display name.
///
/// Empty / whitespace-only input returns null.
String? resolveCropInterestId(String input) {
  final canonical = matchCanonicalCrop(input);
  if (canonical != null) return canonical;
  final normalized = normalizeCropDisplayName(input);
  return normalized.isEmpty ? null : normalized;
}

/// Vocabulary crops plus custom [interests] not already in the vocabulary.
List<String> cropFilterChipsFor(List<String> interests) {
  final extras = interests.where((c) => !isKnownCrop(c));
  return [...discoverCropFilters, ...extras];
}

int _levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  final prev = List<int>.generate(b.length + 1, (i) => i);
  final curr = List<int>.filled(b.length + 1, 0);

  for (var i = 1; i <= a.length; i++) {
    curr[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      final deletion = prev[j] + 1;
      final insertion = curr[j - 1] + 1;
      final substitution = prev[j - 1] + cost;
      curr[j] = deletion < insertion
          ? (deletion < substitution ? deletion : substitution)
          : (insertion < substitution ? insertion : substitution);
    }
    for (var j = 0; j <= b.length; j++) {
      prev[j] = curr[j];
    }
  }
  return prev[b.length];
}
