"""Bridge-contract tests with a fake linker; not Trackpy algorithm validation."""
import importlib.util
from pathlib import Path
import sys
from types import SimpleNamespace
import unittest
from unittest.mock import patch
import numpy as np


class BridgeContractTests(unittest.TestCase):
    def setUp(self):
        self.calls = []

        def fake_link(frame, search_range, memory, pos_columns):
            self.calls.append((search_range, memory, pos_columns))
            result = frame.copy()
            result["particle"] = result["row_id"] + 10
            return result.iloc[::-1]

        path = Path(__file__).parents[1] / "python" / "trackpy_bridge.py"
        spec = importlib.util.spec_from_file_location("test_tracking_bridge", path)
        self.bridge = importlib.util.module_from_spec(spec)
        with patch.dict(sys.modules, {"trackpy": SimpleNamespace(link_df=fake_link)}):
            spec.loader.exec_module(self.bridge)

    def test_two_dimensional_identity_and_fractional_range(self):
        data = [[1, 2, 1, 3], [3, 4, 1, 1], [5, 6, 1, 2]]
        linked = self.bridge.link_detections(data, 0.5, 3)
        self.assertEqual(self.calls[0], (0.5, 3, ["x", "y"]))
        by_row = dict(linked.tolist())
        self.assertEqual(by_row, {1: 12, 2: 13, 3: 14})

    def test_three_dimensional_components(self):
        linked = self.bridge.link_detections([[1, 2, 3, 4, 5]], 2.25, 0)
        self.assertEqual(self.calls[0], (2.25, 0, ["x", "y", "z"]))
        np.testing.assert_array_equal(linked, [[1, 12]])

    def test_empty_does_not_call_linker(self):
        linked = self.bridge.link_detections(np.empty((0, 4)), 1, 0)
        self.assertEqual(linked.shape, (0, 2))
        self.assertEqual(self.calls, [])

    def test_invalid_memory_and_frame(self):
        with self.assertRaises(ValueError):
            self.bridge.link_detections([[1, 2, 3, 4]], 1, 0.5)
        with self.assertRaises(ValueError):
            self.bridge.link_detections([[1, 2, 3, 4.5]], 1, 0)


if __name__ == "__main__":
    unittest.main()
