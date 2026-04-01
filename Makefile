# =============================================================================
# Makefile — ApplicationMenu
# =============================================================================
# All tools (xcodebuild, hdiutil, ditto, codesign, shasum) ship with macOS and
# Xcode Command Line Tools.  No third-party utilities are required.
#
# xcpretty is used when available to format xcodebuild output.  If it is not
# installed the raw xcodebuild output is shown instead.  Install it with:
#   gem install xcpretty
#
# Quick reference
# ---------------
#   make build          Compile Debug build (smoke-check; no artefact saved)
#   make test           Run unit + UI tests
#   make test-unit      Run unit tests only (faster)
#   make archive        Build Release .xcarchive → Releases/archive/
#   make export         Extract .app from archive → Releases/export/
#   make dmg            Build installer .dmg     → Releases/dist/
#   make zip            Wrap .dmg in ZIP          → Releases/dist/
#   make checksum       Print + save SHA-256      → Releases/dist/
#   make release        Full pipeline (archive → export → dmg → zip → checksum)
#   make version        Print current MARKETING_VERSION
#   make bump V=0.2.0   Set a new version in the project file
#   make clean          Remove all generated artefacts
#   make open           Open the project in Xcode
# =============================================================================

# ---------------------------------------------------------------------------
# Project identity
# ---------------------------------------------------------------------------
PROJECT   := ApplicationMenu.xcodeproj
SCHEME    := ApplicationMenu
APP_NAME  := ApplicationMenu

# macOS destination string used by every xcodebuild invocation
DEST      := platform=macOS

# ---------------------------------------------------------------------------
# Output directories  (all under Releases/, which is already in .gitignore)
# ---------------------------------------------------------------------------
RELEASES_DIR := Releases
ARCHIVE_DIR  := $(RELEASES_DIR)/archive
EXPORT_DIR   := $(RELEASES_DIR)/export
STAGING_DIR  := $(RELEASES_DIR)/staging
DIST_DIR     := $(RELEASES_DIR)/dist

# Individual artefact paths
ARCHIVE_PATH := $(ARCHIVE_DIR)/$(APP_NAME).xcarchive
APP_PATH     := $(EXPORT_DIR)/$(APP_NAME).app
DMG_PATH     := $(DIST_DIR)/$(APP_NAME).dmg
ZIP_PATH     := $(DIST_DIR)/$(APP_NAME).zip
SHASUM_PATH  := $(DIST_DIR)/$(APP_NAME).zip.sha256

# Temporary exportOptions.plist (written at export time, removed afterwards)
EXPORT_OPTS  := $(RELEASES_DIR)/.exportOptions.plist

# ---------------------------------------------------------------------------
# Version (read directly from the project file; no Xcode required)
# ---------------------------------------------------------------------------
# Escape dots so the string is safe to use in sed patterns below.
VERSION     := $(shell grep -m1 'MARKETING_VERSION' $(PROJECT)/project.pbxproj \
                 | sed 's/.*= //;s/;//')
VERSION_ESC := $(shell echo "$(VERSION)" | sed 's/\./\\./g')

# ---------------------------------------------------------------------------
# xcodebuild output filter
# Use xcpretty when installed; fall back to raw output transparently.
# ---------------------------------------------------------------------------
XCPRETTY := $(shell command -v xcpretty 2>/dev/null)
ifdef XCPRETTY
  PIPE := | xcpretty
else
  PIPE :=
endif

# ---------------------------------------------------------------------------
# Phony targets
# ---------------------------------------------------------------------------
.PHONY: all build test test-unit archive export dmg zip checksum release \
        version bump open clean help

all: help

# ---------------------------------------------------------------------------
# Development
# ---------------------------------------------------------------------------

## build: Compile a Debug build (smoke-check)
build:
	xcodebuild build \
	  -project       "$(PROJECT)" \
	  -scheme        "$(SCHEME)" \
	  -configuration Debug \
	  -destination   "$(DEST)" \
	  CODE_SIGN_IDENTITY="-" \
	  $(PIPE)

