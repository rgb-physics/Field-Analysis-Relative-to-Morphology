function [rp3D, rp2D] = farmStoreFilCCs(bwObjs)
%FARMSTOREFILCCS Historical 3-D filament table and per-slice 2-D structures.
% Inputs:
%   bwObjs          Binary filament-object volume.
% Outputs:
%   rp3D            3D filament measurements.
%   rp2D            Per-slice 2D property structures.

req = {'Centroid', 'Volume', 'PrincipalAxisLength', 'EigenVectors', 'Directors', 'ExtentInVoxels', 'AspectRatios'};
rp3D = farmMeasureFilaments(bwObjs, req);
rp3D = removevars(rp3D, {'DatasetID', 'Frame', 'ObjectID'});
fields = {'Centroid', 'Area', 'MinorAxisLength', 'MajorAxisLength', 'Orientation'};
rp2D = struct('Centroid', {}, 'Area', {}, 'MinorAxisLength', {}, 'MajorAxisLength', {}, 'Orientation', {}, 'Slice_Index', {});
for z = 1:size(bwObjs, 3)
    current = regionprops(logical(bwObjs(:, :, z)), fields);
    for i = 1:numel(current)
        current(i).Slice_Index = z;
    end
    if ~isempty(current)
        rp2D = [rp2D; current(:)];
    end %#ok<AGROW>
end
end

% -------------------------------------------------------------------------
% BEHAVIOR
% -------------------------------------------------------------------------
% FARMSTOREFILCCS Historical 3-D filament table and per-slice 2-D structures.
% Empty masks return typed empty outputs; no SharedUtilities path needed.
