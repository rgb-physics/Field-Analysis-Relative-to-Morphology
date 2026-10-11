function results = runSegmentationToolsTests
%RUNSEGMENTATIONTOOLSTESTS Run all non-active-contour API tests.
%   RESULTS = RUNSEGMENTATIONTOOLSTESTS adds the required source folders,
%   runs testSegmentationTools.m with detailed output, and returns the
%   matlab.unittest.TestResult array. A failed test raises an error after
%   the complete suite has run so batch/CI execution receives a failure.

testsDirectory = fileparts(mfilename('fullpath'));
repositoryRoot = fullfile(testsDirectory, '..', '..', '..');
addpath(testsDirectory);
addpath(fullfile(repositoryRoot,'APIs','SegmentationTools','src'));
addpath(fullfile(repositoryRoot,'APIs','ImageStackIO','src'));
addpath(fullfile(repositoryRoot,'APIs','SharedUtilities','src'));

import matlab.unittest.TestRunner
import matlab.unittest.TestSuite

suite = TestSuite.fromFile(fullfile(testsDirectory,'testSegmentationTools.m'));
runner = TestRunner.withTextOutput('OutputDetail', ...
    matlab.unittest.Verbosity.Detailed);
diagnosticPath = fullfile(testsDirectory,'SegmentationToolsTestDiagnostics.log');
if isfile(diagnosticPath)
    delete(diagnosticPath);
end
diary(diagnosticPath);
diaryCleanup = onCleanup(@() diary('off'));
results = runner.run(suite);

fprintf('\nSegmentationTools: %d passed, %d failed, %d incomplete.\n', ...
    nnz([results.Passed]),nnz([results.Failed]),nnz([results.Incomplete]));
fprintf('Failure diagnostics: %s\n',diagnosticPath);
diary('off');
clear diaryCleanup
if any([results.Failed]) || any([results.Incomplete])
    error('segmentationtools:TestSuiteFailed', ...
        'One or more SegmentationTools tests failed or were incomplete.');
end
end
