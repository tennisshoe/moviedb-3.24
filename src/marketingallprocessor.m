% For this version of the code I'm checking if the show was favored for
% each year of its run, not just the first

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

shownames = [];
years = [];
found = [];
favored_pre = [];
favored_post = [];
treated_pre = [];
treated_post = [];
pre_showname = {};
post_showname = {};
day = {};

for year = 1947:2016

    % shows that we were able to match on the prime time schedule
    networkShowFound = zeros(size(networkShowYears),'logical');
    % shows that were scheduled next to a highly rated show
    networkShowFavored_Pre = zeros(size(networkShowYears),'logical');
    networkShowFavored_Post = zeros(size(networkShowYears),'logical');
    networkShowTreated_Pre = zeros(size(networkShowYears),'logical');
    networkShowTreated_Post = zeros(size(networkShowYears),'logical');
    loop_pre_showname = cell(size(networkShowYears));
    loop_post_showname = cell(size(networkShowYears));
    loop_day = cell(size(networkShowYears));
    
    duplicates = zeros(size(networkShowYears), 'logical');
    
    disp(['Loading spreadsheet ', num2str(year)]);
    [~, ~, Schedule] = xlsread('C:\Users\achavda\Dropbox (MIT)\Television Project\Data\Schedule.xlsm',num2str(year));
    Schedule(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),Schedule)) = {''};
    
    disp('Processing spreadsheet');
    startIndex = 3;
    if year < 1957
        startIndex = 2;
    end
    highlyRated_intent = highlyRatedShows(highlyRatedYears == (year-1));
    highlyRated_treat = highlyRatedShows(highlyRatedYears == (year));
    Schedule(:,1) = lower(Schedule(:,1));
    ABC = strcmp(Schedule(:,1),'abc');
    NBC = strcmp(Schedule(:,1),'nbc');
    % NBC is the only network that existed through the whole dataset
    assert(sum(NBC)>0)
    CBS = strcmp(Schedule(:,1),'cbs');
    FOX = strcmp(Schedule(:,1),'fox');
    sunday = cellfun(@(x) ~isempty(x) && (min(x) == 1),strfind(Schedule(:,1), 'sunday'));
    monday = cellfun(@(x) ~isempty(x) && (min(x) == 1),strfind(Schedule(:,1), 'monday'));    
    tuesday = cellfun(@(x) ~isempty(x) && (min(x) == 1),strfind(Schedule(:,1), 'tuesday'));    
    wednesday = cellfun(@(x) ~isempty(x) && (min(x) == 1),strfind(Schedule(:,1), 'wednesday'));    
    thursday = cellfun(@(x) ~isempty(x) && (min(x) == 1),strfind(Schedule(:,1), 'thursday'));    
    friday =  cellfun(@(x) ~isempty(x) && (min(x) == 1),strfind(Schedule(:,1), 'friday'));    
    saturday = cellfun(@(x) ~isempty(x) && (min(x) == 1),strfind(Schedule(:,1), 'saturday'));
    dayofweek = sunday + monday + tuesday + wednesday + thursday + friday + saturday;
    data = ABC + NBC + CBS + FOX + dayofweek;
    assert(max(data) == 1 && min(data) == 0);
    % Schedule = Schedule((ABC + NBC + CBS + FOX + dayofweek) ~=0,:);
    currentday = '';
    for i = 1:size(Schedule,1)
        if(~data(i))
            continue;
        end
        if(sunday(i))
            currentday = 'sunday';
            continue;
        end
        if(monday(i))
            currentday = 'monday';
            continue;
        end
        if(tuesday(i))
            currentday = 'tuesday';
            continue;
        end
        if(wednesday(i))
            currentday = 'wednesday';
            continue;
        end
        if(thursday(i))
            currentday = 'thursday';
            continue;
        end
        if(friday(i))
            currentday = 'friday';
            continue;
        end
        if(saturday(i))
            currentday = 'saturday';
            continue;
        end
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
            showIndex = showIndex & (~duplicates);

            while (sum(showIndex) > 1)
                % usually this is two shows with the same name. Dancing
                % with the Stars is an example of a data error
                disp(['Conflict in years on ', showname,num2str(networkShowYears(showIndex)')]);
                % pull out duplicates
                duplicates = duplicates | (showIndex & (networkShowYears==min(networkShowYears(showIndex))));
                showIndex = showIndex & (~duplicates);
            end
            % mark the show(s) as having been found
            networkShowFound = networkShowFound | showIndex;
            % if there are no more shows then stop
            if(sum(showIndex) == 0)
                continue;
            end
            loop_day{showIndex} = currentday;
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
                    loop_post_showname{showIndex} = hitname;
                    hitIndex = strcmpi(hitname,highlyRated_intent);
                    assert(sum(hitIndex) < 2)
                    if(sum(hitIndex) == 1) 
                        % mark the show as being after a hit
                        networkShowFavored_Post = networkShowFavored_Post | showIndex;
                    end
                    % now check if it was actually treated
                    hitIndex = strcmpi(hitname,highlyRated_treat);
                    assert(sum(hitIndex) < 2)
                    if(sum(hitIndex) == 1) 
                        % mark the show as being after a hit
                        networkShowTreated_Post = networkShowTreated_Post | showIndex;
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
                    loop_pre_showname{showIndex} = hitname;                    
                    hitIndex = strcmpi(hitname,highlyRated_intent);
                    assert(sum(hitIndex) < 2)
                    if(sum(hitIndex) == 1) 
                        % mark the show as being before a hit
                        networkShowFavored_Pre = networkShowFavored_Pre | showIndex;
                    end
                    % now check if it was actually treated
                    hitIndex = strcmpi(hitname,highlyRated_treat);
                    assert(sum(hitIndex) < 2)
                    if(sum(hitIndex) == 1) 
                        % mark the show as being after a hit
                        networkShowTreated_Pre = networkShowTreated_Pre | showIndex;
                    end                      
                end                
            end
        end
    end

    shownames = [shownames;networkShows(networkShowFound)];
    years = [years;repmat(year,sum(networkShowFound),1)];
    found = [found;networkShowFound(networkShowFound)];
    favored_pre = [favored_pre;networkShowFavored_Pre(networkShowFound)];
    favored_post = [favored_post;networkShowFavored_Post(networkShowFound)];
    treated_pre = [treated_pre;networkShowTreated_Pre(networkShowFound)];
    treated_post = [treated_post;networkShowTreated_Post(networkShowFound)];
    pre_showname = [pre_showname;loop_pre_showname(networkShowFound)];
    post_showname = [post_showname;loop_post_showname(networkShowFound)];
    day = [day;loop_day(networkShowFound)];
    
end

% still fails for 1458 of 3927 shows. Most of these are daytime shows
% and kids cartoons that did not broadcast during prime time but others
% are failures in string matching such as 1956 West Point - The West
% Point Story
% sum(~networkShowFound)
% sum(networkShowFound)
% sum(networkShowFavored)

disp('Outputing CSV file');

outputTable = table(shownames,years,found,favored_pre,favored_post,treated_pre,treated_post,pre_showname,post_showname, day,'VariableNames',{'showname' 'year','favoredset','favored_pre','favored_post', 'treated_pre','treated_post','pre_showname','post_showname','dayofweek'});
writetable(outputTable,'../dbs/favoredall.csv');

