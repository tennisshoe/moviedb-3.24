clearvars -except ti

%% Initialize variables.
filename = '..\lists\producers.list';
delimiter = '';

%% Format string for each line of text:
%   column1: text (%q)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN, 'ReturnOnError', false);

%% Close the text file.
fclose(fileID);


%% Create output variable
producers = [dataArray{1:end-1}];
%% Clear temporary variables
clearvars filename delimiter formatSpec fileID dataArray ans;

index = 0;
dataSection = false;
titlesFound = 0;
nameID = NaN;

titles = cell(length(producers),1);
name = cell(length(producers),1);
role = cell(length(producers),1);

if(~exist('ti','var'))
    ti = titlesindex();
end

while(index<length(producers))
    index = index + 1;
    line = producers{index};
    if (~dataSection && count(line, '----                    ------'))        
        dataSection = true;
        continue;
    end
    % placeholder for now
    if (dataSection && count(line,'----') > 0)
        dataSection = false;
        continue;
    end
    if (~dataSection)
        continue;
    end
    token = regexp(line,'^(?<name>.+?)\t+(?<contents>.*)','names');
    % check if we have a new name in the line
    if(~isempty(token)) 
        % this will return NaN when the name is not found and 
        % cause us to skip the rest of that name's section
        nameID = ti.lookupNameID(token.name);
        line = token.contents;
    end
    % if we don't have a name, stop
    if(isnan(nameID))
        continue;
    end
    % if no name then the current name is the same as the previous one
    name{index} = nameID;
    % strip out the role from the line, catching producter, production,
    % latin language variants
    [token,line] = regexp(line,'\((?<role>[^\)]*(Produc|produc).*?)\)','names','split');
    if(isempty(token))
        fprintf('Not a producer role: %s\n',line{1});
        continue;
    end
    role{index}=token.role;
    line = join(line);
    line = strrep(line,'(TV)','');
    % if(count(line,'My Extreme Animal Phobia'))
    %    disp('Should find this one');
    % end
    
    %this file doesn't differentiate between movies and TV so try to see
    %if anything matches
    titleID = ti.lookupTitleID(line,false);
    if(isnan(titleID))
        continue;
    end
    titlesFound = titlesFound + 1;    
    if(mod(index,10000) == 0)
        fprintf('Found %i of %i total\n',titlesFound,index);
    end
end

clearvars -except titles names roles ti

disp('Dropping empties');
titles = titles(cellfun(@(x) ~isempty(x),titles));
names = types(cellfun(@(x) ~isempty(x),names));
roles = contents(cellfun(@(x) ~isempty(x),roles));
disp('Creating Table');
outputTable = table(titles,names,roles,'VariableNames',{'TitleID' 'NameID' 'Role'});
disp('Outputing CSV file');
writetable(outputTable,'../dbs/producers.csv');

clearvars -except ti
