function tests=testFieldAnalysis
tests=functiontests(localfunctions);
end

function testFrequencyAxesOddEven(t)
verifyEqual(t,sharedutilities.miscellaneous.genScaledKVec(4),[-2 -1 0 1]/4);
verifyEqual(t,sharedutilities.miscellaneous.genScaledKVec(5),[-2 -1 0 1 2]/5);
axes=fieldanalysis.fourier.frequencyCoordinates([4 5],[2 3]);
verifyEqual(t,axes{1},[-2 -1 0 1]/8);
verifyEqual(t,axes{2},[-2 -1 0 1 2]/15);
end

function testNativeHannBaseline(t)
a=reshape(1:80,8,10);
r=fieldanalysis.fourier.powerSpectrum2D(a,struct('ReturnPower',true));
w=sharedutilities.numerics.generateNDHann(size(a));
verifyEqual(t,r.Power,abs(fftshift(fft2(a.*w))).^2,'RelTol',1e-12);
verifyEqual(t,r.Normalization.AppliedFactor,1);
verifyEqual(t,r.Normalization.WindowSquaredSum,sum(w(:).^2),'AbsTol',1e-12);
verifyEqual(t,r.Normalization.VoxelCount,80);
end

function testSinusoidalFrequencyAndParseval(t)
[x,y]=meshgrid(0:31,0:23); a=cos(2*pi*4*x/32)+0*y;
r=fieldanalysis.fourier.powerSpectrum2D(a,struct('Window',false,'ReturnPower',true,'Spacing',[2 2]));
[~,order]=sort(r.Power(:),'descend'); [iy,ix]=ind2sub(size(a),order(1:2));
verifyEqual(t,sort(r.FrequencyAxes{2}(ix)),[-1 1]/16,'AbsTol',1e-12);
verifyEqual(t,r.FrequencyAxes{1}(iy),[0 0],'AbsTol',1e-12);
verifyEqual(t,sum(r.Power(:))/numel(a),sum(a(:).^2),'RelTol',1e-12);
end

function testMeanSubtractionOptional(t)
a=3*ones(7,9);
r=fieldanalysis.fourier.powerSpectrum2D(a,struct('Window',false,'ReturnPower',true));
verifyEqual(t,r.Power(4,5),(3*numel(a))^2);
s=fieldanalysis.fourier.powerSpectrum2D(a,struct('Window',false,'MeanSubtract',true,'ReturnPower',true));
verifyEqual(t,s.Power,zeros(size(a)),'AbsTol',1e-12);
end

function testThreeDimensionalSpectrum(t)
a=zeros(7,8,9); a(4,5,5)=1;
r=fieldanalysis.fourier.powerSpectrum3D(a,struct('Window',false,'ReturnPower',true));
verifyEqual(t,r.Power,ones(size(a)),'AbsTol',1e-12);
verifyEqual(t,numel(r.FrequencyAxes),3);
verifyEqual(t,sum(r.Radial.Counts),numel(a));
verifyError(t,@()fieldanalysis.fourier.powerSpectrum2D(a),'fieldanalysis:Dimensions');
end

function testSeparateSlicesAndExternalProjection(t)
v=cat(3,ones(8),2*ones(8),3*ones(8));
r=fieldanalysis.fourier.selectSlicesAnalysis(v,[3 1],struct('Window',false,'ReturnPower',true));
verifyEqual(t,[r{1}.Slice,r{2}.Slice],[3 1]);
verifyEqual(t,r{1}.Power,9*r{2}.Power,'AbsTol',1e-10);
p=fieldanalysis.fourier.powerSpectrum2D(mean(v,3),struct('Window',false,'ReturnPower',true));
verifyEqual(t,p.Power,4*r{2}.Power,'AbsTol',1e-10);
end

function testRadialCenterAndBins(t)
for n=[8 9]
    a=zeros(n); c=floor(n/2)+1; a(c,c)=1;
    r=fieldanalysis.fourier.radialAverage(a,struct('Edges',[0 .5 1.5 20 30]));
    verifyEqual(t,r.Mean(1),1); verifyEqual(t,r.Counts(1),1);
    verifyEqual(t,numel(r.Mean),4);
    verifyEqual(t,r.Counts(4),0); verifyTrue(t,isnan(r.Mean(4)));
    ids=fieldanalysis.statistics.generateRadialMatrix([n n],4);
    verifySize(t,ids,[n n]);
    [old,edges,counts]=fieldanalysis.statistics.radiallyAverageMatrix(a,0,0,[0 .5 1.5]);
    verifyEqual(t,numel(old),numel(edges)-1);
    verifyEqual(t,counts(1),1); verifyEqual(t,old(1),1);
end
end

function testThreeDimensionalRadialCenter(t)
for n=[8 9]
    a=zeros(n,n,n); c=floor(n/2)+1; a(c,c,c)=1;
    r=fieldanalysis.fourier.radialAverage(a,struct('Edges',[0 .5 1.5]));
    verifyEqual(t,r.Mean(1),1); verifyEqual(t,r.Counts(1),1);
    [v,~,counts]=fieldanalysis.statistics.radiallyAverageMatrix(a,0,0,[0 .5 1.5]);
    verifyEqual(t,v(1),1); verifyEqual(t,counts(1),1);
