function [trajStruct] = tot2ts(totArray,minTrajLength)
%TOT2TS Takes in an array totArray with 3 columns corresponding to times,
%object IDs, and trajectories, and returns said info in a trajectory
%structure, one index corresponding to each trajectory

%Ensure that totArray is not a table
if isa(totArray, 'table')
    totArray = table2array(totArray);
end

% Store array contents in new structure
trajStruct = struct();
for trajInd = 1:max(totArray(:,3))
    logicVec = totArray(:,3) == trajInd;
    trajStruct(trajInd).objIDs = totArray(logicVec,2);
    trajStruct(trajInd).Frames = totArray(logicVec,1);
    if minTrajLength > sum(logicVec)
        trajStruct(trajInd).TrajLen = 0;
    else
        trajStruct(trajInd).TrajLen = sum(logicVec,'all');
    end
end

% Filter out trajectories that are too short
allTrajLens = [trajStruct.TrajLen];
trajStruct = trajStruct(allTrajLens > 0);

end

