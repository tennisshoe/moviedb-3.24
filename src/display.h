void displayTitleMatches ( struct titleSearchRec *tchain ) ;
void displayListallTitleMatches ( struct titleSearchRec *tchain ) ;
void displayBiography ( struct personRec *rec, char *name, int biopt, struct akaNameRec *aka ) ;
void displayMovieLinks ( int noOfEntries, struct movieLinkRec *links ) ;
void displayPlot ( struct plotRec *rec ) ;
void displayLiterature ( struct lineRec *rec ) ;
void displayNameSearchResults ( struct nameSearchRec *nrec, int tidy ) ;
void displayNameSearchResultsAsBallot ( struct nameSearchRec *nrec ) ;
void displayRawTitleAttrPairs ( struct listEntry lrec [ ], int count, char *name ) ;
void displayTrivia ( struct lineRec *triv, int listId ) ;
void displayTagLines ( struct lineRec *triv ) ;
void displayTitleInfo ( struct titleInfoRec *triv, int listId ) ;
void displayCompactTitleInfo ( struct titleInfoRec *titleInfo, int listId ) ;
void displayTitleSearchResults ( struct titleSearchRec *trec, int tidy ) ;
