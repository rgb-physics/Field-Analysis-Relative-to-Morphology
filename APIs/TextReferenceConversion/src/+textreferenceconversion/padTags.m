function [inTags] = padTags(inTags,tagsLen)
%PADTAGS Takes in a cell array of strings and ensures all contained strings
%have tagsLen number of character
% Rémi Boros - 2025-04-10

for index = 1:numel(inTags)
    inTags{index} = pad(inTags{index},tagsLen);
end

end

