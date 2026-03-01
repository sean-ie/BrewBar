# BrewBar Backlog

Issues to tackle that need a bit more thought before implementing.

---

## Manually-removed cask leaves ghost in brew

**Symptom**: User manually deleted a cask's app (e.g. dragged Burp Suite to Trash). BrewBar
still shows it as installed (brew metadata remains). Trying to uninstall via BrewBar fails with
an error like:
```
Error: Cask 'burp-suite' is not installed.
```
or a missing-file variant. The error banner appears but gives no guidance.

**Fix ideas**:
- Detect "not installed" / "No such file" patterns in the uninstall error.
- When detected, surface a second button in the error overlay: **"Force-remove brew record"**
  that runs `brew uninstall --zap <cask>`, which cleans up the metadata without needing the
  app files to be present.
- Alternatively, run `brew uninstall --zap` automatically as a fallback when the normal
  uninstall fails with this pattern.
