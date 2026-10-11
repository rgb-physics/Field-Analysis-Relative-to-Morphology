function folder = dataRoot()
%DATAROOT Return the absolute path to MeMo's shared test-data folder.

packageFolder = fileparts(mfilename('fullpath'));
testSupportFolder = fileparts(packageFolder);
repositoryRoot = fileparts(testSupportFolder);
folder = fullfile(repositoryRoot, 'test-data');
if ~isfolder(folder)
    error('memotest:MissingDataRoot', ...
        'The repository test-data folder does not exist: %s', folder);
end
end
