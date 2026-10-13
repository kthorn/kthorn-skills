# Lenses

Concern families to sweep. Each starting point is a primitive to search for, not a helper name.
The list is open: when a finding suggests a new family, add the family to the sweep.

## Duplication

| Family | Policy questions | Search starting points |
| --- | --- | --- |
| Object storage I/O | Is the read bounded, pinned to the observed version/ETag, closed? Which error codes mean "not found"? | `get_object`, `head_object`, `put_object`, `.read()` on bodies, `NoSuchKey`, `404`, presign calls |
| Serialization and identity | Key order, separators, NaN handling, encoding, timezone, ID prefixes and truncation | `json.dumps(` with `sort_keys`, `JSONEncoder`, `hashlib`, `isoformat`, `default=` serializers, `strftime` |
| Error taxonomy | Is the same failure classified the same way everywhere? Do retry decisions agree? | `class .*Error(Exception)` with similar names, retryable/transient classification, status-code maps |
| Transport decoding | How are responses validated, decoded, and turned into typed errors? | `response.json()`, `model_validate`, `raise_for_status`, `fetch(` wrappers, JSON error helpers in TS |
| Protocol adapters | Do clients of the same protocol build sessions, headers, and results the same way? Do wrappers each re-forward the whole protocol surface to add one policy? | client/session construction, RPC result unpacking, auth headers, classes implementing the same interface by delegation |
| Domain normalization | Do chemistry, DOI, URL, and identifier normalizers agree? | SMILES standardization calls, `normalize_doi`, URL canonicalization, empty-frame/DataFrame construction |
| Sync/async twins | Do paired implementations still behave the same (defaults, logging, error accounting)? | Modules or classes named `async_*`/`Async*` beside sync counterparts |
| Lifecycle and concurrency | Is cancellation safety implemented once? | `asyncio.shield`, lock-plus-cancelled-flag patterns, `CancelledError` handling around commits |
| Security | Is redaction, sanitization, or encoding applied consistently? | secret regexes, `scrub`/`redact`/`sanitize`, DOMPurify configs, `encodeURIComponent` omissions, path validation |
| Cross-language contracts | Do hand-written types or constants mirror a generated or server-side source? | TS interfaces vs `src/generated/api.ts`; accept lists, extension and media-type sets in Python and TS |
| Configuration | Are environment values parsed once? | `os.environ` / `getenv` of the same name in several modules; settings fields duplicated across services |
| Shared contracts | Do sibling apps or agents that expose the same operation share one core and parameter contract? | same-named handlers or tools in several packages; hand validation beside a contract model |
| Presentation | Are URLs, escaping, and markdown pipelines built once? | hand-built `/api/...` URLs, HTML-escape helpers, `marked.use`, global singletons configured twice |

## Dead code

| Class | Cue | Confirmation |
| --- | --- | --- |
| Unreferenced | No reference outside its definition | Dynamic-consumer check from SKILL.md |
| Test-only | Referenced only from tests | Confirm production uses a different path; delete the tests that only exercise it |
| Registry-only | Present in a registry, `__all__`, or re-export, but never selected or imported | Trace how the registry is read at runtime and in evals |
| Written, never read | A field, setting, metadata key, or column that is assigned or serialized but never consumed | Check persisted data and wire payloads before removal |
| Empty input domain | A transform or branch keyed on values no caller or model can produce | Enumerate actual inputs, e.g. every request model's fields |
| Superseded path | An old implementation kept beside its replacement | Show every caller moved to the replacement |
| Compatibility surface | Aliases, shims, or fallbacks for consumers that no longer exist | Check the repository's compatibility policy; a monorepo without external consumers usually needs none |
| Orphan of a removal | Helpers whose last caller was deleted | `git log --diff-filter=D` on recent removals; re-run reachability on their neighbors |
| Retired switch | Feature flags fully advanced; environment-variable product switches | Flag owner and retirement issue state |
| One-shot scripts | Migrations and backfills already run | Needs operator confirmation; file an issue, never a PR |
| Stale description | Docs, decision records, or docstrings naming missing symbols or claiming callers | The neighbor they describe is often dead or moved |
| Frontend surface | Unused exports, unpassed props, unused stores and CSS tokens, dead-code tool config drift, unused dependencies | Component templates and HTML entry points count as consumers |
