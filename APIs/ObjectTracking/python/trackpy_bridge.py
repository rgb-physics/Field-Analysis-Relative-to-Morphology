"""Adapted from Remi Boros's cens2TrajsSimple.py; MATLAB pyrunfile entry point.

Preserves tp.link_df and memory-based linking. Returns explicit one-based
original row identities and particle IDs; never infers identity from sorting.
"""
import numpy as np
import pandas as pd
import trackpy as tp


def link_detections(data, search_range, memory):
    data = np.asarray(data, dtype=float)
    if data.ndim != 2 or data.shape[1] not in (4, 5):
        raise ValueError("Expected [XY mass frame] or [XYZ mass frame].")
    if not np.isfinite(data).all():
        raise ValueError("Detection coordinates, mass and frames must be finite.")
    if np.any(data[:, -1] < 0) or np.any(data[:, -1] != np.floor(data[:, -1])):
        raise ValueError("Frames must be nonnegative integers.")
    search_range = float(search_range)
    if not np.isfinite(search_range) or search_range <= 0:
        raise ValueError("Search range must be a positive finite number.")
    if not np.isfinite(memory) or memory < 0 or memory != int(memory):
        raise ValueError("Memory must be a nonnegative integer.")
    if len(data) == 0:
        return np.empty((0, 2), dtype=np.int64)
    dimensions = data.shape[1] - 2
    positions = ["x", "y", "z"][:dimensions]
    columns = pd.Index(positions + ["mass", "frame"], dtype=object)
    frame = pd.DataFrame(data, columns=columns)
    frame["frame"] = frame["frame"].astype(np.int64)
    frame["row_id"] = np.arange(len(frame), dtype=np.int64) + 1
    # Stable frame sorting is for Trackpy; row_id retains original identities.
    frame = frame.sort_values(["frame", "row_id"], kind="stable")
    trajectories = tp.link_df(frame, search_range, memory=int(memory), pos_columns=positions)
    trajectories["trajectory_id"] = trajectories["particle"].astype(np.int64) + 1
    return np.column_stack((
        trajectories["row_id"].to_numpy(dtype=np.int64),
        trajectories["trajectory_id"].to_numpy(dtype=np.int64),
    ))


if "dataMat" in globals():
    linkedRows = link_detections(dataMat, cutOffDist, memoryWindow)
