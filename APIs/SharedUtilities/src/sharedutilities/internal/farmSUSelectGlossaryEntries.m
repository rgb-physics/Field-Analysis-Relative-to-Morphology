function [entries, searchIn] = farmSUSelectGlossaryEntries(entries, allowSearchIn, varargin)
%FARMSUSELECTGLOSSARYENTRIES Validate optional section and text-column selections.
defaults = struct('Section', "all");
if allowSearchIn, defaults.SearchIn = "all"; end
options = farmParseOptions(defaults, varargin{:});
sections = textList(options.Section, 'Section');
available = unique(entries.Section, 'stable');
if ~isequal(lower(sections), "all")
    normalized = normalizeSection(sections);
    known = normalizeSection(available);
    if any(~ismember(normalized, known))
        error('sharedutilities:GlossarySection', ...
            'Choose Section from %s, or use "all".', strjoin(available, ', '));
    end
    entries = entries(ismember(normalizeSection(entries.Section), normalized), :);
end
searchIn = string(entries.Properties.VariableNames);
if allowSearchIn
    fields = textList(options.SearchIn, 'SearchIn');
    if ~isequal(lower(fields), "all")
        [found, indices] = ismember(lower(fields), lower(searchIn));
        if any(~found)
            error('sharedutilities:GlossarySearchIn', ...
                'Choose SearchIn from %s, or use "all".', strjoin(searchIn, ', '));
        end
        searchIn = searchIn(indices);
    end
end
end

function values = textList(input, option)
if ~(ischar(input) || isstring(input) || iscellstr(input))
    error('sharedutilities:GlossaryOption', '%s must be text or a text vector.', option);
end
values = strtrim(string(input));
if isempty(values) || ~isvector(values) || any(ismissing(values)) || any(strlength(values) == 0)
    error('sharedutilities:GlossaryOption', 'Supply nonempty text values for %s.', option);
end
values = unique(values(:).', 'stable');
end

function values = normalizeSection(values)
values = lower(regexprep(values, '[\s_-]', ''));
end
