# Python integration checklist and preserved behavior

Original: `src/objecttracking/cens2TrajsSimple.py`, supplied by the user.
It remains unchanged for historical comparison. Adapted implementation:
`python/trackpy_bridge.py`. No Python environment/packages were installed.

## Implemented

- Retain the original NumPy -> pandas DataFrame -> `tp.link_df` algorithm.
- Both 2-D and 3-D positions, explicit `pos_columns`, configurable search
  range and missing-frame memory; no merge/split inference.
- Preserve fractional search range (float), validate integer memory.
- Correct one-based row/trajectory IDs for both dimensions by selecting
  columns by name instead of hard-coded 3-D column offsets.
- Carry original RowID through stable frame sorting and linking; MATLAB
  maps it explicitly to DatasetID/Frame/ObjectID even if rows are reordered.
- Remove unused sys/scipy/savemat/pims/os imports; runtime requirements are
  numpy, pandas and trackpy. Trackpy's own transitive dependencies still apply.
- Resolve script by absolute package-relative path; no working-directory
  assumptions or external filename search.
- Separate export/import from execution; injectable Linker supports tests
  and later external execution without requiring Python in the MATLAB suite.
- No tracking side effects during Python import; MATLAB pyrunfile inputs
  explicitly trigger the bridge. Empty input produces a typed empty output.
- No native Munkres backend in the new API. Historical function retained only.

## Still to do in the user's licensed environment

Four bridge-contract tests have passed in Codex using an injected fake linker
with real NumPy/pandas. They check row identity, both dimensions, fractional
range and empty/invalid inputs. Trackpy itself is absent from that runtime,
so these do not validate Trackpy's linking or MATLAB/Python execution.

1. Inspect `pyenv` and configure a Python version supported by MATLAB R2023a.
   Do not replace the user's environment without agreement. Check MathWorks'
   Python compatibility guidance for that release.
2. Verify imports of numpy/pandas/trackpy; record/pin working package versions
   after verification. Install into the SAME interpreter configured in pyenv.
3. Run real Python integration checks: known 2-D and 3-D tracks, fractional
   search range, reversed input order, missed detections with Memory=0 and >0,
   empty frames, sparse frame numbers, isolated detections and ambiguous links.
4. Compare original and adapted linking on the same detection tables. Compare
   identity partitions, not raw particle numbering, which may vary with order.
5. Confirm physical-coordinate scaling and search-range units in examples.
   No PSF correction or anisotropic linking policy is inferred automatically.
6. Test MATLAB/Python numeric conversions and Python exception reporting on
   the deployed combination; large centroid tables should remain numeric.
7. Clarify timeout/resource/failure behavior for long Trackpy runs. This
   implementation invokes Trackpy over a SMALL detection table, not image
   stacks; a separate external-process backend can be added later if needed.
8. Only after testing, retire or relocate the original Python entry point and
   its old MATLAB workflow, with provenance and compatibility notes.

## Outside current package scope

User decision, October 27, 2026: keep basic Trackpy usage and coordinate/identity
handoff checks. Do not implement the extensions listed below. Existing code is
preserved; this decision does not automatically retire existing public functions.

Trackpy merge/split inference; motion prediction/custom linking strategies;
position-based trajectory analysis; head-tail tracking; gap bridging in the
overlap core (disabled, independent of Trackpy's supported memory option).

## MATLAB usage

```matlab
membership = farmTrackPositions(detectionProperties, ...
    struct('SearchRange',8,'Memory',3,'MassProperty','Volume'));
```

Input rows must represent separate detections, with centroid XY or XYZ.
Do not silently collapse disconnected lineage regions into a shared centroid.
Use ObjectGeometry component identity preparation when making Trackpy inputs.
Volume acts as the original 'mass' column, but `link_df` here links by positions;
passing mass does not automatically make it an assignment criterion.
