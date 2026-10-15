function results = runSharedUtilitiesTests

%RUNSHAREDUTILITIESTESTS Helpers plus affected API regression suites.
farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this file.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', true);

folder = fileparts(mfilename('fullpath')); repo = fileparts(fileparts(fileparts(folder)));
addpath(folder);
for api = {'SharedUtilities','ObjectGeometry','ObjectRelativeProfiles','ObjectTracking','FieldAnalysis','ImageStackIO','SegmentationTools','VisualizationTools'}
    addpath(fullfile(repo,'APIs',api{1},'src'));
end
files = {fullfile(folder,'testSharedUtilities.m'),fullfile(folder,'testCanonicalUtilities.m'), ...
    fullfile(folder,'testFarmLayout.m'), ...
    fullfile(repo,'APIs','ObjectGeometry','tests','testObjectGeometry.m'), ...
    fullfile(repo,'APIs','ObjectRelativeProfiles','tests','testFieldSampling.m'), ...
    fullfile(repo,'APIs','ObjectRelativeProfiles','tests','testVectorFieldSampling.m'), ...
    fullfile(repo,'APIs','ObjectTracking','tests','testObjectTracking.m'), ...
    fullfile(repo,'APIs','FieldAnalysis','tests','testFieldAnalysis.m')};
suite = matlab.unittest.TestSuite.fromFile(files{1});
for k = 2:numel(files), suite = [suite,matlab.unittest.TestSuite.fromFile(files{k})]; end %#ok<AGROW>
logPath = fullfile(tempdir,'SharedUtilitiesTestDiagnostics.log');
diary(logPath); cleanup = onCleanup(@()diary('off'));
runner = matlab.unittest.TestRunner.withTextOutput; results = runner.run(suite);
fprintf('SharedUtilities and API regressions: %d passed, %d failed, %d incomplete.\n', ...
    nnz([results.Passed]),nnz([results.Failed]),nnz([results.Incomplete]));
fprintf('Diagnostics: %s\n',logPath);
clear cleanup
if any([results.Failed])||any([results.Incomplete]), error('sharedutilities:TestsFailed','Utility/regression tests failed.'); end
end
