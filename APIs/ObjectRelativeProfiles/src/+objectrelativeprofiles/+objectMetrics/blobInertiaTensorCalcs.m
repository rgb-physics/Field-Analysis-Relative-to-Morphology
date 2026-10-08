% Calculate local inertia tensor along skeletons of blobs, then calculate
% eigenvalues. The local structure tensor is calculated as a special case
% of the Hessian applied to a binarization of the blobs at each time.
% To be integrated with trajInfoFromOverlaps_MinAxis.m
% NOTE: blobs (and skeletons) are assumed to have cubic voxels
% Quiver test can be used to visualize principle eigenvectors projected
% onto 2D slice of blobs and skeletons.
% 2026-02-16 - Rémi Boros

% For now, load blob tifs labeled by trajectory and (optional) skeletons
% baseDir = '<redacted original absolute path>';
baseDir = 'Session 88, Exp 1';
blobDir = fullfile(baseDir,'4 Tracked Blobs');
blobName = 'E1_T%03i_trajIDs.tif';
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 88, Exp 1';
saveName = 'E1_T%03i_AniStats.mat';
selTimes = 1:50;

loadSkel = 1;
% loadSkel = 1: load skeletons from the following directory; 1 tif per time
skelDir = fullfile(blobDir,'RminStats');    skelName = 'T%03i_IDedSkelMat.tif';
% loadSkel = 0: calculate skeletons using the following parameters
gradCut = .5;   sigma = 2;  hBool = 0;
logicRescale = 2.127;

% Neighborhood radius for calculating the local structure tensor
nRad = 18;  nSigma = nRad/6;
morphKern = 2;
skelCO = 10000;     % Max number of indices per skeleton (for computation)

%%% for quiver test
quiverBool = 0;

if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

