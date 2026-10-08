function [globalID] = readGlobalID(frame2localIDs,selID, selTime)
%READGLOBALID Takes in an map from local object ID, global object ID, and
%time, along with a desired time and ID in that time. Returns the global ID
% Rémi Boros

IDlogic = ismember(frame2localIDs(:,1),selID);
timeLogic = ismember(frame2localIDs(:,3),selTime);

globalID = frame2localIDs(IDlogic & timeLogic,2);

end

