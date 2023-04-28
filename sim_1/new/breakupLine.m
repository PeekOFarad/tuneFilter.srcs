function out=breakupLine(str, substringLength) 
stringLength = length(str);
loopCounter = 1;
for k = 1 : substringLength : stringLength
    index1 = k;
    index2 = min(k + substringLength - 1, stringLength);
    out{loopCounter,1} = str(index1 : index2);
    loopCounter = loopCounter + 1;
end
end