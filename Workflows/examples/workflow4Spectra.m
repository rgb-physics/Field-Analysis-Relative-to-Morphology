function manifest=workflow4Spectra(c)
%WORKFLOW4SPECTRA Separate slices, projection, 3D spectra and linear correlation.
if nargin<1, c=experiment4Config; end
out=memoworkflow.newRun(c,'workflow4'); files=cell(numel(c.SpectrumFrames),1);
for k=1:numel(c.SpectrumFrames)
    frame=c.SpectrumFrames(k); a=memoworkflow.intensity(c,frame,'560'); timer=tic;
    slices=c.SelectedSlices(c.SelectedSlices<=size(a,3));
    if isempty(slices), error('memoworkflow:Slices','No selected Z slices exist.'); end
    opts=struct('Spacing',c.Spacing(1:2),'SpacingUnit','um','NumBins',c.NumBins, ...
        'MeanSubtract',c.MeanSubtract,'Window',c.Window);
    result=struct('Frame',frame,'DatasetID',c.DatasetID);
    result.Slices=fieldanalysis.fourier.selectSlicesAnalysis(a,slices,opts);
    projection=validatestring(c.Projection,{'mean','max'});
    if strcmp(projection,'mean'), projected=mean(double(a),3); else, projected=max(a,[],3); end
    result.Projection=fieldanalysis.fourier.powerSpectrum2D(projected,opts);
    result.Projection.Method=projection;
    opts.Spacing=c.Spacing; result.Volume=fieldanalysis.fourier.powerSpectrum3D(a,opts);
    % Store only radial correlation; discard each full temporary lag map.
    if strcmp(c.CorrelationMode,'3d'), field=a; spacing=c.Spacing;
    elseif strcmp(c.CorrelationMode,'2d'), field=a(:,:,slices(1)); spacing=c.Spacing(1:2);
    else, error('memoworkflow:Correlation','Choose 2d or 3d.'); end
    corr=fieldanalysis.spatialCorrelation.autoCorrelation(field,struct('Spacing',spacing,'MeanSubtract',c.MeanSubtract));
    result.AutoCorrelation=fieldanalysis.fourier.radialAverage(corr.Correlation,struct('Coordinates',{corr.LagAxes},'NumBins',c.NumBins));
    clear corr
    if c.CorrelationCrossChannel
        b=memoworkflow.intensity(c,frame,'647');
        if strcmp(c.CorrelationMode,'2d'), b=b(:,:,slices(1)); end
        corr=fieldanalysis.spatialCorrelation.crossCorrelation(field,b,struct('Spacing',spacing,'MeanSubtract',c.MeanSubtract));
        result.CrossCorrelation=fieldanalysis.fourier.radialAverage(corr.Correlation,struct('Coordinates',{corr.LagAxes},'NumBins',c.NumBins));
        clear corr b
    end
    result.CorrelationOptions=struct('Mode',c.CorrelationMode,'Spacing',spacing,'MeanSubtract',c.MeanSubtract,'Normalization','none');
    result.Seconds=toc(timer);
    files{k}=fullfile(out,sprintf('frame%03i.mat',frame)); memoworkflow.saveNew(files{k},result);
    f=figure('Visible','off'); cleanup=onCleanup(@()close(f));
    subplot(1,2,1); hold on;
    for s=1:numel(result.Slices), r=result.Slices{s}.Radial; plot(r.Centers,r.Mean); end
    r=result.Projection.Radial; plot(r.Centers,r.Mean,'k--');
    r=result.Volume.Radial; plot(r.Centers,r.Mean,'k','LineWidth',2);
    set(gca,'XScale','log','YScale','log'); xlabel('Frequency (cycles/um)'); ylabel('Unnormalized radial power');
    subplot(1,2,2); plot(result.AutoCorrelation.Centers,result.AutoCorrelation.Mean);
    xlabel('Lag magnitude (um)'); ylabel('Unnormalized correlation');
    visualizationtools.export.figSaves(f,out,sprintf('spectra_t%03i',frame),'png',true); clear cleanup
end
manifest=struct('Directory',out,'Files',{files}); memoworkflow.saveNew(fullfile(out,'manifest.mat'),manifest);
fprintf('Workflow 4 outputs: %s\n',out);
end
