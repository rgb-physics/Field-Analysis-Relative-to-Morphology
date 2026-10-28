function tests = testSurfaceSkeletonWorkflow
% Focused synthetic checks; real-data scientific validation is separate.
tests = functiontests(localfunctions);
end

function setupOnce(~)
root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
addpath(root); farmSetup('IncludeTests',true);
end

function testHistoricalDefaultAndAxes(t)
rng(7); mask = rand(17,19,11)>.55;
[a,b] = farmSkel3Dfrom2D(mask); [ra,rb] = historical(mask);
verifyEqual(t,a,ra); verifyEqual(t,b,rb);
for axisName = 'XY'
    dim = find('YXZ'==axisName); order = [setdiff(1:3,dim,'stable'),dim];
    [ra,rb] = historical(permute(mask,order));
    [a,b] = farmSkel3Dfrom2D(mask,axisName);
    verifyEqual(t,a,ipermute(ra,order)); verifyEqual(t,b,ipermute(rb,order));
end
end

function testPopulationReproducibleAndZeroCutoff(t)
mask = false(15,17,9); mask(3:13,4:14,3:7)=true;
[a,b] = farmSkel3Dfrom2D(mask);
rng(42); first = farmSkel3DPop(mask,.5,0,a,b);
rng(42); second = farmSkel3DPop(mask,.5,0,a,b);
verifyEqual(t,first,second); verifyTrue(t,all(first(b)==1));
verifyFalse(t,any(first(~a)~=0));
% Positive cutoff preserves the historical random candidate calculation.
rng(24); got = farmSkel3DPop(mask,.5,2,a,b);
rng(24); candidates = find(bwdist(~mask).*a>=2);
n = min(numel(candidates),round(min(numel(candidates),nnz(b)*.5)));
expected = zeros(size(mask)); expected([candidates(randperm(numel(candidates),n));find(b)])=1;
verifyEqual(t,got,expected);
end

function testCoordinateMappingAndRasterReuse(t)
mask = false(7,8,5); mask(2,4,3)=true; mask(6,7,4)=true;
[points,indices,info] = farmMaskToPoints(mask,'Spacing',[2 3 5],'Origin',[-4 10 20]);
[r,c,z] = ind2sub(size(mask),indices);
verifyEqual(t,points,[-4 10 20]+([c r z]-1).*[3 2 5]);
voxel = (points-info.Origin)./info.Spacing([2 1 3])+1;
back = farmPointsToMatrix(voxel,struct('Size',size(mask)));
verifyEqual(t,back,mask);
[empty,ids] = farmMaskToPoints(false(2,3,4));
verifySize(t,empty,[0 3]); verifyEmpty(t,ids);
end

function testMedialSlabAndConvergence(t)
mask = false(35,37,15); mask(3:33,3:35,4:12)=true;
[surface,info] = farmMedialSurface(mask);
verifyTrue(t,info.Converged); verifyEqual(t,info.Method,'P-6-SI-2');
verifyFalse(t,any(surface(~mask))); verifyLessThan(t,nnz(surface),nnz(mask)/2);
verifyEqual(t,bwconncomp(surface,26).NumObjects,1);
% Away from side faces, the retained sheet is centered and one voxel thick.
verifyTrue(t,all(squeeze(sum(surface(10:25,10:27,:),3))==1,'all'));
central = surface(10:25,10:27,:); [~,~,cz] = ind2sub(size(central),find(central));
verifyEqual(t,unique(cz),8);
verifyEqual(t,farmMedialSurface(surface),surface);
[partial,limited] = farmMedialSurface(mask,'MaxIterations',1);
verifyFalse(t,limited.Converged); verifyGreaterThan(t,nnz(partial),nnz(surface));
end

