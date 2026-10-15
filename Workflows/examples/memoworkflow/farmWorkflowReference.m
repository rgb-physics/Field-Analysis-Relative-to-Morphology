function [distance,gradients,valid,regions,info] = farmWorkflowReference(c,frame,targetSize)

%FARMWORKFLOWREFERENCE Historical in/on/out boundary distance on an isotropic working grid.
[regions,info] = farmWorkflowRegions(c,frame,targetSize);
iso = min(c.Spacing); workingSize = max(2,round(targetSize.*c.Spacing/iso));
work = imresize3(regions,workingSize,'nearest');
[d,~,~,~,~,keep] = farmDistTransFromBoundary(work==2,work==3,work==1,1);
if any(~isfinite(d(:))), error('memoworkflow:Reference','No usable boundary reference; inspect semantic preview.'); end
distance = imresize3(d*iso,targetSize,'nearest');
[gradients,~,directionValid] = farmDistanceGradients(distance, ...
    struct('Sigma',c.ProfileSigma,'Spacing',c.Spacing,'SpacingUnit',c.SpacingUnit, ...
    'DerivativeUnits','physical','DistanceUnit',c.SpacingUnit));
valid = imresize3(keep,targetSize,'nearest');
info.DirectionValid = directionValid; info.WorkingSpacing = iso;
end
