function [] = readObj_remi(fileString)
%READOBJ Takes in the full directory + file name of a .obj file type.
%Returns a struct with all relevant quantities in unique fields taken from
%the first string in each line of the .obj
%Rémi Boros - 2024-10-29

% Open a DI3D OBJ textfile
fid=fopen(fileString,'r');
file_text=fread(fid, inf, 'uint8=>char')';
fclose(fid);
file_lines = regexp(file_text, '\n+', 'split');
file_words = regexp(file_lines, '\s+', 'split');
num_lines = numel(file_lines);

% Get unique fields from starts of each line in .obj
file_starts = cell(num_lines,1);
for index = 1:num_lines
    file_starts(index) = file_words{index}(1);
end
field_names = unique(file_starts);

% Generate struct; store fields in appropriate fields
outStruct = struct();

for fieldInd = 1:numel(field_names)

    currField = field_names{fieldInd};
    if ~isempty(currField)
        field_lines = ismember(file_starts,field_names{fieldInd});

    end

end
% for index = 1:num_lines
    
% end


end

