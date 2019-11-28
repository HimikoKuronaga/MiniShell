%{

	#include <string.h>
	#include <ctype.h>
	#include <stdio.h>
	#include <stdlib.h>
	#include <unistd.h>
	#include <setjmp.h>
	#include <sys/types.h>
	#include <sys/wait.h>
	#include <fcntl.h>
	#include "Symbol.h"
	#include "Code.h"

	#define CD_MS 200
	#define code2(c1,c2); code(c1); code(c2);
	#define code3(c1,c2,c3); code(c1); code(c2); code(c3);
	
	void yyerror (char *s);
	int yylex ();
	void warning(char *s, char *t);
	void extern execerror(char *s, char* t);
%}

%union{
	Symbol *sym;
	Inst *inst;
	int narg;
}

%token<sym> INDEF PROGRAMA ARG CD PATH BACK
%type<sym> programa  
%type<sym> program 
%type<narg> arglist
%right '|' 
%right '>'
%right '-'
%right '*'
%left '<'
%%

list	: 			
	    | list '\n'	            { code2(printdir, STOP); return 1; }
	    | list programa '\n'	{ code2(printdir,STOP); return 1; }
	    | list cd '\n'		    { code3(cdcode, printdir, STOP); return 1; }
	    ;
programa: program  			{ $$=$1; code(exec);  }
	| programa '|' 	programa 	{ if($1->first){$3->first = 0; $1->last = 0;} }
	| programa '>' 	ARG		{ $1->out = 1; $1->redir = $3->name;}
	| programa '<' 	ARG		{ $1->in = 1; $1->redir = $3->name;}		
	;
program : PROGRAMA arglist	{ $$=$1; code2(programpush, (Inst)$1); $1->first = 1; $1->last = 1;}
	;
arglist : /*NOTHING*/   	{ $$ = 0; }
	| expr			{ $$ = 1; }
	| arglist expr	    	{ $$ = $1 + 1; }
	;
expr: ARG			{ code2(argpush,(Inst)$1); }
	| PATH			{ code2(argpush,(Inst)$1); }
	| '-' expr		{ code(optioncode); }
	;
cd  : CD PATH               { code2(argpush, (Inst)$2); }
    | CD ARG                { code2(argpush, (Inst)$2); }
    | CD BACK               { code2(argpush, (Inst)$2); }
    ;
%%

Symbol *install(char *s, int type){
	Symbol *sp = (Symbol *)malloc(sizeof(Symbol));
	sp->name = (char *)malloc(sizeof(strlen(s))+1);
	
	if(type == PROGRAMA){
		int sp->in = 0, sp->out = 0;
	}	

	strcpy(sp->name,s);
	sp->type = type;
	sp->next = symlist;
	

	sp->next = symlist;
	symlist = sp;
	return sp;
}

static struct{
	char *name;	
	int kval;
} comands[] = {
	"cal", PROGRAMA,
	"cat", PROGRAMA,
	"clear", PROGRAMA,
	"cd", CD, 
	"cp", PROGRAMA,
	"date", PROGRAMA,
	"df", PROGRAMA,
	"du", PROGRAMA,
	"find", PROGRAMA,
	"grep", PROGRAMA,
	"head", PROGRAMA,
	"ls", PROGRAMA,
	"mkdir", PROGRAMA,
	"mv", PROGRAMA,
	"ps", PROGRAMA,
	"pstree", PROGRAMA,
	"pwd", PROGRAMA,
	"rm", PROGRAMA,
	"sort", PROGRAMA,
	"uname", PROGRAMA,
	"w", PROGRAMA,
	"wc", PROGRAMA,
	"which", PROGRAMA,
	"who", PROGRAMA,
	"..", BACK, 
	0,0,
};

void init(){
	int i = 0;
	for(i = 0; comands[i].name; i++){
		install(comands[i].name,comands[i].kval);
	}
}

int lineno;
int yylex (){
  	int c;
  	while ((c = getchar ()) == ' ' || c == '\t')  
  		;
 	if (c == EOF) return 0;
	
	else if(isalnum(c)){
		Symbol *s;
		char sbuf[200], *p=sbuf;
		do {
			*p++=c;
		} while ((c=getchar())!=EOF && isalnum(c) || c == '.' );
		ungetc(c, stdin);
		*p='\0';
		
		if((s=lookup(sbuf))==(Symbol *)NULL)
			s = install(sbuf,ARG);
		yylval.sym = s;

		return s->type;
	}else if( c == '/' || c == '.'){
	    Symbol *s;
		char sbuf[200], *p=sbuf;
		do {
			*p++=c;
		} while ((c=getchar())!=EOF && isalnum(c) || c == '/' || c =='.' || c == '_' || c == '-' );
		ungetc(c, stdin);
		*p='\0';

		if((s=lookup(sbuf))==(Symbol *)NULL)
			s = install(sbuf,PATH);
		yylval.sym=s;
		return s->type;
		
	}else if(c == '\n')
		lineno++;
	
	return c;	                
}

void yyerror (char *s) {
	warning(s, (char *) 0);
}

void warning(char *s, char *t){
	if(t)
		fprintf (stderr, " %s %s", t, s);
	fprintf (stderr, "Error cerca de la linea: %d\n", lineno);
}

jmp_buf begin;
extern void execerror(char *s, char *t){
	warning(s, t);    
	longjmp(begin, 0); 
}

void main (int argc, char *argv[]){
	init();
	setjmp(begin);	
	for(initcode(); yyparse(); initcode())
		execute(prog);
}
