function [pyMat] = farmMat2pyTrackMat(storeStruct, customFields)
%FARMMAT2PYTRACKMAT Takes in a structure called storeStruct with fields Vol,
% Inputs:
%   storeStruct     Per-frame structure containing or receiving object properties.
%   customFields    Property field names used by the historical conversion.
% Outputs:
%   pyMat           Historical numeric coordinates, mass and frame layout.

if nargin == 1
    customFields = {'Vol', 'Cens', 'FrameNum'};
end

% Instantiate matrix
centers = vertcat(storeStruct.(customFields{2}));
vols = vertcat(storeStruct.(customFields{1}));
uniqueTimes = vertcat(storeStruct.(customFields{3}));

% Iterate through time and store times
timeRange = 1:numel(storeStruct);
objsPerT = arrayfun(@(x) numel(storeStruct(x).(customFields{1})), timeRange);

% Generate time vector
timeCell = arrayfun(@(x) ones(objsPerT(x), 1) * uniqueTimes(x), timeRange, 'UniformOutput', false);
times = vertcat(timeCell{:});

% Make python matrix
pyMat = [centers, vols, times];

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMMAT2PYTRACKMAT Takes in a structure called storeStruct with fields Vol,
% Cens, FrameNum, and returns a matrix to be converted to a namba DataBase
% with various properties saved in each column
% Trackpy reads in a namba DataFrame with the following fields as headers
% x y (z) mass size ecc signal raw_mass ep frame particle
% z can be dropped for 2D data; as I have it formatted, Centroids contains
% an Nx3 array of coordinates, so simply feeding an Nx2 array here will
% work fine.
% customFields is a cell array of field names for volumes, centroids, and
% frame indices
