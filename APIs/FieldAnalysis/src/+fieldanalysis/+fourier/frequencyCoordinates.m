function axes=frequencyCoordinates(gridSize,spacing)
%FREQUENCYCOORDINATES Shifted FFT axes, Y X [Z], cycles per spacing unit.
if nargin<2, spacing=ones(size(gridSize)); end
validateattributes(gridSize,{'numeric'},{'vector','integer','positive','finite'});
if ~ismember(numel(gridSize),[2 3]), error('fieldanalysis:Dimensions','Specify two or three dimensions.'); end
validateattributes(spacing,{'numeric'},{'vector','positive','finite'});
if numel(spacing)~=numel(gridSize), error('fieldanalysis:Spacing','Spacing must match dimensions in YXZ order.'); end
axes=cell(1,numel(gridSize));
for d=1:numel(gridSize)
    axes{d}=sharedutilities.miscellaneous.genScaledKVec(gridSize(d),spacing(d));
end
end
