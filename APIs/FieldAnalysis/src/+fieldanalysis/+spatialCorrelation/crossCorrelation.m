function result=crossCorrelation(a,b,options)
%CROSSCORRELATION Unnormalized linear correlation, native xcorr2 in 2D.
% 3D uses FFT convolution of A with reversed B (equivalent lag convention).
% Positive lag means A is displaced toward increasing indices relative to B.
if nargin<3, options=struct(); end
a=fieldanalysis.internal.field(a); b=fieldanalysis.internal.field(b);
if ~isequal(size(a),size(b)), error('fieldanalysis:SizeMismatch','Fields must have matching dimensions.'); end
nD=ndims(a);
o=fieldanalysis.internal.options(struct('MeanSubtract',false,'Window',false, ...
    'Spacing',ones(1,nD),'SpacingUnit','voxel'),options);
validateattributes(o.MeanSubtract,{'logical'},{'scalar'});
validateattributes(o.Window,{'logical'},{'scalar'});
validateattributes(o.Spacing,{'numeric'},{'vector','positive','finite','numel',nD});
originalMeans=[mean(a(:)),mean(b(:))];
if o.MeanSubtract, a=a-originalMeans(1); b=b-originalMeans(2); end
if o.Window
    w=sharedutilities.numerics.generateNDHann(size(a)); a=a.*w; b=b.*w;
end
if nD==2
    if exist('xcorr2','file')==0, error('fieldanalysis:Dependency','2D correlation requires MATLAB xcorr2 (Signal Processing Toolbox).'); end
    correlation=xcorr2(a,b);
else
    rev=b;
    for d=1:nD, rev=flip(rev,d); end
    outSize=size(a)+size(b)-1;
    correlation=real(ifftn(fftn(a,outSize).*fftn(rev,outSize)));
end
lags=cell(1,nD);
for d=1:nD, lags{d}=(-(size(b,d)-1):(size(a,d)-1))*o.Spacing(d); end
result=struct('Correlation',correlation,'LagAxes',{lags}, ...
    'ZeroLagIndex',size(b),'Boundary','linear','Normalization','none', ...
    'MeanSubtract',o.MeanSubtract,'Window',o.Window,'InputMeans',originalMeans, ...
    'GridSize',size(a),'Spacing',o.Spacing,'SpacingUnit',o.SpacingUnit);
end
