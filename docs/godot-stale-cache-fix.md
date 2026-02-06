# Godot Stale Script Cache Issue

## Problem

When `.gd` files are edited outside the Godot editor (e.g. from Cursor, VS Code, or any external tool), Godot's file watcher may not detect the changes. The editor continues running old cached bytecode from the `.godot/` directory, even though the source files on disk are up to date.

### Symptoms

- Scripts appear to not reflect recent changes
- Features you just added don't work (no selection, no movement, no input handling, etc.)
- No errors in the Output panel -- everything looks fine but the game doesn't behave correctly
- The game worked once, then stopped working after closing and reopening the preview

### Why It Happens

Godot compiles GDScript files into bytecode and caches the result in the `.godot/` directory. When files are modified externally, the editor may not notice the change, so it keeps using the stale compiled version. This is especially common after large changes that touch multiple `.gd` files at once.

## Fix

### Quick Fix (try this first)

1. In the Godot editor, go to **Project > Reload Current Project**
2. This forces a full reimport and recompile of all scripts

### Full Cache Clear (if the quick fix doesn't work)

1. **Close Godot** completely
2. **Delete the `.godot/` folder** in your project root directory
3. **Reopen the project** in Godot

The `.godot/` folder is purely a cache -- Godot regenerates it automatically on next launch. This forces a clean reimport of all resources (textures, scenes, etc.) and a full recompile of all scripts.

```bash
# From the project root:
rm -rf .godot/
```

### Force a Script Recompile (alternative)

If you don't want to nuke the whole cache, you can force Godot to recompile a specific script by making a trivial edit to it inside the Godot editor (add a space, then remove it, then save). This triggers the file watcher and forces a recompile of that script and its dependencies.

## Prevention

- After making large external edits, do **Project > Reload Current Project** before running the game
- If something that was working suddenly breaks after an external edit session, suspect the cache first
- When adding new resource files (images, scenes) externally, Godot may also need a reload to import them properly -- check that `.import` files show `valid=true`

## Related Issues

- **Fabricated UIDs**: When creating `.tscn` files externally, do NOT invent `uid://` values. Either omit the UID entirely (Godot will assign one) or create the scene inside the Godot editor. A bad UID can corrupt the UID cache and cause preload failures.
- **Wrong file formats**: Images saved as JPEG but with a `.png` extension will fail to import. Verify with `file <path>` in the terminal. Convert with `sips -s format png <file> --out <file>` on macOS.