end
end

function testGaussianWeights(t)
a=reshape(1:25,5,5); [x,y]=meshgrid(-2:2); radii=sqrt(x.^2+y.^2);
r=fieldanalysis.fourier.radialAverage(a,struct('Edges',[0 1 3],'Sigma',.7));
for k=1:2
    w=exp(-((radii(:)-r.Centers(k))/.7).^2/2);
    verifyEqual(t,r.Mean(k),sum(a(:).*w)/sum(w),'AbsTol',1e-12);
end
end

function testConditionalArrayVectorEquivalence(t)
m=[0 2 4;6 8 10]; c=[0 0 1;1 2 2];
o=struct('Edges',[0 1 2 3 4],'Statistics',{{'Mean','Variance','Sum','Count'}});
a=fieldanalysis.conditional.conditionalStatistics(m,c,o);
b=fieldanalysis.conditional.conditionalStatistics(m(:),c(:),o);
verifyEqual(t,a.Statistics,b.Statistics);
verifyEqual(t,a.Statistics.Mean(1:3),[1;5;9]);
verifyEqual(t,a.Statistics.Count,[2;2;2;0]);
verifyTrue(t,isnan(a.Statistics.Mean(4)));
verifyEqual(t,a.Statistics.Sum(4),0);
end

function testConditionalIdentityAndExclusions(t)
m=[10 20 30 40]; c=[0 1 1 9];
o=struct('Edges',[0 1 2],'GroupIDs',[9 2 9 2],'Statistics',{{'Mean'}});
r=fieldanalysis.conditional.conditionalStatistics(m,c,o);
verifyEqual(t,r.Statistics.GroupID,[2;2;9;9]);
verifyEqual(t,r.Statistics.Count,[0;1;1;1]);
verifyEqual(t,r.ExcludedCounts.Count,[1;0]);
end

function testPairOrderingAndJointHistogram(t)
a=[1 2 3 4]; b=[4 3 2 1];
r=fieldanalysis.statistics.pairedFieldStatistics(a,b);
verifyEqual(t,r.Correlation(1,2),-1,'AbsTol',1e-12);
h=fieldanalysis.conditional.jointHistogram(a,b,struct('EdgesA',[0 2.5 5],'EdgesB',[0 2.5 5]));
verifyEqual(t,h.Counts,[0 2;2 0]); verifyEqual(t,h.ExcludedCount,0);
end

function testLinearCorrelationNoWrapAndLagSign(t)
a=zeros(5,6); b=a; a(4,5)=2; b(2,2)=3;
r=fieldanalysis.spatialCorrelation.crossCorrelation(a,b);
verifySize(t,r.Correlation,[9 11]);
[~,idx]=max(r.Correlation(:)); [iy,ix]=ind2sub(size(r.Correlation),idx);
verifyEqual(t,[r.LagAxes{1}(iy),r.LagAxes{2}(ix)],[2 3]);
verifyEqual(t,r.Correlation(iy,ix),6,'AbsTol',1e-12);
verifyEqual(t,nnz(abs(r.Correlation)>1e-10),1);
end

function testCorrelation3DAgainstDirectConvolution(t)
a=reshape(1:60,[3 4 5]); b=flip(a,2);
r=fieldanalysis.spatialCorrelation.crossCorrelation(a,b,struct('Spacing',[2 3 4]));
expected=convn(a,flip(flip(flip(b,1),2),3),'full');
verifyEqual(t,r.Correlation,expected,'AbsTol',1e-8);
verifyEqual(t,r.ZeroLagIndex,[3 4 5]);
verifyEqual(t,r.LagAxes{3},(-4:4)*4);
end

function testAutocorrelationZeroLag(t)
a=reshape(1:20,4,5);
r=fieldanalysis.spatialCorrelation.autoCorrelation(a);
verifyEqual(t,r.Correlation(4,5),sum(a(:).^2),'AbsTol',1e-10);
s=fieldanalysis.spatialCorrelation.autoCorrelation(a,struct('MeanSubtract',true));
verifyEqual(t,s.Correlation(4,5),sum((a(:)-mean(a(:))).^2),'AbsTol',1e-10);
end

function testInvalidInputs(t)
verifyError(t,@()fieldanalysis.fourier.powerSpectrum2D([1 NaN;2 3]),'fieldanalysis:InvalidData');
verifyError(t,@()fieldanalysis.conditional.conditionalStatistics([1 Inf],[1 2]),'fieldanalysis:InvalidData');
verifyError(t,@()fieldanalysis.conditional.conditionalStatistics(ones(2),ones(3)),'fieldanalysis:SizeMismatch');
verifyError(t,@()fieldanalysis.spatialCorrelation.crossCorrelation(ones(2),ones(3)),'fieldanalysis:SizeMismatch');
verifyError(t,@()fieldanalysis.fourier.powerSpectrum2D(ones(3),struct('Typo',1)),'fieldanalysis:Options');
end

function testEmptyConditionalSupport(t)
r=fieldanalysis.conditional.conditionalStatistics([],[],struct('Edges',[0 1 2]));
verifyEqual(t,r.Statistics.Count,[0;0]);
verifyTrue(t,all(isnan(r.Statistics.Mean)));
end
