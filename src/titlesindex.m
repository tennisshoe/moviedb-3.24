classdef titlesindex < handle
    properties (Access = private)
        mapShow
        mapNames
        charBuffer = blanks(1024);
        logfile
    end
    methods (Access = public)
        function index = getMapShow(obj)
            if isempty(obj.mapShow)
                loadMapShow(obj);
            end
            index = obj.mapShow;            
        end
        function index = getMapNames(obj)
            if isempty(obj.mapNames)
                loadMapNames(obj);
            end
            index = obj.mapNames;            
        end
        function titleID = lookupTitleID(obj,line,debug)
            if(~exist('debug','var'))
                debug = true;
            end
            map = obj.getMapShow();
            if(isstring(line))
                line = char(line);
            end
            debugline = line;
            if (isempty(obj.logfile))
                obj.logfile = fopen('UnairedShows.txt','w+');
            end
            % first remove the suspended tag so regex is easier
            line = strrep(line,'{{SUSPENDED}}','');
            % get the show title and year, which we're considering required
            % sometimes the title includes quotes to specifically indicate
            % a TV show
            expression = '^"?(?<title>[^"]*)"?\s\((?<year>\d{4})/?[IV]*\)\s?';
            [tokensTitleYear,line] = regexp(line, expression, 'names', 'split');
            if(~(isempty(tokensTitleYear)))
                % next pull out the epsiode info
                expression = '\s?\(#(?<season>\d*)?.(?<episodeNumber>\d*)?\)';
                [tokensSeasonEpsiodeNumber,line] = regexp(char(join(line)), expression, 'names', 'split');
                % this could potentially return more than one match. Take
                % the first
                if(~isempty(tokensSeasonEpsiodeNumber))
                    tokensSeasonEpsiodeNumber = tokensSeasonEpsiodeNumber(1);
                end
                % what's left is the episode names
                expression = '\s*{(?<episode>.*?)\s*}\s*';
                tokensEpisodeName = regexp(char(join(line)), expression, 'names');
                s = 1;
                if(~isempty(tokensTitleYear) && ~isempty(tokensTitleYear.title))
                    e = s + length(tokensTitleYear.title) - 1;
                    obj.charBuffer(s:e) = tokensTitleYear.title(1:end);
                    s = e + 1;
                end
                obj.charBuffer(s) = '|';
                s = s + 1;
                if(~isempty(tokensTitleYear) && ~isempty(tokensTitleYear.year))
                    e = s + length(tokensTitleYear.year) - 1;
                    obj.charBuffer(s:e) = tokensTitleYear.year(1:end);
                    s = e + 1;
                end
                obj.charBuffer(s) = '|';
                s = s + 1;
                % let's try skipping episode name since the strings might
                % not match well
                %{
                if(~isempty(tokensEpisodeName) && ~isempty(tokensEpisodeName.episode))
                    e = s + length(tokensEpisodeName.episode) - 1;
                    obj.charBuffer(s:e) = tokensEpisodeName.episode(1:end);
                    s = e + 1;
                end
                %}
                obj.charBuffer(s) = '|';
                s = s + 1;
                if(~isempty(tokensSeasonEpsiodeNumber) &&~isempty(tokensSeasonEpsiodeNumber.season))
                    e = s + length(tokensSeasonEpsiodeNumber.season) - 1;
                    obj.charBuffer(s:e) = tokensSeasonEpsiodeNumber.season(1:end);
                    s = e + 1;
                end
                obj.charBuffer(s) = '|';
                s = s + 1;
                if(~isempty(tokensSeasonEpsiodeNumber) && ~isempty(tokensSeasonEpsiodeNumber.episodeNumber))
                    e = s + length(tokensSeasonEpsiodeNumber.episodeNumber) - 1;
                    obj.charBuffer(s:e) = tokensSeasonEpsiodeNumber.episodeNumber(1:end);
                    s = e + 1;
                end
                % s = e+1;
                % e = s;
                % obj.charBuffer(s:e) = '\0';
                key = obj.charBuffer(1:(s-1));
                % key=strcat(tokensTitleYear.title,'|',tokensTitleYear.year,'|',tokensEpisodeName.episode,'|',tokensSeasonEpsiodeNumber.season,'|',tokensSeasonEpsiodeNumber.episodeNumber);
                % key=char(key);
                if(isKey(map,key))
                    titleID = map(key);
                    % Bulk of this is "Fox and Friends" type daily shows.
                    % Removing because some unaired pilots have weird production
                    % company data that is messing with 'real' values.
                    if(~isempty(tokensEpisodeName) && isempty(tokensSeasonEpsiodeNumber)) 
                       titleID = NaN;
                    end                    
                else
                    % throwing too many errors on producerprocessor since
                    % the data mixes TV with movies
                    if(debug)
                        fprintf('Couldn''t find key: %s\n',key);
                    end
                    titleID = NaN;
                end
            else
                if(debug)
                    fprintf('Title / year failure: %s\n',line{1});
                end
                titleID = NaN;
            end         
        end
        function nameID = lookupNameID(obj,name,debug)
            if(~exist('debug','var'))
                debug = true;
            end
            
            nameID = NaN;
            map = obj.getMapNames();
            
            tokens = regexp(name,'^(?<lastname>[^,]*?)\s*,\s*(?<firstname>.*)','names');
            if(isempty(tokens))
				% default to name being lastname
				key = strcat('|',name);
            else 
                key = strcat(tokens.firstname,'|',tokens.lastname);
			end
			if(isKey(map,key))
				nameID = map(key);
			else
				% throwing too many errors on producerprocessor since
				% the data mixes TV with movies
				if(debug)
					fprintf('Couldn''t find name: %s\n',key);
				end
			end
        end
    end
    methods (Access = private)
        function loadMapShow(obj)
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

            % only doing the short version since matches are more reliable
            % key = strcat(ShowName,'|',strYear,'|',EpisodeName,'|',strSeason,'|',strEpisodeNumber);
            keyShort = strcat(ShowName,'|',strYear,'||',strSeason,'|',strEpisodeNumber);

            disp('Building map');
            % obj.mapShow = containers.Map(key,TitleID,'UniformValues',true);
            % obj.mapShow = [obj.mapShow;containers.Map(keyShort,TitleID,'UniformValues',true)];
            obj.mapShow = containers.Map(keyShort,TitleID,'UniformValues',true);

            disp('Done loading map');

        end
        function loadMapNames(obj)
            filename = '../dbs/names.csv';
            delimiter = ',';
            startRow = 2;

            formatSpec = '%f%q%q%[^\n\r]';

            %% Open the text file.
            fprintf('Loading %s\n',filename);
            fileID = fopen(filename,'r');

            dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'EmptyValue' ,NaN,'HeaderLines' ,startRow-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');

            %% Close the text file.
            fclose(fileID);


            %% Allocate imported array to column variable names
            NameID = dataArray{:, 1};
            FirstName = dataArray{:, 2};
            LastName = dataArray{:, 3};

            %% Clear temporary variables
            clearvars filename delimiter startRow formatSpec fileID dataArray ans;

            disp('Parsing strings');

            key = strcat(FirstName,'|',LastName);

            disp('Building map');
            obj.mapNames = containers.Map(key,NameID,'UniformValues',true);

            disp('Done loading map');

        end        
    end


end

