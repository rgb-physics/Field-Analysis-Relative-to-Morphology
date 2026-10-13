function report = auditFilamentOrientation()
%AUDITFILAMENTORIENTATION Compare formulas found in FARM historical workflows.
% Run report = auditFilamentOrientation(); requires base MATLAB only.
% Does not execute historical scripts or modify repository files. Formula
% checks do not establish image-axis conventions; an image test follows below.
wrap = @(a) mod(a+pi/2,pi)-pi/2;
angles = [0 pi/6 pi/4 pi/2 3*pi/4 pi].';
c = cos(angles);
absoluteCosine = cos(wrap(angles));
squaredCosine = c.^2;
nematic2D = cos(2*angles);
nematic3D = (3*c.^2-1)/2;
legacyTensor3D = 3*c.^2-1;
legacyRecoveredAngle = acos(sqrt(legacyTensor3D+1/3));
report = table(angles*180/pi,absoluteCosine,squaredCosine,nematic2D, ...
    nematic3D,legacyTensor3D,legacyRecoveredAngle, ...
    'VariableNames',{'AngleDegrees','AbsoluteCosine','SquaredCosine', ...
    'Nematic2D','Nematic3D','Historical3DTensor','HistoricalRecoveredAngle'});
disp(report)
tol=1e-12;
assert(max(abs(absoluteCosine-abs(c)))<tol);
assert(max(abs(nematic2D-(2*squaredCosine-1)))<tol);
assert(max(abs(legacyTensor3D-2*nematic3D))<tol);
assert(max(abs(cos(2*wrap(angles))-nematic2D))<tol);
assert(max(abs(cos(2*wrap(angles+pi))-nematic2D))<tol);
assert(max(abs((3*cos(angles+pi).^2-1)/2-nematic3D))<tol);
% Check tensor formulations directly, matching the historical source.
for i=1:numel(angles)
    n=[cos(angles(i));sin(angles(i))]; r=[1;0];
    qn=n*n'-eye(2)/2; qr=r*r'-eye(2)/2;
    assert(abs(sum(qn.*qr,'all')+1/2-squaredCosine(i))<tol);
    assert(abs(2*sum(qn.*qr,'all')-nematic2D(i))<tol);
    n=[n;0]; r=[r;0];
    qn=n*n'-eye(3)/3; qr=r*r'-eye(3)/3;
    assert(abs(3*sum(qn.*qr,'all')-legacyTensor3D(i))<tol);
end
% Explicit isotropic ensembles give zero nematic order relative to a fixed axis.
uniform2D=(0:359)'*pi/180;
assert(abs(mean(cos(2*uniform2D)))<tol);
uniform3D=[eye(3);-eye(3)];
assert(abs(mean((3*uniform3D(:,1).^2-1)/2))<tol);
% Signed acos(dot) wrapping is not invariant under reversing a director.
a=pi/6;
assert(abs(wrap(acos(cos(a)))+wrap(acos(-cos(a))))<tol);
assert(abs(wrap(acos(cos(a)))-wrap(acos(-cos(a))))>tol);
fprintf('Historical acos wrapping changes angle sign under director reversal.\n');
fprintf('Historical 3-D inverse produces complex values for known real angles.\n');
assert(~isreal(legacyRecoveredAngle));
% Averaging wrapped angles is unsafe across the periodic seam.
pair=[89;-89]*pi/180;
directorMean=0.5*atan2(mean(sin(2*pair)),mean(cos(2*pair)));
assert(abs(abs(directorMean)-pi/2)<tol);
assert(abs(mean(pair))<tol); % arithmetic mean incorrectly points horizontally
% Coordinate scaling vs covariance scaling (no image resampling).
points=[-4 -1 0;-2 1 1;0 0 -1;2 -1 1;4 1 0];
spacingXYZ=[0.2 0.4 0.8]; A=diag(spacingXYZ);
assert(norm(cov(points.*spacingXYZ)-A*cov(points)*A','fro')<tol);
fprintf('All analytical checks passed.\n');
% Optional Image Processing Toolbox checks: establish eigenvector row order
% and regionprops orientation sign using known objects, not source comments.
if exist('regionprops3','file') && exist('regionprops','file')
    vol=false(15,25,11); vol(6:8,4:22,5:7)=true;
    stats=regionprops3(vol,'EigenVectors','PrincipalAxisLength');
    director=stats.EigenVectors{1}(:,1);
    fprintf('X-long object: raw first eigenvector = [%g %g %g]\n',director);
    assert(abs(director(3))<1e-6);
    fprintf('Compare row order with the historical [2 1 3] swap before adopting it.\n');
    diagonal=false(21); diagonal(sub2ind(size(diagonal),5:17,5:17))=true;
    s=regionprops(diagonal,'Orientation');
    fprintf('Increasing-row/increasing-column line: regionprops Orientation=%g degrees\n',s.Orientation);
end
end
