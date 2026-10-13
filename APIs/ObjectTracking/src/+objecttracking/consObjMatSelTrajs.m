function outMat = consObjMatSelTrajs(selectTrajs,objIDs,totTable,matDims)
%CONSOBJMATSELTRAJS Historical one-frame reconstruction, corrected output.
% Numeric mapping [time object trajectory], objIDs.pixIDs cell of indices.
% Native trajectory values retained; file export is a separate operation.
if istable(totTable), totTable=table2array(totTable); end
selected=ismember(totTable(:,3),selectTrajs);
rows=totTable(selected,:); outMat=zeros(matDims);
for i=1:size(rows,1)
    outMat(objIDs.pixIDs{rows(i,2)})=rows(i,3);
end
end
