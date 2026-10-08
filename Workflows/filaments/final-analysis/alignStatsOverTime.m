% Take in data from COMBINED_Fils2Aligns_InOnOut_TIFS.m, plot global
% alignment over time, along with other quantities
% 2026-08-06 - Rémi Boros

expDirs = {'Exp 1', 'Exp 2', 'Exp 3','Exp 4 - Rmin Redo', 'Exp 5'};

for index = 1:numel(expDirs)
% filStatsDir = fullfile('<redacted original absolute path>',expDirs{index},'6 Filament Data\AlignmentData - Fils2Aligns_TIFS');
filStatsDir = fullfile('Session 88',expDirs{index},'6 Filament Data\AlignmentData - Fils2Aligns_TIFS');
filStatsName = 'Filament Statistics %03i.mat';

selTimes = 1:57;
timeStr = 'Frame';

%% Concatenate data over time, then save in a single table
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    load(fullfile(filStatsDir,sprintf(filStatsName,currT)));
    rp3D.(timeStr) = repmat(currT,size(rp3D,1),1);
    if tInd == 1
        totTable = rp3D;
    else
        totTable = vertcat(totTable,rp3D);
    end
end
save(fullfile(filStatsDir,'FilamentStats_Concat.mat'),'totTable');

end
%% 
storeVals = zeros(numel(selTimes), numel(expDirs));
for index = 1:numel(expDirs)
% Load data
% filStatsDir = fullfile('<redacted original absolute path>',expDirs{index},'6 Filament Data\AlignmentData - Fils2Aligns_TIFS');
filStatsDir = fullfile('Session 88',expDirs{index},'6 Filament Data\AlignmentData - Fils2Aligns_TIFS');
load(fullfile(filStatsDir,'FilamentStats_Concat.mat'),'totTable');

% 2D order parameter
% Each filament has isosurface gradient sampled at CoM
% The product n . g calculated at each filament CoM is cos(theta)
% where theta is the angle difference between the filament alignment and
% surface normal at nearest object surface
% Alignment is then (n . g)^2 - 1/2 for 2D angles
% First, filter out small and non-elongated filaments
% Second, filter out filaments that point too far along z
% Third, calculate 2D dot product between remaining fils and iso-gradients
% Fourth, report mean 2D alignment
% Later, bin alignments, then plot angle distributions acos(binEdges)
% Time independent filters

thetaStr = 'theta3D';   dotStr = 'dot3D';
lenStr = 'AniLengths'; arStr = 'AniAspectRatios'; 
lenStr2 = 'Lengths'; arStr2 = 'AspectRatios'; 
comStr = 'Centroids'; rStr = 'DeltaR';
iooStr = 'inOnOutInd';  dirsStr = 'AniDirectors'; gradStr = 'distGrads';

% Cutoffs for filters
arCut = 1.1;
lenCut = 1.5;
iooVal = 170;
zCut = 0.5;
rBnd = [0 -10];

% Prep data
% Load directors and gradients at CoMs
rodDirs = [totTable.(dirsStr)]; 
gradDirs = [totTable.(gradStr)];
% Normalize directors in 2D and 3D
normFils = getUnitVecs(rodDirs(:,1:3));
normGrads = getUnitVecs(gradDirs(:,1:3));
normFils2D = getUnitVecs(rodDirs(:,1:2));
normGrads2D = getUnitVecs(gradDirs(:,1:2));
% Get 2D dot products in x-y plane
dotFN2D = dot(normFils2D,normGrads2D,2);

% Define filter logic
arLogic = totTable.(arStr) > arCut;
lenLogic = totTable.(lenStr) > lenCut;
iooLogic = totTable.(iooStr) == iooVal;
rLogic = (totTable.(rStr) >= min(rBnd)) & (totTable.(rStr) <= max(rBnd));
% Filter out z
zLogic = normFils(:,3) < zCut;

for tInd = 1:numel(selTimes)
    
    currT = selTimes(tInd);
    % Filter filaments
    tLogic = totTable.(timeStr) == currT;
    % totLogic = tLogic & arLogic & lenLogic & iooLogic & zLogic;
    totLogic = tLogic & arLogic & lenLogic & rLogic & zLogic;
    filt2D = dotFN2D(totLogic);
    storeVals(tInd,index) = mean((2*(filt2D).^2 - 1));
end

end

%% plot all avg aligns with tflips
tFlips = [30 27 24 19 28];
deltaT = 0.5;

figure
for index = 1:numel(tFlips)

    scatter(deltaT*(selTimes-tFlips(index)),storeVals(:,index),'filled');
    hold on

end
box on
xlabel('Time (min)')
ylabel('Avg. Align')
set(gca,'FontSize',15)
ylim([-.2 1])
legend(expDirs)


%% histogram of angles
    % Bin dot products
    [binVals,binEdges] = histcounts(filt2D,-1:.02:1);
    % acos(bin edges)
    acosBins = acos(binEdges);
    % Plot bin values vs acos(edges)
    figure
    scatter(bndmod(acosBins(2:end),-pi/2,pi/2),binVals,'filled');
    % Vs. just bin acos(dot prods 2D)
    figure
    histogram(bndmod(acos(filt2D),-pi/2,pi/2),40)


%%
% Bin dot products
[a,b,c] = histcounts(abs(isodot3D(totLogic)),40);
% acos(bin edges)
acosBins = acos(b);
% Plot bin values vs acos(edges)
figure
plot(acosBins(2:end),a);


figure
histogram(isodot3DA(totLogic),40)
hold on
histogram(isodot3D(totLogic),40)
figure
histogram(isotheta(totLogic),40)
hold on
histogram(isothetaA(totLogic),40)

figure
histogram(acos(isodot3DA(totLogic)))
hold on
histogram(acos(isodot3D(totLogic)))




test = table2array(totTable(tLogic,lenStr));
test2 = table2array(totTable(tLogic,lenStr2));
% sum((test>lenCut))/numel(test)



