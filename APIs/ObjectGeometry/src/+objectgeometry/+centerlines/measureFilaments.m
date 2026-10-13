function [properties, objects] = measureFilaments(input, requested, options)
%MEASUREFILAMENTS Native and selected derived filament properties; no skeleton.
% REQUESTED: any native regionprops(3) name, plus Directors, AspectRatios,
% Lengths (historical voxel principal-axis length), ScaledDirectors,
% ProjectedExtent, ScaledAspectRatios. Derived values are opt-in.
% 'all' requests native properties only. OPTIONS.Identity holds prepareObjects
% options. ExtentWidthFloor=eps is positive in SpacingUnit units. Scaled values
% reuse the historical coordinate-scaled covariance/PCA method, WITHOUT
% resampling masks. Extent is max-minus-min of voxel CENTER projections, not
% equivalent-ellipsoid axis length. Metadata explicitly distinguishes units.
% Directors use [X Y Z] or [X Y] in image coordinates (Y increases downwards).
% Eigenvector sign is arbitrary; use nematic alignment, not polar direction.
if nargin<2||isempty(requested), requested={'Directors','Lengths','AspectRatios'}; end
if nargin<3, options=struct(); end
options=objectgeometry.internal.options(options,struct('Identity',struct(),'ExtentWidthFloor',eps));
validateattributes(options.ExtentWidthFloor,{'numeric'},{'real','finite','scalar','positive'});
objects=objectgeometry.objects.prepareObjects(input,options.Identity);
names=cellstr(string(requested)); names=names(:).';
derived={'Directors','Lengths','AspectRatios','ScaledDirectors','ProjectedExtent','ScaledAspectRatios'};
for i=1:numel(names)
    matched=find(strcmpi(names{i},derived),1);
    if ~isempty(matched), names{i}=derived{matched}; end
end
native=setdiff(names,derived,'stable'); dims=numel(objects.Grid.Size);
needAxes=any(ismember(names,{'Directors','Lengths','AspectRatios'}));
if needAxes
    if dims==3, dependencies={'PrincipalAxisLength','EigenVectors'};
    else, dependencies={'MajorAxisLength','MinorAxisLength','Orientation'}; end
    native=unique([native dependencies],'stable');
end
[properties,objects]=objectgeometry.objects.measureObjects(objects,native);
n=height(properties);
if needAxes
    if dims==3
        dirs=zeros(n,3); lens=properties.PrincipalAxisLength;
        for i=1:n, e=properties.EigenVectors{i}; dirs(i,:)=e([2 1 3],1).'; end
    else
        angle=-deg2rad(properties.Orientation);
        dirs=[cos(angle) sin(angle)];
        lens=[properties.MajorAxisLength properties.MinorAxisLength];
    end
    if ismember('Directors',names), properties.Directors=dirs; end
    if ismember('Lengths',names), properties.Lengths=lens(:,1); end
    if ismember('AspectRatios',names), properties.AspectRatios=lens(:,1)./lens(:,2); end
end
if any(ismember(names,{'ScaledDirectors','ProjectedExtent','ScaledAspectRatios'}))
    dirs=nan(n,dims); extents=zeros(n,1); ratios=nan(n,1);
    scale=objects.Grid.Spacing([2 1 3]); scale=scale(1:dims);
    for i=1:n
        indices=objects.Components.PixelIdxList{i};
        if dims==3
            [y,x,z]=ind2sub(objects.Grid.Size,indices); coordinates=[x y z];
        else
            [y,x]=ind2sub(objects.Grid.Size,indices); coordinates=[x y];
        end
        centered=coordinates.*scale; centered=centered-mean(centered,1);
        covariance=(centered.'*centered)/max(size(centered,1)-1,1);
        [eigenvectors,eigenvalues]=eig(covariance);
        [eigenvalues,order]=sort(diag(eigenvalues),'descend');
        e=eigenvectors(:,order);
        projections=centered*e;
        spans=max(projections,[],1)-min(projections,[],1);
        extents(i)=spans(1); ratios(i)=spans(1)/max(options.ExtentWidthFloor,spans(2));
        % A degenerate major eigenspace has no unique orientation.
        if eigenvalues(1)>0 && (eigenvalues(1)-eigenvalues(2))>eps(max(1,eigenvalues(1)))*10
            dirs(i,:)=e(:,1).';
        end
    end
    if ismember('ScaledDirectors',names), properties.ScaledDirectors=dirs; end
    if ismember('ProjectedExtent',names), properties.ProjectedExtent=extents; end
    if ismember('ScaledAspectRatios',names), properties.ScaledAspectRatios=ratios; end
end
% Discard dependencies not requested; do not retain expensive native fields.
keys={'DatasetID','Frame','ObjectID'};
if ~any(strcmpi(names,'all'))
    available=properties.Properties.VariableNames; keep=keys;
    for i=1:numel(names)
        matched=find(strcmpi(names{i},available),1);
        if isempty(matched), error('objectgeometry:MissingProperty','Requested property %s was not produced.',names{i}); end
        keep{end+1}=available{matched}; %#ok<AGROW>
    end
    properties=properties(:,unique(keep,'stable'));
end
properties.Properties.UserData=struct('Grid',objects.Grid,'SourceGrid',objects.SourceGrid, ...
    'Transform',objects.Transform,'DatasetID',objects.DatasetID,'Frame',objects.Frame, ...
    'NativeUnits','voxel','ProjectedExtentUnit',objects.Grid.SpacingUnit, ...
    'ExtentWidthFloor',options.ExtentWidthFloor,'DirectorAxes','XYZ','YDirection','increasing rows');
end
