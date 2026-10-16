function [trajStruct] = farmAddFieldStruct2Traj(inStruct, trajStruct, desFields, desTrajs)
%FARMADDFIELDSTRUCT2TRAJ This function takes in inStruct, a structure with
% Inputs:
%   inStruct        Input structure containing the requested fields.
%   trajStruct      Trajectory structure receiving or providing selected histories.
%   desFields       Field names to copy into trajectories.
%   desTrajs        Optional indices of trajectories to update.
% Outputs:
%   trajStruct      Trajectory structure with requested per-frame properties.

% Check if desTrajs was passed
if nargin == 3
    desTrajs = 1:numel(trajStruct);
end

% For indexing
field1 = desFields{1};
storeSize = size(inStruct(1).(field1));
offDim = prod(storeSize(2:end));

% Define object IDs in inStruct frame and all time frame
numObjsPerT = [0 farmStructFieldSizes(inStruct, field1)] / offDim;  % Objects in each frame
sumObjsPerT = cumsum(numObjsPerT);                      % Total objects to current frame

% Add storeStruct info to trajStructs
for trajInd = 1:numel(desTrajs)
    currTraj = desTrajs(trajInd);
    currObjInds = trajStruct(currTraj).objIDs;
    currFrames = trajStruct(currTraj).Frames;
    globObjInds = currObjInds + sumObjsPerT(currFrames)';       % Shift object IDs by time they were defined in
    % Iterate through fields and store
    for fieldInd = 1:numel(desFields)
        currField = desFields{fieldInd};
        allFieldVals = vertcat(inStruct.(currField));
        if isa(allFieldVals, 'cell')
            allFieldVals = cell2mat(allFieldVals);
        end
        trajStruct(currTraj).(currField) = allFieldVals(globObjInds, :);
    end
end

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMADDFIELDSTRUCT2TRAJ This function takes in inStruct, a structure with
% properties of objects divided by frame and stores desired fields in
% desFields in trajStruct with identical field names for all indices of
% storeStruct. trajStruct is expected to have at least two fields objIDs and
% Frames, used to index
