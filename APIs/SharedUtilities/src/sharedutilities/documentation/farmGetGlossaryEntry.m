function entry = farmGetGlossaryEntry(term, varargin)
%FARMGETGLOSSARYENTRY Return one farmGlossary entry as a scalar struct of strings.
% Inputs:
%   term            One glossary or Data Dictionary entry name.
%   varargin        Optional Section filter as name/value pairs.
% Outputs:
%   entry           Entry fields as a scalar struct of strings.

validateattributes(term, {'char', 'string'}, {'nonempty'});
term = string(term);
if ~isscalar(term) || ismissing(term) || strlength(strtrim(term)) == 0
    error('sharedutilities:GlossaryTerm', 'Supply one nonempty glossary term.');
end
term = strtrim(term);
% Source is an alternative name for the existing Data source entry.
if strcmpi(term, 'Source')
    term = "Data source";
end
entries = farmGlossaryEntries(varargin{:});
rows = find(entries.Term == term);
if isempty(rows)
    rows = find(strcmpi(entries.Term, term));
end
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

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMGETGLOSSARYENTRY Return one farmGlossary entry as a scalar struct of strings.
% Prefer exact spelling; otherwise allow an unambiguous case-insensitive match.
% Source is an alternative lookup name for Data source; no duplicate entry is added.
% Optional Section accepts one name or a string vector; default is all sections.
