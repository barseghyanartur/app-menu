==========================
How to release a macOs app
==========================

Archive the application
=======================
#. Xcode -> Product -> Build
#. Xcode -> Product -> Archive : Distribute App -> Custom -> Copy App : Export
#. Create another directory `ApplicationMenuInstaller` in the directory where your `ApplicationMenu.app` was created.
#. Move the `ApplicationMenu.app` into that directory.
#. Create an alias from `/Applications` directory: Finder -> Macintosch HD -> `Ctrl + Click` on the `Applications` -> Make Alias.
#. Move the created alias from `/Users/me/Desktop` into `ApplicationMenuInstaller`.
#. Create a dmg archive:

   .. code-block:: sh

	  hdiutil create -volname "ApplicationMenu" -srcfolder ApplicationMenuInstaller -ov -format UDZO ApplicationMenu.dmg

#. Pack the `ApplicationMenu.dmg` into a ZIP archive (using `Double Commander`).

Calculate shasum for tap
========================
#. Calculate the shasum for the `ApplicationMenu.zip` archive:

   .. code-block:: sh
   
       shasum -a 256 ApplicationMenu.zip