## test: Run the full test suite (unit + UI tests)
test:
	xcodebuild test \
	  -project       "$(PROJECT)" \
	  -scheme        "$(SCHEME)" \
	  -destination   "$(DEST)" \
	  CODE_SIGN_IDENTITY="-" \
	  $(PIPE)

## test-unit: Run unit tests only, skipping UI tests (faster)
test-unit:
	xcodebuild test \
	  -project       "$(PROJECT)" \
	  -scheme        "$(SCHEME)" \
	  -destination   "$(DEST)" \
	  -only-testing  "$(APP_NAME)Tests" \
	  CODE_SIGN_IDENTITY="-" \
	  $(PIPE)

# ---------------------------------------------------------------------------
# Release pipeline
# ---------------------------------------------------------------------------

## archive: Build a Release .xcarchive
archive:
	@mkdir -p "$(ARCHIVE_DIR)"
	xcodebuild archive \
	  -project      "$(PROJECT)" \
	  -scheme       "$(SCHEME)" \
	  -configuration Release \
	  -archivePath  "$(ARCHIVE_PATH)" \
	  CODE_SIGN_IDENTITY="-" \
	  $(PIPE)
	@echo "→ Archive: $(ARCHIVE_PATH)"

## export: Extract the .app from the archive (equivalent to: Distribute App → Copy App)
export:
	@test -d "$(ARCHIVE_PATH)" || \
	  (echo "No archive found at $(ARCHIVE_PATH). Run 'make archive' first."; exit 1)
	@mkdir -p "$(EXPORT_DIR)"
	@# Write a self-contained exportOptions.plist for the "Copy App" method.
	@# This replicates the manual: Distribute App → Custom → Copy App → Export.
	@printf '%s\n' \
	  '<?xml version="1.0" encoding="UTF-8"?>' \
	  '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
	  '<plist version="1.0">' \
	  '<dict>' \
	  '    <key>method</key>' \
	  '    <string>copy</string>' \
	  '</dict>' \
	  '</plist>' \
	  > "$(EXPORT_OPTS)"
	xcodebuild -exportArchive \
	  -archivePath        "$(ARCHIVE_PATH)" \
	  -exportPath         "$(EXPORT_DIR)" \
	  -exportOptionsPlist "$(EXPORT_OPTS)" \
	  $(PIPE)
	@rm -f "$(EXPORT_OPTS)"
	@echo "→ App: $(APP_PATH)"

## dmg: Build the installer .dmg  (equivalent to: create ApplicationMenuInstaller + hdiutil)
#
# The staging directory mirrors what was previously assembled by hand:
#   ApplicationMenuInstaller/
#     ApplicationMenu.app          ← the exported app
#     Applications                 ← symlink to /Applications  (replaces the
#                                     Finder "Make Alias" step; a symlink inside
#                                     a .dmg behaves identically to a Finder alias
#                                     for drag-install purposes)
dmg:
	@test -d "$(APP_PATH)" || \
	  (echo "No .app found at $(APP_PATH). Run 'make export' first."; exit 1)
	@mkdir -p "$(STAGING_DIR)" "$(DIST_DIR)"
	@rm -rf "$(STAGING_DIR)/$(APP_NAME).app" "$(STAGING_DIR)/Applications"
	ditto "$(APP_PATH)" "$(STAGING_DIR)/$(APP_NAME).app"
	@ln -sf /Applications "$(STAGING_DIR)/Applications"
	hdiutil create \
	  -volname   "$(APP_NAME)" \
	  -srcfolder "$(STAGING_DIR)" \
	  -ov \
	  -format    UDZO \
	  "$(DMG_PATH)"
	@echo "→ DMG: $(DMG_PATH)"

