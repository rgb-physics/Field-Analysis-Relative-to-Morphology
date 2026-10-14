function [indices,omitted]=rasterIndices(points,grid,options)
%RASTERINDICES Convert one-based coordinate rows to current-grid indices.
dims=numel(grid.Size);
validateattributes(points,{'numeric'},{'2d','real','finite'});
if size(points,2)~=dims, error('objectgeometry:PointDimensions','Use N-by-%d coordinate rows, including for empty input.',dims); end
p=double(points);
if strcmp(options.CoordinateOrder,'XYZ'), p(:,[1 2])=p(:,[2 1]); end
switch options.Rounding
    case 'nearest', p=round(p);
    case 'floor', p=floor(p);
    case 'ceil', p=ceil(p);
end
inside=all(p>=1 & p<=grid.Size,2); omitted=nnz(~inside);
if omitted && strcmp(options.BoundsPolicy,'error')
    error('objectgeometry:RepresentationBounds','Rounded locations lie outside the grid. Use BoundsPolicy=omit to discard them.');
end
p=p(inside,:); indices=zeros(0,1);
if ~isempty(p), columns=num2cell(p,1); indices=sub2ind(grid.Size,columns{:}); end
indices=unique(indices(:));
end