function testMedialVariableThicknessAndCurvedShell(t)
[y,x,z] = ndgrid(1:31,1:35,1:23);
width = 1+floor((x-1)/12);
mask = x>=3 & x<=33 & y>=3 & y<=29 & abs(z-12)<=width;
surface = farmMedialSurface(mask);
verifyEqual(t,bwconncomp(surface,26).NumObjects,1);
verifyTrue(t,all(any(surface(8:23,8:28,:),3),'all'));
% A cylindrical shell has overlap in XY projection and a nontrivial tunnel.
radius = sqrt((x-18).^2+(z-12).^2);
shell = radius>=7 & radius<=10 & y>=5 & y<=27;
medial = farmMedialSurface(shell);
verifyFalse(t,any(medial(~shell)));
verifyEqual(t,bwconncomp(medial,26).NumObjects,bwconncomp(shell,26).NumObjects);
verifyEqual(t,cubicalEuler(medial),cubicalEuler(shell));
verifyLessThan(t,nnz(medial),nnz(shell));
end

function testMedialEmptyThinFullAndAnisotropy(t)
verifyEqual(t,farmMedialSurface(false(4,5,6)),false(4,5,6));
thin = false(11,12,7); thin(3:9,3:10,4)=true;
verifyEqual(t,farmMedialSurface(thin),thin);
[full,info] = farmMedialSurface(true(9,11,7));
verifyTrue(t,info.Converged); verifyGreaterThan(t,nnz(full),0);
verifyError(t,@() farmMedialSurface(thin,'Spacing',[1 1 2]),'objectgeometry:SurfaceAnisotropy');
verifyError(t,@() farmMedialSurface(thin,'MaxIterations',NaN),'objectgeometry:SurfaceIterations');
end

