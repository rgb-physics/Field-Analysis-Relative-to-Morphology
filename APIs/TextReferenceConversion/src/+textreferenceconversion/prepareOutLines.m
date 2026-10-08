function [outLines] = prepareOutLines(allLines,inTags,concStr,tagsLen)
%PREPAREOUTLINES Take in strings from nbib, then prepare concatenated
%strings corresponding to desired tags (inTags) to be stored in bibtex
%format. tagsLen is a variable that determines the max length of a nbib
%tag; this length is typically 4. concStr is a connector string that goes
%in between concatenated strings that share a tag, eg. ' and ' between
%author names.
% Rémi Boros - 2025-04-10

% default tagsLen = 4, if not passed
if nargin == 3
    tagsLen = 4;
end

% Convert strings into matrix of characters
lineChars = char(allLines);

% Get indices of lines with tags/delimiters
lineStarts = lineChars(:,1:tagsLen);
allTags = splitlines(string(lineStarts));
isTag = ~ismember(allTags,pad('',tagsLen));
% Group lines by tag index
lineToTag = cumsum(isTag);

%%%%%%%%  Construct Strings %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Step 1: find indices of desired tags in allTags
[tagInds,inMap] = ismember(allTags,inTags);
tagOrder = inMap(inMap>0);

% Step 2: find all lines that have the above indices (search for \n's)
[~,lnGrpInds] = ismember(lineToTag,lineToTag(tagInds));

% Step 3: Combine CONSECUTIVE lines that are split up
concatLines = cell(max(lnGrpInds),1);
for currGrp = 1:max(lnGrpInds)
    currLines = find(lnGrpInds == currGrp);
    % Concatenate strings, removing [<TAG>'- '] from each line start
    % Gotta use a for loop :((
    tempStr = '';
    for lineInd = 1:numel(currLines)
        currLine = currLines(lineInd);
        tempStr = [tempStr allLines{currLine}(:,(tagsLen+3):end)];
    end
    concatLines{currGrp} = tempStr;
end

% Step 4: Combine lines that share a tag with "connector string"
outLines = cell(numel(inTags),1);
for currTag = 1:max(tagOrder)
    lineInds = find(tagOrder == currTag);
    tempStr = '';
    % Iterate over each line sharing a tag and concatenate
    for lineInd = 1:numel(lineInds)
        if lineInd > 1
            tempStr = [tempStr concStr];
        end
        tempStr = [tempStr concatLines{lineInds(lineInd)}];
    end
    outLines{currTag} = tempStr;
end

end

