function results = runFieldSamplingTests

%RUNFIELDSAMPLINGTESTS Focused interface checks, not scientific validation.
farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this file.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', true);

folder = fileparts(mfilename('fullpath')); addpath(folder);
suite = [matlab.unittest.TestSuite.fromFile(fullfile(folder,'testFieldSampling.m')), ...
    matlab.unittest.TestSuite.fromFile(fullfile(folder,'testVectorFieldSampling.m'))];
runner = matlab.unittest.TestRunner.withTextOutput;
results = runner.run(suite);
fprintf('Field sampling: %d passed, %d failed, %d incomplete.\n', ...
    nnz([results.Passed]),nnz([results.Failed]),nnz([results.Incomplete]));
if any([results.Failed])||any([results.Incomplete])
    error('objectrelativeprofiles:TestsFailed','Field sampling interface tests failed.');
end
end
