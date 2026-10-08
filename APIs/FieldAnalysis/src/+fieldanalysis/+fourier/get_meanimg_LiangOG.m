clear all
close all
% FolderName='<redacted original absolute path>';
FolderName='';
% meanimg=zeros(804,804,251);
maxt=29;
% for xy=1:2
threshold=1400;
for i=1:maxt
    tic
    filename=sprintf('zstep1um_t1min_mag40x_center001_T%02d.tif',i);

    imgstack=readTifStack([FolderName filename]);
    imgstack(imgstack>threshold)=threshold;
    if (i==1)
        meanimg=imgstack;
    else
    meanimg=meanimg+imgstack;
    end
    toc
end
meanimg=meanimg./mean(meanimg,'all');
save([FolderName 'meanimg.mat'],'meanimg','-v7.3')
%%
sz=size(meanimg);
xx=(ceil(-sz(2)/2):floor(sz(2)/2)).*xypixel0;
yy=(ceil(-sz(1)/2):floor(sz(1)/2)).*xypixel0;
zz=(ceil(-sz(3)/2):floor(sz(3)/2)).*zstep0;
[xgrid,ygrid,zgrid]=meshgrid(xx,yy,zz);
% load('<redacted original absolute path>')
load('')
psfc=psf./max(psf(:))-0.24;
szp=size(psfc);
twsize=0.2;
t3=pagemtimes(tukeywin(szp(2),twsize)*tukeywin(szp(1),twsize)',permute(tukeywin(szp(3),twsize),[3 2 1]));    
xxp=(ceil(-szp(2)/2):floor(szp(2)/2)).*xypixel;
yyp=(ceil(-szp(1)/2):floor(szp(1)/2)).*xypixel;
zzp=(ceil(-szp(3)/2):floor(szp(3)/2)).*zstep;
[xpgrid,ypgrid,zpgrid]=meshgrid(xxp,yyp,zzp);
psfc2=psfc;
psft=psfc2.*t3;
psf2=interp3(xpgrid,ypgrid,zpgrid,psft,xgrid,ygrid,zgrid,'cubic',0);
psf2cut=pickcenter(psf2,10);
clear xgrid;clear ygrid;clear zgrid;clear psf2;
meanimg1=single(deconvlucy(single(meanimg),psf2cut,5));
%%
zmin=75;
zmax=175;
xmin=1;
xmax=803;
ymin=1;
ymax=803;
meanimg2=meanimg1(ymin:ymax,xmin:xmax,zmin:zmax);
xypixel0=22/40;
zstep0=1;
sz=size(meanimg2);
szn=round(sz(3)*zstep0/xypixel0);
if (rem(szn,2)==0)
    szn=szn+1;
end
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
standardplot()
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