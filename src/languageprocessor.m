%% Marking 1 if found to be foreign and 0 if english
%% some shows will have two(+) entries, one(+) foreign and one domestic
%% Stata script will need to rationalize that

clearvars -except ti

%% Initialize variables.
filename = '..\lists\language.list';
formatSpec = '%s%s%[^\n\r]';

disp('Opening file');
%% Find start and end rows
display('Finding Start and End Rows');
startRow = 1;
fileID = fopen(filename,'r');
tline = fgetl(fileID);
while ischar(tline)
    startRow = startRow + ~isempty(tline);
    if(strfind(tline, '=====') > 0)
        tline = -1;
    else
        tline = fgetl(fileID);
    end
end

tline = fgetl(fileID);
endRow = startRow;
while ischar(tline)
    if(strfind(tline, '------') > 0)
        tline = -1;
        endRow = endRow - 1;
    else
        tline = fgetl(fileID);
        endRow = endRow + ~isempty(tline);
    end
end
fclose(fileID);

%% Open the text file.
fileID = fopen(filename,'r');
textscan(fileID, '%[^\n\r]', startRow-1, 'WhiteSpace', '', 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, endRow-startRow+1, 'Delimiter', '\t', 'MultipleDelimsAsOne', true, 'EmptyValue' ,NaN,'ReturnOnError', false, 'EndOfLine', '\r\n');

%% Close the text file.
fclose(fileID);

disp('Setting up variables');

%% Only using rating and title
Title = strtrim(dataArray{1});
Language = strtrim(dataArray{2});

%% Clear temporary variables
clearvars filename startRow endRow formatSpec fileID dataArray ans;

titleids = [];
foreign = [];
    
if(~exist('ti','var'))
    ti = titlesindex();
end

titlesFound = 0;
tvFound = 0;

for index=1:length(Title)
    if(mod(index,10000) == 0)
        fprintf('Found %i of %i TV and %i total\n',titlesFound,tvFound,index);
    end
    
    line = Title{index};
    % skip things that are not TV
    if(line(1) ~= '"')
        continue;
    end
    tvFound = tvFound + 1;
    titleID = ti.lookupTitleID(line);
    if(isnan(titleID))
        continue;
    end
        
    titlesFound = titlesFound + 1;
    titleids = [titleids;titleID];
    foreign = [foreign;~strcmpi(Language(index),'English')];
end

disp('Creating table');
outputTable = table(titleids,foreign,'VariableNames',{'TitleID' 'Foreign'});
disp('Outputing CSV file');
writetable(outputTable,'../dbs/language.csv');

clearvars -except ti