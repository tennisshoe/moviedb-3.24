#include <iostream>
#include <map>
#include "exporter.h"
#define CSV_IO_NO_THREAD
#include "csv.h"



int main () {
	std::cout << "Creating Titles Index"  << std::endl;
	io::CSVReader<7,
		io::trim_chars<' ','\t'>,
		io::double_quote_escape<',', '"'>,
		io::throw_on_overflow,
		io::no_comment> in(TITLESCSV);
	in.read_header(io::ignore_no_column, 
		"TitleID",
		"Show Name", 
		"Year", 
		"Episode Name", 
		"Season", 
		"Episode Number",
		"Is Suspended");
	long lTitleID;
	std::string strShowName;
	char* striYear;
	std::string strEpisodeName;
	char* ptriSeason;
	char* ptriEpisodeNumber;
	int IsSuspended;
	std::map<std::string,long> mapShow;
	while(in.read_row(lTitleID, strShowName, striYear,strEpisodeName,ptriSeason,ptriEpisodeNumber,IsSuspended)){
		std::string key = strShowName + '|' + striYear + '|' + strEpisodeName +'|'+ ptriSeason+'|'+ ptriEpisodeNumber;
		mapShow[key] = lTitleID;
	}
	std::cout << "Created Titles Index of " << mapShow.size() << " elements" << std::endl;
	

}