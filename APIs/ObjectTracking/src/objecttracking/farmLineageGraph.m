function graph = farmLineageGraph(tracking)
%FARMLINEAGEGRAPH Optional directed graph, including isolated detections.
d = tracking.Detections;
[foundS,s] = ismember(tracking.Links.SourceDetectionID,d.DetectionID);
[foundT,t] = ismember(tracking.Links.TargetDetectionID,d.DetectionID);
if any(~foundS|~foundT), error('objecttracking:UnknownLink','A link refers to an unknown detection.'); end
graph = digraph(s,t,[],height(d));
for name = d.Properties.VariableNames
    graph.Nodes.(name{1}) = d.(name{1});
end
end
