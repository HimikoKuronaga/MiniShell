typedef union Datum{
	Symbol *sym;
	char *string;
	int val;	
}Datum;

typedef void (*Inst)();
#define STOP (Inst)0

#define NSTACK 256
#define NPROG 2000
#define MAXARGS 15

#define READ 0
#define WRITE 1

static Datum stack[NSTACK];	/* la pila */
static Datum *stackp;		/* siguiente lugar libre en la pila */

Inst prog[NPROG]; 	/* la maquina */
Inst *progp;	  	/* siguiente lugar libre para la generacion de codigo */
Inst *pc;		/* contador de programa durante la ejecucion */


static int argc;
int fd[2];
char *args[MAXARGS];
int input;
extern void execerror(char *s, char *t);
char *PROYECTO = "PROYECTO"; 

void initcode();
Inst *code(Inst f);
void execute(Inst *p);


void push(Datum d); /*Mete un valor a la pila*/
Datum pop();		/*Saca un elemento de la pila*/
void printdir();	/*Imprime el directorio en el que se encuentra*/
void exec();		/*ejecuta el programa escrito*/
void argpush();		/*Mete a la pila un parametro del programa que se desea ejecutar*/
void optioncode();	/*saca el ultimo parametro que entro y le concatena un '-' */
void cdcode();		/*Para cambiar de directorio*/

void argspop();		

void initcode(){
	stackp = stack;
	progp = prog;
	argc = 0;
	pipe(fd);
}

Inst *code(Inst f){ 
	Inst *oprogp = progp;
	if (progp >= &prog[NPROG])
		execerror("\nProgram to big\n", "");
	*progp++ = f;
	return oprogp;
}

void execute(Inst *p){ 
	for(pc  =  p;   *pc != STOP ;) 
		(*(*pc++))();
}

void push(Datum d){
    if (stackp >= &stack[NSTACK])
		execerror("\nSTACK UNDERFLOW\n", "");
	*stackp++ = d;
}

Datum pop(){
	if (stackp <= stack)
		execerror("\nSTACK UNDERFLOW\n", "");	
	return *--stackp;
}

void printdir(){
	char cwd[1024];
	getcwd(cwd, sizeof(cwd));
	printf("%s # ", cwd);
}

void exec(){
	Datum d;
	d = pop();
	argspop();
	args[0] = d.sym->name;	
	int primero = d.sym->first, ultimo = d.sym -> last;

	pipe(fd);
	pid_t pid = fork();
	if(pid < 0){
		puts("Error en fork");
		return;
	}else if(pid == 0){
		if(d.sym->in){
			fd[0] = open(PROYECTO, O_RDONLY |  O_CREAT, 0555);
			close(0);
			dup(fd[0]);
		}else if(primero && !ultimo){
			fd[1] = open(PROYECTO, O_WRONLY | O_TRUNC |  O_CREAT, 0666);
			close(1);
			dup(fd[1]);
		}else if( !primero && !ultimo){
			fd[0] = open(PROYECTO, O_RDWR | O_CREAT, 0777);
			close(0);
			close(1);
			dup(fd[0]);
			dup(fd[0]);
		}else if( !primero && ultimo){
			fd[0] = open(PROYECTO, O_RDONLY | O_CREAT, 0777);
			close(0);
			dup(fd[0]);		
		}
		if(d.sym->out){
				fd[1] = open(d.sym->redir, O_WRONLY | O_TRUNC |  O_CREAT, 0666);
				close(1);
				dup(fd[1]);
		}

		if(execvp(args[0],args) < 0)
				fprintf(stderr, "\n\tERROR: No se pudo ejecutar el comando: %s\n\n", args[0]);		
		exit(0);
	}else{
		close(fd[1]);
		close(fd[0]);
		wait(NULL);
		return;
	}
}


void programpush(){
	Datum d;
	d.sym = ((Symbol *)*pc++);
	push(d);
}

void argpush(){
	Datum d;
	d.string = ((Symbol *)*pc++)->name;
	push(d);
	argc++;
}

void optioncode(){
	Datum d = pop();
	int len = strlen(d.string);
	char *buf = (char*)malloc(sizeof(char)*len);
	strcat(buf,"-");
	strcat(buf,d.string);
	d.string = buf;
	push(d);
}


void cdcode(){
	Datum d;
	d = pop();
	chdir(d.string);  
}

void argspop(){
	int i;
	Datum d;
	args[argc+1] = NULL;
	for( i = argc ; i >= 1 ; i--){
		d = pop();
		args[i] = d.string;
	}
	argc = 0;
}



