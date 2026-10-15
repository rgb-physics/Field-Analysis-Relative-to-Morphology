function manifest = farmWorkflow1Objects(c)

%FARMWORKFLOW1OBJECTS Compatibility entry for setupWorkflow1's local workflow.
% Editable setup and implementation now live together in setupWorkflow1.m.
farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this file.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', false);

if nargin<1, c = farmExperiment4Config; end
workflowInput = c; % script dispatch skips manual setup/preview
run(fullfile(fileparts(mfilename('fullpath')),'setupWorkflow1.m'));
manifest = result;
end
