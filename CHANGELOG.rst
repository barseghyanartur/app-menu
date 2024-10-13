Release history and notes
=========================

`Sequence based identifiers
<http://en.wikipedia.org/wiki/Software_versioning#Sequence-based_identifiers>`_
are used for versioning (schema follows below):

.. code-block:: text

    major.minor[.revision]

- It's always safe to upgrade within the same minor version (for example, from
  0.3 to 0.3.4).
- Minor version changes might be backwards incompatible. Read the
  release notes carefully before upgrading (for example, when upgrading from
  0.3.4 to 0.4).
- All backwards incompatible changes are mentioned in this document.

0.1.4
-----
2024-10-13

- Support web apps from more sources (Brave apps, Edge apps, Opera apps).

0.1.3
-----
2024-05-23

- Correct version in the meta-data.
- Add a Version tab to About section.
- Add info about tap-install.

0.1.2
-----
2024-02-14

.. note::

   Release dedicated to my dear valentine - Anahit.

- Added option for case insensitive application sorting.

0.1.1
-----
2024-02-03

- Add Chrome Apps.

0.1
---
2024-01-31

- Initial beta release.
