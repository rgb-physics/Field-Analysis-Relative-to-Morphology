function matches = farmSearchGlossary(text, varargin)
%FARMSEARCHGLOSSARY Case-insensitive literal search across all farmGlossary text.
% Inputs:
%   text            Literal case-insensitive search text.
%   varargin        Optional Section and SearchIn filters as name/value pairs.
% Outputs:
%   matches         Table of entries matching the literal text and selected filters.

validateattributes(text, {'char', 'string'}, {'nonempty'});
text = string(text);
if ~isscalar(text) || ismissing(text) || strlength(strtrim(text)) == 0
    error('sharedutilities:GlossarySearch', 'Supply one nonempty search string.');
end
entries = farmGlossaryEntries();
[entries, searchIn] = farmSUSelectGlossaryEntries(entries, true, varargin{:});
selected = false(height(entries), 1);
for name = searchIn
    selected = selected | contains(entries.(char(name)), strtrim(text), 'IgnoreCase', true);
end
matches = entries(selected, :);
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMSEARCHGLOSSARY Case-insensitive literal search across all farmGlossary text.
% Returns matching rows of farmGlossaryEntries; no matches returns an empty table.
% Optional Section="all" and SearchIn="all" also accept string vectors:
% farmSearchGlossary("geometry", 'SearchIn', ["Term", "Definition"], ...
%     'Section', ["Glossary", "DataDictionary"]). Fields combine with OR;
% the section filter and text-match filter combine with AND.
