function result=conditionalStatistics(measured,conditioning,options)
%CONDITIONALSTATISTICS Bin corresponding values of one field by another.
% Matching arrays or equally sized sample vectors; selection occurs upstream.
% Edges override NumBins. Histcounts includes the last edge in the last bin.
if nargin<3, options=struct(); end
o=fieldanalysis.internal.options(struct('Edges',[],'NumBins',20,'Statistics',{{'Mean','Variance'}}, ...
    'GroupIDs',[]),options);
if ~isequal(size(measured),size(conditioning))
    if ~(isvector(measured)&&isvector(conditioning)&&numel(measured)==numel(conditioning))
        error('fieldanalysis:SizeMismatch','Measured and conditioning arrays must correspond.');
    end
end
if ~(isnumeric(measured)||islogical(measured))||~isreal(measured)||ndims(measured)>3|| ...
        ~(isnumeric(conditioning)||islogical(conditioning))||~isreal(conditioning)||ndims(conditioning)>3
    error('fieldanalysis:Field','Values must be real numeric arrays.');
end
m=double(measured(:)); c=double(conditioning(:));
if any(~isfinite(m))||any(~isfinite(c)), error('fieldanalysis:InvalidData','Repair NaN/Inf values before analysis.'); end
if isempty(o.Edges)
    validateattributes(o.NumBins,{'numeric'},{'scalar','integer','positive','finite'});
    if isempty(c), error('fieldanalysis:Edges','Empty input requires explicit bin edges.'); end
    [~,edges,bin]=histcounts(c,o.NumBins);
else
    edges=double(o.Edges(:)');
    validateattributes(edges,{'numeric'},{'vector','finite','increasing'});
    if numel(edges)<2, error('fieldanalysis:Edges','At least two edges are required.'); end
    [~,~,bin]=histcounts(c,edges);
end
if isempty(o.GroupIDs)
    ids=ones(size(m)); groups=1;
else
    ids=o.GroupIDs(:);
    if numel(ids)~=numel(m), error('fieldanalysis:SizeMismatch','GroupIDs must correspond to samples.'); end
    validateattributes(ids,{'numeric'},{'real','finite'});
    groups=unique(ids);
end
names=cellstr(string(o.Statistics));
fieldanalysis.internal.reduce([],names); % Validate requested names even for empty groups.
nBins=numel(edges)-1; nRows=numel(groups)*nBins;
GroupID=zeros(nRows,1); Bin=zeros(nRows,1); Count=zeros(nRows,1);
LeftEdge=zeros(nRows,1); RightEdge=zeros(nRows,1);
stats=struct();
for k=1:numel(names), stats.(names{k})=NaN(nRows,1); end
row=0; excluded=zeros(numel(groups),1);
for g=1:numel(groups)
    inGroup=ids==groups(g); excluded(g)=nnz(inGroup&bin==0);
    for b=1:nBins
        row=row+1; sel=inGroup&bin==b;
        GroupID(row)=groups(g); Bin(row)=b; Count(row)=nnz(sel);
        LeftEdge(row)=edges(b); RightEdge(row)=edges(b+1);
        v=fieldanalysis.internal.reduce(m(sel),names);
        for k=1:numel(names), stats.(names{k})(row)=v.(names{k}); end
    end
end
t=table(GroupID,Bin,LeftEdge,RightEdge,Count);
reserved=t.Properties.VariableNames;
for k=1:numel(names)
    if strcmpi(names{k},'Count'), continue; end
    if any(strcmpi(names{k},reserved)), error('fieldanalysis:Statistic','Statistic name conflicts with a key.'); end
    t.(names{k})=stats.(names{k});
end
result=struct('Edges',edges,'Statistics',t,'ExcludedCounts',table(groups(:),excluded, ...
    'VariableNames',{'GroupID','Count'}),'InputCount',numel(m));
end
