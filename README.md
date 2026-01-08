# path-manager

A shell function to easily manipulate your `$PATH`.

## Installation

### Homebrew (macOS/Linux)

```bash
brew install boochtek/tap/path
```

Then add to your `~/.bashrc` or `~/.zshrc`:

```bash
source "$(brew --prefix)/opt/path/path.sh"
```

### Manual

Clone the repository:

```bash
git clone https://github.com/boochtek/path-manager.git ~/.path-manager
```

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
source ~/.path-manager/path.sh
```

## Usage

```bash
path <command> [args]
```

### Commands

| Command | Description |
|---------|-------------|
| `list`, `ls`, `show` | List all paths (numbered) |
| `add`, `a` | Add a path |
| `remove`, `rm`, `del` | Remove a path |
| `move`, `mv` | Move an existing path |
| `check`, `validate` | Show missing paths and duplicates |
| `dedup` | Remove duplicate entries |
| `clean` | Remove duplicates and non-existent paths |
| `contains`, `has` | Exit 0 if path exists in PATH, 1 otherwise |
| `help`, `-h`, `--help` | Show help |

### Options for `add` and `move`

| Option | Description |
|--------|-------------|
| `--beginning`, `-b` | Add/move to beginning of PATH |
| `--end`, `-e` | Add/move to end of PATH (default for `add`) |
| `--before <path>` | Add/move before the specified path |
| `--after <path>` | Add/move after the specified path |

### Examples

```bash
# List all entries
path list

# Add ~/bin to end of PATH
path add ~/bin

# Add ~/bin to beginning of PATH
path add ~/bin --beginning
path add ~/bin -b

# Add ~/bin right before /usr/bin
path add ~/bin --before /usr/bin

# Remove a path
path remove ~/bin

# Move /usr/local/bin to the beginning
path move /usr/local/bin -b

# Check for problems (missing directories, duplicates)
path check

# Clean up PATH (remove duplicates and non-existent directories)
path clean

# Check if a path exists (useful in scripts)
if path contains ~/bin; then
    echo "~/bin is in PATH"
fi
```

## Features

- **Idempotent**: `add` silently succeeds if path exists; `remove` silently succeeds if path doesn't exist
- **Duplicate detection**: Warns when operating on paths that appear multiple times
- **Path normalization**: Expands `~` and removes trailing slashes (preserves `$VARIABLES`)
- **Validation**: `check` shows which paths don't exist on the filesystem
- **Cleanup**: `clean` removes both duplicates and non-existent paths in one command

## Compatibility

- Bash 3.2+ (for built-in macOS version)
- Zsh 5.0+

## Why a shell function?

A standalone script cannot modify the parent shell's environment variables (like `$PATH`).
The `path` command **MUST** be a shell function that gets sourced into your shell session.

## License

MIT License - see [LICENSE](LICENSE.txt) for details.

## Development

### Making a Release

Use the Makefile to manage releases:

```bash
# Full release workflow (bump version, tag, push, update Homebrew formula)
make release VERSION=x.y.z

# Or run individual steps:
make bump-version VERSION=x.y.z  # Commit version changes
make tag VERSION=x.y.z            # Create signed git tag
make push                         # Push commits and tags
make update-formula VERSION=x.y.z # Update Homebrew formula with SHA
```

The `release` target automates:
1. Bumping version in relevant files and committing
2. Creating a signed git tag
3. Pushing commits and tags to GitHub
4. Downloading the release tarball and computing SHA256
5. Updating the Homebrew formula with new version and SHA

## Contributing

Issues and pull requests welcome at [github.com/boochtek/path-manager](https://github.com/boochtek/path-manager).
