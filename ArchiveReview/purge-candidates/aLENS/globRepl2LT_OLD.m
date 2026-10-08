function [outPairs,IDsKey,stitchedRows] = globRepl2LT(IDConvert,selIDs)
%GLOBREPL2LT Takes in ID LUT of the form [Local, Global, Repl, Time] and a
%number of IDs that are found either in Global or Repl. column. The
%function returns a pair of [Local, Time] values for each ID found in
%[Global, Repl]. Used to get local+time indices from global or replaced
%indices. IDConvert is expected to be a table with columns 
% Local, Global, Replace, Time
% Rémi Boros - 2024-11-13

% From global/replace ID, get local ID and time 
[selLogic,IDsOrder] = ismember(table2array(IDConvert(:,2:3)),selIDs);
selInds = find(selLogic);
[rowIDs,~] = ind2sub(size(IDConvert),selInds);
% Define LT pairs and reconstructed selIDs with matching order to outPairs
IDsKey = selIDs(IDsOrder(IDsOrder > 0));
outPairs = table2array(IDConvert(rowIDs,[1 4]));
% Get row indices of IDConvert that correspond to output pairs
tempConstruct = [outPairs(:,1) IDsKey outPairs(:,2)];
globalRows = ismember(table2array(IDConvert(:,[1 2 4])),tempConstruct,'rows');
replRows = ismember(table2array(IDConvert(:,[1 3 4])),tempConstruct,'rows');
stitchedRows = [find(globalRows); find(replRows)];

end

