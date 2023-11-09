# GVSU-CIS343-GvLogo

GV Logo
We've seen how languages are created - now it is time to make one!
We are going to remake a classic language called Logo (there is a version built into Python called turtle ).
Logo was a language created for educational purposes, with a focus on drawing. You had a little turtle on
the screen, and you moved her around with commands. You imagined a pen being attached to the turtle's
tail, and if the pen was down, the turtle drew as she moved.

# Recall, you build as follows:
* bison -d gvlogo.y
* flex gvlogo.l
* clang *.c -o gvlogo -I./include -L./lib -lSDL2 -ll -lm
