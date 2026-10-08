
% FolderName='<redacted original absolute path>';
FolderName='';
nameFormat = 'zstep1um_t1min_mag40x_center001_T%02i.tif';
% meanimg=zeros(804,804,251);
selTs = 1;
loadMean = 1;
% for xy=1:2
threshold=1400;
% Generate mean img
if loadMean == 1
    load(fullfile(FolderName,'meanimg.mat'));
else
    for tInd = 1:numel(selTs)
        currT = selTs(tInd);
        tic
        imgstack=readTifStack(fullfile(FolderName,sprintf(nameFormat,currT)));
        imgstack(imgstack>threshold)=threshold;
        if (tInd==1)
            meanimg=imgstack;
        else
        meanimg=meanimg+imgstack;
        end
        toc
    end
    meanimg=meanimg./mean(meanimg,'all');
    save([FolderName 'meanimg.mat'],'meanimg','-v7.3')
end

%%
% sz=size(meanimg);
% xx=(ceil(-sz(2)/2):floor(sz(2)/2)).*xypixel0;
% yy=(ceil(-sz(1)/2):floor(sz(1)/2)).*xypixel0;
% zz=(ceil(-sz(3)/2):floor(sz(3)/2)).*zstep0;
% [xgrid,ygrid,zgrid]=meshgrid(xx,yy,zz);
% load('')
% psfc=psf./max(psf(:))-0.24;
% szp=size(psfc);
% twsize=0.2;
% t3=pagemtimes(tukeywin(szp(2),twsize)*tukeywin(szp(1),twsize)',permute(tukeywin(szp(3),twsize),[3 2 1]));    
% xxp=(ceil(-szp(2)/2):floor(szp(2)/2)).*xypixel;
% yyp=(ceil(-szp(1)/2):floor(szp(1)/2)).*xypixel;
% zzp=(ceil(-szp(3)/2):floor(szp(3)/2)).*zstep;
% [xpgrid,ypgrid,zpgrid]=meshgrid(xxp,yyp,zzp);
% psfc2=psfc;
% psft=psfc2.*t3;
% psf2=interp3(xpgrid,ypgrid,zpgrid,psft,xgrid,ygrid,zgrid,'cubic',0);
% psf2cut=pickcenter(psf2,10);
% clear xgrid;clear ygrid;clear zgrid;clear psf2;
% meanimg1=single(deconvlucy(single(meanimg),psf2cut,5));
%%
zmin=75;    zmax=175;
xmin=1;     xmax=803;
ymin=1;     ymax=803;
hannBool = 1;

% Sub select image
meanimg2=meanimg(ymin:ymax,xmin:xmax,zmin:zmax);
selField = meanimg2;
if hannBool == 1
    hannWeights = generateNDHann(size(selField));
    selField = selField.*hannWeights;
end

xypixel0=2*11/40;
zstep0=1;
sz=size(selField);
szn=round(sz(3)*zstep0/xypixel0);
if (rem(szn,2)==0)
    szn=szn+1;
end

% FFT img, (then pad dimensions s.t. matrix side lengths are equal)
fftBG = fftn(selField);

% "Scale down" to share q-pixels to 1/(smallest L)
pixSizes = [0.55 0.55 1];           %% VARIABLE
% inCutOff = 2;       % (in um)
imgDims = size(selField);
qPix = 1./imgDims.*1./pixSizes;

% Try 1: 1D means along each dimension
fshftBG = abs(fftshift(fftBG));
qBnds = round(imgDims/2)-mod(imgDims,2);
sideLens = pixSizes.*imgDims;
qScales = 1./(sideLens);
meanZ = squeeze(mean(fshftBG,[1 2]));
meanX = squeeze(mean(fshftBG,[2 3]))';
meanY = squeeze(mean(fshftBG,[1 3]));
% Display Try 1
% Fs/L*(0:L-1), where Fs is 1/pixSize, L is size(meanimg2)
qStruct = struct();
for ind = 1:3
    qStruct(ind).vals = qScales(ind)*(-qBnds(ind):qBnds(ind)-mod(imgDims(ind)+1,2));
end
figure
plot(qStruct(1).vals,meanX);
title('pretrim')
hold on
plot(qStruct(2).vals,meanY);
plot(qStruct(3).vals,meanZ);

% Inner q (low q) cutoff
hiQ = .07;        %(in 1/um)
hiQ_Z = abs(qStruct(3).vals) - hiQ > 0;
hiQ_X = abs(qStruct(1).vals) - hiQ > 0;
hiQ_Y = abs(qStruct(2).vals) - hiQ > 0;

% Get max values in ranges
maxZ = max(meanZ(hiQ_Z));
maxX = max(meanX(hiQ_X));
maxY = max(meanY(hiQ_Y));
% Store low-q z vals for later
ogZVals = meanZ;
% Assign maxes to low-q
meanX(~hiQ_X) = maxX;
meanY(~hiQ_Y) = maxY;
meanZ(~hiQ_Z) = maxZ;
figure
plot(qStruct(1).vals,meanX);
title('postrim')
hold on
plot(qStruct(2).vals,meanY);
plot(qStruct(3).vals,meanZ);

% Cutoff high q
loQ = 1;      %(in 1/um)
refZ = abs(qStruct(3).vals) - loQ < 0;
refX = abs(qStruct(1).vals) - loQ < 0;
refY = abs(qStruct(2).vals) - loQ < 0;

% Subselect wave numbers
subZ = qStruct(3).vals(refZ);

% Resize
rsX = imresize(meanX(refX),size(subZ));
rsY = imresize(meanY(refY),size(subZ));
% Plot
figure
plot(subZ,rsX);
title('Sub')
hold on
plot(subZ,rsY);
plot(subZ,meanZ(refZ));

% Get mean xy profile
meanXY = (rsX + rsY)/2;
plot(subZ,meanXY);
% Rescale z profile to match meanXY
rescZ = meanXY(:)./meanZ(refZ);
% rescZ(~hiQ_Z) = ogZVals(~hiQ_Z);

% Repmat z profile, then take product
zCol = permute(rescZ,[3 2 1]);
zReps = repmat(zCol,size(selField,1),size(selField,2));
zMat = zeros(size(selField));
zMat(:,:,refZ) = zReps;
temp = zMat.*fftshift(fftBG);
temp2 = ifftshift(ifftn(temp));
% zMat = repmat(rescZ, )

%% Test on another image

imgstack=tiffreadVolume(fullfile(FolderName,sprintf(nameFormat,1)));
subStack = imgstack(ymin:ymax,xmin:xmax,zmin:zmax);
test = fftn(subStack);
test2 = ifftn(test.*zMat);
tset3 = ifftn(test.*crct);

        %%

% qXs = 
% scfBG = imresize3(fftBG,imgDims./qPix*maxQP);
% test = abs(fftshift(scfBG));

% Define real space and q-space pixels 
sideLens = pixSizes.*imgDims;
qScales = 1./(sideLens);
% Rescale fftBG to have same dimensions in kx and ky
if qScales(1) ~= qScales(2)
    maxLen = max(imgDims(1:2));
    fftBG = imresize3(fftBG,[maxLen maxLen imgDims(3)]);
    qScales = qScales.*imgDims./size(fftBG);
end



qBnds = round(imgDims/2)-mod(imgDims,2);

% Rescale x and y to be same size
if qScales(1) ~= qScales(2)
    sqSize = max(1./qScales(1:2)./pixSizes(1:2));
    fftBG = imresize3(fftBG,[sqSize sqSize imgDims(3)]);
    selField = imresize3(selField,[sqSize sqSize imgDims(3)]);
    % Rescale dimensions
    ogDims = imgDims;
    imgDims = size(selField);
    pixSizes = pixSizes.*imgDims./ogDims;
    qBnds = round(imgDims/2)-mod(imgDims,2);
    qScales = 1./(pixSizes.*imgDims);
end
fshftBG = abs(fftshift(fftBG));
%%

% Get smallest dimension: remove inner (low-q) data points
innerCut = 3;
temp = fftBG;
temp(:,:, [1:innerCut, (end-innerCut+1):end]) = 0.0001;
% Rescaled cut xy dimensions from ratio of qBnds
qRatio = qScales

% Artificially set certain range to zero, then transform back
winBnd0s = [25 25 5];
temp = fftBG;
temp(winBnd0s(1):(end-winBnd0s(1)),winBnd0s(2):(end-winBnd0s(2)),winBnd0s(3):(end-winBnd0s(3))) = 0;

% Try 1: 1D means along each dimension
meanZ = squeeze(mean(fshftBG,[1 2]));
meanX = squeeze(mean(fshftBG,[2 3]));
meanY = squeeze(mean(fshftBG,[1 3]));
% Display Try 1
% Fs/L*(0:L-1), where Fs is 1/pixSize, L is size(meanimg2)
figure
plot(qScales(1)*(-qBnds(1):qBnds(1)),meanX);
hold on
plot(qScales(2)*(-qBnds(2):qBnds(2)),meanY);
plot(qScales(3)*(-qBnds(3):qBnds(3)),meanZ);

%% 
[meanimg3,f3]=densifyimg_fft(meanimg2,[sz(1) sz(2) szn]);

sz=size(meanimg3);
kx=(ceil(-sz(2)/2):floor(sz(2)/2)).*(1/sz(2)/xypixel0);
ky=(ceil(-sz(1)/2):floor(sz(1)/2)).*(1/sz(1)/xypixel0);
kz=(ceil(-sz(3)/2):floor(sz(3)/2)).*(1/sz(3)/xypixel0); 
cutoff=0.5;
conpensate=1;
%%
f5=abs(f3);
[kxgrid,kygrid,kzgrid]=meshgrid(kx,ky,kz);
midpos=round(size(kxgrid)/2);
ks=sqrt(kxgrid.^2+kygrid.^2+kzgrid.^2);
f5(ks>cutoff)=nan;
f5(midpos(1)-5:midpos(1)+5,:,:)=nan;
f5(:,midpos(2)-5:midpos(2)+5,:)=nan;
f5(:,:,midpos(3)-5:midpos(3)+5)=nan;
% f5x=squeeze(mean(f5,[2 3],'omitnan'));
% f5y=squeeze(mean(f5,[1 3],'omitnan'));
% f5z=squeeze(mean(f5,[1 2],'omitnan'));
f5x=squeeze(sum(f5,[2 3],'omitnan'));
f5y=squeeze(sum(f5,[1 3],'omitnan'));
f5z=squeeze(sum(f5,[1 2],'omitnan'));
f5x=f5x./max(f5x);
f5y=f5y./max(f5y);
f5z=f5z./max(f5z);
f5x2=interp1(kx,f5x,kz,"cubic")';
f5y2=interp1(ky,f5y,kz,"cubic")';
figure;plot(kx,f5x,'LineWidth',2)
hold on;plot(ky,f5y,'LineWidth',2)
plot(kz,f5z,'LineWidth',2)
xlabel('$k (\mu m^{-1})$','Interpreter','latex','FontSize',20)
ylabel('OTF','FontSize',20)
legend('OTF(k_x)','OTF(k_y)','OTF(k_z)','Location','best','FontSize',20)
% standardplot()
sz=size(f5);
crct1=ones(sz(1),1);
crct2=ones(1,sz(2));
crct3=permute(squeeze(abs((f5x2+f5y2)./2./f5z).^conpensate),[3 2 1]);
crct3(~isfinite(crct3))=min(abs(crct3));
crct3(isnan(crct3))=min(crct3);
crct=pagemtimes(crct1*crct2,crct3);
% f5=f3.*crct;
% f5(ks>cutoff)=0;
% f5(isnan(f5))=0;
%%
kzc=squeeze(kz);
crct3c=squeeze(crct3);
save([FolderName 'normf5_deconvolved.mat'],'kzc','crct3c')
% %%
% imgstack=imgstack./mean(meanimg,3);
% imgstack1=imgstack(ymin:ymax,xmin:xmax,zmin:zmax);
% [imgstack2,f3]=densifyimg_fft(imgstack1,[sz(1) sz(2) szn]);
% f5=f3.*crct;
% f5(ks>cutoff)=0;
% f5(isnan(f5))=0;
% imgstack5=abs(ifftn(fftshift(f5)));
function psf2cut=pickcenter(psf2,wsize)
sz=size(psf2);
m=round(sz/2);
psf2cut=psf2(m(1)-wsize:m(1)+wsize,m(2)-wsize:m(2)+wsize,m(3)-wsize:m(3)+wsize);

end
%% 
function [imgstack31,f31]= densifyimg_fft(imgstack3,sz1)
    sz=size(imgstack3);
    f3=fftshift((fftn(imgstack3)));
    f31=zeros(sz1(1),sz1(2),sz1(3));
    f31(:,:,(sz1(3)-sz(3))/2+1:(sz1(3)-sz(3))/2+sz(3))=f3;
    imgstack31=real(ifftn(ifftshift(f31)));
end


