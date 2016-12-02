% can maybe do more regexp parsing of the distrubutor string
% seems like most have year, country, media and language information

clearvars -except ti

%% Initialize variables.
filename = '..\lists\genres.list';
delimiter = '';
formatSpec = '%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Create output variable
inputfile = [dataArray{1:end-1}];
%% Clear temporary variables
clearvars filename delimiter formatSpec fileID dataArray ans;

titles = cell(length(inputfile),1);
genres = cell(length(inputfile),1);

if(~exist('ti','var'))
    ti = titlesindex();
end

titlesFound = 0;
tvFound = 0;

for index=1:length(inputfile)
    if(mod(index,10000) == 0)
        fprintf('Found %i of %i TV and %i total\n',titlesFound,tvFound,index);
    end
    
    line = inputfile{index};
    % look for things that look like genre data. pre and post content gets 
    % skipped as a side effect
    tokens = regexp(line,'^(?<show>.*?)\t+(?<genre>.+)','names');
    % probaly pre or post data section
    if(isempty(tokens))
        continue;
    end    
    % skip things that are not TV
    if(tokens.show(1) ~= '"')
        continue;
    end
    if((tokens.show(2) == '6') && (tokens.show(3) == '0'))
        disp('Found 60')
    end
    
    tvFound = tvFound + 1;
    titleID = ti.lookupTitleID(tokens.show);
    if(isnan(titleID))
        continue;
    end
        
    titlesFound = titlesFound + 1;    
    titles{index} = titleID;
    genres{index} = tokens.genre;    
end

disp('Dropping empties');
titles = titles(cellfun(@(x) ~isempty(x),titles));
genres = genres(cellfun(@(x) ~isempty(x),genres));
disp('Creating table');
outputTable = table(titles,genres,'VariableNames',{'TitleID' 'Genre'});
disp('Outputing CSV file');
writetable(outputTable,'../dbs/genres.csv');

clearvars -except ti