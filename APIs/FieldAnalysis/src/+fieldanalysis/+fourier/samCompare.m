%% Load
% dataDir =  '<redacted original absolute path>';
dataDir =  'Session 81, Exp 2';
dataName = 't%03i_illBleachCorr16bit_560.tif';
selectTimes = 1:20;
selZ = 44;
pixSize = 11*2/20;
figure
for tInd = 1:numel(selectTimes)
% selTimes = [1 25 65];

%% Sam code
currT = selectTimes(tInd);
img = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT))));
img = mean(img(:,:,selZ),3);
back = ones(size(img));
tic
[X,Y]=meshgrid([1:size(img,2)],[1:size(img,1)]);
%weights=.5.*(1 - cos(2*pi*X./1608)).*.5.*(1 - cos(2*pi*Y./1608));
weights=ones(size(img,1),size(img,2));
u=double(img).*weights./back;
umin=min(u(:));
umax=max(u(:));
% u=u-min(u(:));u=u./max(u(:));
weights=.5.*(1 - cos(2*pi*X./size(img,2))).*.5.*(1 - cos(2*pi*Y./size(img,1)));

%u=imbinarize(u,.25).*weights;
%u=imbinarize(imgaussfilt(u,1),.4).*u;
u=u.*weights;
%u=u./mean(u(:));

L=size(u);
skip=1;
Qs=[4096/32,4096/32]'; % the number of Q's to calculate
Qs=Qs.*8;
Qs=size(u);
k1=skip*2*pi/L(1)*(-Qs(1)/2:Qs(1)/2-1)';
k2=skip*2*pi/L(2)*(-Qs(2)/2:Qs(2)/2-1);
k=sqrt(bsxfun(@plus,k1.^2,k2.^2));
[k,ind]=sort(k(:));
numbin=round([1:.5:floor(size(k,1).^(1/2))].^2);
startbin=numbin(1:end-1);
endbin=numbin(2:end)-1;
Sq1=abs(fftshift(fft2(u)).^2)./prod(size(img));
Sq1(floor(size(Sq1,1)/2)+1,floor(size(Sq1,2)/2)+1)=0;
Sq11=Sq1(:,:);
sSq=Sq11(ind);
Sqbin_dummy2=zeros(numel(startbin),1);
numbin2=zeros(numel(startbin),1);
kmag=zeros(numel(startbin),1);
for q=1:numel(numbin)-1
    totbins=startbin(q):endbin(q);
    numbin2(q)=sum(~isnan(sSq(startbin(q):endbin(q))));
    kmag(q)=sum(k(startbin(q):endbin(q))./numbin2(q),'omitnan');
    kvar(q)=std(k(startbin(q):endbin(q)))./sqrt(numbin(q));
    Sqbin_dummy2(q)=sum(sSq(startbin(q):endbin(q))./numbin2(q),'omitnan');
    Sqbinerr(q)=std(sSq(startbin(q):endbin(q)))./sqrt(numbin(q));

end
toc
Sq_binimg=Sqbin_dummy2(1:end);
ktotimg=kmag(1:end)./(2.*pi*pixSize);
loglog(ktotimg,Sq_binimg);
% pause(.1)
hold on
end

%% Remi Code
tInd = 1; hannBool = 1; 
zRanges = [1 1];    zIncr = 1;
sigmaVal = 2;
zRange = zRanges(1):zIncr:zRanges(2); 
% Instantiate
currT = selTimes(tInd);
if tInd == 1
    % currTif = tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT)));
    currTif = img;
    imgSize = size(currTif);    
    rMaxes = round(imgSize(1:2)/2) - mod(imgSize(1:2),2);       % Even/odd edgecase
    xyStarts = 1 + floor(imgSize(1:2)/2) - rMaxes;
    xyEnds = round(imgSize(1:2)/2) + rMaxes;
    if hannBool == 1
        hannMat = repmat(generateNDHann(2*rMaxes + mod(imgSize(1:2),2)),[1 1 numel(zRange)]);
    else
        hannMat = ones([2*rMaxes,numel(zRange)]);
    end
end

% Load fraction of image of interest
% currTif = double(tiffreadVolume(fullfile(dataDir,sprintf(dataName,currT)),...
%     'PixelRegion',{[xyStarts(1) 1 xyEnds(1)],[xyStarts(2) 1 xyEnds(2)],[zRanges(1) zIncr zRanges(2)]}));
currTif = img;
scaleMat = hannMat/sum(currTif(:));
% Calculate fourier transform of each 2D xy slice
storeMat = abs(fftshift(fft2(currTif.*scaleMat)).^2)./prod(imgSize);       % hanning, then shift (hanning is nonlinear)
Sq1=abs(fftshift(fft2(u)).^2)./prod(size(img));
% storeMat = fftshift(abs(fft2(currTif.*scaleMat)));       % hanning, then shift (hanning is nonlinear)
% Calculate 2D fourier transform of real space projection along z
storeMat2D = fftshift(abs(fft2(mean(currTif,3).*scaleMat(:,:,1))));
% Radially average and store
if tInd == 1
    [meanVals,~] = radiallyAverageMatrix(storeMat,sigmaVal,1,qRange);
    [meanValsProj,q_bins] = radiallyAverageMatrix(storeMat2D,sigmaVal,1,qRange);
    FFTPixSize = 1/(2*rMaxes*pixSize);
    kValsMid = FFTPixSize*(q_bins(1:end-1) + q_bins(2:end))/2;
    kVals = FFTPixSize*q_bins;
else
    temp = radiallyAverageMatrix(storeMat,sigmaVal,1,qRange);
    meanVals = [meanVals, temp];
    temp = radiallyAverageMatrix(storeMat2D,sigmaVal,1,qRange);
    meanValsProj = [meanValsProj, temp];
end

