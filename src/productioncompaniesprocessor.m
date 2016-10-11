% can maybe do more regexp parsing of the distrubutor string
% seems like most have year, country, media and language information

clearvars -except ti

%% Initialize variables.
filename = '..\lists\production-companies.list';
delimiter = '';
formatSpec = '%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);

%% Close the text file.
fclose(fileID);

%% Create output variable
companies = [dataArray{1:end-1}];
%% Clear temporary variables
clearvars filename delimiter formatSpec fileID dataArray ans;

titles = cell(length(companies),1);
name = cell(length(companies),1);
countrycode = cell(length(companies),1);

if(~exist('ti','var'))
    ti = titlesindex();
end

titlesFound = 0;
tvFound = 0;
dataSection = false;

for index=1:length(companies)
    if(mod(index,10000) == 0)
        fprintf('Found %i of %i TV and %i total\n',titlesFound,tvFound,index);
    end
    
    line = companies{index};
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
    % skip things that are not TV
    if(line(1) ~= '"')
        continue;
    end
    tvFound = tvFound + 1;
    % tokens = regexp(line,'^(?<show>.*)\t+(?<distributor>.+?)\s+\[(?<countrycode>\w\w)\]\s*','names');
    tokens = regexp(line,'^(?<show>.*)\t+(?<distributor>.+?)','names');
    if(isempty(tokens))
        fprintf('Failed to parse: %s\n', line);
        continue;
    end
    titleID = ti.lookupTitleID(tokens.show);
    if(isnan(titleID))
        continue;
    end
    titlesFound = titlesFound + 1;
    distributor = tokens.distributor;
    tokens = regexp(distributor,'\[(?<countrycode>\w\w)\]','names');
    titles{index} = titleID;
    name{index} = distributor;
    if(~isempty(tokens))
        countrycode{index} = tokens.countrycode;
    else 
        % hacky but not sure what else to do and stil have columns the 
        % right size for the table
        countrycode{index} = ' ';
    end
end

disp('Dropping empties');
titles = titles(cellfun(@(x) ~isempty(x),titles));
name = name(cellfun(@(x) ~isempty(x),name));
countrycode = countrycode(cellfun(@(x) ~isempty(x),countrycode));
disp('Creating table');
outputTable = table(titles,name, countrycode,'VariableNames',{'TitleID' 'ProductionCompany' 'CountryCode'});
disp('Outputing CSV file');
writetable(outputTable,'../dbs/production-companies.csv');

clearvars -except ti