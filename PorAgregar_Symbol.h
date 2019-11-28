typedef struct Symbol{
	char *name;
	int type;
	int first;
	int last;
	int in, out;
	char *redir;
	struct Symbol *next;
}Symbol;

Symbol *lookup(char *s);
Symbol *install(char *s, int type);

static Symbol *symlist = 0;

Symbol *lookup(char *s){
    Symbol *sp;
    for (sp=symlist; sp != (Symbol *)0; sp=sp->next ){
        if((strcmp(sp->name,s)) == 0){
            return sp;
        }
    }
    return 0;
}




