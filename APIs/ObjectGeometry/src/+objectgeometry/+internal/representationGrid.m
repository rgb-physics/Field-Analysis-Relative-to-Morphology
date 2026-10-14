function grid=representationGrid(grid)
%REPRESENTATIONGRID Validate a current 2-D/3-D grid without changing calibration.
if ~isstruct(grid)||~isscalar(grid)||~isfield(grid,'Size')
    error('objectgeometry:RepresentationGrid','Provide a scalar grid with Size.');
end
validateattributes(grid.Size,{'numeric'},{'vector','integer','positive','finite','real'});
grid.Size=double(grid.Size(:).');
if ~ismember(numel(grid.Size),[2 3]), error('objectgeometry:RepresentationGrid','Grid Size must be YX or YXZ.'); end
axes='YX'; if numel(grid.Size)==3, axes='YXZ'; end
if isfield(grid,'Axes')&&~strcmp(grid.Axes,axes)
    error('objectgeometry:RepresentationGrid','Grid Axes must match Size: %s.',axes);
end
grid.Axes=axes;
if ~isfield(grid,'Spacing'), grid.Spacing=ones(1,numel(grid.Size)); end
validateattributes(grid.Spacing,{'numeric'},{'vector','real','finite','positive'});
% Prepared 2-D objects retain a third spacing entry; preserve it.
if ~ismember(numel(grid.Spacing),unique([numel(grid.Size),3]))
    error('objectgeometry:RepresentationGrid','Spacing must match the spatial dimensions.');
end
if ~isfield(grid,'SpacingUnit'), grid.SpacingUnit='pixel'; end
unit=string(grid.SpacingUnit);
if ~isscalar(unit)||ismissing(unit)||strlength(unit)==0, error('objectgeometry:RepresentationGrid','Specify scalar SpacingUnit.'); end
end
