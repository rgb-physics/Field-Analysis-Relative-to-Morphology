function [stitchedLTs,GRIDs,areGlobs] = globRepl2LT(IDConvert,selIDs)
%GLOBREPL2LT %GLOBREPL2LT Takes in ID LUT of the form [Local, Global, Repl, Time] and a
%number of IDs that are found either in Global or Repl. column. The
%function returns a pair of [Local, Time] values for each ID found in
%[Global, Repl]. Used to get local+time indices from global or replaced
%indices. IDConvert is expected to be a table with columns 
% Local, Global, Replace, Time
% Rémi Boros - 2024-11-18

% Convert lookup table to array
IDCKey = table2array(IDConvert);
% Find Global IDs and Replace IDs in LUT, then get corresponding [L,T] prs
[globLTs,globIDs] = mapWrap(selIDs(:),IDCKey(:,2),IDCKey(:,[1 4]),'rows');
[replLTs,replIDs] = mapWrap(selIDs(:),IDCKey(:,3),IDCKey(:,[1 4]),'rows');
% Define logical matrix to distinguish global IDs from replace IDs
areGlobs = logical(globIDs);
% Store stitched [L,T] pairs
stitchedLTs = zeros(size(globLTs)); 
stitchedLTs(areGlobs,:) = globLTs(areGlobs,:);
stitchedLTs(~areGlobs,:) = replLTs(~areGlobs,:);
% Reconstruct selIDs, retaining order from stitched LTs
GRIDs = globIDs + replIDs;

end

