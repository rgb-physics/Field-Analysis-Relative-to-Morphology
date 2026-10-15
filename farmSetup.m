function info = farmSetup(varargin)
%FARMSETUP Add FARM functions to this MATLAB session's search path.
%   farmSetup adds reusable API functions. Examples and tests are optional:
%   farmSetup('IncludeExamples', true, 'IncludeTests', true)
%   No paths are saved permanently, and no datasets or archives are added.
p = inputParser;
addParameter(p, 'IncludeExamples', false, @(x) islogical(x) && isscalar(x));
addParameter(p, 'IncludeTests', false, @(x) islogical(x) && isscalar(x));
parse(p, varargin{:});
root = fileparts(mfilename('fullpath'));
addpath(root);
apis = dir(fullfile(root, 'APIs'));
for k = 1:numel(apis)
    source = fullfile(apis(k).folder, apis(k).name, 'src');
    if apis(k).isdir && isfolder(source), addpath(genpath(source)); end
end
addpath(genpath(fullfile(root, 'Workflows', 'src')));
if p.Results.IncludeExamples || p.Results.IncludeTests
    addpath(genpath(fullfile(root, 'Workflows', 'examples')));
    for k = 1:numel(apis)
        folder = fullfile(apis(k).folder, apis(k).name, 'examples');
        if apis(k).isdir && isfolder(folder), addpath(genpath(folder)); end
    end
end
if p.Results.IncludeTests
    addpath(genpath(fullfile(root, 'tests')));
    for k = 1:numel(apis)
        folder = fullfile(apis(k).folder, apis(k).name, 'tests');
        if apis(k).isdir && isfolder(folder), addpath(genpath(folder)); end
    end
    folder = fullfile(root, 'Workflows', 'tests');
    if isfolder(folder), addpath(genpath(folder)); end
end
info = struct('Root', root, 'IncludeExamples', p.Results.IncludeExamples, ...
    'IncludeTests', p.Results.IncludeTests);
end
