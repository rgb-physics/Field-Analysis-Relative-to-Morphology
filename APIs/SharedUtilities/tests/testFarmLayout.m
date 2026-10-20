function tests = testFarmLayout
%TESTFARMLAYOUT Check ordinary-folder lookup and migrated interfaces.
root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(root);
farmSetup('IncludeTests', true);
tests = functiontests(localfunctions);
end

function testOrdinarySourceFolders(t)
info = farmSetup();
apis = dir(fullfile(info.Root, 'APIs'));
allNames = strings(0, 1);
for k = 1:numel(apis)
    source = fullfile(apis(k).folder, apis(k).name, 'src');
    if ~apis(k).isdir || ~isfolder(source), continue; end
    files = dir(fullfile(source, '**', '*.m'));
    for j = 1:numel(files)
        parts = split(string(fullfile(files(j).folder, files(j).name)), filesep);
        verifyFalse(t, any(startsWith(parts, '+')));
        verifyTrue(t, startsWith(files(j).name, 'farm'));
    end
    allNames = [allNames; string({files.name}.')]; %#ok<AGROW>
end
verifyEqual(t, numel(unique(lower(allNames))), numel(allNames));
end

function testPublicFunctionLookup(t)
info = farmSetup('IncludeExamples', true);
names = {'farmReadTiff', 'farmReadH5', 'farmMakeSource', 'farmMakeExperiment', ...
    'farmMakeClasses', 'farmMeasureObjects', 'farmMeasureFilaments', ...
    'farmQueryFrame', 'farmPowerSpectrum2D', 'farmGlossary', ...
    'farmWorkflow1Objects', 'farmWorkflow2Filaments'};
for k = 1:numel(names)
    location = which(names{k});
    verifyNotEmpty(t, location, names{k});
    verifyTrue(t, startsWith(location, [info.Root filesep], 'IgnoreCase', true));
end
end

function testSharedDataStaysOffSearchPath(t)
info = farmSetup('IncludeTests', true);
verifyEqual(t, farmTestDataRoot(), fullfile(info.Root, 'tests', 'data'));
entries = string(strsplit(path, pathsep));
dataRoot = string(fullfile(info.Root, 'tests', 'data'));
verifyFalse(t, any(strcmpi(entries, dataRoot) | ...
    startsWith(entries, dataRoot + filesep, 'IgnoreCase', true)));
verifyTrue(t, isfolder(fullfile(info.Root, 'Examples and Workflows', 'examples')));
end

function testConsistentOptionsOrder(t)
defaults = struct('Alpha', 1, 'Beta', 2);
user = struct('Alpha', 3);
expected = struct('Alpha', 3, 'Beta', 2);
verifyEqual(t, farmFAOptions(user, defaults), expected);
verifyEqual(t, farmOGOptions(user, defaults), expected);
verifyEqual(t, farmSUOptions(user, defaults), expected);
verifyEqual(t, farmFAOptions([], defaults), defaults);
verifyEqual(t, farmOGOptions([], defaults), defaults);
verifyEqual(t, farmSUOptions([], defaults), defaults);
verifyError(t, @() farmFAOptions(struct('Typo', 1), defaults), 'fieldanalysis:Options');
verifyError(t, @() farmOGOptions(struct('Typo', 1), defaults), 'objectgeometry:UnknownOption');
verifyError(t, @() farmSUOptions(struct('Typo', 1), defaults), 'sharedutilities:Options');
end

function testHistoricalH5AxisMappingWithoutFixtures(t)
folder = tempname;
mkdir(folder);
cleanup = onCleanup(@() rmdir(folder, 's'));
file = fullfile(folder, 'axes.h5');
raw = reshape(uint16(1:120), [3 4 5 2]);
h5create(file, '/exported_data', size(raw), 'Datatype', 'uint16');
h5write(file, '/exported_data', raw);
image = farmReadH5(file, '/exported_data', ...
    struct('SourceAxes', 'CXYZ', 'Channels', [3 1]));
expected = permute(raw([3 1], :, :, :), [3 2 4 1]);
verifyEqual(t, squeeze(image.Data), expected);
clear cleanup
end
