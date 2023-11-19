%{
#include <stdio.h>
#include <stdlib.h>
#include "gvlogo.tab.h"

extern void yyerror(const char* s);
%}

%%
penup      { return PENUP; }
pendown    { return PENDOWN; }
print      { return PRINT; }
changecolor { return CHANGE_COLOR; }
color      { return COLOR; }
clear      { return CLEAR; }
turn       { return TURN; }
where      { return WHERE; }
loop       { return LOOP; }
move       { return MOVE; }
save       { return SAVE; }
+          { return PLUS; }
-          { return SUB; }
*          { return MULT; }
/          { return DIV; }
=          { return ASSIGN; }
[0-9]+(\.[0-9]+)?  { yylval.f = atof(yytext); return NUMBER; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.s = strdup(yytext); return VARIABLE; }
[ \t\r\n]			;
.			{ yyerror("Lexing Syntax error.\n"); } 

%%
