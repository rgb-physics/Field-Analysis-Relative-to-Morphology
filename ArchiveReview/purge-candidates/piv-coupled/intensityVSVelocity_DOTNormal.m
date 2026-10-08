% Compare intensities on sheet surfaces to degree of velocity alignment
% with surface normal.
% Requires calculation of mesh, velocity fields from PIV on mesh surfaces,
% intensities sampled on vertices, and vertex normals.
% 2025-07-30 - Rémi Boros
% Vertex coordinates are (x,y,z) in microns (expected)
% meshData = '<redacted original absolute path>';
meshData = 'Session 28, Exp 6';
meshName = 'DataStoreStructT%03i_scatInt_Bot.mat';
% pivDir = '<redacted original absolute path>';
pivDir = 'Session 28, Exp 6';
pivName = 't%03i_heightDiffs_meshes.mat';

% Load matrix sizes from metadata
load(fullfile(pivDir,'metadata.mat'));

selTimes = 150:200;
structVar = 'currStruct';
normSign = -1;      % direction of surface normal

timeColorArray = flipud(othercolor('BuDRd_18',200));
%% 
% saveDir = '<redacted original absolute path>';
saveDir = 'Session 28, Exp 6';
saveName = 'T%03i.tif';
if ~exist(saveDir,'dir')
    mkdir(saveDir);
end

xBnds = [0 250];
yBnds = [0 250];
zBnds = [140 90];

for tInd = 1:numel(selTimes)
% tInd = 1;
    currT = selTimes(tInd);
    
    % Load data
    currStruct = load(fullfile(meshData,sprintf(meshName,currT)),structVar).(structVar);
    load(fullfile(pivDir,sprintf(pivName,currT)));
    currV = currStruct.v;   currF = currStruct.f;
    
    % Get vertex normals
    vtxNormals = per_vertex_normals(currV, currF);  % normalized
    if mean(vtxNormals(:,3))*normSign < 0 
        vtxNormals = -vtxNormals;
    end
    
    % Approximate components of velocity on vertices
    % scIntVX = scatteredInterpolant(cenCoords(:,1),cenCoords(:,2),cenCoords(:,3),allShifts(:,1));
    % scIntVY = scatteredInterpolant(cenCoords(:,1),cenCoords(:,2),cenCoords(:,3),allShifts(:,2));
    % scIntVZ = scatteredInterpolant(cenCoords(:,1),cenCoords(:,2),cenCoords(:,3),allShifts(:,3));
    % xOnV = scIntVX(currV(:,1),currV(:,2),currV(:,3));
    % yOnV = scIntVY(currV(:,1),currV(:,2),currV(:,3));
    % zOnV = scIntVZ(currV(:,1),currV(:,2),currV(:,3));
    
    % Smoother fields than using all (zeros)
    scIntVX = scatteredInterpolant(validCenCoords(:,1),validCenCoords(:,2),validCenCoords(:,3),shifts(:,1));
    scIntVY = scatteredInterpolant(validCenCoords(:,1),validCenCoords(:,2),validCenCoords(:,3),shifts(:,2));
    scIntVZ = scatteredInterpolant(validCenCoords(:,1),validCenCoords(:,2),validCenCoords(:,3),shifts(:,3));
    xOnVrt = scIntVX(currV(:,1),currV(:,2),currV(:,3));
    yOnVrt = scIntVY(currV(:,1),currV(:,2),currV(:,3));
    zOnVrt = scIntVZ(currV(:,1),currV(:,2),currV(:,3));
    % Combine
    velOnVrt = [xOnVrt, yOnVrt, zOnVrt];
    velMags = sqrt(sum(velOnVrt.^2,2));
    velVrtNorm = velOnVrt./velMags;
    
    % Dot with vertex normals
    velDotNorm = sum(vtxNormals.*velVrtNorm,2);
    
    % Plot
    % Triangulate, project fields onto surface
    % Correct sheet direction, if desired 
    if zBnds(1) > zBnds(2)
        if tInd == 1
            meanZ = mean(currV(:,3));
        end
        currV(:,3) = -currV(:,3) + 2*meanZ;
    end

    figure
    % currField = zOnV - zOnV2;
    currField = velDotNorm;
    tri = triangulation(currF,currV);
    trisurf(tri, (currField(:)), 'edgecolor','none');
    axis equal
    if zBnds(1) > zBnds(2)
        zlim(circshift(zBnds,1));
        zt = get(gca, 'ZTick');
        set(gca, 'ZTick',zt, 'ZTickLabel',fliplr(zt))
    else
        zlim(zBnds)
    end
    xlim(xBnds)
    ylim(yBnds)
    colorbar
    colormap(timeColorArray);
    set(gca, 'FontSize',15);
    exportgraphics(gca,fullfile(saveDir,sprintf(saveName,currT)));
    close()
