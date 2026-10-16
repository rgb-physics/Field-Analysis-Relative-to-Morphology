function [outXs, outYs] = farmFilBackBones2D(CoMs, MajAxes, Oris)
%FARMFILBACKBONES2D Take in filament centroids, orientations, and major axes;
% Inputs:
%   CoMs            Filament center coordinates, with one filament per column.
%   MajAxes         Filament major-axis lengths.
%   Oris            Filament orientations in radians.
% Outputs:
%   outXs           X coordinates of the idealized filament backbones.
%   outYs           Y coordinates of those backbones.

outXs = MajAxes / 2 .* [cos(Oris); -cos(Oris)] + CoMs(1, :);
outYs = MajAxes / 2 .* [-sin(Oris); sin(Oris)] + CoMs(2, :);

end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMFILBACKBONES2D Take in filament centroids, orientations, and major axes;
% Returns an array or x and y coordinates to plot cooresponding to lines
% centered at centroids with length of the major axes pointing along
% orientations.
% Oris must be in radians, CoMs is two rows: top for x, bot for y
% 2025-04-15 - Rémi Boros
