function membership = trackPositions(detections, options)
%TRACKPOSITIONS Optional Python Trackpy backend; no merge/split inference.
% SearchRange=8 (same units as scaled coordinates), Memory=3 missing frames;
% MassProperty=''; CoordinateScale=[]; Linker=[] optional injection for tests
% or external execution: @(matrix,range,memory)->[RowID TrajectoryID], one-based.
% Requires configured MATLAB pyenv, numpy, pandas, trackpy unless Linker supplied.
if nargin<2, options=struct(); end
options=objectgeometry.internal.options(options,struct('SearchRange',8,'Memory',3, ...
    'MassProperty','','CoordinateScale',[],'Linker',[]));
validateattributes(options.SearchRange,{'numeric'},{'real','finite','scalar','positive'});
validateattributes(options.Memory,{'numeric'},{'real','finite','scalar','integer','nonnegative'});
[matrix,map]=objecttracking.trackpy.exportDetections(detections, ...
    struct('MassProperty',options.MassProperty,'CoordinateScale',options.CoordinateScale));
if isempty(matrix), membership=map(:,{'DatasetID','Frame','ObjectID'}); membership.DetectionID=zeros(0,1); membership.TrajectoryID=zeros(0,1); return; end
if isempty(options.Linker)
    folder=fileparts(mfilename('fullpath'));
    script=fullfile(folder,'..','..','..','python','trackpy_bridge.py');
    try
        linked=double(pyrunfile(script,'linkedRows',dataMat=matrix, ...
            cutOffDist=options.SearchRange,memoryWindow=options.Memory));
    catch exception
        failure=MException('objecttracking:TrackpyExecution', ...
            'Trackpy execution failed. Check MATLAB pyenv and numpy/pandas/trackpy. Original: %s',exception.message);
        failure=addCause(failure,exception); throw(failure);
    end
else
    if ~isa(options.Linker,'function_handle'), error('objecttracking:TrackpyLinker','Linker must be a function handle.'); end
    linked=options.Linker(matrix,options.SearchRange,options.Memory);
end
membership=objecttracking.trackpy.importLinks(linked,map);
membership.Properties.UserData=struct('Method','trackpy','Options',options,'ExportMetadata',map.Properties.UserData);
end
