classdef titlesindex < handle
    properties (Access = private)
        mapShow
    end
    methods (Access = public)
        function index = getMap(obj)
            if isempty(obj.mapShow)
                loadMap(obj);
            end
            index = obj.mapShow;            
        end
        function titleID = lookupTitleID(obj,line)
            map = obj.getMap();
            % first remove the suspended tag so regex is easier
            line = strrep(line,'{{SUSPENDED}}','');
            % get the show title and year, which we're considering required
            expression = '^"(?<title>[^"]*)"\s\((?<year>\d{4})/?[IV]*\)\s?';
            [tokensTitleYear,line] = regexp(line, expression, 'names', 'split');
            if(~(isempty(tokensTitleYear)))
                % next pull out the epsiode info
                expression = '\s?\(#(?<season>\d*)?.(?<episodeNumber>\d*)?\)';
                [tokensSeasonEpsiodeNumber,line] = regexp(line{2}, expression, 'names', 'split');
                % what's left is the episode names
                expression = '{(?<episode>.*)}';
                tokensEpisodeName = regexp(line{1}, expression, 'names');
                key=strcat(tokensTitleYear.title,'|',tokensTitleYear.year,'|',tokensEpisodeName.episode,'|',tokensSeasonEpsiodeNumber.season,'|',tokensSeasonEpsiodeNumber.episodeNumber);
                if(isKey(map,key))
                    titleID = map(key);
                else
                    fprintf('Couldn''t find key: %s\n',key);
                    titleID = NaN;
                end
            else
                fprintf('Title / year failure: %s\n',line{1});
                titleID = NaN;
            end
        end
    end
    methods (Access = private)
        function loadMap(obj)
            %% Initialize variables.
            filename = '../dbs/titles.csv';
            delimiter = ',';
            startRow = 2;

            %% Format string for each line of text:
            formatSpec = '%u%q%f%q%f%f%f%*[^\n\r]';
            fprintf('Loading %s\n',filename);
            fileID = fopen(filename,'r');

            %% Read columns of data according to format string.
            dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false);
            fclose(fileID);

            %% Allocate imported array to column variable names
            TitleID = dataArray{:, 1};
            ShowName = dataArray{:, 2};
            Year = dataArray{:, 3};
            EpisodeName = dataArray{:, 4};
            Season = dataArray{:, 5};
            EpisodeNumber = dataArray{:, 6};
            IsSuspended = dataArray{:, 7};

            %% Clear temporary variables
            clearvars filename delimiter startRow formatSpec fileID dataArray ans;
            disp('Parsing strings');
            strYear = num2str(Year,'%-i');
            strYear = cellstr(strYear);
            strYear(isnan(Year)) = {''};

            strSeason = num2str(Season,'%-i');
            strSeason = cellstr(strSeason);
            strSeason(isnan(Season)) = {''};

            strEpisodeNumber = num2str(EpisodeNumber,'%-i');
            strEpisodeNumber = cellstr(strEpisodeNumber);
            strEpisodeNumber(isnan(EpisodeNumber)) = {''};

            key = strcat(ShowName,'|',strYear,'|',EpisodeName,'|',strSeason,'|',strEpisodeNumber);
            keyShort = strcat(ShowName,'|',strYear,'||',strSeason,'|',strEpisodeNumber);

            disp('Building map');
            obj.mapShow = containers.Map(key,TitleID,'UniformValues',true);
            obj.mapShow = [obj.mapShow;containers.Map(keyShort,TitleID,'UniformValues',true)];

            clearvars key keyShort strYear strSeason strEpisodeNumber
            clearvars TitleID ShowName Year EpisodeName Season EpisodeNumber IsSuspended;
            clearvars mapKeys mapValues;

            disp('Done loading map');

        end
    end


end

