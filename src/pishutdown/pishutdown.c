/*
 * pishutdown.c:
 * This program executes commands on parametrizable input pins.
 * Idea comes mainly from following site:
 *  - https://maker-tutorials.com/raspberry-pi-mit-einer-bueroklammer-ausschalten-bzw-herunterfahren/
 * But that program was insufficient to react on 2 inputs ..
 *
 * Copyright (c) 2018-2019 Hayati Ayguen. <h_ayguen@web.de>
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

/* up to maximum of 8 input pins and 16 configurable commands from command line */
#define MAX_NUM_CMDS  16
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
  int aPinNo[MAX_NUM_CMDS];
  int aPressCount[MAX_NUM_CMDS];
  int aPUDval[MAX_NUM_CMDS];
  int aPinTrigVal[MAX_NUM_CMDS];
  const char * aCommand[MAX_NUM_CMDS];
  int aUniquePinNo[MAX_NUM_CMDS];
  int aUniquePinCmdIdx[MAX_NUM_PINS]; /* idx to command aPinNo[]..aCommand[] */
  int numCmds = 0;
  int numPins = 0;
  int pressedPinNo = -1;
  int pressedPinCount = 0;
  int pressedPinSince = -1;
  int i, j;

  /* process command line arguments */
  for ( i = 1; i < argc; ++i )
  {
    if ( numCmds >= MAX_NUM_CMDS )
    {
      fprintf(stderr, "maximum %d pins/commands allowed. ignoring '%s' and following ones.\n", MAX_NUM_CMDS, argv[i]);
      break;
    }
    aPinNo[numCmds] = atoi(argv[i]);
    if ( aPinNo[numCmds] >= 0 )  /* allow simple deactivation of pin/action */
    {
      if ( i + 4  >= argc )
      {
        fprintf(stderr, "too few arguments after pin number %s. expected mode and command.\n", argv[i]);
        break;
      }

      if (!strcmp(argv[i+1], "up"))
        aPUDval[numCmds] = PUD_UP;
      else if (!strcmp(argv[i+1], "down") || !strcmp(argv[i+1], "dn"))
        aPUDval[numCmds] = PUD_DOWN;
      else if (!strcmp(argv[i+1], "off"))
        aPUDval[numCmds] = PUD_OFF;
      else
      {
        aPUDval[numCmds] = PUD_OFF;
        fprintf(stderr, "unknown pull mode '%s'. expected one of 'up', 'down' or 'off'. using 'off' as default.\n", argv[i+1]);
      }

      aPinTrigVal[numCmds] = atoi( argv[i+2] );
      aPressCount[numCmds] = atoi( argv[i+3] );
      if ( aPressCount[numCmds] <= 0 )
        aPressCount[numCmds] = 1;
      aCommand[numCmds] = argv[i+4];
      aUniquePinNo[numCmds] = -1;

      ++numCmds;
    }
    i += 4;  /* skip the parameters any way */
  }

  if ( !numCmds )
  {
    fprintf(stderr, "usage: %s ( <pin> <pullUp/Down> <pinValue> <#press> <command> )+\n", argv[0]);
    fprintf(stderr, "\texecutes commands on changed input pins\n");
    fprintf(stderr, "\tpin          wiringPi pin number, or -1 for deactivation\n");
    fprintf(stderr, "\t             see column 'wPi' on command 'gpio readall' of WiringPi\n");
    fprintf(stderr, "\tpullUp/Down  setup pull value for pin: 'up', 'down' or 'off'. only 1st value from same pin is used!\n");
    fprintf(stderr, "\tpinValue     digitalRead() value, on which to execute command. '0', '1' or '-1' for any\n");
    fprintf(stderr, "\t#press       number of times to be pressed to accept for this command. >= 1\n");
    fprintf(stderr, "\tcommand      command to execute when pinValue matches, e.g. '/sbin/shutdown now'.\n");
    exit(10);
  }

  if (wiringPiSetup () == -1)
    exit (1);

  fprintf(stderr, "parsed command line has %d different commands\n", numCmds);
  for ( i = 0; i < numCmds && numPins < MAX_NUM_PINS; ++i )
  {
    for ( j = 0; j < numPins; ++j )
    {
      if ( aPinNo[i] == aUniquePinNo[j] )
        break;
    }
    if ( j >= numPins )
    {
      aUniquePinNo[numPins] = aPinNo[i];
      aUniquePinCmdIdx[numPins] = i;
      ++numPins;
    }
  }
  fprintf(stderr, "parsed command line has %d different pins\n", numPins);

  for ( i = 0; i < numPins; ++i )
  {
    globalCounter[i] = 0;
    pinMode( aUniquePinNo[i], INPUT );
    pullUpDnControl( aUniquePinNo[i], aPUDval[aUniquePinCmdIdx[i]] );
  }

  /* use always both edges. commanding single edge does sometimes report both, too! */
  for ( i = 0; i < numPins; ++i )
    wiringPiISR( aUniquePinNo[i], INT_EDGE_BOTH, aInts[i] );

  /* endless loop */
  while (1)
  {
    int v, pv;
    delay(50);  /* wait some ms */
    if ( pressedPinNo >= 0 )
      pressedPinSince += 50;

    for ( i = 0; i < numPins; ++i )
    {
      if (! globalCounter[i])
        continue;
      v = globalCounter[i];
      globalCounter[i] = 0;
      pv = digitalRead( aUniquePinNo[i] );
      if ( aPinTrigVal[aUniquePinCmdIdx[i]] < 0 || aPinTrigVal[aUniquePinCmdIdx[i]] == pv )
      {
        fprintf(stderr, "pin %d (idx %d) got triggered %d times (single push), digitalRead() value is %d.\n", aUniquePinNo[i], i, v, pv);
        if ( aUniquePinNo[i] == pressedPinNo )
        {
          ++pressedPinCount;
          pressedPinSince = 0;  /* restart timer - waiting for next keypress - or timeout */
        }
        else
        {
          pressedPinNo = aUniquePinNo[i];
          pressedPinCount = 1;
          pressedPinSince = 0;
        }
      }
    }

    if ( pressedPinSince >= 1000 && pressedPinNo >= 0 )
    {
      /* look for the command to execute */
      fprintf(stderr, "pin %d was pressed %d times. looking for command to execute ..\n", pressedPinNo, pressedPinCount);
      for ( i = 0; i < numCmds; ++i )
      {
        if ( aPinNo[i] == pressedPinNo && aPressCount[i] == pressedPinCount )
        {
          fprintf(stderr, "found => calling '%s'\n\n", aCommand[i]);
          system(aCommand[i]);
          /* clear pressed pins */
          pressedPinNo = -1;
          pressedPinCount = 0;
          pressedPinSince = -1;
          break;
        }
      }
      if ( pressedPinNo >= 0 )
      {
        fprintf(stderr, "not found => reset\n\n");
        /* clear pressed pins */
        pressedPinNo = -1;
        pressedPinCount = 0;
        pressedPinSince = -1;
      }
    }

  }

  return 0;
}
