# Neovim config

Plugins are managed with [lazy.nvim](https://github.com/folke/lazy.nvim) and
pinned via [lazy-lock.json](lazy-lock.json). Automatic update checks are
disabled, so updates are done manually.

## Updating plugins

Inside Neovim:

```
:Lazy update
```

This fetches the latest versions and updates `lazy-lock.json`. Commit the
lockfile change afterwards so other machines pick up the same versions.

Or from the shell:

```sh
nvim --headless "+Lazy! update" +qa
```

## Syncing to the lockfile

After pulling this repo on another machine, install the exact pinned versions
with:

```
:Lazy restore
```

Use `:Lazy sync` instead if you also want to remove plugins that are no longer
in the spec.

## Updating LSP servers (Mason)

Language servers are installed through [mason.nvim](https://github.com/mason-org/mason.nvim).
Outdated-package checks on open are disabled, so update manually:

```
:MasonUpdate   " refresh the Mason registry
:Mason         " open the UI, then press U to update all installed packages
```
