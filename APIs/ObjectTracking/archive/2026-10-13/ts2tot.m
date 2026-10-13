function [totTable] = ts2tot(trajStruct,fieldNames)
%TS2TOT Takes in a structure trajStruct. Each index of this struct contains
%object ID information and time/frame information from which the object is
%sampled. By default, these fields are alled objIDs and Frames, but can be
%something else if passed in the cell array fieldNames. The order of the
%strings in in fieldNames is expected to be {'objIDs','Frames'}. The
%function returns a table containing time, object, trajectory information
% 2023-11-21

% Define field names to probe if not given by the user
if nargin == 1
    fieldNames = {'objIDs','Frames'};
end

% Count number of objects in each trajectory
allIDs = vertcat(trajStruct.(fieldNames{1}));
allFrames = vertcat(trajStruct.(fieldNames{2}));
trajVec = structLenVec(trajStruct, fieldNames{1});

% Sort based on time
[Time, sortOrder] = sort(allFrames);
ObjectID = allIDs(sortOrder);
Trajectory = trajVec(sortOrder);

%Save in table
totTable = table(Time, ObjectID, Trajectory);

end


