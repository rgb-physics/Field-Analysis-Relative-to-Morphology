function tests=testOwnershipCleanup
%TESTOWNERSHIPCLEANUP Old and canonical entry points preserve behavior.
tests=functiontests(localfunctions);
end
function testNumericAliases(t)
verifyEqual(t,sharedutilities.plotting.logAB(2,[4 8]), ...
    sharedutilities.numerics.logAB(2,[4 8]));
[x,y]=sharedutilities.plotting.loglogBin([1 2 4 8],[1 4 16 64],10);
[a,b]=fieldanalysis.statistics.loglogBin([1 2 4 8],[1 4 16 64],10);
verifyEqual(t,x,a); verifyEqual(t,y,b);
end
function testViolinGraphicsAndStatistics(t)
before=findall(groot,'Type','figure'); cleanup=onCleanup(@()localCloseNew(before));
figure('Visible','off');
[m1,d1]=sharedutilities.plotting.manVlnPlot(1,[1 2 3],0:4,.4);
p1=findobj(gca,'Type','patch'); x=p1.XData; y=p1.YData; color=p1.FaceColor;
figure('Visible','off');
[m2,d2]=visualizationtools.display.manVlnPlot(1,[1 2 3],0:4,.4);
p2=findobj(gca,'Type','patch');
verifyEqual(t,[m1 d1],[m2 d2]); verifyEqual(t,[m2 d2],[2 2]);
verifyEqual(t,p2.XData,x); verifyEqual(t,p2.YData,y); verifyEqual(t,p2.FaceColor,color);
clear cleanup
end
function testGroupedViolinAlias(t)
before=findall(groot,'Type','figure'); visibility=get(groot,'DefaultFigureVisible');
cleanup=onCleanup(@()localRestore(before,visibility)); set(groot,'DefaultFigureVisible','off');
[m1,d1]=sharedutilities.plotting.plotVlns([1 1 3 3],[1 2 2 3],[0 2 4],0:4,.4);
patches1=findobj(gcf,'Type','patch'); xs=get(patches1,'XData'); ys=get(patches1,'YData');
[m2,d2]=visualizationtools.display.plotVlns([1 1 3 3],[1 2 2 3],[0 2 4],0:4,.4);
patches2=findobj(gcf,'Type','patch');
verifyEqual(t,m1,m2); verifyEqual(t,d1,d2);
verifyEqual(t,get(patches2,'XData'),xs); verifyEqual(t,get(patches2,'YData'),ys);
clear cleanup
end
function testFigureExportAlias(t)
folder=tempname; mkdir(folder); cleanup=onCleanup(@()rmdir(folder,'s'));
f=figure('Visible','off'); figureCleanup=onCleanup(@()close(f)); plot(1:3,[2 1 3]);
sharedutilities.plotting.figSaves(f,folder,'old',{'png','fig'},true);
visualizationtools.export.figSaves(f,folder,'new',{'png','fig'},true);
verifyTrue(t,isfile(fullfile(folder,'old.fig'))&&isfile(fullfile(folder,'new.fig')));
verifyEqual(t,imread(fullfile(folder,'old.png')),imread(fullfile(folder,'new.png')));
visualizationtools.export.figSaves(f,folder,'disabled','png',false);
verifyFalse(t,isfile(fullfile(folder,'disabled.png')));
clear figureCleanup cleanup
end
function localCloseNew(before)
after=findall(groot,'Type','figure');
for k=1:numel(after)
    if ~any(after(k)==before)&&isgraphics(after(k)), close(after(k)); end
end
end
function localRestore(before,visibility)
localCloseNew(before); set(groot,'DefaultFigureVisible',visibility);
end
