% Combine Session 88 measurements without changing source experiment files.
sourceRoot = 'O:\Session 88\FARM Output';
outputFile = fullfile(sourceRoot, 'session88-combined.mat');
assert(~isfile(outputFile), 'Output already exists: %s', outputFile);
folders = dir(fullfile(sourceRoot, 'Exp*'));
folders = folders([folders.isdir]);
[~, order] = sort({folders.name});
folders = folders(order);
assert(numel(folders) == 5, 'Expected five experiment folders.');
tables = cell(numel(folders), 1);
Experiments = struct([]);
for k = 1:numel(folders)
    sourceFile = fullfile(sourceRoot, folders(k).name, 'workflow2-output.mat');
    loaded = load(sourceFile, 'result');
    r = loaded.result;
    t = r.Filaments;
    assert(istable(t), 'Filaments must be a table.');
    assert(all(ismember({'DatasetID','Frame','ObjectID'}, t.Properties.VariableNames)));
    if k > 1
        assert(isequal(t.Properties.VariableNames, tables{1}.Properties.VariableNames), ...
            'Measurement columns differ between experiments.');
        assert(isequal(t.Properties.VariableUnits, tables{1}.Properties.VariableUnits), ...
            'Measurement units differ between experiments.');
        assert(isequal(r.SpacingUnit, Experiments(1).Metadata.SpacingUnit));
    end
    tables{k} = t;
    Experiments(k).Name = folders(k).name;
    Experiments(k).SourceFile = sourceFile;
    Experiments(k).RowCount = height(t);
    Experiments(k).DatasetIDs = unique(string(t.DatasetID));
    Experiments(k).TableMetadata = t.Properties;
    Experiments(k).Metadata = rmfield(r, 'Filaments');
    fprintf('%s: %d measurements, %d measured frames\n', folders(k).name, height(t), numel(unique(t.Frame)));
end
allIDs = vertcat(Experiments.DatasetIDs);
assert(numel(unique(allIDs)) == numel(allIDs), 'Dataset IDs overlap across experiments.');
Filaments = vertcat(tables{:});
clear tables loaded r t;
keys = Filaments(:, {'DatasetID','Frame','ObjectID'});
assert(height(unique(keys, 'rows')) == height(Filaments), 'Duplicate object identities.');
clear keys;
assert(height(Filaments) == sum([Experiments.RowCount]));
SourceRoot = sourceRoot;
CreatedAt = datetime('now', 'TimeZone', 'UTC');
save(outputFile, 'Filaments', 'Experiments', 'SourceRoot', 'CreatedAt', '-v7.3');
savedData = load(outputFile, 'Filaments');
assert(height(savedData.Filaments) == sum([Experiments.RowCount]));
fprintf('SAVED %s\nTOTAL %d rows, %d experiments\n', outputFile, height(Filaments), numel(Experiments));