%% Iterate over time, iterate over blobs, iterate over indices of skeletons
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    ogLabels = double(tiffreadVolume(fullfile(blobDir,sprintf(blobName,currT))));
    
    % Define conversion factors and voxel scale from labels and images
        if tInd == 1
            if abs(morphKern) > 0
                morphObj = strel('sphere',abs(morphKern));
            end
        end
        % If loading skelMat
        if loadSkel == 1
            currSkel = double(tiffreadVolume(fullfile(skelDir,sprintf(skelName,currT))));
            matSize = size(currSkel);
        else
            matSize = size(ogLabels)*logicRescale;
        end
    % Rescale labels, then calculate distance transform (first time)
        currBlobs = imresize3(ogLabels,matSize,'nearest');
        dilBlobs = imdilate(currBlobs,morphObj); % used to sample blob surroundings
        % Get distance transform
        distLabs = bwdist(~logical(currBlobs));
    % Erode or dilate to smooth boundaries, if requested
        morphMat = imgaussfilt3(distLabs,abs(morphKern));     % blur distance transform
        loadLabels = consMatLnB(dilBlobs,morphMat > morphKern/2);    % threshold blurred EDT
        % If not loading skelMat
        if loadSkel == 0
            [~,currSkel] = skel3DBlobs(loadLabels,gradCut,sigma,hBool);
        end
    
    %%%%%%%%%%%%%%%%%%%%%%% this is the new stuff
    % Pad arrays - reflect blobs, 0-pad skeletons
        padBlobs = padarray(loadLabels,[nRad nRad nRad],'symmetric');
        padSkels = padarray(currSkel,[nRad nRad nRad]);
    
    % Instantiate matrices to calculate inertia tensor indices 
        if tInd == 1
            [rowMat, colMat, depMat] = ndgrid(-nRad:nRad,-nRad:nRad,-nRad:nRad); 
            % Generate tensor indices using 0-centered matrices
            ind11 = colMat.^2 + depMat.^2;
            ind22 = rowMat.^2 + depMat.^2;
            ind33 = colMat.^2 + rowMat.^2;
            ind12 = -rowMat.*colMat;
            ind23 = -depMat.*colMat;
            ind13 = -rowMat.*depMat;
        end     
    
    % Iterate through all blobs
    uniqueBlobs = unique(padBlobs(padBlobs>0));
    inertiaStore = struct();
    mat1 = [];
    mat2 = [];
    gBlurBlobs = imgaussfilt3(double(logical(padBlobs)),nSigma);
        tic
    for blobInd = 1:numel(uniqueBlobs)
        currBlob = uniqueBlobs(blobInd);
        % Identify the current skeleton
        currSkel = padSkels == currBlob;
        skelInds = find(currSkel);
        if numel(skelInds) == 0
            inertiaStore(end+1).BlobID = currBlob;    
            inertiaStore(end).SkelInd = 0;
            inertiaStore(end).SkelCoord = 0;
            inertiaStore(end).scndMoment = NaN;
            inertiaStore(end).Evals = [0 0 0];    
            inertiaStore(end).FracAni = NaN;
            inertiaStore(end).Sphericity = NaN;
        else
    % Iterate through all skeleton indices in current blob
        % Select subset of skeleton if indices exceed cutoff
            if numel(skelInds) > skelCO
    
                %%%%%%%%%%%%%%%%%%%%%%%%%% QUIVER TEST %%%%%%%%%%%%%%%%%%%%%%%%
                if quiverBool == 1
                    [rowVals,colVals,depVals] = ind2sub(size(padBlobs),skelInds);
                    zLogic = depVals == selZ;
                    subSkelPre = skelInds(zLogic);
                    subSkel = randsample(subSkelPre,skelCO);
                else
                    subSkel = randsample(skelInds,skelCO);
                end
            else
                subSkel = skelInds;
            end
            for index = 1:numel(skelInds)
                % Convert current index to coordinate in matrix
                currInd = skelInds(index);
                [row0,col0,dep0] = ind2sub(size(padBlobs),currInd);
                % Is in the subSkeleton?
                if ~ismember(currInd,subSkel)
                    continue
                else
                % add Xo-coord to each matrix
                    shftRows = rowMat + row0;
                    shftCols = colMat + col0;
                    shftDeps = depMat + dep0;
                % Subsample gauss-blurred image at current X0
                    sampInds = sub2ind(size(padBlobs),shftRows,shftCols,shftDeps);
                    gBlrSub = gBlurBlobs(sampInds);
                    % subSampBlobs = reshape(gBlurBlobs(sampInds),size(shftRows));
        
                % Construct second moment
                    m11 = sum(ind11.*gBlrSub,'all');   m22 = sum(ind22.*gBlrSub,'all');   m33 = sum(ind33.*gBlrSub,'all');
                    m12 = sum(ind12.*gBlrSub,'all');   m23 = sum(ind23.*gBlrSub,'all');   m13 = sum(ind13.*gBlrSub,'all');
                    scndM = [m11 m12 m13; ...
                             m12 m22 m23;...
                             m13 m23 m33];
                % Get eigenvalues and construct eccentricity scalar
                    % eVals = eig(scndM);
                    [eVecs,eVals] = eig(scndM);
                    eVals = sum(eVals,2);   maxInd = find(max(eVals));
                    % mat1(end+1,1:3) = [row0, col0, dep0];
                    % mat2(end+1,1:3) = eVecs(:,maxInd);
                    % fractional anisotropy
                    eMean = sum(eVals)/3;
                    FA = sqrt(3/2) * sqrt(sum((eVals - eMean).^2)) ./ sqrt(sum(eVals.^2));
                    eccent = min(abs(eVals))/max(abs(eVals));
                end
            % Store
                inertiaStore(end+1).BlobID = currBlob;    
                inertiaStore(end).SkelInd = find(ismember(skelInds,currInd));
                inertiaStore(end).SkelCoord = [row0,col0,dep0];
                inertiaStore(end).scndMoment = scndM;
                inertiaStore(end).Evals = eVals';    
                inertiaStore(end).FracAni = FA;
                inertiaStore(end).Sphericity = eccent;
            end     
        end

    end
    toc
        pause(.01)
    save(fullfile(saveDir,sprintf(saveName,currT)),'inertiaStore','nRad','nSigma',"morphKern",'skelCO');
end
%% quiver in plane
% figure
% imagesc(gBlurBlobs(:,:,selZ) - 2*logical(padSkels(:,:,selZ)));
% hold on
% quiver(mat1(:,2),mat1(:,1),mat2(:,2),mat2(:,1),.2,'ShowArrowHead','off','Color','black');
% quiver(mat1(:,2),mat1(:,1),-mat2(:,2),-mat2(:,1),.2,'ShowArrowHead','off','Color','black');
% title(sprintf('Z - %03i, Window - %02i, gBlur - %02i',selZ-nRad,nRad,nSigma))

