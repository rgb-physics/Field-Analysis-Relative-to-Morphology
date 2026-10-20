%% ACTIVE FOAM E5 -- workflow 2 output passed explicitly to alignment plotting
% Everything under O:\Session 88 is READ ONLY. Outputs are under package tests/data.
% Running the whole script processes real frames 25:30 in a fresh run.
% To reuse already processed data, set savedWorkflow2File to workflow2-output.mat.

%% DEFINITIONS AND INPUTS -- edit the configuration function to change choices
repo = 'C:\Users\Remi Boros\OneDrive\Documents\ChatGPT\MATLAB - Split Repos\MeMo';
addpath(repo);
farmSetup('IncludeExamples', true);
c = farmActiveFoamE5Config;

% Confirmed: image spacing [.55 .55 .7] um YXZ; probabilities [1.5 1.5 1.5] um.
% [inside,on/wall,outside] = channels [3,2,1]. No corrected 560 TIFF is needed.
% Acquisition spacing is 30 s/frame. Frame 25 is the plotted elapsed-time origin:
% t = (Frame - 25)*30 s, giving [0,30,60,90,120,150] s. Absolute start is unknown.
% A = Order3D = (3*cos(theta)^2 - 1)/2; isotropic mean 0, parallel 1.
% r = workflow2.Filaments.BoundaryDistance (um), negative inside, positive outside.
% Retain the computational boundary at r=0; do not shift it onto a measured peak.
savedWorkflow2File = '';

%% PROCESS OR LOAD WORKFLOW 2 -- independent of plotting
if isempty(savedWorkflow2File)
    workflow2 = farmProcessActiveFoamE5(c);
else
    saved = load(savedWorkflow2File, 'result');
    workflow2 = saved.result;
    workflow2.OriginalDirectory = workflow2.Directory;
    workflow2.Directory = fileparts(savedWorkflow2File);
end

%% EXPLICIT HANDOFF -- workflow 2 output is the plotting workflow's input
% No source images are read by this plotting call. Inputs come from Filaments.
plotOptions = c.AlignmentPlot;
plotOptions.OutputDirectory = fullfile(workflow2.Directory, 'alignment-plots');
alignmentReport = farmPlotActiveFoamAlignment(workflow2, plotOptions);

% Inspect tables without rerunning images:
% alignmentReport.Binned, MovingPeak, FixedPeak, Bands, QualityCounts.
% Figures show rod-weighted means and rod standard deviation, NOT confidence intervals.
% Plotting refuses to overwrite an existing output directory: choose a new one.
