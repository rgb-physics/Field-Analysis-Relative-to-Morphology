% Takes in two directories and name formats corresponding to tifs of the
% same sizes. Calculates the spatial cross correlation of these fields for
% multiple time points. The two fields are expected to be concurrent and
% have the same time indices
% Assumes fields both have anti-correlation around 0, so they will both be
% shifted s.t. mean = 0 in each frame. Shift the fields, then apply hanning
% windows to minimize boundary effects
% 2024-04-29

%% Directory info
% dataDir1 = '<redacted original absolute path>';
dataDir1 = 'Session 81, Exp 2';
dataDir2 = dataDir1;
dataName1 = 't%03i_illBleachCorr16bit_488.tif';
dataName2 = 't%03i_illBleachCorr16bit_560.tif';

selectTimes = 40;
pixSize = 11*2/20;
rescaleVec = [1 1 1];
binRange = 1:2:40;
binAvgSigma = 0;

% Plot color info
timeColorVec = [1 0.5 0.5; 1 0 0; 0 0 1; 0 1 0; 0 0 0; 0 0 0];
timeColorStamps = [1 19 25 39 110 270];
timeColorArray = stitchGradients(timeColorVec,timeColorStamps);

% 3D or 2D bool
dimVal = 2;

%% Iterate over time
timeStore = zeros(numel(selectTimes), numel(binRange));
waitObj = waitbar(0,'Setting up...');
for tInd = 1:numel(selectTimes)

    currT = selectTimes(tInd);
    waitObj = progressBar(tInd,selectTimes,waitObj);
    % Load fields
    currTif1 = double(tiffreadVolume(fullfile(dataDir1,sprintf(dataName1,currT))));
    currTif2 = double(tiffreadVolume(fullfile(dataDir2,sprintf(dataName2,currT))));
    % Rescale and shift fields
    % procImg1 = imresize3(currTif1,size(currTif1).*rescaleVec);
    % procImg2 = imresize3(currTif2,size(currTif1).*rescaleVec);
    procImg1 = imresize3(currTif1,size(currTif1).*rescaleVec) - mean(currTif1(:));
    procImg2 = imresize3(currTif2,size(currTif1).*rescaleVec) - mean(currTif2(:));
    normFact = std(procImg2(:))*std(procImg1(:));
    imgSize = size(procImg2);
    % Apply hanning window to each image
    if tInd == 1
        rMaxes = round(imgSize(1:2)/2) - mod(imgSize(1:2),2);       % Even/odd edgecase
        if dimVal == 2
            hannMat = repmat(generateNDHann(2*rMaxes + mod(imgSize(1:2),2)),[1 1 imgSize(3)]);
        else
            hannMat = generateNDHann(size(procImg2));
        end
    end
    readyImg1 = procImg1.*hannMat;
    readyImg2 = procImg2.*hannMat;
    % Calculate cross correlation in fourier space
    if dimVal == 2
        fftProd = fft2(readyImg1).*conj(fft2(readyImg2));
        ccFields = ifftshift(ifftshift(ifft2(fftProd),1),2);
    else
        fftProd = fftn(readyImg1).*conj(fftn(readyImg2));
        ccFields = ifftshift(ifftn(fftProd));
    end
    % Radially average
    if dimVal == 2
        timeStore(tInd,:) = radiallyAverageMatrix(real(ccFields),binAvgSigma,1,binRange)/normFact;
    else
        timeStore(tInd,:) = radiallyAverageMatrix(real(ccFields),binAvgSigma,0,binRange)/normFact;
    end
end


%% Implement artificial 3D stack to 2D tiling
% Choose square tiling dim
tileNum = floor(sqrt(size(procImg2,3)));
selZ = 1:tileNum^2;
% Flip every other z layer lr
tiledMat1 = tileMatFunc(currTif1(:,:,selZ),tileNum);
tiledMat2 = tileMatFunc(currTif2(:,:,selZ),tileNum);

test1 = gpuArray(tiledMat1);
test2 = gpuArray(tiledMat2);
% Calculate cross-corr
% ccorrMat = conv2(tiledMat1,flip(flip(tiledMat2,1),2));

% transform2 = blockReshape2D(transform1,size(transform1,2)/2)';    
% transform3 = transform2;
% transform3(:,(size(transform3,2)/2):end) = fliplr(transform3(:,(size(transform3,2)/2):end));
% transform4 = blockReshape2D(transform3,size(transform3,2)/2)';
% tiledMat = blockReshape2D(transform4,size(currTif1,1)*tileNum);

% Shift, hann, calc corr

function tiledMat = tileMatFunc(inMat2D,tileNum)
    
inMat2D(:,:,2:2:end) = flipud(inMat2D(:,:,2:2:end));
transformMat = blockReshape2D(inMat2D,size(inMat2D,2))'; % Line up every slice
tiledMat = blockReshape2D(transformMat,size(inMat2D,1)*tileNum); % Tile

end

