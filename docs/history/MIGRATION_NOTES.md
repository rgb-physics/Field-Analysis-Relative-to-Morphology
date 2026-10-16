> Historical snapshot, retained October 15, 2026. Read the [current user guide](../README.md) and [history index](README.md) before following these older notes.

# Migration notes

The local `MeMo` checkout is a first-pass organization of the files named in `PROPOSED_TREE.md` and its user-marked routing section. The source archive and the existing `imagestackio` package were left unchanged.

- Source-to-destination mapping and copy status: `MIGRATION_CHECKLIST.md`.
- Files in `ArchiveReview/variants` are the selected archived backup variants named by the proposal.
- The one planned source file without an implementation, `readND2.m`, remains a placeholder in the tree plan; the ND2 SDK dependency is unresolved.
- The copy preserves source contents. No MATLAB validation, refactoring, or API compatibility work was performed during this first-pass organization.
- The 140 paths explicitly left out of the proposal remain excluded from this copy. 3D PIV, Chan-Vese files, `.asv` autosaves, and private datasets are not included.
- `TextReferenceConversion` was present in the first-pass copy but has since been removed because reference conversion is outside this project's scope.
