#include <iostream>
#include "moviedb.h"
#include "dbutils.h"
#include "exporter.h"
#include "csv.h"

int main {
	std::cout << "Creating Titles Index\n"
	io::CSVReader<7,
		trim_char<' ','\t'>,
		double_quote_escape<',', '"'>,
		> in(TITLESCSV);
	in.read_header(no_comment, 
		"TitleID",
		"Show Name", 
		"Year", 
		"Episode Name", 
		"Season", 
		"Episode Number",
		"Is Suspended");
	long lTitleID;
	std::string strShowName;
	int iYear
	std::string strEpisodeName;
	int iSeasonl
	int iEpisodeNumber;
	bool IsSuspended;
	std::map<string,std::map<string,long>> mapShow;
	while(in.read_row(vendor, size, speed)){
		// do stuff with the data
	}
}