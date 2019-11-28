Gram=y.tab.c y.tab.h

all: $(Gram)
	@gcc -o minijs y.tab.c symbol.c code.c init.c math.c -lm
	@echo Compiled

$(Gram): minijs.y
	@yacc -d minijs.y
clean:
	@rm -f *.out  *.tab.* com
	@echo Clean
