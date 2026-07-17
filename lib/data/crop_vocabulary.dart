/// Shared crop names for Profile interests and Discover filter chips.
const List<String> discoverCropFilters = [
  'Maize',
  'Cassava',
  'Beans',
  'Groundnuts',
  'Rice',
];

/// Whether [crop] is in the shared Discover vocabulary (exact match).
bool isKnownCrop(String crop) => discoverCropFilters.contains(crop);
