# ObjectTracking tests

Run `results=runObjectTrackingTests(); table(results)` from this folder in
MATLAB R2023a with Image Processing Toolbox. Twelve focused synthetic tests
cover the new overlap core, lineage selection, inheritance policies, sparse
IDs, empty frames and identity-preserving converters/adapters.

The MATLAB suite uses an injected Trackpy linker; actual Python execution is
separate. `test_trackpy_bridge.py` has four Python contract tests using an
injected fake linker and real numpy/pandas. Those tests passed in Codex.
See ../PYTHON_INTEGRATION.md for real Trackpy setup and validation work.

Dedicated real-data lineage examples/user testing, many-to-many scientific
acceptance and large-network performance remain pending. Preserve original
implementations until replacement workflows have been compared.
