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
        self.frames = []

        def fake_link(frame, search_range, memory, pos_columns):
            self.calls.append((search_range, memory, pos_columns))
            self.frames.append(frame.copy())
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

    def test_coordinates_mass_and_frames_keep_matlab_column_order(self):
        for dimensions in (2, 3):
            coordinates = np.array([[101.25, 7.5, 900.75],
                                    [12.5, -40.25, 30.5],
                                    [0.5, 12, 9.25]])[:, :dimensions]
            data = np.column_stack((coordinates, [13, 17, 23], [8, 2, 8]))
            linked = self.bridge.link_detections(data, 2.5, 0)
            frame = self.frames[-1]
            positions = ["x", "y", "z"][:dimensions]
            # Frame sorting reorders rows, but must not swap or offset coordinates.
            returned_coordinates = np.column_stack([frame[position].to_numpy() for position in positions])
            np.testing.assert_array_equal(returned_coordinates, coordinates[[1, 0, 2]])
            np.testing.assert_array_equal(frame["mass"].to_numpy(), [17, 13, 23])
            np.testing.assert_array_equal(frame["frame"].to_numpy(), [2, 8, 8])
            np.testing.assert_array_equal(frame["row_id"].to_numpy(), [2, 1, 3])
            self.assertEqual(dict(linked.tolist()), {1: 12, 2: 13, 3: 14})
            if dimensions == 2:
                self.assertNotIn("z", frame.columns)

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
