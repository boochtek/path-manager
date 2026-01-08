.PHONY: release bump-version update-formula tag push help

# Default target
help:
	@echo "Available targets:"
	@echo "  release VERSION=x.y.z  - Full release: bump version, tag, push, update formula"
	@echo "  bump-version VERSION=x.y.z - Update version in files"
	@echo "  tag VERSION=x.y.z      - Create and sign git tag"
	@echo "  push                   - Push commits and tags to origin"
	@echo "  update-formula VERSION=x.y.z - Update Homebrew formula with version and SHA"

# Full release process
release: bump-version tag push update-formula
	@echo "Release $(VERSION) complete!"

# Bump version in relevant files
bump-version:
	@test -n "$(VERSION)" || (echo "ERROR: VERSION not set. Use: make bump-version VERSION=x.y.z" && exit 1)
	@echo "Bumping version to $(VERSION)..."
	@# Add version bumping logic here if you track version in other files
	@git add -A
	@git commit -m "Bump version to $(VERSION)" || true
	@echo "Version bumped to $(VERSION)"

# Create and sign a git tag
tag:
	@test -n "$(VERSION)" || (echo "ERROR: VERSION not set. Use: make tag VERSION=x.y.z" && exit 1)
	@echo "Creating tag v$(VERSION)..."
	@git tag -s -m "Release version $(VERSION)" "v$(VERSION)"
	@echo "Tag v$(VERSION) created"

# Push commits and tags
push:
	@echo "Pushing to origin..."
	@git push origin main
	@git push origin --tags
	@echo "Pushed to origin"

# Update Homebrew formula with new version and SHA
update-formula:
	@test -n "$(VERSION)" || (echo "ERROR: VERSION not set. Use: make update-formula VERSION=x.y.z" && exit 1)
	@echo "Updating Homebrew formula for version $(VERSION)..."
	@echo "Computing SHA256..."
	@SHA=$$(curl -sL "https://github.com/boochtek/path-manager/archive/refs/tags/v$(VERSION).tar.gz" | shasum -a 256 | cut -d' ' -f1); \
	echo "SHA256: $$SHA"; \
	sed -i.bak "s|archive/refs/tags/v.*\.tar\.gz|archive/refs/tags/v$(VERSION).tar.gz|" Formula/path.rb; \
	sed -i.bak "s|sha256 \".*\"|sha256 \"$$SHA\"|" Formula/path.rb; \
	rm -f Formula/path.rb.bak
	@git add Formula/path.rb
	@git commit -m "Update Homebrew formula to $(VERSION)" || echo "No changes to commit"
	@echo "Formula updated for version $(VERSION)"
