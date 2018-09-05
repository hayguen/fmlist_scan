/*
 * pwm.c:
 *	This tests the hardware PWM channel.
 *
 * Copyright (c) 2012-2013 Gordon Henderson. <projects@drogon.net>
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

int main (int argc, char *argv[])
{
  int frq = (1 < argc) ? atoi( argv[1] ) : 2000;
  int dly = (2 < argc) ? atoi( argv[2] ) : 1000;
  int va = (3 < argc) ? atoi( argv[3] ) : 0;
  int usepwm = (4 < argc) ? atoi( argv[4] ) : 1;

  printf ("Raspberry Pi wiringPi PWM test program\n");
  if ( argc <= 1 )
  {
    printf("usage: %s [ <frequency> [ <delay> [ <val_after> [ <usepwm> [ <sequence> ] ] ] ] ]\n", argv[0]);
    printf("\tfrequency: in Hz. default: 2000 Hz\n");
    printf("\tdelay:     in ms. default: 1000 ms\n");
    printf("\tval_after: pin value - to set after delay. default = 0\n");
    printf("\tuse_pwm:   play [sequence] (=1) or not (=0), later just setting val_after. default = 1\n");
    printf("\tsequence:  sequence of delay values setting play duration and pause duration.\n");
  }

  printf("using frequency %d\n", frq);


  if (wiringPiSetup () == -1)
    exit (1) ;


  if ( usepwm )
  {
    pinMode (1, PWM_OUTPUT);

    if ( argc <= 5 )
    {
      pwmToneWrite(1, frq);
      delay(dly);
    }
    else
    {
      for ( int k = 5; k < argc; ++k )
      {
        int f = (k & 1 ? frq : 0);
        dly = atoi( argv[k] );
        printf("k %d: tone at %d Hz for %d ms\n", k, f, dly);
        pwmToneWrite(1, f);
        delay(dly);
      }
    }
  }

  pinMode (1, OUTPUT);
  digitalWrite(1, va);

  return 0 ;
}
