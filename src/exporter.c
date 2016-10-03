#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "moviedb.h"
#include "dbutils.h"
#include "exporter.h"



int main ( int argc, char **argv ) {
	
	int iReturnValue = 0;

	iReturnValue = exportTitles();

	return iReturnValue;
}

//return value needs to be freed after use
char* encodeCSVString(const char* strInput) {
	//first count number of quotes in input
	int iQuoteCount = 0;
	char * ptrQuote = strchr(strInput,'"');
	while(ptrQuote != NULL) {
		iQuoteCount++;
		ptrQuote = strchr(ptrQuote+1,'"');
	}
	
	//then allocate space for the doublequoted version
	//with an extra quote on both ends and the end string character
	long lSize = (strlen(strInput)+ iQuoteCount + 2 + 1) * sizeof(char);
	char * strOutput = malloc(lSize);
	
	//now go through the original string and copy double quotes
	char  * ptrInput, * ptrOutput;
	ptrOutput = strOutput;
	*ptrOutput = '"';
	ptrOutput++;
	ptrInput = strInput;
	while(*ptrInput != '\0') {
		if(*ptrInput == '"') {
			*ptrOutput = '"';
			ptrOutput++;			
		}
		*ptrOutput = *ptrInput;
		ptrOutput++;			
		ptrInput++;
	}
	*ptrOutput = '"';
	ptrOutput++;			
	*ptrOutput = '\0';
	return strOutput;
}

int exportAttributes() {
	//coded in two passes
	//first we count the maximum number of attributes per line 
	//then we do the actual file parsing

	FILE * fpAttributesCSV, * fpAttributesKey;	
	fpAttributesKey = openFile ( ATTRKEY ) ;
	int iMaxAttributes = 0;
	char  line [ MXLINELEN ] ;
	long lLineNumber = 0;
	long lMaxLine = 0;
	
	while ( fgets ( line, MXLINELEN, fpAttributesKey ) != NULL ) {
		
		lLineNumber++;
		if (lLineNumber % 10000 == 0) {
			fprintf(stderr, "Line: %li\n",lLineNumber);
		}
		
		int iLineAttributes = 0;
		char * ptrToken = strtok(line, "()");
		while(ptrToken != NULL ) {
			iLineAttributes++;
			ptrToken = strtok(NULL, "()");
		}
		iMaxAttributes = iLineAttributes > iMaxAttributes ? iLineAttributes : iMaxAttributes;
		lMaxLine = iLineAttributes == iMaxAttributes ? lLineNumber : lMaxLine;
	}
	fclose(fpAttributesKey);
	
	fprintf(stderr,"Max attributes : %i at line %li\n",iMaxAttributes,lMaxLine);
	
	//open csvfile for writing
	fpAttributesCSV = writeFile(ATTRIBUTESCSV);
	//writer out headers
	putString("AttributeID", fpAttributesCSV);
	int iAttributeCount = 0;
	while(iAttributeCount++ < iMaxAttributes) {
		fprintf(fpAttributesCSV,",Attribute %i",iAttributeCount);
	}
	putString("\n", fpAttributesCSV);
	
	char * ptrID;
	fpAttributesKey = openFile ( ATTRKEY ) ;
	lLineNumber = 0;
	
	while ( fgets ( line, MXLINELEN, fpAttributesKey ) != NULL ) {
		
		lLineNumber++;
		if (lLineNumber % 10000 == 0) {
			fprintf(stderr, "Line: %li\n",lLineNumber);
		}
		
		//first get the ID
		ptrID = strchr(line,FSEP);
		if(ptrID == NULL) {
			fprintf(stderr,"Missing ID marker on line %li\n",lLineNumber);
			continue;
		}
		*ptrID = '\0';
		long lNameID = strtol (ptrID + 1, (char **) NULL, 16);	
		fprintf(fpAttributesCSV,"%li",lNameID);
		
		char * ptrToken = strtok(line, "()");
		while(ptrToken != NULL ) {
			//remove initial padding
			while(*ptrToken == ' ') {
				ptrToken++;
			}
			//write out only if non-empty at this point
			if(*ptrToken != '\0') {
				char * encodedString = encodeCSVString(ptrToken);
				fprintf(fpAttributesCSV,",%s",encodedString);
				free(encodedString);
			}
			ptrToken = strtok(NULL, "()");
		}
		putString("\n", fpAttributesCSV);
	}
	fclose(fpAttributesKey);
	fclose(fpAttributesCSV);
	
}

