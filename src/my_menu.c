#include "my_menu.h"

#include <stdlib.h>
#include <ncurses.h>
#include <menu.h>
#include <string.h>
#include <form.h>

#define ARRAY_SIZE(a) (sizeof(a) / sizeof(a[0]))
#define CTRLD 4
#define MY_KEY_BACKSPACE 127


/*
 * RANK | username | total ranking points | total capacity | number of drives
 */

/* NOTE: number of elements in this list will be determined by JSON file */
char* system_descriptions[] = {
						"1    User No. 1    200 TDriveBytes    20 TB    10 drives",
						"2    User No. 2    100 TDriveBytes    20 TB     5 drives",
						"3    User No. 3     96 TDriveBytes    24 TB     4 drives",
						"4    User No. 4     80 TDriveBytes    20 TB     4 drives",
                        (char*)NULL,
                  };

static void print_in_middle(WINDOW *win, int starty, int startx, int width, char *string, chtype color);

void init_ncurses(void)
{
	initscr();
	start_color();
	cbreak();
	noecho();
	keypad(stdscr,TRUE);
	init_pair(1, COLOR_RED, COLOR_BLACK);
}

void init_syslist(void)
{
	FIELD* fields[5];
	FORM* my_form;
	WINDOW* my_form_win;

	int i, ch, n_systems, character, rows , cols, field_height, field_width, startx, starty, offscreen_rows, additional_buffers, term_width, term_height;
	field_height = 1;
	startx = 4;
	additional_buffers = 0;
	n_systems = ARRAY_SIZE(system_descriptions);
	getmaxyx(stdscr, term_height, term_width);

	for (i=0; i < n_systems - 1; ++i)
	{
		field_width = strlen(system_descriptions[i]);
		offscreen_rows = (term_width - field_width > 0 ) ? term_width - field_width : 0;
		starty = i;
		fields[i] = new_field(field_height, field_width, starty, startx, offscreen_rows, additional_buffers);
		/*set_field_back(fields[i], A_UNDERLINE);*/
		field_opts_off(fields[i], O_AUTOSKIP);
		set_field_buffer(fields[i], 0, system_descriptions[i]);
	}

	my_form = new_form(fields);
	scale_form(my_form, &rows, &cols);
	my_form_win = newwin(rows + 4, cols + 4, 4, 4);
	keypad(my_form_win, TRUE);
	set_form_win(my_form, my_form_win);
	set_form_sub(my_form, derwin(my_form_win, rows, cols, 2, 2));
	box(my_form_win, 0, 0);
	print_in_middle(my_form_win, 1, 0, cols + 4, "My Form", COLOR_PAIR(1));
	post_form(my_form);
	wrefresh(my_form_win);
	refresh();
	while ((ch = wgetch(my_form_win)) != KEY_F(1))
	{
		switch(ch)
		{
			case KEY_DOWN:
				form_driver(my_form, REQ_NEXT_FIELD);
				form_driver(my_form, REQ_END_LINE);
				break;
			case KEY_UP:
				form_driver(my_form, REQ_PREV_FIELD);
				form_driver(my_form, REQ_END_LINE);
				break;
			case KEY_LEFT:
				form_driver(my_form, REQ_PREV_CHAR);
				break;
			case KEY_RIGHT:
				form_driver(my_form, REQ_NEXT_CHAR);
				break;
			case MY_KEY_BACKSPACE:
				form_driver(my_form, REQ_DEL_PREV);
				break;
			case KEY_DC:
				form_driver(my_form, REQ_DEL_CHAR);
				break;
			default:
				form_driver(my_form, ch);
				break;
		}
	}

	unpost_form(my_form);
	free_form(my_form);

	for (i=0; i < n_systems; ++i)
	{
		free_field(fields[i]);
	}
	endwin();
	return;

	/* height, width, starty, startx, number of offscreen rows and number of additional working buffers */
}

static void print_in_middle(WINDOW *win, int starty, int startx, int width, char *string, chtype color)
{
	int length, x, y;
	float temp;

	if(win == NULL)
		win = stdscr;

	getyx(win, y, x);
	if(startx != 0)
		x = startx;
	if(starty != 0)
		y = starty;
	if(width == 0)
		width = 80;

	length = strlen(string);
	temp = (width - length)/ 2;
	x = startx + (int)temp;
	wattron(win, color);
	mvwprintw(win, y, x, "%s", string);
	wattroff(win, color);
	refresh();
}

