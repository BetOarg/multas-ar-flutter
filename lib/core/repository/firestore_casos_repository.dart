// Firestore synchronization is not enabled in the current release.
// The active repository is LocalCasosRepository in casos_repository.dart.
//
// The former prototype depended on undeclared Firebase packages and did not
// implement the ICasosRepository contract safely: it returned dynamic values,
// mixed remote maps with Drift entities, and left download/upsert incomplete.
// Do not enable this path until typed mapping, conflict resolution, deletion
// queueing, security rules, and integration tests are implemented.
