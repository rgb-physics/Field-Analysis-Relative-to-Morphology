function saveNew(path,result)
%SAVENEW Never overwrite an existing file.
if isfile(path), error('memoworkflow:Exists','Refusing overwrite: %s.',path); end
save(path,'result','-v7.3');
end
