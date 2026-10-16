function [reorganizedArray, linear_grid] = farmArrayOrganizer2D(arr, Dcell)
%FARMARRAYORGANIZER2D Reorganize a 2D array into complete spatial blocks.
% Inputs:
%   arr             Input 2D numeric array.
%   Dcell           Block dimensions in YX array order.
% Outputs:
%   reorganizedArray Values reorganized into spatial blocks.
%   linear_grid     Linear grid positions of the blocks.

[Ny, Nx] = size(arr);
Dy = Dcell(1);
Dx = Dcell(2);

xcell = 1:Dx;
ycell = 1:Dy;
[Xcell, Ycell] = meshgrid(xcell, ycell);
linear_cell = Ycell(:) + Ny * (Xcell(:) - 1);

xgrid = 1:floor(Nx / Dx);
ygrid = 1:floor(Ny / Dy);
[Xgrid, Ygrid] = meshgrid(xgrid, ygrid);
linear_grid = Dy * (Ygrid(:) - 1) + Ny * Dx * (Xgrid(:) - 1) + 1;

[Lc, Lg] = meshgrid(linear_cell, linear_grid);
reorganizedIndex = Lg + Lc - 1;
reorganizedArray = reshape(arr(reorganizedIndex(:)), size(reorganizedIndex));

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
