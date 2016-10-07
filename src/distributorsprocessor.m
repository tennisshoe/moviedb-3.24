% can maybe do more regexp parsing of the distrubutor string
% seems like most have year, country, media and language information

clearvars -except ti

%% Initialize variables.
filename = '..\lists\distributors.list';
delimiter = '';
formatSpec = '%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Create output variable
distributors = [dataArray{1:end-1}];
%% Clear temporary variables
clearvars filename delimiter formatSpec fileID dataArray ans;

titles = cell(length(distributors),1);
contents = cell(length(distributors),1);

if(~exist('ti','var'))
    ti = titlesindex();
end

titlesFound = 0;
tvFound = 0;
dataSection = false;

for index=1:length(distributors)
    if(mod(index,10000) == 0)
        fprintf('Found %i of %i TV and %i total\n',titlesFound,tvFound,index);
    end
    
    line = distributors{index};
    if (~dataSection && line(1)=='=')        
        dataSection = true;
        continue;
    end
    if (dataSection && line(1)=='-')
        dataSection = false;
        continue;
    end
    if (~dataSection)
        continue;
    end
    % first pull out everything before the first set of tabs. That will be
    % used to get the titleID. Tabs afterwards are hit or miss and can't
    % be used as a marker for anything. 
    tokens = regexp(line,'^(?<show>.*?)\t+(?<distributor>.+)','names');
    % skip things that are not TV
    if(tokens.show(1) ~= '"')
        continue;
    end
    tvFound = tvFound + 1;
    titleID = ti.lookupTitleID(tokens.show);
    if(isnan(titleID))
        continue;
    end
    titlesFound = titlesFound + 1;
    titles{index} = titleID;
    contents{index} = tokens.distributor;
end

disp('Dropping empties');
titles = titles(cellfun(@(x) ~isempty(x),titles));
contents = contents(cellfun(@(x) ~isempty(x),contents));
disp('Creating table');
outputTable = table(titles,contents,'VariableNames',{'TitleID' 'Distributor'});
disp('Outputing CSV file');
writetable(outputTable,'../dbs/distributors.csv');

clearvars -except ti