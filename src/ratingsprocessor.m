clearvars -except ti

%% Initialize variables.
filename = '..\lists\ratings.list';
startRow = 282;
endRow = 664918;
%% New | Distribution | Votes | Rating | Title
formatSpec = '%6s%10s%10s%6s%s%[^\n\r]';

disp('Opening file');

%% Open the text file.
fileID = fopen(filename,'r');
textscan(fileID, '%[^\n\r]', startRow-1, 'WhiteSpace', '', 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, endRow-startRow+1, 'Delimiter', '', 'WhiteSpace', '', 'EmptyValue' ,NaN,'ReturnOnError', false, 'EndOfLine', '\r\n');

%% Close the text file.
fclose(fileID);

disp('Setting up variables');

%% Create output variable
inputfile = [dataArray{1:end-1}];

%% Only using rating and title
Rating = str2double(dataArray{4});
Title = strtrim(dataArray{5});

%% Clear temporary variables
clearvars filename startRow endRow formatSpec fileID dataArray ans;

titleids = cell(length(Title),1);
ratings = cell(length(Title),1);

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
    titleids{index} = titleID;
    ratings{index} = Rating(index);
end

disp('Dropping empties');
titleids = titleids(cellfun(@(x) ~isempty(x),titleids));
ratings = ratings(cellfun(@(x) ~isempty(x),ratings));
disp('Creating table');
outputTable = table(titleids,ratings,'VariableNames',{'TitleID' 'Ratings'});
disp('Outputing CSV file');
writetable(outputTable,'../dbs/ratings.csv');

clearvars -except ti