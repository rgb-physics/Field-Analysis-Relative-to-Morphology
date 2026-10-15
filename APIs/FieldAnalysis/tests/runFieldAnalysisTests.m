function results = runFieldAnalysisTests

%RUNFIELDANALYSISTESTS Synthetic numerical and interface checks.
farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this file.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', true);

folder = fileparts(mfilename('fullpath')); addpath(folder);
repo = fileparts(fileparts(fileparts(folder)));
addpath(fullfile(repo,'APIs','FieldAnalysis','src'));
addpath(fullfile(repo,'APIs','SharedUtilities','src'));
logPath = fullfile(tempdir,'FieldAnalysisTestDiagnostics.log');
diary(logPath); cleanup = onCleanup(@()diary('off'));
suite = matlab.unittest.TestSuite.fromFile(fullfile(folder,'testFieldAnalysis.m'));
runner = matlab.unittest.TestRunner.withTextOutput;
results = runner.run(suite);
fprintf('FieldAnalysis: %d passed, %d failed, %d incomplete.\n', ...
    nnz([results.Passed]),nnz([results.Failed]),nnz([results.Incomplete]));
fprintf('Diagnostics: %s\n',logPath);
clear cleanup
if any([results.Failed])||any([results.Incomplete]), error('fieldanalysis:TestsFailed','FieldAnalysis tests failed.'); end
end
