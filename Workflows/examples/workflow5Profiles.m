function manifest=workflow5Profiles(c,filamentManifest)
%WORKFLOW5PROFILES Intensity/support profiles and optional stored alignment profiles.
% A workflow2 manifest is optional; no hidden recomputation of filament geometry.
if nargin<1, c=experiment4Config; end
out=memoworkflow.newRun(c,'workflow5'); files=cell(numel(c.Frames),1);
for k=1:numel(c.Frames)
    frame=c.Frames(k); a=memoworkflow.intensity(c,frame,'560');
    [objects,mask]=memoworkflow.objects(c,frame,size(a));
    iso=min(c.Spacing); workingSize=max(2,round(size(mask).*c.Spacing/iso));
    work=imresize3(logical(mask),workingSize,'nearest');
    if strcmp(c.ProfileReference,'boundary')
        work=segmentationtools.cleanup.returnSmoothBlobsBW(work,0,1,c.ProfileSigma);
        distance=sharedutilities.numerics.signedBWDist(work)*iso;
    elseif strcmp(c.ProfileReference,'skeleton')
        geometry=objectgeometry.objects.generateGeometry(objects,'skeleton',struct('Sigma',c.GeometrySigma));
        skeleton=false(size(mask)); skeleton(vertcat(geometry.Records.Indices))=true;
        work=imresize3(skeleton,workingSize,'nearest');
        % Nonnegative exterior distance: explicit definition rather than global-min shifting.
        distance=bwdist(work)*iso;
    else, error('memoworkflow:Reference','Choose boundary or skeleton.'); end
    distance=imresize3(distance,size(a),'nearest');
    result=struct('Frame',frame,'Reference',c.ProfileReference,'DistanceUnit','um','Edges',c.ProfileEdges);
    for channel=c.ProfileChannels
        if strcmp(channel{1},'560'), image=a;
        else, image=memoworkflow.intensity(c,frame,channel{1}); end
        result.(['Channel' channel{1}])=fieldanalysis.conditional.conditionalStatistics(image,distance, ...
            struct('Edges',c.ProfileEdges,'Statistics',{{'Mean','Sum','Std'}}));
    end
    if nargin>=2
        t=filamentManifest.Filaments; t=t(t.Frame==frame&t.Selected&isfinite(t.Order2D),:);
        result.Alignment=fieldanalysis.conditional.conditionalStatistics(t.Order2D,t.BoundaryDistance, ...
            struct('Edges',c.ProfileEdges,'GroupIDs',double(t.RegionClass),'Statistics',{{'Mean','Std'}}));
    end
    files{k}=fullfile(out,sprintf('frame%03i.mat',frame)); memoworkflow.saveNew(files{k},result);
    f=figure('Visible','off'); cleanup=onCleanup(@()close(f)); hold on;
    for channel=c.ProfileChannels
        t=result.(['Channel' channel{1}]).Statistics;
        plot((t.LeftEdge+t.RightEdge)/2,t.Mean);
    end
    xlabel(['Distance to ' c.ProfileReference ' (um)']); ylabel('Mean corrected intensity'); legend(c.ProfileChannels);
    visualizationtools.export.figSaves(f,out,sprintf('profiles_t%03i',frame),'png',true); clear cleanup
end
manifest=struct('Directory',out,'Files',{files}); memoworkflow.saveNew(fullfile(out,'manifest.mat'),manifest);
fprintf('Workflow 5 outputs: %s\n',out);
end
