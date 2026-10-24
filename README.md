# nix-flakify

A catch-all repository for Nix flakes that provide development environments for
projects that don't maintain their own flakes.

Each project's environment lives under `<github-owner>/<repo>`, with its own
`flake.nix` and `flake.lock` to keep dependencies pinned independently. Using the
upstream GitHub organization or owner avoids clashes between repository names.

## Environments

| Project | Environment | Shells |
| --- | --- | --- |
| [Tasks](https://github.com/tasks/tasks) | `tasks/tasks` | `default` |
| [Voice](https://github.com/PaulWoitaschek/Voice) | `PaulWoitaschek/Voice` | `default`, `emulator` |

## Usage

You'll need Nix with flakes enabled. For automatic environment loading, you'll
also need direnv with nix-direnv configured.

With this repository checked out at `~/Work/nix-flakify`, point the project's
`.envrc` at its environment here. For Tasks:

```sh
use flake "path:$HOME/Work/nix-flakify/tasks/tasks"
```

Run `direnv allow` in the project directory after updating `.envrc`.

To enter an environment directly:

```sh
nix develop "path:$HOME/Work/nix-flakify/tasks/tasks"
```

For Voice, use `PaulWoitaschek/Voice` in place of `tasks/tasks`. To enter its
emulator shell:

```sh
nix develop "path:$HOME/Work/nix-flakify/PaulWoitaschek/Voice#emulator"
```

Run these commands from the corresponding project's checkout so build commands
and shell settings use that project's working directory.

## Adding a project

Copy the project's `flake.nix` and `flake.lock` into `<github-owner>/<repo>` here,
using the upstream owner's and repository's spelling. Update the project's
`.envrc` to use that directory, keeping any other project-specific settings
intact.

Flakes here must work independently of the project's source tree. If a flake
reads versions from project files, record the required values in the flake and
keep them in sync when updating the project's toolchain.

This is a public repository. Keep credentials, private URLs, and other sensitive
project details out of committed files.
