function c = farmE5SaveMeasurements(c)
%FARME5SAVEMEASUREMENTS Save this frame's measurements and diagnostics to a local run folder.
% Inputs:
%   c   Configuration struct containing the settings and earlier results below.
% Configuration fields read:
%   c.Frame: acquisition frame used in the output filename.
%   c.RunDirectory: existing local output folder created by the accompanying script.
% Earlier results read:
%   c.Results.Properties: completed observation table from farmE5MeasureAlignment.
%   c.Results.SamplingDiagnostics: field-query diagnostics from farmE5SampleFields.
%   c.Results.SegmentationInfo, GradientInfo: calculation metadata from earlier stages.
% Outputs:
%   c   The same configuration, with these results added or updated:
%   c.Results.SavedFrameFile: full path to the new frameNNN.mat file.
%   The MAT variable result contains Filaments, SamplingDiagnostics, SegmentationInfo, and GradientInfo.
%   Dense image/geometry arrays remain in c.Results and are not saved by this stage.
%
% This is an editable E5 teaching example, not a new general package API.
% Settings remain in c; intermediate data is stored in c.Results.

% Configuration and Earlier Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Read the fields used by this stage explicitly.
frame = c.Frame;
runDirectory = c.RunDirectory;
properties = c.Results.Properties;
samplingDiagnostics = c.Results.SamplingDiagnostics;
segmentationInfo = c.Results.SegmentationInfo;
gradientInfo = c.Results.GradientInfo;

% Stage Calculation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
frameFile = fullfile(runDirectory, sprintf('frame%03i.mat', frame));
if isfile(frameFile)
    error('farm:E5StageOutputExists', 'Choose a new run directory; output already exists: %s', frameFile);
end
result = struct('Filaments', properties, 'SamplingDiagnostics', samplingDiagnostics, ...
    'SegmentationInfo', segmentationInfo, 'GradientInfo', gradientInfo);
save(frameFile, 'result', '-v7.3');
fprintf('Frame %g measurements saved to: %s\n', frame, frameFile);

% Retained Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Keep these values available to inspect or pass to later stages.
c.Results.SavedFrameFile = frameFile;
end
