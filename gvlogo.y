%{
#define WIDTH 640
#define HEIGHT 480
#define MAX_VARIABLES 256    //added


#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_thread.h>

static SDL_Window* window;
static SDL_Renderer* rend;
static SDL_Texture* texture;
static SDL_Thread* background_id;
static SDL_Event event;
static int running = 1;
static const int PEN_EVENT = SDL_USEREVENT + 1;
static const int DRAW_EVENT = SDL_USEREVENT + 2;
static const int COLOR_EVENT = SDL_USEREVENT + 3;

double variables[MAX_VARIABLES]; // Array to store variable values
char* varNames[MAX_VARIABLES];   // Array to store variable names
int varCount = 0;

typedef struct color_t {
	unsigned char r;
	unsigned char g;
	unsigned char b;
} color;

static color current_color;
static double x = WIDTH / 2;
static double y = HEIGHT / 2;
static int pen_state = 1;
static double direction = 0.0;

int yylex(void);
void yyerror(const char* s);
void startup();
int run(void* data);
void prompt();
void penup();
void pendown();
void move(double num);
void turn(double dir);
void where();  // added
void gotoxy(double x, double y); // added
int lookupVariable(char *varName); // added
void setVariable(char *varName, double value); // added
void output(const char* s);
void change_color(int r, int g, int b);
void clear();
void save(const char* path);
void shutdown();


%}

%union {
	float f;
	int i;    //added
	char* s;

}

%locations

%token SEP
%token PENUP
%token PENDOWN
%token PRINT
%token CHANGE_COLOR
%token COLOR
%token CLEAR
%token TURN
%token WHERE 
%token LOOP
%token MOVE
%token SAVE
%token GOTO
%token EQUALS
%token NUMBER
%token END
%token PLUS SUB MULT DIV
%token ASSIGN                      //added
%token<s> STRING QSTRING
%token <s> VARIABLE
%type<f> expression NUMBER
%type <i> variable            //added
%left PLUS SUB				   //added
%left MULT DIV             //added
%%

program:		
				statement_list END				{ printf("Program complete."); shutdown(); exit(0); }
		;
statement_list:	
				statement					
		|	    statement_list statement
		;
statement:		
				command SEP					{ prompt(); }
		|	    error '\n' 					{ yyerrok; prompt(); }
		|       VARIABLE ASSIGN expression { setVariable($1, $3); }
		|  		expression { printf("Result: %f\n", $1); }
		;

command:		
				PENUP						{ penup(); }
        |       PENDOWN                     { pendown(); }
		|       PRINT QSTRING               { printf("%s", $2); }
		|       SAVE STRING                 { save($2); }
		|       COLOR NUMBER NUMBER NUMBER  { change_color($2, $3, $4); }
		|       CLEAR                       { clear(); }
		|       TURN expression             { turn($2); }
		|       MOVE expression             { move($2); }
		|       GOTO expression expression  { gotoxy($2, $3); }
		|       WHERE                       { where(); }
		;

expression:	
			 NUMBER { $$ = $1; }
		| 	expression PLUS expression { $$ = $1 + $3; }
		| 	expression SUB expression { $$ = $1 - $3; }
		| 	expression MULT expression { $$ = $1 * $3; }
		| 	expression DIV expression { $$ = $1 / $3; }
		| 	'(' expression ')' { $$ = $2; }  
		| 	variable { $$ = variables[$1]; }
		;

variable:
    		VARIABLE { $$ = lookupVariable(yylval.s); }
	;

%%

