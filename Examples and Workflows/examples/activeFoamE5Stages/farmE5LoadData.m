function c = farmE5LoadData(c)
%FARME5LOADDATA Load the intensity and probabilities for one acquisition frame.
% Inputs:
%   c   Configuration struct containing the settings and earlier results below.
% Configuration fields read:
%   c.Experiment: named Intensity647 and Probabilities sources, with paths and metadata.
%   c.Frame: acquisition frame to load; set it to a member of c.Frames.
% Earlier results read:
%   None. Loading clears c.Results from the preceding frame.
% Outputs:
%   c   The same configuration, with these results added or updated:
%   c.Results.IntensityImage, ProbabilityImage: loaded images with metadata.
%   c.Results.Raw, Probabilities: YXZ intensity and YXZC probability arrays.
%   c.Results.TargetSize: image dimensions in YXZ order.
%   c.Results.InputFiles: frame/source/path table.
%   c.Results.MissingInput: true if either source file is missing; no arrays loaded.
%
% This is an editable E5 teaching example, not a new general package API.
% Settings remain in c; intermediate data is stored in c.Results.

% Configuration and Earlier Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read the fields used by this stage explicitly.
frame = c.Frame;
sources = c.Experiment.Sources;

% Stage Calculation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Start a new frame without retaining stale results from an earlier frame.
c.Results = struct('MissingInput', false);
intensityFile = fullfile(sources.Intensity647.Folder, sprintf(sources.Intensity647.NamePattern, frame));
probabilityFile = fullfile(sources.Probabilities.Folder, sprintf(sources.Probabilities.NamePattern, frame));
if ~isfile(intensityFile) || ~isfile(probabilityFile)
    c.Results.MissingInput = true;
    fprintf(2, 'Skipping frame %g. Missing inputs:\n', frame);
    if ~isfile(intensityFile)
        fprintf(2, '%s\n', intensityFile);
    end
    if ~isfile(probabilityFile)
        fprintf(2, '%s\n', probabilityFile);
    end
    return
end
intensityImage = farmLoadSource(c.Experiment, 'Intensity647', frame);
probabilityImage = farmLoadSource(c.Experiment, 'Probabilities', frame);
raw = intensityImage.Data(:, :, :, 1, 1);
probabilities = probabilityImage.Data(:, :, :, :, 1);
targetSize = [size(raw, 1) size(raw, 2) size(raw, 3)];
inputFiles = cell2table({frame, 'Intensity647', intensityFile; frame, 'Probabilities', probabilityFile}, ...
    'VariableNames', {'Frame', 'Source', 'Path'});
fprintf('Frame %g loaded: image %s, probabilities %s.\n', frame, mat2str(targetSize), mat2str(size(probabilities)));

% Retained Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Keep these values available to inspect or pass to later stages.
c.Results.IntensityImage = intensityImage;
c.Results.ProbabilityImage = probabilityImage;
c.Results.Raw = raw;
c.Results.Probabilities = probabilities;
c.Results.TargetSize = targetSize;
c.Results.InputFiles = inputFiles;
end