int exportNames() {

	FILE * fpNamesCSV, * fpNamesKey;

	//open csvfile for writing
	fpNamesCSV = writeFile(NAMESCSV);
	//writer out headers
	putString("NameID,First Name,Last Name\n", fpNamesCSV);

	char  line [ MXLINELEN ] ;
	char  *ptrID, *ptrFirstName, *ptrLastName;
	char* emptyString = "";
	long lineNumber = 0;

	//opening title file and dump to CSV
	fpNamesKey = openFile ( NAMEKEY ) ;
	while ( fgets ( line, MXLINELEN, fpNamesKey ) != NULL ) {
		// Example Line: 
		// Galvan, Annabelle|2b21fc
	
		lineNumber++;
		if (lineNumber % 10000 == 0) {
			fprintf(stderr, "Line: %li\n",lineNumber);
		}
		
		//find the id marker and set it as the end of the name string
		ptrID = strchr(line,FSEP);
		if(ptrID == NULL) {
			fprintf(stderr,"Missing ID marker on line %li\n",lineNumber);
			continue;
		}
		*ptrID = '\0';
		long lNameID = strtol (ptrID + 1, (char **) NULL, 16);
		
		ptrFirstName = strchr(line,',');
		if(ptrFirstName == NULL) {
			ptrFirstName = emptyString;
		} else {
			*ptrFirstName = '\0';
			ptrFirstName++;
			if(*ptrFirstName == ' ') {
				ptrFirstName++;
			}
		}
		
		ptrLastName = line;
		
		char * strEncodedFirst, * strEncodedLast;
		strEncodedFirst = encodeCSVString(ptrFirstName);
		strEncodedLast = encodeCSVString(ptrLastName);
		
		fprintf(fpNamesCSV,"%li,%s, %s\n",
			lNameID,
			strEncodedFirst, 
			strEncodedLast);

		free(strEncodedFirst);
		free(strEncodedLast);
			
		
	}
	fclose(fpNamesCSV);
	fclose(fpNamesKey);
	return 0;
}

