function entry = farmGetGlossaryEntry(term, varargin)
%FARMGETGLOSSARYENTRY Return one glossary entry as a scalar struct of strings.
% Prefer exact spelling; otherwise allow an unambiguous case-insensitive match.
% Optional Section accepts one name or a string vector; default is all sections.
validateattributes(term, {'char', 'string'}, {'nonempty'});
term = string(term);
if ~isscalar(term) || ismissing(term) || strlength(strtrim(term)) == 0
    error('sharedutilities:GlossaryTerm', 'Supply one nonempty glossary term.');
end
term = strtrim(term);
entries = farmGlossaryEntries(varargin{:});
rows = find(entries.Term == term);
if isempty(rows), rows = find(strcmpi(entries.Term, term)); end
if isempty(rows)
    error('sharedutilities:UnknownGlossaryTerm', ...
        'Unknown glossary term "%s". Use glossary("search", "%s") to find related entries.', term, term);
elseif numel(rows) > 1
    error('sharedutilities:AmbiguousGlossaryTerm', ...
        'Use exact spelling and/or Section to distinguish these entries: %s.', ...
        strjoin(entries.Section(rows) + ":" + entries.Term(rows), ', '));
end
entry = table2struct(entries(rows, :));
end
