function report = farmInstallGaussdiff(sourceFolder)
%FARMINSTALLGAUSSDIFF Check and install a local copy of Gaussian derivative code.
% Inputs:
%   sourceFolder   Folder containing gfilter.m and gaussiankernel.m from
%                  gaussdiff. Omit to check an existing local installation.
% Outputs:
%   report         Installation folder, copied filenames and check status.
%
% See also farmSetup, farmSkel3DBlobs

if nargin < 1
    sourceFolder = '';
end

root = fileparts(mfilename('fullpath'));
destination = fullfile(root, 'local-dependencies', 'GaussDiff');
files = {'gfilter.m', 'gaussiankernel.m'};
sourceFolder = string(sourceFolder);

if ~isscalar(sourceFolder) || ismissing(sourceFolder)
    error('farm:GaussdiffFolder', 'Provide one folder containing the gaussdiff files.');
end

if strlength(sourceFolder) == 0
    sourceFolder = string(destination);
end

sourceFolder = char(sourceFolder);

% Check every required file before creating or changing the local folder.
fprintf('Checking gaussdiff in: %s\n', sourceFolder);

for fileInd = 1:numel(files)
    source = fullfile(sourceFolder, files{fileInd});

    if ~isfile(source)
        error('farm:MissingGaussdiff', ...
            ['Missing %s. Obtain gaussdiff (MathWorks File Exchange 19696), ' ...
             'then call farmInstallGaussdiff with its extracted folder.'], source);
    end
end

% Check the supplied functions on small known inputs using a temporary path.
% Restore the original path if a check fails; do not save global path changes.
oldPath = path;
restorePath = onCleanup(@() path(oldPath));
addpath(sourceFolder, '-begin');
clear gfilter gaussiankernel

fprintf('Checking smoothing and first derivatives on a constant 3D field.\n');
input = ones(9, 9, 9);
smooth = gfilter(input, 1, [0 0 0]);
derivative = gfilter(input, 1, [0 1 0]);

if ~isequal(size(smooth), size(input)) || ~isequal(size(derivative), size(input)) ...
        || any(~isfinite(smooth(:))) || any(~isfinite(derivative(:))) ...
        || any(abs(smooth(:) - 1) > 1e-10) || any(abs(derivative(:)) > 1e-10)
    error('farm:GaussdiffCheck', ...
        'The supplied gaussdiff failed its basic checks. Existing local files were not changed.');
end

% Refuse to replace different files. Resolve version changes explicitly.
for fileInd = 1:numel(files)
    installed = fullfile(destination, files{fileInd});
    source = fullfile(sourceFolder, files{fileInd});

    if isfile(installed) && ~strcmp(fileread(installed), fileread(source))
        error('farm:GaussdiffExists', ...
            'A different %s already exists. Review the two versions before replacing it.', installed);
    end
end

if ~isfolder(destination)
    mkdir(destination);
end

fprintf('Installing unchanged source files into: %s\n', destination);

for fileInd = 1:numel(files)
    installed = fullfile(destination, files{fileInd});

    if ~isfile(installed)
        copyfile(fullfile(sourceFolder, files{fileInd}), installed);
    end
end

% Retain license files if the extracted provider folder includes them.
notices = [dir(fullfile(sourceFolder, 'LICENSE*')); ...
    dir(fullfile(sourceFolder, 'COPYING*'))];

for fileInd = 1:numel(notices)
    if notices(fileInd).isdir
        continue
    end

    installed = fullfile(destination, notices(fileInd).name);

    if ~isfile(installed)
        copyfile(fullfile(notices(fileInd).folder, notices(fileInd).name), installed);
    end
end

clear restorePath
clear gfilter gaussiankernel
addpath(destination, '-begin');

report = struct('Folder', destination, 'Files', {files}, 'Passed', true);
fprintf('gaussdiff is ready for this session. farmSetup adds this local copy in later sessions.\n');
fprintf('No global paths were saved. Third-party source remains local to this checkout.\n');
end


% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% Uses a caller-supplied extracted gaussdiff folder; no network download,
% account changes, add-on installation or source rewriting occurs. Copies only
% gfilter.m, gaussiankernel.m and supplied LICENSE/COPYING files. Different
% existing source files are never overwritten. The basic constant-field test
% checks availability and simple behavior, not full scientific correctness.
%
% EXAMPLES
% -------------------------------------------------------------------------
% report = farmInstallGaussdiff('C:/downloads/gaussdiff');
% report = farmInstallGaussdiff; % check an existing project-local installation
