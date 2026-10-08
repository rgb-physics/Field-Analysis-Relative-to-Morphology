% Take in a directory, scan for .nbibs, generate .bibs with desired fields
% Rémi Boros - 2025-04-10

% ogDir = '<redacted original absolute path>';
ogDir = '';
saveDir = fullfile(ogDir,'Converted');
moveDir = fullfile(ogDir,'Added');

convExt = '*.nbib';

% Tags in and out
tagsLen = 4;
inTags = {'FAU','TI','TA','DP','VI','IP','AID'};
outTags = {'author','title','journal','year','volume','pages','doi'};
concStr = ' and ';       % Used to combine multiple strings that share inTag
refType = 'article';
fieldStart = '{';   fieldEnd = '},';

% Pad tags:
inTags = padTags(inTags,tagsLen);

%% Generate folders
if ~exist(saveDir,'dir')
    mkdir(saveDir)
end
if ~exist(moveDir,'dir')
    mkdir(moveDir)
end

%% Find all nbibs, write them all to .txt files
allnbibs = dir(fullfile(ogDir,convExt));
for index = 1:numel(allnbibs)
    % Load text file, then split by line
    currFile = extractFileText(fullfile(ogDir,allnbibs(index).name));
    allLines = splitlines(currFile);
    % From raw split lines and desired tags, prepare lines to keep
    [outLines] = prepareOutLines(allLines,inTags,concStr,tagsLen);

%%%%%%%% Manually repair 'year' tag %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    excptTag = 'year';
    if sum(ismember(outTags,excptTag))
        lineInd = ismember(outTags,excptTag);
        excptLine = outLines{lineInd};
        outLines{lineInd} = excptLine(1:4);
        yearStr = outLines{lineInd}(1:end);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Write lines to file
    % File start: ' @<article>{<chars->','>_<year>, '
    % File end  : ' } '
    % startString = sprintf('@%s{%s_%s',)

    % Find first author name: start after "fieldStart," end before comma
    authorTag = 'FAU ';
    authorInd = ismember(inTags,authorTag);
    authorNames = outLines{(authorInd)};
    if numel(authorNames) > 0
        commaInds = strfind(authorNames,',');
        firstAuthor = authorNames((numel(fieldStart)):commaInds(1)-1);
    else
        firstAuthor ='';
    end
    % Append article type, author name, year:
    firstLine = sprintf('@%s{%s_%s,',refType,firstAuthor,yearStr);
    % Open file and start writing
    % Out Structure Format: outTag{index} = {associated line},
    outLoc = fullfile(saveDir,sprintf('%s_%s.txt',firstAuthor,yearStr));
    writelines(firstLine,outLoc);
    % Iterate through tags, write lines
    for currTag = 1:numel(inTags)
        outStr = sprintf('\t%s = %s%s%s',...
            outTags{currTag},fieldStart,outLines{currTag},fieldEnd);
        writelines(outStr,outLoc,WriteMode='append');
    end
    % Finish with closed bracket, then close
    writelines('}',outLoc,WriteMode='append');
    fclose all;

end
