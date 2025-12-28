# Agent Instructions

When creating issues, Pull Requests, or commits, please adhere to the following conventions:

## Semantic Prefixes
All issues, PR titles, and commit messages must start with one of the following semantic prefixes:
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code (whitespace, formatting, missing semi-colons, etc)
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `build`: Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)
- `ci`: Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs)
- `chore`: Other changes that don't modify src or test files
- `revert`: Reverts a previous commit

## Capitalization
- Do NOT use Title Case (Capitalizing Every Word).
- Use sentence case for the description following the prefix.

**Examples:**
- ✅ `feat: add new search functionality`
- ❌ `Feat: Add New Search Functionality`
- ❌ `Add new search functionality`
 
## PR Template
- Ensure you use the provided Pull Request template when creating a PR.
- Fill out all relevant sections (Summary, Type of Change, Checklist).
- When using the command line, verify the PR description is correctly formatted.
