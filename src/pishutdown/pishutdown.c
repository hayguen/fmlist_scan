/*
 * pishutdown.c:
 * This program executes commands on parametrizable input pins.
 * Idea comes mainly from following site:
 *  - https://maker-tutorials.com/raspberry-pi-mit-einer-bueroklammer-ausschalten-bzw-herunterfahren/
 * But that program was insufficient to react on 2 inputs ..
 *
 * Copyright (c) 2018 Hayati Ayguen. <h_ayguen@web.de>
 ***********************************************************************
 * This file is part of wiringPi:
 *	https://projects.drogon.net/raspberry-pi/wiringpi/
 *
 *    wiringPi is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU Lesser General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    wiringPi is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public License
 *    along with wiringPi.  If not, see <http://www.gnu.org/licenses/>.
 ***********************************************************************
 */

#include <wiringPi.h>

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

/* up to maximum of 8 inputs configurable from command line */
#define MAX_NUM_PINS	8

/* global data for interrupt functions */
static volatile int globalCounter[MAX_NUM_PINS];

/* interrupt functions */
void myInterrupt0(void) { ++globalCounter[0]; }
void myInterrupt1(void) { ++globalCounter[1]; }
void myInterrupt2(void) { ++globalCounter[2]; }
void myInterrupt3(void) { ++globalCounter[3]; }
void myInterrupt4(void) { ++globalCounter[4]; }
void myInterrupt5(void) { ++globalCounter[5]; }
void myInterrupt6(void) { ++globalCounter[6]; }
void myInterrupt7(void) { ++globalCounter[7]; }

/* setup table of function pointers for easier use */
void (*aInts[MAX_NUM_PINS])(void)
= {
  &myInterrupt0, &myInterrupt1,
  &myInterrupt2, &myInterrupt3,
  &myInterrupt4, &myInterrupt5,
  &myInterrupt6, &myInterrupt7
};


int main (int argc, char *argv[])
{
  int aPinNo[MAX_NUM_PINS];
  int aPUDval[MAX_NUM_PINS];
  int aPinTrigVal[MAX_NUM_PINS];
  const char * aCommand[MAX_NUM_PINS];
  int numPins = 0;
  int i;

  /* process command line arguments */
  for ( i = 1; i < argc; ++i )
  {
    if ( numPins >= MAX_NUM_PINS )
    {
      fprintf(stderr, "maximum %d pins/commands allowed. ignoring '%s' and following ones.\n", MAX_NUM_PINS, argv[i]);
      break;
    }
    aPinNo[numPins] = atoi(argv[i]);
    if ( aPinNo[numPins] >= 0 )  /* allow simple deactivation of pin/action */
    {
      if ( i + 3  >= argc )
      {
        fprintf(stderr, "too few arguments after pin number %s. expected mode and command.\n", argv[i]);
        break;
      }

      if (!strcmp(argv[i+1], "up"))
        aPUDval[numPins] = PUD_UP;
      else if (!strcmp(argv[i+1], "down") || !strcmp(argv[i+1], "dn"))
        aPUDval[numPins] = PUD_DOWN;
      else if (!strcmp(argv[i+1], "off"))
        aPUDval[numPins] = PUD_OFF;
      else
      {
        aPUDval[numPins] = PUD_OFF;
        fprintf(stderr, "unknown pull mode '%s'. expected one of 'up', 'down' or 'off'. using 'off' as default.\n", argv[i+1]);
      }

      aPinTrigVal[numPins] = atoi( argv[i+2] );

      aCommand[numPins] = argv[i+3];

      ++numPins;
    }
    i += 3;  /* skip the parameters any way */
  }

  if ( !numPins )
  {
    fprintf(stderr, "usage: %s ( <pin> <pullUp/Down> <inputValue> <command> )+\n", argv[0]);
    fprintf(stderr, "\texecutes commands on changed input pins\n");
    fprintf(stderr, "\tpin          wiringPi pin number, or -1 for deactivation\n");
    fprintf(stderr, "\t             see column 'wPi' on command 'gpio readall' of WiringPi\n");
    fprintf(stderr, "\tpullUp/Down  setup pull value for pin: 'up', 'down' or 'off'.\n");
    fprintf(stderr, "\tpinValue     digitalRead() value, on which to execute command. '0', '1' or '-1' for any\n");
    fprintf(stderr, "\tcommand      command to execute when pinValue matches, e.g. '/sbin/shutdown now'.\n");
    exit(10);
  }

  if (wiringPiSetup () == -1)
    exit (1);

  for ( i = 0; i < numPins; ++i )
  {
    globalCounter[i] = 0;
    pinMode( aPinNo[i], INPUT );
    pullUpDnControl( aPinNo[i], aPUDval[i] );
  }

  /* use always both edges. commanding single edge does sometimes report both, too! */
  for ( i = 0; i < numPins; ++i )
    wiringPiISR( aPinNo[i], INT_EDGE_BOTH, aInts[i] );

  /* endless loop */
  while (1)
  {
    int v, pv;
    delay(50);  /* wait some ms */
    for ( i = 0; i < numPins; ++i )
    {
      if (! globalCounter[i])
        continue;
      v = globalCounter[i];
      globalCounter[i] = 0;
      pv = digitalRead( aPinNo[i] );
      fprintf(stderr, "pin %d (idx %d) got triggered %d times, digitalRead() value is %d.\n", aPinNo[i], i, v, pv);
      if ( aPinTrigVal[i] < 0 || aPinTrigVal[i] == pv )
      {
        fprintf(stderr, "=> calling '%s'\n", aCommand[i]);
        system(aCommand[i]);
      }
    }
  }

  return 0;
}
