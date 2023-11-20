%{
#include <stdio.h>
#include <stdlib.h>
#include "gvlogo.tab.h"

extern void yyerror(const char* s);
%}

%%
;           { return SEP; }
PENUP     { return PENUP; }
PENDOWN    { return PENDOWN; }
PRINT      { return PRINT; }
CHANGECOLOR { return CHANGE_COLOR; }
COLOR      { return COLOR; }
CLEAR      { return CLEAR; }
TURN       { return TURN; }
WHERE      { return WHERE; }
LOOP        { return LOOP; }
MOVE       { return MOVE; }
SAVE       { return SAVE; }
GOTO        { return GOTO; }
\+          { return PLUS; }
-          { return SUB; }
\*          { return MULT; }
\/          { return DIV; }
=          { return ASSIGN; }
[0-9]+(\.[0-9]+)?  { yylval.f = atof(yytext); return NUMBER; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.s = strdup(yytext); return VARIABLE; }
[ \t\r\n]			;
.			{ yyerror("Lexing Syntax error.\n"); } 

%%
