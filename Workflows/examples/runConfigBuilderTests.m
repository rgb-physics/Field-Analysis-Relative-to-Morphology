function results=runConfigBuilderTests
%RUNCONFIGBUILDERTESTS Configuration/consumer tests; no O: datasets required.
folder=fileparts(mfilename('fullpath')); addpath(folder);
results=runtests(fullfile(folder,'testConfigBuilders.m'));
if any([results.Failed])||any([results.Incomplete])
    error('memoworkflow:TestsFailed','Configuration builder tests failed.');
end
end
