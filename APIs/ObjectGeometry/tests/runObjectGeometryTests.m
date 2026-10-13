function results=runObjectGeometryTests
%RUNOBJECTGEOMETRYTESTS Run focused synthetic tests for the implemented API.
% Skeleton derivative dependency and scientific real-data validation remain
% separate from this suite. Existing sheet/prototype helpers are not claimed
% to be fully covered. Failure produces a nonzero MATLAB batch exit status.
folder=fileparts(mfilename('fullpath')); addpath(folder);
logPath=fullfile(tempdir,'ObjectGeometryTestDiagnostics.log');
diary(logPath); cleanup=onCleanup(@() diary('off'));
suite=matlab.unittest.TestSuite.fromFile(fullfile(folder,'testObjectGeometry.m'));
runner=matlab.unittest.TestRunner.withTextOutput('OutputDetail',matlab.unittest.Verbosity.Detailed);
results=runner.run(suite);
fprintf('\nObjectGeometry: %d passed, %d failed, %d incomplete.\n', ...
    nnz([results.Passed]),nnz([results.Failed]),nnz([results.Incomplete]));
fprintf('Diagnostics: %s\n',logPath);
clear cleanup
if any([results.Failed])||any([results.Incomplete])
    error('objectgeometry:TestSuiteFailed','ObjectGeometry tests failed or were incomplete.');
end
end
