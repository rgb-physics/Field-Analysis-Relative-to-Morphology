function results=runWorkflowExampleTests
%RUNWORKFLOWEXAMPLETESTS Synthetic tests only; no O: data is modified/read.
folder=fileparts(mfilename('fullpath')); addpath(folder);
results=runtests(fullfile(folder,'testWorkflowExamples.m'));
if any([results.Failed])||any([results.Incomplete]), error('memoworkflow:TestsFailed','Example tests failed.'); end
end
