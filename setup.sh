#!/bin/bash

# Setup script for mjchi7.github.io Hugo blog
# This script sets up git hooks and ensures the development environment is ready

set -e  # Exit on error

echo "🚀 Setting up mjchi7.github.io blog..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not a git repository. Please run this script from the repository root."
    exit 1
fi

# Install git hooks
echo "📦 Installing git hooks..."
if [ -d ".githooks" ]; then
    # Copy all hooks from .githooks to .git/hooks
    for hook in .githooks/*; do
        if [ -f "$hook" ]; then
            hook_name=$(basename "$hook")
            cp "$hook" ".git/hooks/$hook_name"
            chmod +x ".git/hooks/$hook_name"
            echo "  ✅ Installed $hook_name"
        fi
    done
else
    echo "  ⚠️  No .githooks directory found, skipping hook installation"
fi

# Check if Hugo is installed
echo ""
echo "🔍 Checking dependencies..."
if command -v hugo &> /dev/null; then
    hugo_version=$(hugo version)
    echo "  ✅ Hugo is installed: $hugo_version"
else
    echo "  ⚠️  Hugo is not installed. Please install Hugo to build the site."
    echo "     Visit: https://gohugo.io/getting-started/installing/"
fi

# Check if git is configured
if git config user.name &> /dev/null && git config user.email &> /dev/null; then
    echo "  ✅ Git is configured"
else
    echo "  ⚠️  Git user not configured. Run:"
    echo "     git config user.name 'Your Name'"
    echo "     git config user.email 'your.email@example.com'"
fi

echo ""
echo "✅ Setup complete! You're ready to start blogging."
echo ""
echo "Quick commands:"
echo "  make build  - Build the site"
echo "  make serve  - Start local development server"
echo "  make clean  - Clean build artifacts"
