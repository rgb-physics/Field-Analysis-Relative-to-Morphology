function tests = testVectorFieldSampling

farmRoot = fileparts(mfilename('fullpath'));
while ~isfile(fullfile(farmRoot, 'farmSetup.m'))
    farmParent = fileparts(farmRoot);
    if strcmp(farmParent, farmRoot), error('farm:Setup', 'Cannot locate farmSetup.m above this file.'); end
    farmRoot = farmParent;
end
addpath(farmRoot);
farmSetup('IncludeExamples', true, 'IncludeTests', true);

tests = functiontests(localfunctions);
end
function setupOnce(~)
folder = fileparts(mfilename('fullpath')); root = fullfile(folder,'..','..','..');
for api = {'ObjectRelativeProfiles','ObjectGeometry','SharedUtilities'}
    addpath(fullfile(root,'APIs',api{1},'src'));
end
end
function testOpposingVectors(testCase)
f = struct('X',[3 -3],'Y',[4 -4]);
t = farmQueryVectorField(f,[1 2], ...
    {'MeanVector','MagnitudeOfMean','MeanMagnitude','RMSMagnitude'}, ...
    struct('ComponentNames',{{'X','Y'}},'FieldName','Velocity'));
verifyEqual(testCase,t.Velocity_MeanVector,[0 0]);
verifyEqual(testCase,t.Velocity_MagnitudeOfMean,0);
verifyEqual(testCase,t.Velocity_MeanMagnitude,5); verifyEqual(testCase,t.Velocity_RMSMagnitude,5);
end
function testIndependentComponentsAndPairValidity(testCase)
f = struct('X',[1 NaN 3 5],'Y',[2 4 Inf 10],'Z',[3 6 9 -Inf]);
t = farmQueryVectorField(f,1:4,'all', ...
    struct('ComponentNames',{{'X','Y','Z'}}));
verifyEqual(testCase,t.Vector_MeanVector,[3 16/3 6],'AbsTol',1e-12);
verifyEqual(testCase,t.Vector_X_NaNCount,1); verifyEqual(testCase,t.Vector_Y_PositiveInfCount,1);
verifyEqual(testCase,t.Vector_Z_NegativeInfCount,1);
verifyEqual(testCase,t.Vector_CompleteVectorCount,1); verifyEqual(testCase,t.Vector_IncompleteVectorCount,3);
verifyEqual(testCase,t.Vector_MeanMagnitude,sqrt(14),'AbsTol',1e-12);
verifyEqual(testCase,t.Vector_CovariancePairCounts{1},[3 2 2;2 3 2;2 2 3]);
verifyEqual(testCase,t.Vector_Covariance{1}(1,2),16);
end
function testKnownCovariance(testCase)
f = struct('X',[1 2 3],'Y',[2 4 6]);
t = farmQueryVectorField(f,1:3,{'Covariance'}, ...
    struct('ComponentNames',{{'X','Y'}}));
verifyEqual(testCase,t.Vector_Covariance{1},[1 2;2 4],'AbsTol',1e-12);
t = farmQueryVectorField(f,1:3,{'Covariance'}, ...
    struct('ComponentNames',{{'X','Y'}},'VarianceNormalization',1));
verifyEqual(testCase,t.Vector_Covariance{1},[1 2;2 4]*2/3,'AbsTol',1e-12);
end
function testEmptyZeroAndExplicitOrder(testCase)
f = struct('X',[0 2],'Y',[0 4]);
t = farmQueryVectorField(f,[],{'MeanVector','MeanMagnitude'}, ...
    struct('ComponentNames',{{'Y','X'}}));
verifyTrue(testCase,all(isnan(t.Vector_MeanVector))); verifyEqual(testCase,t.Vector_CompleteVectorCount,0);
t = farmQueryVectorField(f,1,{'MeanVector','MeanMagnitude'}, ...
    struct('ComponentNames',{{'Y','X'}}));
verifyEqual(testCase,t.Vector_MeanMagnitude,0); verifyEqual(testCase,t.Vector_CompleteVectorCount,1);
t = farmQueryVectorField(f,2,{'MeanVector'}, ...
    struct('ComponentNames',{{'Y','X'}}));
verifyEqual(testCase,t.Vector_MeanVector,[4 2]);
end
function testFrameIntegration(testCase)
f = struct('VX',ones(3,4),'VY',2*ones(3,4)); supports = struct('object',true(3,4));
q = struct('Kind','vector','Name','Velocity','Support','object', ...
    'Fields',{{'VX','VY'}},'Statistics',{{'MeanMagnitude','MeanVector'}});
t = farmQueryFrame(f,supports,q);
verifyEqual(testCase,t.Velocity_MeanVector,[1 2]);
verifyEqual(testCase,t.Velocity_MeanMagnitude,sqrt(5),'AbsTol',1e-12);
end
function testMismatchAndExplicitNames(testCase)
f = struct('X',ones(3),'Y',ones(4));
verifyError(testCase,@() farmQueryVectorField(f,1,{'MeanVector'}, ...
    struct('ComponentNames',{{'X','Y'}})),'objectrelativeprofiles:GridMismatch');
verifyError(testCase,@() farmQueryVectorField(f,1), ...
    'objectrelativeprofiles:ComponentNames');
end
