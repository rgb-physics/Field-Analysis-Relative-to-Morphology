function matches = farmSearchGlossary(text, varargin)
%FARMSEARCHGLOSSARY Case-insensitive literal search across all glossary text.
% Returns matching rows of glossaryEntries; no matches returns an empty table.
% Optional Section="all" and SearchIn="all" also accept string vectors:
% farmSearchGlossary("geometry", 'SearchIn', ["Term", "Definition"], ...
%     'Section', ["Glossary", "DataDictionary"]). Fields combine with OR;
% the section filter and text-match filter combine with AND.
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
