# Contributing to CleanMac

Thank you for your interest in contributing to CleanMac! This document provides guidelines and information for contributors.

## 🚀 Quick Start

### Prerequisites

- macOS 10.15 (Catalina) or newer
- Bash 3.2+ (macOS default) or Bash 4.0+ (recommended, install via Homebrew)
- Git
- Basic knowledge of Bash scripting

### Setup Development Environment

```bash
# Clone the repository
git clone https://github.com/shade-solutions/cleanmac.git
cd cleanmac

# Make script executable
chmod +x cleanmac.sh

# Test the current version
./cleanmac.sh
```

## 📋 How to Contribute

### 1. Find an Issue

Browse our [open issues](https://github.com/shade-solutions/cleanmac/issues) and find one that interests you. Issues are labeled by:

- `phase-1`, `phase-2`, etc. - Implementation phase
- `high-priority` - Important features
- `good-first-issue` - Great for newcomers
- `enhancement` - New features
- `bug` - Bug fixes
- `documentation` - Documentation improvements

### 2. Comment on the Issue

Let us know you're working on it! Comment on the issue to avoid duplicate work.

### 3. Fork and Branch

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR-USERNAME/cleanmac.git
cd cleanmac

# Create a feature branch
git checkout -b feature/issue-NUMBER-short-description
```

### 4. Make Your Changes

Follow our coding standards (see below).

### 5. Test Your Changes

```bash
# Run the script
./cleanmac.sh

# Test with dry-run
./cleanmac.sh --dry-run

# Test specific features
# (Add more test commands as testing framework develops)
```

### 6. Commit and Push

```bash
# Add your changes
git add .

# Commit with a clear message
git commit -m "feat: Add description of feature

- Detailed point 1
- Detailed point 2

Closes #ISSUE_NUMBER"

# Push to your fork
git push origin feature/issue-NUMBER-short-description
```

### 7. Create Pull Request

- Go to GitHub and create a Pull Request
- Reference the issue number in the description
- Describe what you changed and why
- Wait for review and feedback

## 💻 Coding Standards

### Bash Style Guide

```bash
# Use 4-space indentation
if [ condition ]; then
    do_something
fi

# Use descriptive variable names
total_size=0
file_count=0

# Use functions for reusability
calculate_size() {
    local directory="$1"
    # Implementation
}

# Add comments for complex logic
# This loop iterates through all node_modules directories
for dir in "${dirs[@]}"; do
    # Process each directory
done

# Use $() instead of backticks
result=$(command)

# Quote variables to handle spaces
rm -rf "$directory"

# Use [[ ]] instead of [ ] for tests
if [[ "$var" == "value" ]]; then
    # Do something
fi
```

### Module Organization

When adding new functionality:

1. **Core utilities** → `lib/core.sh`
2. **UI components** → `lib/ui.sh`
3. **Cleanup logic** → `lib/cleaner.sh` (to be created)
4. **Config management** → `lib/config.sh` (to be created)
5. **Reports** → `lib/reporter.sh` (to be created)

### Error Handling

```bash
# Always check if operations succeed
if ! command; then
    print_error "Command failed"
    return 1
fi

# Use set -e at the beginning of scripts
set -e

# Trap errors
trap 'print_error "Script failed at line $LINENO"' ERR
```

### Safety Practices

```bash
# Confirm before destructive operations
if confirm "Delete $file_count files?"; then
    # Perform deletion
fi

# Respect dry-run mode
if [ "$DRY_RUN" = false ]; then
    rm -rf "$directory"
else
    print_info "Would delete: $directory"
fi

# Check if files exist before operating on them
if [ -d "$directory" ]; then
    # Process directory
fi
```

## 🧪 Testing

### Manual Testing

Always test your changes with:

1. **Normal execution**
2. **Dry-run mode**
3. **Edge cases** (empty directories, permission issues, etc.)
4. **Different terminal emulators** (Terminal.app, iTerm2, etc.)

### Automated Testing

(Coming soon - test framework is being developed)

```bash
# Run unit tests
./tests/run_tests.sh

# Run specific test
./tests/unit/test_core.sh
```

## 📝 Commit Message Format

We follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
type(scope): subject

body

footer
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```
feat: Add path-specific scanning with --path flag

- Implemented --path argument parsing
- Added depth limiting with --depth flag
- Support for multiple paths via --paths
- Added tests for path scanning

Closes #6
```

```
fix: Correct size calculation for symlinks

Fixed bug where symlinks were counted towards total size
even when follow_symlinks was disabled.

Fixes #42
```

## 🐛 Reporting Bugs

When reporting bugs, please include:

1. **macOS version**
2. **Bash version** (`bash --version`)
3. **Steps to reproduce**
4. **Expected behavior**
5. **Actual behavior**
6. **Error messages** (if any)
7. **Screenshots** (if applicable)

## 💡 Suggesting Features

When suggesting features:

1. **Check if it's already planned** (see PRD.md and open issues)
2. **Describe the use case** - Why is this feature needed?
3. **Provide examples** - How would it work?
4. **Consider alternatives** - Are there other ways to achieve this?

## 📚 Documentation

When adding features, please update:

- **README.md** - User-facing documentation
- **PRD.md** - If it's a significant feature
- **IMPLEMENTATION_STATUS.md** - Track progress
- **Code comments** - Explain complex logic
- **Help text** - Update `--help` output

## 🎯 Development Roadmap

See [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) for current progress and upcoming features.

## 📞 Communication

- **GitHub Issues** - For bugs and feature requests
- **GitHub Discussions** - For questions and general discussion
- **Pull Requests** - For code contributions

## ⚖️ Code of Conduct

Be respectful, professional, and constructive in all interactions.

## 📄 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

## 🙏 Thank You!

Your contributions help make CleanMac better for everyone. We appreciate your time and effort!

**Happy Coding! 🚀**