% colorbar
end

%% Compare intensity on vertices to velN
% Collate intensities and normals 
int2uM = 41/10000;
allInts = []; allVNs = [];
allMags = []; allTs = [];
meanVel = zeros(numel(selTimes),3);
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
        
    % Load data
    currStruct = load(fullfile(meshData,sprintf(meshName,currT)),structVar).(structVar);
    load(fullfile(pivDir,sprintf(pivName,currT)));
    
    % Get vertex normals
    currV = currStruct.v;   currF = currStruct.f;
    vtxNormals = per_vertex_normals(currV, currF);  % normalized
    if mean(vtxNormals(:,3))*normSign < 0 
        vtxNormals = -vtxNormals;
    end
    
    % Smoother fields than using all (zeros) - use validCenCoords, not all
    scIntVX = scatteredInterpolant(validCenCoords(:,1),validCenCoords(:,2),validCenCoords(:,3),shifts(:,1));
    scIntVY = scatteredInterpolant(validCenCoords(:,1),validCenCoords(:,2),validCenCoords(:,3),shifts(:,2));
    scIntVZ = scatteredInterpolant(validCenCoords(:,1),validCenCoords(:,2),validCenCoords(:,3),shifts(:,3));
    xOnVrt = scIntVX(currV(:,1),currV(:,2),currV(:,3));
    yOnVrt = scIntVY(currV(:,1),currV(:,2),currV(:,3));
    zOnVrt = scIntVZ(currV(:,1),currV(:,2),currV(:,3));
    % Combine velocities
    velOnVrt = [xOnVrt, yOnVrt, zOnVrt];
    velMags = sqrt(sum(velOnVrt.^2,2));
    velVrtNorm = velOnVrt./velMags;
    
    % Dot with vertex normals
    velDotNorm = sum(vtxNormals.*velVrtNorm,2);
    currInts = currStruct.intV*int2uM;

    % Append
    allInts = [allInts; currInts];
    allVNs = [allVNs; velDotNorm];
    allMags = [allMags; velMags];
    allTs = [allTs; repmat(currT,numel(currInts),1)];
    meanVel(tInd,:) = mean(velOnVrt);
end

%% histogram magic
Iedges = 35:80;
VNedges = -1:.05:1;
subIInds = 1:numel(Iedges);

[N,~,~,binI,binVN] = histcounts2(allInts,allVNs,Iedges,VNedges);

figure
meanVNs = [];
stdVNs = [];
for index = subIInds
    currI = Iedges(index);
    valInds = binI == index;
    meanVNs(end+1) = mean(allVNs(valInds));
    stdVNs(end + 1) = std(allVNs(valInds));
    histogram(allVNs(valInds),VNedges)
    [tempN,tempEdges] = histcounts(allVNs(valInds),VNedges);
    % sum(tempN.*(tempEdges(1:(end-1))) + tempEdges(2:end)/2)
    hold on
end

%% Look at mean order over I over time
for index = 1:numel(subIInds)
    valInds = binI == index;
    if sum(valInds) > 0
    figure
    title(sprintf('Intensity: %i',Iedges(index)));
        for tInd = 1:numel(selTimes)
            
            currT = selTimes(tInd);
            tLogic = allTs == currT;
            histogram(allVNs(valInds & tLogic),VNedges)
            hold on
            
    
        end
    end

end

%% total intensity over time
totInts = zeros(size(selTimes));
for tInd = 1:numel(selTimes)

    currT = selTimes(tInd);
    tLogic = allTs == currT;
    totInts(tInd) = sum(allInts(tLogic));

