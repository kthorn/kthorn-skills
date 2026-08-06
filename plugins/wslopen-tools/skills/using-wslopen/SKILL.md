---
name: using-wslopen
description: Use when sharing a local WSL file or directory with a Windows user who has supplied an installed wslopen configuration.
compatibility: Requires the Windows wslopen protocol handler and visible distro/root configuration.
---

# Using wslopen

## Preconditions

Use this only when the user has explicitly supplied a `wslopen` configuration, typically the generated block containing:

- `Configured WSL distro: <distro>`
- `Allowed WSL root: <root>`

Do not infer either value from the current machine, username, repository, or an example. Without both values, use a plain path.

## Emit a link

For a directory or supported file equal to the root or beneath it on a `/` segment boundary, emit:

```markdown
[Q1 plan.md — line 42](wslopen://Ubuntu/home/alice/work/reports/Q1%20plan.md)
```

- Preserve `/` separators and percent-encode path characters such as spaces (`%20`), `%` (`%25`), `#` (`%23`), and `?` (`%3F`).
- The URI contains only the absolute WSL path. Put line numbers in visible link text—never a `#...` fragment or query string.
- The hostname is exactly the configured distro (host matching is case-insensitive in the handler).

Use a plain path when configuration is absent, the path is outside the configured root, the path contains a literal double quote, or the target is not a directory or a supported document/data/image/media type. See [the exact supported extension list](../../README.md#allowed-targets) when unsure.

## Do not install implicitly

Installation changes a per-user Windows registry key. Refer the user to the plugin README when they ask to set it up; do not run the installer unless they explicitly request installation.
