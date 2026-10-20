function results = runConfigBuilderTests

%RUNCONFIGBUILDERTESTS Configuration/consumer tests; no O: datasets required.
farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this file.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', false);

folder = fileparts(mfilename('fullpath')); addpath(folder);
results = runtests(fullfile(folder,'testConfigBuilders.m'));
if any([results.Failed])||any([results.Incomplete])
    error('memoworkflow:TestsFailed','Configuration builder tests failed.');
end
end
