function [distance,gradients,valid,regions,info]=reference(c,frame,targetSize)
%REFERENCE Historical in/on/out boundary distance on an isotropic working grid.
[regions,info]=memoworkflow.regions(c,frame,targetSize);
iso=min(c.Spacing); workingSize=max(2,round(targetSize.*c.Spacing/iso));
work=imresize3(regions,workingSize,'nearest');
[d,~,~,~,~,keep]=objectgeometry.objects.distTransFromBoundary(work==2,work==3,work==1,1);
if any(~isfinite(d(:))), error('memoworkflow:Reference','No usable boundary reference; inspect semantic preview.'); end
distance=imresize3(d*iso,targetSize,'nearest');
[gradients,~,directionValid]=objectgeometry.objects.distanceGradients(distance, ...
    struct('Sigma',c.ProfileSigma,'Spacing',c.Spacing,'DerivativeUnits','physical','DistanceUnit','um'));
valid=imresize3(keep,targetSize,'nearest');
info.DirectionValid=directionValid; info.WorkingSpacing=iso;
end
