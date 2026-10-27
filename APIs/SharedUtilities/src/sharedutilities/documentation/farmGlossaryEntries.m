function entries = farmGlossaryEntries(varargin)
%FARMGLOSSARYENTRIES Read every defined entry from the repository's written farmGlossary.
% Inputs:
%   varargin        Optional Section filter as name/value pairs.
% Outputs:
%   entries         Table of glossary and Data Dictionary entries in source order.

folder = fileparts(mfilename('fullpath'));
source = fullfile(folder, '..', '..', '..', '..', '..', 'GLOSSARY-CAPABILITIES.md');
if ~isfile(source)
    error('sharedutilities:GlossarySource', 'Written glossary not found: %s', source);
end
lines = regexp(fileread(source), '\r\n|\n|\r', 'split');
prototype = struct('Term', "", 'Section', "", 'Group', "", 'DataType', "", ...
                   'Definition', "", 'Inputs', "Inputs: {''}", 'Notes', "");
records = repmat(prototype, 0, 1);
section = "";
group = "";
current = 0;
definitionComplete = false;

for k = 1:numel(lines)
    line = strtrim(lines{k});
    if startsWith(line, '### ')
        group = string(strtrim(line(5:end)));
        current = 0;
        continue
    elseif startsWith(line, '## ')
        section = erase(string(strtrim(line(4:end))), ' ');
        group = "";
        current = 0;
        continue
    end
    heading = regexp(line, '^\*\*(.+?)\*\*\s+\[(.*)\]\s*$', 'tokens', 'once');
    if ~isempty(heading)
        records(end + 1, 1) = prototype; %#ok<AGROW>
        current = numel(records);
        records(current).Term = string(heading{1});
        records(current).Section = section;
        records(current).Group = group;
        records(current).DataType = string(heading{2});
        definitionComplete = false;
        continue
    end
    if current == 0
        continue
    end
    if isempty(line)
        if strlength(records(current).Definition) > 0
            definitionComplete = true;
        end
        continue
    end
    line = cleanMarkup(line);
    if startsWith(line, 'Inputs:')
        records(current).Inputs = line;
        definitionComplete = true;
    elseif ~definitionComplete
        separator = " ";
        if startsWith(line, '[')
            separator = string(newline);
        end
        records(current).Definition = joinText(records(current).Definition, line, separator);
    else
        records(current).Notes = joinText(records(current).Notes, line, " ");
    end
end
if isempty(records)
    error('sharedutilities:GlossarySource', 'No glossary entries were recognized in %s.', source);
end
entries = struct2table(records);
if height(unique(entries(:, {'Section', 'Term'}))) ~= height(entries) || any(strlength(entries.Definition) == 0)
    error('sharedutilities:GlossarySource', 'The glossary has duplicate exact terms within a section or missing definitions.');
end
entries = farmSUSelectGlossaryEntries(entries, false, varargin{:});
end

function text = cleanMarkup(text)
% Internal helper.
text = string(strrep(strrep(text, '\*', '*'), '`', ''));
end

function text = joinText(previous, next, separator)
% Internal helper.
if strlength(previous) == 0
    text = next;
else
    text = previous + separator + next;
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMGLOSSARYENTRIES Read every defined entry from the repository's written farmGlossary.
% Returns string columns Term, Section, Group, DataType, Definition, Inputs, Notes.
% Section defaults to "all"; optionally select "Glossary", "DataDictionary",
% or a string vector of sections. Group is the topical heading within a section.
% No cached copy: edits to the document appear on the next call. Source order
% and capitalization are preserved, including separate workflow-variable entries.
% A missing input layout is represented by exactly "Inputs: {''}".
