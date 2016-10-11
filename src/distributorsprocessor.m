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
company = cell(length(distributors),1);
language = cell(length(distributors),1);
yearStart = cell(length(distributors),1);
yearEnd = cell(length(distributors),1);
region = cell(length(distributors),1);
media = cell(length(distributors),1);
original = cell(length(distributors),1);

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
    cont = tokens.distributor;
    % grabbing the title
    [tokens,next] = regexp(cont, '^\s*(?<company>.*?)(?=\s*(?:\[|\)|$))','names','split');
    if(isempty(tokens)) 
        fprintf('Failed to find company : %s\n', line);
        continue;
    end    
    comp = tokens.company;
    [tokens,next] = regexp(join(next), '\[(?<language>\w\w)\]','names','split');
    if(isempty(tokens) ) 
        lang = ' ';
    else 
        lang = tokens.language;
    end  
    [tokens,next] = regexp(join(next), '\((?<yearStart>\d{4}|\?{4})(?:-|\))','names','split');
    % getting begining of year range
    if(isempty(tokens) || strcmp(tokens(1).yearStart,'????')) 
        syear = ' ';
    else 
        syear = tokens(1).yearStart;
    end
    [tokens,next] = regexp(join(next), '-(?<yearEnd>\d{4})\)','names','split');
    if(isempty(tokens)) 
        eyear = syear;
    else 
        eyear = tokens.yearEnd;
    end
    % doing media first since there are a fixed number of tokens
    % and we to a * on region
    [tokens,next] = regexp(join(next), '\((?<media>TV|all media|VHS|laserdisc|VoD|video|DVD|theatrical)\)','names','split');
    if(isempty(tokens)) 
        medi = ' ';
    else 
        medi = tokens.media;
    end
    % mark original airing flag
    [tokens,next] = regexp(join(next), '\((?<original>origian airing)\)','names','split');
    if(isempty(tokens)) 
        orig = 0;
    else 
        orig = 1;
    end
    [tokens,next] = regexp(join(next), '^\s*\((?<region>\w*)\)','names','split');
    if(isempty(tokens)) 
        regi = ' ';
    else 
        regi = tokens.region;
    end
    
    titlesFound = titlesFound + 1;    
    titles{index} = titleID;
    contents{index} = cont;
    company{index}  = comp;
    language{index} = lang; 
    yearStart{index} = syear;
    yearEnd{index} = eyear;
    media{index} = medi;
    region{index} = regi;
    original{index} = orig;
    
end

disp('Dropping empties');
titles = titles(cellfun(@(x) ~isempty(x),titles));
contents = contents(cellfun(@(x) ~isempty(x),contents));
company = company(cellfun(@(x) ~isempty(x),company));
language = language(cellfun(@(x) ~isempty(x),language));
yearStart = yearStart(cellfun(@(x) ~isempty(x),yearStart));
yearEnd = yearEnd(cellfun(@(x) ~isempty(x),yearEnd));
media = media(cellfun(@(x) ~isempty(x),media));
region = region(cellfun(@(x) ~isempty(x),region));
original = original(cellfun(@(x) ~isempty(x),original));
disp('Creating table');
outputTable = table(titles,contents,company,language,yearStart,yearEnd,media,region,original, ...
    'VariableNames',{'TitleID' 'Contents' 'Company' 'Language' 'StartYear' 'EndYear' 'Media' 'Region' 'OriginalAiring'});
disp('Outputing CSV file');
writetable(outputTable,'../dbs/distributors.csv');

clearvars -except ti