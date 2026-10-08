%% Fit power spectra to structure factor
% dataDir = '<redacted original absolute path>';
dataDir = 'Session 84';
dataName = 'powerSpectra_variables.mat';

selectTime =  28;

%% Load data
load(fullfile(dataDir,dataName));

%% Fit data set
close all
selectSpectrum = storeMat(:,:,selectTime);
selRange = 5:400;

testEqn = 'a*(1/(1 + (x*L)^m))';

 ft=fittype(testEqn,'independent','x');
    weights=log(1./(selectSpectrum));
    weights=weights-min(weights);
    fo = fitoptions('Method','NonlinearLeastSquares',...
               'Lower',[0,10^6,-10],...
               'Upper',[Inf,10^25,10],...
               'StartPoint',[40,10^8.5,5],...
               'Weights',weights(selRange));
    f=fit(scaledK(selRange)',selectSpectrum(selRange),ft,fo)
    % f=fit(w(5:end),fftcorrelations(5:cutoff2,ino),ft,fo);
loglog(scaledK(selRange),f.a*(1./(1+(scaledK(selRange)*f.L).^f.m)))
hold on
loglog(scaledK(selRange),selectSpectrum(selRange));

loglog(scaledK(selRange),2.87*10^8*(1./(1+(scaledK(selRange)*36.66).^3.7)),'--')

% test = fit(scaledK(1:end-1)', selectSpectrum,testEqn);


