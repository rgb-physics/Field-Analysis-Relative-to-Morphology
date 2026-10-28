function c = farmE5MeasureFilaments(c)
%FARME5MEASUREFILAMENTS Detect filaments and measure their positions, shapes, and directions.
% Inputs:
%   c   Configuration struct containing the settings and earlier results below.
% Configuration fields read:
%   c.Frame, DatasetID, Spacing, SpacingUnit: frame identity and YXZ spatial calibration.
%   c.FilamentLoader: optional @(frame) mask loader; empty selects intensity detection.
%   c.FilamentSigma: LoG smoothing in intensity-grid voxels.
%   c.FilamentSegmentationMethod, FilamentThreshold: intensity segmentation settings.
%   c.FilamentProperties: requested measurement names.
%   c.ExtentWidthFloor: positive floor used in derived filament measurements.
% Earlier results read:
%   c.Results.Raw: corrected intensity array from farmE5LoadData.
% Outputs:
%   c   The same configuration, with these results added or updated:
%   c.Results.Response, FilamentSegmentation: detection results; empty for a supplied mask.
%   c.Results.FilamentMask: detected or supplied binary mask.
%   c.Results.Properties: measurement table, without boundary-relative quantities yet.
%   c.Results.Objects: prepared memberships returned by farmMeasureFilaments.
%
% This is an editable E5 teaching example, not a new general package API.
% Settings remain in c; intermediate data is stored in c.Results.

% Configuration and Earlier Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read the fields used by this stage explicitly.
frame = c.Frame;
raw = c.Results.Raw;

% Stage Calculation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
response = [];
filamentSegmentation = [];
if isempty(c.FilamentLoader)
    response = -farmLOG(double(raw), c.FilamentSigma);
    filamentSegmentation = farmSegmentIntensity(response, ...
        struct('Method', c.FilamentSegmentationMethod, 'Threshold', c.FilamentThreshold, 'ReturnComponents', true));
    filamentMask = filamentSegmentation.Mask;
    measurementInput = filamentSegmentation.Components;
else
    filamentMask = c.FilamentLoader(frame);
    measurementInput = filamentMask;
end
identity = struct('DatasetID', c.DatasetID, 'Frame', frame, 'Spacing', c.Spacing, 'SpacingUnit', c.SpacingUnit);
% Reuse segmentation components; a user-supplied mask still needs preparation.
[properties, objects] = farmMeasureFilaments(measurementInput, c.FilamentProperties, ...
    struct('Identity', identity, 'ExtentWidthFloor', c.ExtentWidthFloor));
fprintf('Measured %d filament detections.\n', height(properties));

% Retained Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Keep these values available to inspect or pass to later stages.
c.Results.Response = response;
c.Results.FilamentSegmentation = filamentSegmentation;
c.Results.FilamentMask = filamentMask;
c.Results.Properties = properties;
c.Results.Objects = objects;
end
