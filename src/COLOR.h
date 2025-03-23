#pragma once

#ifndef COLOR_H
#define COLOR_H

#define RESET     "\033[0m"
#define RED       "\x1B[31;1m"
#define GREEN     "\x1B[32;1m"
#define YELLOW    "\x1B[33;1m"
#define BLUE      "\x1B[34;1m"
#define MAGENTA   "\x1B[35;1m"
#define CYAN      "\x1B[36;1m"
#define WHITE     "\x1B[37;1m"
#define DRAW_TEXT (COLOR, TEXT) COLOR TEXT RESET

#endif

