function info = farmSetup(varargin)
%FARMSETUP Add FARM functions to this MATLAB session's search path.
% Inputs:
%   varargin   Name/value pairs: IncludeExamples=false, IncludeTests=false.
% Outputs:
%   info       Struct containing Root, IncludeExamples and IncludeTests.

% Read settings without changing the saved MATLAB path.
p = inputParser;
addParameter(p, 'IncludeExamples', false, @(x) islogical(x) && isscalar(x));
addParameter(p, 'IncludeTests', false, @(x) islogical(x) && isscalar(x));
parse(p, varargin{:});
root = fileparts(mfilename('fullpath'));
folders = {root};
apis = dir(fullfile(root, 'APIs'));
apis = apis([apis.isdir] & ~ismember({apis.name}, {'.', '..'}));

% Add each API's source folders to this session.
for apiInd = 1:numel(apis)
    source = fullfile(apis(apiInd).folder, apis(apiInd).name, 'src');

    if apis(apiInd).isdir && isfolder(source)
        folders{end + 1} = genpath(source);
    end
end

% Add only the explicitly installed local Gaussian derivative dependency.
gaussdiff = fullfile(root, 'local-dependencies', 'GaussDiff');

if isfolder(gaussdiff)
    folders{end + 1} = gaussdiff;
end

if p.Results.IncludeExamples || p.Results.IncludeTests
    folders{end + 1} = genpath(fullfile(root, 'Examples and Workflows', 'examples'));

    for apiInd = 1:numel(apis)
        folder = fullfile(apis(apiInd).folder, apis(apiInd).name, 'examples');

        if apis(apiInd).isdir && isfolder(folder)
            folders{end + 1} = genpath(folder);
        end
    end
end

if p.Results.IncludeTests
    % Keep datasets and saved source snapshots off the MATLAB search path.
    folders{end + 1} = fullfile(root, 'tests');
    folders{end + 1} = genpath(fullfile(root, 'tests', 'memotest'));

    for apiInd = 1:numel(apis)
        folder = fullfile(apis(apiInd).folder, apis(apiInd).name, 'tests');

        if apis(apiInd).isdir && isfolder(folder)
            folders{end + 1} = genpath(folder);
        end
    end

    folder = fullfile(root, 'Examples and Workflows', 'tests');

    if isfolder(folder)
        folders{end + 1} = genpath(folder);
    end
end

% Add folders together, preserving the precedence of successive addpath calls.
folders = folders(~cellfun('isempty', folders));
addpath(folders{end:-1:1});

info = struct('Root', root, 'IncludeExamples', p.Results.IncludeExamples, ...
    'IncludeTests', p.Results.IncludeTests);
end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Paths apply to this MATLAB session only; savepath is not called.
% IncludeTests also adds examples used by the tests. Datasets and archives
% are not added. Path visibility alone does not establish public API support.
%
% EXAMPLES
% -------------------------------------------------------------------------
% farmSetup
% info = farmSetup('IncludeExamples', true, 'IncludeTests', true);
