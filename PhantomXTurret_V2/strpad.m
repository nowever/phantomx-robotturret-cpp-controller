function stringVal = strpad(stringVal,totalChars,charPosition,fillChar)
if nargin<4
    fillChar = '0';
    if nargin<3
        charPosition='pre';
        if nargin<2
            warning('You must pass the required totalChars');
        end
    end
end

if length(stringVal)>=totalChars
    warning('The string is already longer than the required pad value');    
    return;
end
if size(fillChar,1) ~= 1 || size(fillChar,2) ~=1
    warning('The fill char pass is too large using 0 (zeros) instead');    
    fillChar = '0';
end

% Go through from the current length to the desired length the required len
for i=length(stringVal)+1:totalChars
    if strcmp(charPosition,'pre')
        stringVal = [fillChar,stringVal];    
    elseif strcmp(charPosition,'post')
        stringVal = [stringVal,fillChar];    
    end
end
end