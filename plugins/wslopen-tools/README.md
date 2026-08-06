# wslopen tools

`wslopen://` links let a Windows user open an allowed WSL directory in Explorer or an allowed file in its default Windows application. The plugin also provides `using-wslopen`, a shared Claude Code/pi skill for authoring those links.

## Install the Windows handler

From **Windows PowerShell**, clone this repository and run the installer with an explicit WSL distro and an existing root equal to `/home/<user>` or beneath it:

```powershell
git clone https://github.com/kthorn/kthorn-skills.git
cd kthorn-skills\plugins\wslopen-tools
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\install.ps1 `
  -Distro Ubuntu -AllowedRoot /home/alice
```

The installer writes only under `%LOCALAPPDATA%\wslopen` and `HKCU\Software\Classes\wslopen`. It prints and saves `%LOCALAPPDATA%\wslopen\agent-instructions.md`. Copy that generated block into durable agent instructions—such as Pi's `~/.pi/agent/AGENTS.md` in the configured distro or an applicable Claude `CLAUDE.md`. Re-run installation and replace the copied block if the distro or root changes.

Install this marketplace package in Claude Code or pi separately to make the shared skill discoverable; the Git clone above is the explicit Windows-side installer source.

## Optional Windows Terminal trust

Windows Terminal warns before opening unfamiliar custom schemes. To suppress that warning after reviewing the handler, add `"wslopen"` to the existing `safeUriSchemes` array in Windows Terminal's settings:

```json
"safeUriSchemes": ["wslopen"]
```

The installer intentionally does not edit terminal settings. The handler works without this opt-in.

## Allowed targets

Directories always open in Explorer. Files open through Windows default associations only when their final extension is in this allowlist (case-insensitive):

| Class | Extensions |
| --- | --- |
| Documents | `.doc`, `.docx`, `.md`, `.odt`, `.pdf`, `.ppt`, `.pptx`, `.rtf`, `.txt` |
| Data | `.csv`, `.json`, `.ods`, `.tsv`, `.xls`, `.xlsx`, `.xml`, `.yaml`, `.yml` |
| Images | `.bmp`, `.gif`, `.jpeg`, `.jpg`, `.png`, `.tif`, `.tiff`, `.webp` |
| Media | `.aac`, `.flac`, `.m4a`, `.m4v`, `.mov`, `.mp3`, `.mp4`, `.mpeg`, `.mpg`, `.ogg`, `.wav`, `.webm`, `.wmv` |

Extensionless and unlisted files are rejected. This is an intentional safety limit, not a claim that other types are inherently unsafe.

## Verify

The framework-free tests require Windows with the named WSL distro available:

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tests\open.tests.ps1 -Distro Ubuntu -AllowedRoot /home/alice
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File .\tests\install.tests.ps1 -Distro Ubuntu -AllowedRoot /home/alice
```

Then manually Ctrl+click one configured-root directory link and one allowed file link. Confirm Explorer and the expected default application open. This manual step exercises the real registered protocol and Windows application association; the automated tests deliberately do not launch applications.

## Security boundary

The handler accepts exactly one `wslopen://<distro>/<percent-encoded-absolute-path>` argument. It rejects unexpected URI components, malformed escaping, backslashes, controls, noncanonical/out-of-root paths, and symlinks resolving outside the configured root. It resolves paths through direct `wsl.exe -d <distro> --exec readlink -f -- <path>` arguments—never a shell command—and rejects decoded double quotes before invoking WSL. Share a path containing a literal double quote as plain text instead. It then retries the UNC target through `\\wsl.localhost` and `\\wsl$` before dispatching an allowlisted plan.

Linux root comparisons are ordinal and case-sensitive; Windows extension comparisons are case-insensitive. A local filesystem entry can change between path validation and Windows dispatch; this small TOCTOU window remains, but the dispatch target is already canonicalized and constrained to the configured `/home/<user>` subtree.
