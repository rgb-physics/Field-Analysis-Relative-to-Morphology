function manifest=workflow2Filaments(c)
%WORKFLOW2FILAMENTS Centroid association with semantic/distance vector fields.
if nargin<1, c=experiment4Config; end
out=memoworkflow.newRun(c,'workflow2'); tables=cell(numel(c.Frames),1);
for k=1:numel(c.Frames)
    frame=c.Frames(k); timer=tic;
    raw=memoworkflow.intensity(c,frame,'647');
    if isempty(c.FilamentLoader)
        response=-sharedutilities.numerics.LOG(double(raw),c.FilamentSigma);
        segmentation=segmentationtools.binarization.segmentIntensity(response, ...
            struct('Method','fixed','Threshold',c.FilamentThreshold)); mask=segmentation.Mask;
    else, mask=c.FilamentLoader(frame); end
    identity=struct('DatasetID',c.DatasetID,'Frame',frame,'Spacing',c.Spacing,'SpacingUnit','um');
    properties=objectgeometry.centerlines.measureFilaments(mask, ...
        {'Volume','Centroid','Directors','Lengths','AspectRatios','ScaledDirectors','ProjectedExtent','ScaledAspectRatios'}, ...
        struct('Identity',identity,'ExtentWidthFloor',eps));
    [distance,g,valid,regions,referenceInfo]=memoworkflow.reference(c,frame,size(mask));
    xyz=round(properties.Centroid);
    indices=sub2ind(size(mask),xyz(:,2),xyz(:,1),xyz(:,3));
    reference=zeros(height(properties),3);
    for d=1:3, field=g(:,:,:,d); reference(:,d)=field(indices); end
    properties.CoMIndices=indices; properties.BoundaryDistance=distance(indices);
    properties.RegionClass=regions(indices); properties.ReferenceValid=valid(indices);
    properties.ReferenceDirectionValid=referenceInfo.DirectionValid(indices);
    properties.DistanceGradient=reference;
    directors=properties.ScaledDirectors;
    finite=all(isfinite(directors),2)&all(isfinite(reference),2);
    order3=NaN(height(properties),1); order2=order3; angle2=order3;
    a=objectgeometry.orientation.nematicAlignment(directors(finite,:),reference(finite,:));
    options=struct('Plane',[1 2],'MaxNormalComponent',c.MaxZComponent);
    b=objectgeometry.orientation.nematicAlignment(directors(finite,:),reference(finite,:),options);
    order3(finite)=a.Order; order2(finite)=b.Order; angle2(finite)=b.SignedAngle;
    properties.Order3D=order3; properties.Order2D=order2; properties.SignedAngle2D=angle2;
    properties.Selected=properties.ReferenceValid&properties.ReferenceDirectionValid& ...
        properties.ProjectedExtent>=c.MinFilamentLength&properties.ScaledAspectRatios>=c.MinAspectRatio;
    % Separate selection flag; raw measurements are retained.
    tables{k}=properties;
    memoworkflow.saveNew(fullfile(out,sprintf('frame%03i.mat',frame)), ...
        struct('Filaments',properties,'ReferenceInfo',rmfield(referenceInfo,'DirectionValid'),'Seconds',toc(timer)));
    if k==1
        z=round(size(mask,3)/2); f=figure('Visible','off'); cleanup=onCleanup(@()close(f));
        subplot(1,2,1); imagesc(raw(:,:,z)); axis image; title('Filament intensity');
        subplot(1,2,2); imagesc(regions(:,:,z)); axis image; clim([0 3]); colorbar; title('0 unclassified; 1 inside; 2 wall; 3 outside');
        visualizationtools.export.figSaves(f,out,'semantic-preview','png',true); clear cleanup
    end
end
manifest=struct('Directory',out,'Filaments',objectgeometry.objects.concatenateMeasurements(tables));
memoworkflow.saveNew(fullfile(out,'manifest.mat'),manifest);
fprintf('Workflow 2 outputs: %s\n',out);
end