int exportTitles() {
	FILE * fpTitlesCSV, * fpTitlesKey;

	//open csvfile for writing
	fpTitlesCSV = writeFile(TITLESCSV);
	//writer out headers
	putString("TitleID,Show Name, Year, Episode Name, Season, Episode Number,Is Suspended\n", fpTitlesCSV);

	char  line [ MXLINELEN ] ;
	char  *ptrID, *ptrEndquote, *ptrYear, *ptrEndYear, *ptrEpisodeName, *ptrEndEpisodeName, *ptrStartBracket, *ptrEndBracket, *ptrSeason, *ptrEpisodeNumber, *ptrEndEpisodeNumber, *ptrSuspended;
	char* emptyString = "";
	long lineNumber = 0;

	//opening title file and dump to CSV
	fpTitlesKey = openFile ( TITLEKEY ) ;
	while ( fgets ( line, MXLINELEN, fpTitlesKey ) != NULL ) {
		// Example Line: 
		// "#1 Single" (2006) {Cats and Dogs (#1.4)}|2
	
		lineNumber++;
		
		//if the first character isn't ", its not a TV show
		if (line[0] != TVQUOTE) continue;
		char* strTitleName = line+1;
		
		//verify there is an endquote, otherwise something is wrong with this record
		ptrEndquote = strchr(strTitleName,TVQUOTE);
		if(ptrEndquote == NULL) {
			fprintf(stderr,"Missing endquote on line %li\n",lineNumber);
			continue;
		}
		//set endquote as end of string
		*ptrEndquote = '\0';
				
		//check for marker of begining of ID		
	    ptrID = strchr ( ptrEndquote+1, FSEP ) ;
		if(ptrID == NULL) {
			fprintf(stderr,"Missing ID marker on line %li\n",lineNumber);
			continue;
		}
		//the fgets should put a null at the end of the ID number
		long lTitleID = strtol (ptrID + 1, (char **) NULL, 16);

		//check if suspended flag is set
		//"#GirlProblems" (2015) {{SUSPENDED}}|aa
		int isSuspended = FALSE;
		ptrSuspended = strstr(ptrEndquote+1, " {{SUSPENDED}}");
		if(ptrSuspended != NULL) {
			isSuspended = TRUE;
			//move things around so the rest of the code works
			*ptrSuspended = FSEP;
			*(ptrSuspended+1) = '\0';
			ptrID = ptrSuspended;
		}		
		
		//next find the year begining marker
		ptrYear = strchr(ptrEndquote+1,'(');
		if(ptrYear == NULL) {
			fprintf(stderr,"Missing year on line %li\n",lineNumber);
			continue;
		}
		//year starts one after the marker;
		ptrYear = ptrYear+1;
		//next find the year end marker
		ptrEndYear = strchr(ptrYear,')');
		if(ptrYear == NULL) {
			fprintf(stderr,"Missing year on line %li\n",lineNumber);
			continue;
		}		
		*ptrEndYear = '\0';
				
		//All of these other strings are optional; assuming any combination of existance is ok
		ptrEpisodeName=ptrSeason=ptrEpisodeNumber=emptyString;
	
		//next find the epsiode information begining marker
		ptrStartBracket = strchr(ptrEndYear+1,'{');
		if(ptrStartBracket != NULL) {
			ptrEndBracket = strchr(ptrStartBracket,'}');
			if(ptrEndBracket == NULL) {
				fprintf(stderr,"Missing end bracket on line %li\n",lineNumber);
				continue;
			}
			//as a robustness check should have ptrID -1 = end epsiode
			if(ptrEndBracket+1 != ptrID) {
				fprintf(stderr,"End bracket and ID misaligned on line %li\n",lineNumber);
				continue;
			}
			ptrEpisodeName = ptrStartBracket+1;
			ptrEndEpisodeName = strchr(ptrStartBracket+1,'(');
			if(ptrEndEpisodeName == NULL) {
				//could be a case of missing episode information
				ptrEndEpisodeName = strchr(ptrStartBracket+1,'}');
				//need to add one since we usually go back one to null
				ptrEndEpisodeName++;
				if(ptrEndEpisodeName == NULL) {				
					fprintf(stderr,"Missing end name on line %li\n",lineNumber);
					continue;
				}
			}			
			*(ptrEndEpisodeName-1) = '\0';				

			//look for episode information
			ptrSeason = strchr(ptrEndEpisodeName+1,'#');
			if(ptrSeason == NULL) {
				ptrSeason = emptyString;
			} else {
				ptrSeason = ptrSeason+1;
			}
			
			//now episode number information
			ptrEpisodeNumber = strchr(ptrSeason,'.');
			if(ptrEpisodeNumber == NULL) {
				ptrEpisodeNumber = emptyString;
			} else {
				*ptrEpisodeNumber = '\0';
				ptrEpisodeNumber = ptrEpisodeNumber+1;
			}
	
			
			ptrEndEpisodeNumber = strchr(ptrEpisodeNumber,')');
			if(ptrEndEpisodeNumber != NULL) {
				*ptrEndEpisodeNumber = '\0';
			}
			*ptrEndBracket = '\0';			
		}	

		// char * strEncodedTitle, * strEncodedYear, * strEncodedEpisodeName, * strEncodedSeason, * strEncodedEpisodeNumber;
		char * strEncodedTitle, * strEncodedEpisodeName;
		strEncodedTitle = encodeCSVString(strTitleName);
		int iYear = atoi(ptrYear);
		//strEncodedYear = encodeCSVString(ptrYear);
		strEncodedEpisodeName = encodeCSVString(ptrEpisodeName);
		int iSeason = atoi(ptrSeason);
		//strEncodedSeason = encodeCSVString(ptrSeason);
		int iEpisodeNumber = atoi(ptrEpisodeNumber);
		//strEncodedEpisodeNumber = encodeCSVString(ptrEpisodeNumber);
		
		//write out the line of data
		fprintf(fpTitlesCSV,"%li,%s, %i, %s, %i, %i, %i\n",
			lTitleID,
			strEncodedTitle, 
			iYear,
			strEncodedEpisodeName ,
			iSeason ,
			iEpisodeNumber,
			isSuspended);
			
			/* 		fprintf(fpTitlesCSV,"%li,%s, %s, %s, %s, %s, %i\n",
			lTitleID,
			strEncodedTitle, 
			strEncodedYear,
			strEncodedEpisodeName ,
			strEncodedSeason ,
			strEncodedEpisodeNumber,
			isSuspended); */			
			
		free(strEncodedTitle);
		//free(strEncodedYear);
		free(strEncodedEpisodeName);
		//free(strEncodedSeason);
		//free(strEncodedEpisodeNumber);
	}
	
	fclose(fpTitlesCSV);
	fclose(fpTitlesKey);
	
	return 0;	
}

