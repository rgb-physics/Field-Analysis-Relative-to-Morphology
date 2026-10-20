function folder = farmTestDataRoot()

%FARMTESTDATAROOT Return the absolute path to MeMo's shared tests/data folder.

packageFolder = fileparts(mfilename('fullpath'));
testSupportFolder = fileparts(packageFolder);
repositoryRoot = fileparts(testSupportFolder);
folder = fullfile(repositoryRoot, 'tests', 'data');
if ~isfolder(folder)
    error('memotest:MissingDataRoot', ...
        'The repository tests/data folder does not exist: %s', folder);
end
end
