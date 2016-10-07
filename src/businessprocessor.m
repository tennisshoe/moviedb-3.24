clearvars -except ti

%% Initialize variables.
filename = '..\lists\business.list';
delimiter = '';

%% Format string for each line of text:
%   column1: text (%q)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%q%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);

%% Close the text file.
fclose(fileID);


%% Create output variable
business = [dataArray{1:end-1}];
%% Clear temporary variables
clearvars filename delimiter formatSpec fileID dataArray ans;

%{
'AD'    Admissions
'BT'    Production Budget
'CP'    Copyright Holder
'GR'    Gross Receipts
'MV'    Title
'OW'    Opening Weekend Gross
'PD'    Production Dates
'RT'    Rental Income
'SD'    Filming / Shooting Dates
'ST'    Studio where filmed
'WG'    Weekend Gross
%}

index = 0;
titleID = NaN;
titlesFound = 0;
tvFound = 0;

titles = cell(length(business),1);
types = cell(length(business),1);
contents = cell(length(business),1);

if(~exist('ti','var'))
    ti = titlesindex();
end

while(index<length(business))
    index = index + 1;
    line = business{index};
    findResult = strfind(line,'MV: ');
    if(findResult==1)
        % we know we are at the beginning of a new movie record
        titleID = NaN;
        if(strfind(line,'MV: "')==1)
            tvFound = tvFound + 1;
            titleID = ti.lookupTitleID(line(5:end));
            if(~isnan(titleID))
                titlesFound = titlesFound + 1;
            end
        end
    else 
        % now save data for each found movie
        % we know it isn't a MV: tag so we just grab any line matches
        if(~isnan(titleID))
            expression = '^(?<type>[A-Z]{2}):\s(?<content>.*)';
            tokenTypeContents = regexp(line,expression,'names');
            if(~(isempty(tokenTypeContents)))
                titles{index}= titleID;
                types{index} = tokenTypeContents.type;
                contents{index} = tokenTypeContents.content;
            end
        end        
    end
    if(mod(index,10000) == 0)
        fprintf('Found %i of %i TV and %i total\n',titlesFound,tvFound,index);
    end
end

clearvars index findResult expression line titlesFound tvFound business tokenTypeContents titleID

disp('Dropping empties');
titles = titles(cellfun(@(x) ~isempty(x),titles));
types = types(cellfun(@(x) ~isempty(x),types));
contents = contents(cellfun(@(x) ~isempty(x),contents));
disp('Creating Table');
outputTable = table(titles,types,contents,'VariableNames',{'TitleID' 'Type' 'Content'});
disp('Outputing CSV file');
writetable(outputTable,'../dbs/business.csv');

clearvars titles types contents outputTable