int main(int argc, char** argv){
	startup();
	return 0;
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

void prompt(){
	printf("gv_logo > ");
}

void penup(){
	event.type = PEN_EVENT;		
	event.user.code = 0;
	SDL_PushEvent(&event);
}

void pendown() {
	event.type = PEN_EVENT;		
	event.user.code = 1;
	SDL_PushEvent(&event);
}

void move(double num){
	event.type = DRAW_EVENT;
	event.user.code = 1;
	event.user.data1 = (void*)(intptr_t)num;
	SDL_PushEvent(&event);
}

void turn(double dir){
	event.type = PEN_EVENT;
	event.user.code = 2;
	event.user.data1 = (void*)(intptr_t)dir;
	SDL_PushEvent(&event);
}
// Modify the CFG to allow a variable value in the move , turn , and goto  commands
// *goto - Moves the turtle to a particular coordinate.Draws if the pen is down, otherwise does not.
void gotoxy(double newx, double newy) {
	if (pen_state) {
		SDL_SetRenderTarget(rend, texture);
		SDL_RenderDrawLine(rend, x, y, newx, newy);
		SDL_SetRenderTarget(rend, NULL);
	    SDL_RenderCopy(rend, texture, NULL, NULL); // Update the window with the new line

	}
	// then  update the position
	x = newx;
	y = newy;
}

// *where - Prints the current coordinates.
void where(){
	printf("Current position: (%f, %f)\n", x, y);
}

// Add variables. You can limit the number of possible variables and simply create a fixed sized array
// to use, or implement a dynamically sized symbol table.
int lookupVariable(char *varName) {
    for (int i = 0; i < varCount; ++i) {
        if (strcmp(varNames[i], varName) == 0) {
            return i;
        }
    }
    // create a new one
    if (varCount < MAX_VARIABLES) {
        varNames[varCount] = strdup(varName);
        return varCount++;
    } else {
        yyerror("Too many variables");
        exit(1);
    }
}

void setVariable(char *varName, double value) {
    int index = lookupVariable(varName);
    variables[index] = value;
}

void output(const char* s){
	printf("%s\n", s);
}

void change_color(int r, int g, int b){
	event.type = COLOR_EVENT;
	current_color.r = r;
	current_color.g = g;
	current_color.b = b;
	SDL_PushEvent(&event);
}

void clear(){
	event.type = DRAW_EVENT;
	event.user.code = 2;
	SDL_PushEvent(&event);
}

void startup(){
	SDL_Init(SDL_INIT_VIDEO);
	window = SDL_CreateWindow("GV-Logo", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, WIDTH, HEIGHT, SDL_WINDOW_SHOWN);
	if (window == NULL){
		yyerror("Can't create SDL window.\n");
	}
	
	//rend = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_TARGETTEXTURE);
	rend = SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE | SDL_RENDERER_TARGETTEXTURE);
	SDL_SetRenderDrawBlendMode(rend, SDL_BLENDMODE_BLEND);
	texture = SDL_CreateTexture(rend, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, WIDTH, HEIGHT);
	if(texture == NULL){
		printf("Texture NULL.\n");
		exit(1);
	}
	SDL_SetRenderTarget(rend, texture);
	SDL_RenderSetScale(rend, 3.0, 3.0);

	background_id = SDL_CreateThread(run, "Parser thread", (void*)NULL);
	if(background_id == NULL){
		yyerror("Can't create thread.");
	}
	while(running){
		SDL_Event e;
		while( SDL_PollEvent(&e) ){
			if(e.type == SDL_QUIT){
				running = 0;
			}
			if(e.type == PEN_EVENT){
				if(e.user.code == 2){
					double degrees = ((intptr_t)e.user.data1) * M_PI / 180.0;
					direction += degrees;
				}
				pen_state = e.user.code;
			}
			if(e.type == DRAW_EVENT){
				if(e.user.code == 1){
					int num = (int)(intptr_t)event.user.data1;
					double x2 = x + num * cos(direction);
					double y2 = y + num * sin(direction);
					if(pen_state != 0){
						SDL_SetRenderTarget(rend, texture);
						SDL_RenderDrawLine(rend, x, y, x2, y2);
						SDL_SetRenderTarget(rend, NULL);
						SDL_RenderCopy(rend, texture, NULL, NULL);
					}
					x = x2;
					y = y2;
				} else if(e.user.code == 2){
					SDL_SetRenderTarget(rend, texture);
					SDL_RenderClear(rend);
					SDL_SetTextureColorMod(texture, current_color.r, current_color.g, current_color.b);
					SDL_SetRenderTarget(rend, NULL);
					SDL_RenderClear(rend);
				}
			}
			if(e.type == COLOR_EVENT){
				SDL_SetRenderTarget(rend, NULL);
				SDL_SetRenderDrawColor(rend, current_color.r, current_color.g, current_color.b, 255);
			}
			if(e.type == SDL_KEYDOWN){
			}

		}
		//SDL_RenderClear(rend);
		SDL_RenderPresent(rend);
		SDL_Delay(1000 / 60);
	}
}

int run(void* data){
	prompt();
	yyparse();
	return 0;
}

void shutdown(){
	running = 0;
	SDL_WaitThread(background_id, NULL);
	SDL_DestroyWindow(window);
	SDL_Quit();
}

void save(const char* path){
	SDL_Surface *surface = SDL_CreateRGBSurface(0, WIDTH, HEIGHT, 32, 0, 0, 0, 0);
	SDL_RenderReadPixels(rend, NULL, SDL_PIXELFORMAT_ARGB8888, surface->pixels, surface->pitch);
	SDL_SaveBMP(surface, path);
	SDL_FreeSurface(surface);
}
