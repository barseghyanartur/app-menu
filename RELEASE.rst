==========================
How to release a macOs app
==========================

Archive the application
=======================
#. Xcode -> Product -> Build
#. Xcode -> Product -> Archive : Distribute App -> Custom -> Copy App : Export
#. Run the release pipeline:

   .. code-block:: sh

       make release

   This builds the archive, exports the .app, creates the DMG, computes the
   SHA-256 checksum, and generates the Homebrew cask file.

Calculate shasum for tap
========================
The ``make release`` target computes the checksum automatically. The SHA-256
is printed to stdout and saved to ``Releases/dist/ApplicationMenu.dmg.sha256``.

Manual steps after ``make release``
====================================
#. Tag and push:

   .. code-block:: sh

       git tag <version> && git push --tags

#. Upload ``Releases/dist/ApplicationMenu.dmg`` to the GitHub release.
#. Copy ``Releases/tap/app-menu.rb`` to your Homebrew tap's ``Casks/`` directory.