function testNormalsObliqueAndInsufficient(t)
[u,v] = ndgrid(-5:.5:5,-5:.5:5);
points = [u(:),v(:),.3*u(:)-.4*v(:)];
queries = (1:7:size(points,1)).';
[normals,info] = farmEstimateSurfaceNormals(points,queries,'Radius',2,'MaxNeighbors',24);
truth = [-.3 .4 1]; truth=truth/norm(truth);
verifyTrue(t,all(info.Valid)); verifyLessThan(t,max(1-abs(normals*truth.')),1e-12);
verifyLessThanOrEqual(t,max(info.NeighborCount),24);
[bad,badInfo] = farmEstimateSurfaceNormals(points,queries,'Radius',.01);
verifyTrue(t,all(isnan(bad),'all')); verifyFalse(t,any(badInfo.Valid));
line = [(1:8).',zeros(8,2)];
verifyTrue(t,all(isnan(farmEstimateSurfaceNormals(line,1:8,'Radius',10)),'all'));
[empty,~] = farmEstimateSurfaceNormals(points,[],'Radius',2); verifySize(t,empty,[0 3]);
end

function testGeometryCollectionMedialIntegration(t)
mask=false(31,33,15); mask(3:14,3:14,4:12)=true; mask(19:28,20:30,4:12)=true;
geometry=farmGenerateGeometry(mask,'skeleton',struct('Method','medial-surface'));
rendered=false(size(mask));
for rInd=1:numel(geometry.Records)
    rendered(geometry.Records(rInd).Indices)=true;
end
verifyEqual(t,rendered,farmMedialSurface(mask));
verifyEqual(t,numel(geometry.Records),2);
verifyEqual(t,geometry.Grid.Size,size(mask));
verifyError(t,@() farmGenerateGeometry(mask,'skeleton', ...
    struct('Method','medial-surface','SurfaceMaxIterations',1)), ...
    'objectgeometry:SurfaceNotConverged');
end

function testDefaultMaskSignAndPlyReadback(t)
mask=false(13,13,9); mask(2:12,2:12,3:7)=true;
[row,col]=ndgrid(4:10,4:10);
source=sub2ind(size(mask),row(:),col(:),6*ones(numel(row),1));
points=[col(:),row(:),6*ones(numel(row),1)];
normals=repmat([0 0 -1],size(points,1),1);
[oriented,info]=farmOrientSurfaceNormals(points,normals,'Radius',1.5, ...
    'SourceMask',mask,'SourceIndices',source);
verifyTrue(t,all(info.Referenced)); verifyTrue(t,all(oriented(:,3)>0));
file=[tempname '.ply']; cleanup=onCleanup(@() delete(file));
farmWritePointPly(file,points,'Normals',oriented);
cloud=pcread(file);
verifyEqual(t,double(cloud.Location),points,'AbsTol',1e-6);
verifyEqual(t,double(cloud.Normal),oriented,'AbsTol',1e-6);
end

function testSpatialOrientationCurvesPastHalfTurn(t)
[theta,z] = ndgrid(linspace(0,1.7*pi,90),0:.5:2);
points = [10*cos(theta(:)),10*sin(theta(:)),z(:)];
truth = [cos(theta(:)),sin(theta(:)),zeros(numel(z),1)];
rng(8); normals = truth.*(2*(rand(size(theta(:)))>.5)-1);
[oriented,info] = farmOrientSurfaceNormals(points,normals,'Radius',1.1, ...
    'MaxNeighbors',12,'ReferenceDirections',truth);
verifyEqual(t,numel(unique(info.Group)),1);
verifyGreaterThan(t,min(sum(oriented.*truth,2)),.999);
verifyTrue(t,all(info.Referenced));
end

function testSpatialOrientationDoesNotBridgeParallelFolds(t)
[x,y] = ndgrid(0:4,0:4); base = [x(:),y(:),zeros(numel(x),1)];
points = [base;base+[0 0 .2]];
normals = repmat([0 0 1],size(points,1),1); normals(2:2:end,:)=-normals(2:2:end,:);
refs = [repmat([0 0 1],25,1);repmat([0 0 -1],25,1)];
[oriented,info] = farmOrientSurfaceNormals(points,normals,'Radius',1.1, ...
    'MaxNeighbors',12,'MaxNormalOffset',.15,'ReferenceDirections',refs);
verifyEqual(t,numel(unique(info.Group)),2);
verifyGreaterThan(t,min(sum(oriented.*refs,2)),.999);
normals(1,:)=NaN;
[oriented,info] = farmOrientSurfaceNormals(points,normals,'Radius',1.1);
verifyEqual(t,info.Group(1),0); verifyTrue(t,all(isnan(oriented(1,:))));
end

function testBoundarySeedDirections(t)
mask = false(11,13,9); mask(2:10,2:12,3:7)=true;
indices = sub2ind(size(mask),[6;6],[7;7],[4;6]);
[refs,info] = farmSurfaceBoundaryDirections(mask,indices);
verifyEqual(t,refs,[0 0 -1;0 0 1]); verifyEqual(t,info.Metric,'voxel-Euclidean');
refs = farmSurfaceBoundaryDirections(true(3,3,3),14);
verifyEqual(t,norm(refs),1,'AbsTol',1e-12);
end

function testTemporalMatchingRotationAndWholeGroupFlip(t)
previous = [0 0 0;1 0 0;0 2 0;2 2 0];
rotation = [0 0 1;0 1 0;-1 0 0]; translation=[4 7 2];
current = previous*rotation.'+translation; order=[3 1 4 2]; current=current(order,:);
matches = farmMatchSurfaceFrames(current,previous,'MaxDistance',.01, ...
    'Rotation',rotation,'Translation',translation);
verifyEqual(t,matches.PreviousIndices,order.');
pn = repmat([0 0 1],4,1); normals=-pn*rotation.';
[aligned,info] = farmAlignSurfaceNormalSigns(normals,pn,ones(4,1),matches);
verifyEqual(t,aligned,-normals); verifyTrue(t,info.Resolved); verifyTrue(t,info.Flipped);
matches.CurrentIndices=matches.CurrentIndices(1); matches.PreviousIndices=matches.PreviousIndices(1);
[unaligned,info] = farmAlignSurfaceNormalSigns(normals,pn,ones(4,1),matches);
verifyEqual(t,unaligned,normals); verifyFalse(t,info.Resolved);
end

function testTemporalConflictAndEmptyFrames(t)
matches=struct('CurrentIndices',(1:4).','PreviousIndices',(1:4).');
normals=repmat([0 0 1],4,1); previous=normals; previous(3:4,:)=-previous(3:4,:);
[aligned,info]=farmAlignSurfaceNormalSigns(normals,previous,ones(4,1),matches);
verifyEqual(t,aligned,normals); verifyFalse(t,info.Resolved);
matches=farmMatchSurfaceFrames(zeros(0,3),zeros(0,3),'MaxDistance',1);
verifyEmpty(t,matches.CurrentIndices);
[aligned,info]=farmAlignSurfaceNormalSigns(zeros(0,3),zeros(0,3),zeros(0,1),matches);
verifySize(t,aligned,[0 3]); verifyEmpty(t,info.Group);
end

function testPlyCoordinatesNormalsAndHistoricalScaling(t)
file=[tempname '.ply']; cleanup=onCleanup(@() delete(file));
points=[1 2 3;4 5 6];
farmWritePointPly(file,points,'Normals',[0 0 2;0 3 0]);
text=fileread(file); verifyTrue(t,contains(text,'element vertex 2'));
verifyTrue(t,contains(text,'element face 0')); verifyTrue(t,contains(text,'property double nx'));
body=extractAfter(text,sprintf('end_header\n')); values=sscanf(body,'%f',[6 Inf]).';
verifyEqual(t,values,[points,[0 0 1;0 1 0]]);
mask=false(3,4,5); mask(2,3,4)=true;
farmLogic2Ply(mask,file,[2 3 4]); text=fileread(file);
values=sscanf(extractAfter(text,sprintf('end_header\n')),'%f',[3 Inf]).';
verifyEqual(t,values,[6 6 16]);
farmWritePointPly(file,zeros(0,3)); verifyTrue(t,contains(fileread(file),'element vertex 0'));
end

function [a,b] = historical(mask)
d=size(mask); first=reshape(bwskel(reshape(mask,[d(1)*d(2),d(3)])),d);
second=permute(reshape(bwskel(reshape(permute(mask,[2 1 3]), ...
    [d(1)*d(2),d(3)])),[d(2),d(1),d(3)]),[2 1 3]);
a=first|second; b=first&second;
end

function e = cubicalEuler(mask)
% Euler characteristic of the union of closed foreground voxel cubes.
d=size(mask); vertices=false(d+1);
for i=0:1
    for j=0:1
        for k=0:1
            vertices((1:d(1))+i,(1:d(2))+j,(1:d(3))+k)= ...
                vertices((1:d(1))+i,(1:d(2))+j,(1:d(3))+k)|mask;
        end
    end
end
edges=0; faces=0;
for axis=1:3
    other=setdiff(1:3,axis); edgeSize=d+1; edgeSize(axis)=d(axis);
    edge=false(edgeSize);
    for i=0:1
        for j=0:1
            sub={1:d(1),1:d(2),1:d(3)};
            sub{other(1)}=sub{other(1)}+i; sub{other(2)}=sub{other(2)}+j;
            edge(sub{:})=edge(sub{:})|mask;
        end
    end
    edges=edges+nnz(edge); faceSize=d; faceSize(axis)=d(axis)+1;
    face=false(faceSize);
    for i=0:1
        sub={1:d(1),1:d(2),1:d(3)}; sub{axis}=sub{axis}+i;
        face(sub{:})=face(sub{:})|mask;
    end
    faces=faces+nnz(face);
end
e=nnz(vertices)-edges+faces-nnz(mask);
end