## zip: Wrap the .dmg in a ZIP archive (required format for the Homebrew cask)
zip:
	@test -f "$(DMG_PATH)" || \
	  (echo "No .dmg found at $(DMG_PATH). Run 'make dmg' first."; exit 1)
	@mkdir -p "$(DIST_DIR)"
	@# ditto -ck produces a macOS-native ZIP with no resource-fork noise.
	@# The result is a ZIP containing just ApplicationMenu.dmg at its root,
	@# which is the format the tap formula (and GitHub releases) expect.
	ditto -ck "$(DMG_PATH)" "$(ZIP_PATH)"
	@echo "→ ZIP: $(ZIP_PATH)"

## checksum: Compute and save the SHA-256 of the ZIP (paste into the tap formula)
checksum:
	@test -f "$(ZIP_PATH)" || \
	  (echo "No ZIP found at $(ZIP_PATH). Run 'make zip' first."; exit 1)
	@shasum -a 256 "$(ZIP_PATH)" | tee "$(SHASUM_PATH)"
	@echo "→ Checksum saved: $(SHASUM_PATH)"

## release: Full pipeline — archive → export → dmg → zip → checksum
release: archive export dmg zip checksum
	@echo ""
	@echo "╔══════════════════════════════════════════════════════╗"
	@echo "║  Release artefacts ready — v$(VERSION)"
	@echo "╠══════════════════════════════════════════════════════╣"
	@echo "║  Archive  : $(ARCHIVE_PATH)"
	@echo "║  App      : $(APP_PATH)"
	@echo "║  DMG      : $(DMG_PATH)"
	@echo "║  ZIP      : $(ZIP_PATH)"
	@echo "║  SHA-256  : $$(awk '{print $$1}' $(SHASUM_PATH))"
	@echo "╠══════════════════════════════════════════════════════╣"
	@echo "║  Next steps:"
	@echo "║  1. git tag $(VERSION) && git push --tags"
	@echo "║  2. Upload $(APP_NAME).zip to the GitHub release"
	@echo "║  3. Update barseghyanartur/app-menu-tap with the"
	@echo "║     new version and SHA-256 shown above"
	@echo "╚══════════════════════════════════════════════════════╝"

# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------

## version: Print the current MARKETING_VERSION
version:
	@echo $(VERSION)

## bump V=x.y.z: Set a new MARKETING_VERSION in the Xcode project file
#
# Usage: make bump V=0.2.0
#
# Only MARKETING_VERSION lines are touched; CURRENT_PROJECT_VERSION (the
# integer build number) is left unchanged.
bump:
	@test -n "$(V)" || { echo "Usage: make bump V=<new.version>  e.g. make bump V=0.2.0"; exit 1; }
	@grep -q "MARKETING_VERSION = $(VERSION_ESC);" "$(PROJECT)/project.pbxproj" || \
	  { echo "Current version '$(VERSION)' not found in project file."; exit 1; }
	@sed -i '' \
	  "s/MARKETING_VERSION = $(VERSION_ESC);/MARKETING_VERSION = $(V);/g" \
	  "$(PROJECT)/project.pbxproj"
	@echo "Bumped: $(VERSION) → $(V)"
	@echo "Remember to add an entry to CHANGELOG.rst before committing."

## open: Open the project in Xcode
open:
	open "$(PROJECT)"

## clean: Remove all generated artefacts (the Releases/ directory)
clean:
	@rm -rf "$(RELEASES_DIR)"
	@echo "Removed $(RELEASES_DIR)/"

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

## help: List available targets
help:
	@echo ""
	@echo "Usage: make <target>  [V=<version> for bump]"
	@echo ""
	@awk '/^## /{sub(/^## /,""); n=index($$0,": "); printf "  \033[36m%-14s\033[0m %s\n", substr($$0,1,n-1), substr($$0,n+2)}' \
	  $(MAKEFILE_LIST)
	@echo ""
	@echo "  Current version: $(VERSION)"
	@echo ""
