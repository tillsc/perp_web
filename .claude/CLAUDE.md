# Project Notes

## Non-obvious patterns

### Frontend
- Custom Web Components (`customElements.define`) — no Stimulus
- Turbolinks (not Turbo/Hotwire)

### Controllers
- Namespaced by area: `Internal::` for admin, `Announcer::` etc.

### Models & Queries
- `strict_loading_by_default = true` in development — always preload associations used in views, lazy loading raises `StrictLoadingViolationError`
- Prefer `preload()` explicitly to avoid N+1
- Arel for complex queries, not raw SQL strings
- Scope/method pairs that express the same predicate (e.g. `scope :honorable` + `def honorable?`) must be adjacent — method directly after scope

### Services
- Some Service objects support a preview mode before persisting

### CSS
- SCSS scoped per feature: `internal.scss`, `results.scss`, etc.
- State classes like `.changed`, `.withdrawn` for visual state

### Migrations
- Never reference model classes or constants — migrations must run without models

### Tests
- Minitest + fixtures; focus only on critical business logic

### Style
- Short variable names (`p`, `mp`) acceptable in tight loops

## Print

See `docs/print.md`.