end
%% Pick time - align vs I
% figure
% saveDir1 = '<redacted original absolute path>';
saveDir1 = 'Session 28, Exp 6';
if ~exist(saveDir1,'dir')
    mkdir(saveDir1);
end
numCutOff = 750;

for tInd = 1:numel(selTimes)
% subTs = 150:177;
% tLogic = ismember(allTs, subTs);
tLogic = allTs == currT;
currT = selTimes(tInd);
% magLogic = allMags > 0.1;
meanVNs = [];      stdVNs = [];
counts  = [];
for index = subIInds
    currI = Iedges(index);
    valInds = (binI == index) & tLogic;
    % valInds = (binI == index) & tLogic & magLogic;
    counts(end+1) = sum(valInds);
    meanVNs(end+1) = mean(allVNs(valInds));
    stdVNs(end + 1) = std(allVNs(valInds));
    % histogram(allVNs(valInds),VNedges)
    % [tempN,tempEdges] = histcounts(allVNs(valInds),VNedges);
    % sum(tempN.*(tempEdges(1:(end-1))) + tempEdges(2:end)/2)
    hold on
end

validInds = counts > numCutOff;

figure
errorbar(Iedges(validInds),meanVNs(validInds),stdVNs(validInds));
hold on
highInds = (meanVNs > 0)&(validInds);
lowInds = (meanVNs <= 0)&(validInds);
scatter(Iedges(highInds),meanVNs(highInds),20,'red','filled');
scatter(Iedges(lowInds),meanVNs(lowInds),20,'black','filled');
xlim([35 80])
ylim([-1 1])
% title(sprintf('Frame: %i',currT))
exportgraphics(gcf,fullfile(saveDir1,sprintf('Time%03i.tif',currT)));
close();
% scatter(Iedges,test)
end
%% Look at distribution at select I over time
figure
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    tLogic = allTs == currT;
    valInds = binI == index;
    histogram(allVNs(valInds&tLogic),VNedges)
    hold on
    pause(.1)
end

%% Mean velocity mag at each time
figure
meanMags = zeros(size(selTimes));
stdMags = meanMags;
for tInd = 1:numel(selTimes)
    currT = selTimes(tInd);
    tLogic = allTs == currT;
    meanMags(tInd) = mean(allMags(tLogic));
    stdMags(tInd)  = std(allMags(tLogic));
end

%%
[meanVNs,stdVNs] = max(movmean(a,4),[],1);

manVlnPlot(b(10),a(:,10),b,2);


% [V2F, F2V] = meshAveragingOperators(currF, currV);
% [vF_n, vF_t] = resolveTangentNormalVector(currF, currV, V2F*velOnVrt) ;
% [vnF_n, vnF_t] = resolveTangentNormalVector(currF, currV, V2F*velVrtNorm) ;

% velDotNorm



%%


% Test - quiver
figure
scatter3(currV(:,1),currV(:,2),currV(:,3),3,'blue','filled');
hold on
quiver3(currV(:,1),currV(:,2),currV(:,3),vtxNormals(:,1),vtxNormals(:,2),vtxNormals(:,3),2);
% quiver3(currV(:,1),currV(:,2),currV(:,3),xOnV,yOnV,zOnV,15,'magenta');
% quiver3(currV(:,1),currV(:,2),currV(:,3),xOnV2,yOnV2,zOnV2,15,'green');
axis equal
% quiver3(cenCoords(:,1),cenCoords(:,2),cenCoords(:,3),allShifts(:,1),allShifts(:,2),allShifts(:,3),15);

%% 



% Triangulate, project fields onto surface
figure
% currField = zOnV - zOnV2;
currField = velDotNorm;
tri = triangulation(currF,currV);
trisurf(tri, (currField(:)), 'edgecolor','none');
axis equal
colormap(timeColorArray);
colorbar

% unqCenX = unique(cenCoords(:,1))';
% unqCenY = unique(cenCoords(:,2))';
% unqCenZ = unique(cenCoords(:,3))';
% [xVals,yVals,zVals] = ndgrid(unqCenX,unqCenY,unqCenZ);
% grIntVX = griddedInterpolant(xVals,yVals,zVals,allShifts(:,1));



