---
name: opencode-zen-models
description: Use when checking or refreshing OpenCode Zen free models, updating opencode-zen-models.json, replacing retired model IDs, or synchronizing embedded fallback snapshots and registered consumers.
---

# Update OpenCode Zen models

## Refresh the provider list

1. Run `opencode models opencode --refresh --verbose`.
2. Treat the command as live authority. The registry is a machine-local cache, not product or architecture authority.
3. Count a model as current free Zen only when its provider is `opencode`, its status is `active`, and all input, output, cache-read, and cache-write costs are zero.
4. Use the provider model ID in configs. Keep the display name only as an alias.

Completion criterion: every live, active, zero-cost Zen model has an ID and display name recorded for comparison.

## Compare the registry

1. Read `~/.config-slim/opencode/opencode-zen-models.json`.
2. If the registry is absent, create it from the embedded bootstrap snapshot.
3. Record additions, removals, and ID or display-name changes. Do not invent limits or capabilities.

Completion criterion: each live and cached ID is classified as unchanged, added, removed, or renamed.

## Update routing

1. Retain the order of surviving Zen models.
2. Append new free Zen IDs to the Zen segment.
3. Remove retired or nonfree Zen IDs.
4. Keep external providers after Zen. Keep Gemini last unless the user directs otherwise.
5. If an assigned model was removed, compare the role's required capabilities with the verbose provider output. Use the first compatible surviving Zen model in the existing order.
6. Ask the user before changing an assignment when no compatible model exists or the replacement changes modality or tool support.
7. Update only paths listed under the registry's `consumers` field.
8. Keep model IDs embedded in configs because configs do not load the registry at runtime.
9. Keep the registry pointer and the complete embedded snapshot in portable docs and skills.
10. Preserve unrelated fields and the order of non-Zen providers. Do not add metadata fields to plugin configs.

Completion criterion: the registry, assignments, listed configs, and portable snapshots agree.

## Validate the update

1. Parse each JSON file.
2. Parse `~/.omo/omo.jsonc` after removing only its initial comment line.
3. Verify that every registry Zen ID appears in `opencode models opencode`.
4. Verify that the fallback list has no duplicates and Gemini is last.
5. Verify that every consumer path exists.
6. Search consumers for removed IDs.
7. Run `git diff --check` in each project consumer.
8. Report added, removed, and replaced IDs. Include changed files, validation results, unresolved choices, and the restart requirement.
9. Tell the user to restart OpenCode.

Completion criterion: every check passes, or the report names the blocker without claiming completion.

## Bootstrap snapshot

This snapshot was verified on 2026-08-22. Use it only when the registry is unavailable.

1. `opencode/nemotron-3-ultra-free`
2. `opencode/nemotron-3.5-lightning-free`
3. `opencode/x-preview-f-free` (display name: Ox Alpha Free (Unlimited))
4. `opencode/muse-spark-1.2-contributor-free` (display name: Muse Spark 1.2 Free)
5. `opencode/big-pickle`
6. `opencode/hy3-free`
7. `opencode/mimo-v2.5-free`
8. `deepseek/deepseek-v4-flash`
9. `openai/gpt-5.6-luna`
10. `google/gemini-3.7-flash`
