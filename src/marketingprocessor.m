clearvars
clc
disp('Loading network show list');
filename = 'C:\Users\achavda\Dropbox (MIT)\Television Project\Data\moviedb-3.24\dbs\networkshows.csv';
delimiter = ',';
startRow = 2;
formatSpec = '%q%u%[^\n\r]';
fileID = fopen(filename,'r');
networkShows = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
fclose(fileID);
networkShowYears = cell2mat(networkShows(2));
% shows that we were able to match on the prime time schedule
networkShowFound = zeros(size(networkShowYears),'logical');
% shows that were scheduled next to a highly rated show
networkShowFavored = zeros(size(networkShowYears),'logical');
networkShows = networkShows{1,1};
% clean the show names using the same regex we use below
networkShowsClean = cellfun(@(x) regexp(x,'^(.*?)\s*(?:\(|\[|#|$)','tokens'),networkShows);
networkShowsClean = cellfun(@(x) x{1},networkShowsClean,'UniformOutput',false);
clearvars filename delimiter startRow formatSpec fileID;

disp('Loading nielson hit list');
filename = 'C:\Users\achavda\Dropbox (MIT)\Television Project\Data\moviedb-3.24\dbs\highlyrated.csv';
delimiter = ',';
startRow = 2;
formatSpec = '%q%q%u%[^\n\r]';
fileID = fopen(filename,'r');
highlyRatedShows = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
fclose(fileID);
highlyRatedYears = cell2mat(highlyRatedShows(3));
highlyRatedShows = highlyRatedShows{1,1};
% clean the show names using the same regex we use below
highlyRatedShowsClean = cellfun(@(x) regexp(x,'^(.*?)\s*(?:\(|\[|#|$)','tokens'),highlyRatedShows);
highlyRatedShowsClean = cellfun(@(x) x{1},highlyRatedShowsClean,'UniformOutput',false);

clearvars filename delimiter startRow formatSpec fileID;

for year = 1947:2016
    disp(['Loading spreadsheet ', num2str(year)]);
    [~, ~, Schedule] = xlsread('C:\Users\achavda\Dropbox (MIT)\Television Project\Data\Schedule.xlsm',num2str(year));
    Schedule(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),Schedule)) = {''};
    
    disp('Processing spreadsheet');
    startIndex = 3;
    if year < 1957
        startIndex = 2;
    end
    highlyRated = highlyRatedShows(highlyRatedYears == (year-1));
    ABC = strcmp(Schedule(:,1),'ABC');
    NBC = strcmp(Schedule(:,1),'NBC');
    % NBC is the only network that existed through the whole dataset
    assert(sum(NBC)>0)
    CBS = strcmp(Schedule(:,1),'CBS');
    FOX = strcmp(Schedule(:,1),'Fox');
    Schedule = Schedule((ABC + NBC + CBS + FOX) ~=0,:);
    for i = 1:size(Schedule,1)
        % skip the network and season information
        endIndex = length(Schedule(i,:));
        for j = startIndex:endIndex
            showname = Schedule{i,j};
            if (isempty(showname))
                continue
            end
            if(isnumeric(showname))
                showname = num2str(showname);
            end
            tokens = regexp(showname,'^(?<show>.*?)\s*(?:\(|\[|#|$)','names');
            showname = tokens.show;
            showIndex = strcmpi(showname,networkShowsClean);
            % filter out shows that are too new to be in this data slice
            showIndex = showIndex & (networkShowYears <= (year+1));
            if(sum(showIndex) == 0)
                disp(['Failed to find ',showname]);
                continue;
            end
            % filter out shows that have already been marked
            showIndex = showIndex & (~networkShowFound);
            if (sum(showIndex) > 1)
                % usually this is two shows with the same name. Dancing
                % with the Stars is an example of a data error
                disp(['Conflict in years on ', showname,num2str(networkShowYears(showIndex)')]);
            end
            % if there are no more shows then stop
            if(sum(showIndex) == 0)
                continue;
            end
            % mark the show as having been found
            networkShowFound = networkShowFound | showIndex;
            % check if next to a highly rated show
            j_hit = 0;
            if(j > startIndex)
                hitname = Schedule{i,j-1};
                if (~isempty(hitname))
                    if(isnumeric(hitname))
                        hitname = num2str(hitname);
                    end
                    tokens = regexp(hitname,'^(?<show>.*?)\s*(?:\(|\[|#|$)','names');
                    hitname = tokens.show;
                    hitIndex = strcmpi(hitname,highlyRated);
                    assert(sum(hitIndex) < 2)
                    if(sum(hitIndex) == 1) 
                        % mark the show as being next to a hit
                        networkShowFavored = networkShowFavored | showIndex;
                    end                
                end
            end
            if (j < endIndex)
                hitname = Schedule{i,j+1};
                if (~isempty(hitname))
                    if(isnumeric(hitname))
                        hitname = num2str(hitname);
                    end
                    tokens = regexp(hitname,'^(?<show>.*?)\s*(?:\(|\[|#|$)','names');
                    hitname = tokens.show;
                    hitIndex = strcmpi(hitname,highlyRated);
                    assert(sum(hitIndex) < 2)
                    if(sum(hitIndex) == 1) 
                        % mark the show as being next to a hit
                        networkShowFavored = networkShowFavored | showIndex;
                    end                
                end                
            end
        end
    end
    clearvars -except  networkShowFavored networkShowYears networkShows networkShowFound networkShowsClean highlyRatedShowsClean highlyRatedShows highlyRatedYears
end

% still fails for 1458 of 3927 shows. Most of these are daytime shows
% and kids cartoons that did not broadcast during prime time but others
% are failures in string matching such as 1956 West Point - The West
% Point Story
sum(~networkShowFound)
sum(networkShowFound)
sum(networkShowFavored)

disp('Outputing CSV file');
showname = networkShows(networkShowFound);
year = networkShowYears(networkShowFound);
found = networkShowFound(networkShowFound);
favored = networkShowFavored(networkShowFound);

outputTable = table(showname,year,found,favored,'VariableNames',{'showname' 'year','favoredset','favored'});
writetable(outputTable,'../dbs/favored.csv');

