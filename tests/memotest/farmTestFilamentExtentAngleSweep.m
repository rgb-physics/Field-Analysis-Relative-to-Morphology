function report = farmTestFilamentExtentAngleSweep(zSpacing,expectedLengthUm)

%FARMTESTFILAMENTEXTENTANGLESWEEP Known physical centerlines sampled onto voxel grids.
% Synthetic ground truth comes from endpoints/directions, not another PCA.
% Fixed XY spacing=1 um; supplied Z spacing; optional length=40 um; elevations 0:15:90
% from XY; azimuths 0/45/90 in XY. Thin digital lines remain 26-connected.
validateattributes(zSpacing,{'numeric'},{'scalar','real','finite','positive'});
if nargin<2, expectedLengthUm = 40; end
validateattributes(expectedLengthUm,{'numeric'},{'scalar','real','finite','positive'});
spacing = [1 1 zSpacing]; xyzSpacing = spacing([2 1 3]); expected = expectedLengthUm;
elevations = 0:15:90; azimuths = [0 45 90]; count = numel(elevations)*numel(azimuths);
elevation = zeros(count,1); azimuth = elevation; projected = elevation; native = elevation;
endpointSpan = elevation; angleError = elevation; voxelCount = elevation; objectCount = elevation;
row = 0;
for phi = azimuths
    for theta = elevations
        row = row+1;
        direction = [cosd(theta)*cosd(phi),cosd(theta)*sind(phi),sind(theta)];
        % Dense continuous centerline, then nearest-voxel sampling. Rounding
        % may shift each location by at most half the voxel diagonal.
        steps = ceil(4*expected/min(spacing));
        positions = 4+(linspace(0,expected,steps+1).'*direction)./xyzSpacing;
        positions = unique(round(positions),'rows');
        sz = max(positions,[],1)+3; sz = sz([2 1 3]);
        mask = false(sz);
        indices = sub2ind(sz,positions(:,2),positions(:,1),positions(:,3));
        mask(indices) = true;
        identity = struct('Spacing',spacing,'SpacingUnit','um','Connectivity',26);
        objects = farmPrepareObjects(mask,identity);
        props = farmMeasureFilaments(objects, ...
            {'ExtentInVoxels','ProjectedExtent','ScaledDirectors'});
        objectCount(row) = height(props);
        if height(props)~=1, error('memotest:DisconnectedLine','Synthetic filament did not form one component.'); end
        elevation(row) = theta; azimuth(row) = phi;
        projected(row) = props.ProjectedExtent; native(row) = props.ExtentInVoxels;
        % Endpoint-only reference uses the specified direction, not fitted axes.
        start = round(4+[0 0 0]);
        finish = round(4+expected*direction./xyzSpacing);
        endpointSpan(row) = norm((finish-start).*xyzSpacing);
        dotValue = abs(dot(props.ScaledDirectors,direction));
        angleError(row) = acosd(min(1,max(0,dotValue)));
        voxelCount(row) = nnz(mask);
    end
end
expectedLength = repmat(expected,count,1);
error = projected-expectedLength;
% Conservative discretization allowances, not estimates of measurement accuracy.
lengthTolerance = repmat(2*norm(spacing),count,1);
angleTolerance = repmat(asind(min(1,2*norm(spacing)/expected)),count,1);
report = table(repmat(1,count,1),repmat(zSpacing,count,1),elevation,azimuth, ...
    expectedLength,endpointSpan,projected,error,100*error/expected,native, ...
    angleError,voxelCount,objectCount,lengthTolerance,angleTolerance, ...
    'VariableNames',{'XYSpacingUm','ZSpacingUm','ElevationDegrees','AzimuthDegrees', ...
    'ExpectedLengthUm','RoundedEndpointSpanUm','ProjectedExtentUm','ErrorUm', ...
    'ErrorPercent','ExtentInVoxels','DirectorErrorDegrees','VoxelCount', ...
    'ComponentCount','LengthToleranceUm','DirectorToleranceDegrees'});
end
