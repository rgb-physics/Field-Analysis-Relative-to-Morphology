function values=reduce(samples,names)
%REDUCE Ordinary statistics; empty selections have zero count/sum.
names=cellstr(string(names)); samples=samples(:); values=struct();
for k=1:numel(names)
    name=names{k};
    switch lower(name)
        case 'count', value=numel(samples);
        case 'sum', value=sum(samples);
        case {'mean','median','variance','std','min','max'}
            if isempty(samples), value=NaN;
            else
                switch lower(name)
                    case 'mean', value=mean(samples);
                    case 'median', value=median(samples);
                    case 'variance', value=var(samples);
                    case 'std', value=std(samples);
                    case 'min', value=min(samples);
                    case 'max', value=max(samples);
                end
            end
        otherwise, error('fieldanalysis:Statistic','Unknown statistic: %s.',name);
    end
    if ~isvarname(name), error('fieldanalysis:Statistic','Statistic names must be valid field names.'); end
    values.(name)=value;
end
end
