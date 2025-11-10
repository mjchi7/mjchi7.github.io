# mjchi7.github.io

Personal blog built with [Hugo](https://gohugo.io/) static site generator.

## Initial Setup

When cloning this repository on a new machine, run the setup script:

```bash
./setup.sh
```

This will:
- Install git hooks (automatic site rebuilding on commit)
- Verify Hugo installation
- Check git configuration

## Development

### Prerequisites
- [Hugo](https://gohugo.io/getting-started/installing/) (Extended version)
- Git

### Common Commands

```bash
# Start local development server
make serve

# Build the site (output to docs/)
make build

# Clean build artifacts
make clean

# Generate new post
hugo new posts/post-name.md
```

### Git Hooks

This repository includes a pre-commit hook that automatically:
- Rebuilds the Hugo site before each commit
- Copies images to the docs directory
- Stages the built files (docs/) for commit
- Aborts commit if build fails

The hook is located in [.githooks/pre-commit](.githooks/pre-commit) and is installed via [setup.sh](setup.sh).

## Deployment

The site is deployed to GitHub Pages from the `docs/` directory on the `master` branch.

## Reference
- Hugo Quick Start: https://gohugo.io/getting-started/quick-start/