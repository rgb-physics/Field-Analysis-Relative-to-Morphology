function options=parseOptions(defaults,varargin)
%PARSEOPTIONS Strict scalar struct or name/value options for public builders.
% Internal construction utility; does not load data.
options=defaults;
if numel(varargin)==1 && isstruct(varargin{1})
    supplied=varargin{1};
    if ~isscalar(supplied), error('sharedutilities:Config','Use a scalar options struct.'); end
elseif isempty(varargin)
    supplied=struct();
else
    if mod(numel(varargin),2), error('sharedutilities:Config','Use name/value pairs.'); end
    supplied=struct();
    for k=1:2:numel(varargin)
        name=varargin{k};
        if ~(ischar(name)||(isstring(name)&&isscalar(name))) || ~isvarname(char(name))
            error('sharedutilities:Config','Option names must be valid scalar names.');
        end
        name=char(name);
        if isfield(supplied,name), error('sharedutilities:Config','Repeated option: %s',name); end
        supplied.(name)=varargin{k+1};
    end
end
names=fieldnames(supplied);
for k=1:numel(names)
    name=names{k};
    if ~isfield(defaults,name), error('sharedutilities:Config','Unknown option: %s',name); end
    options.(name)=supplied.(name);
end
end
