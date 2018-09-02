#
/*
 *    Copyright (C) 2013, 2014, 2015, 2016, 2017
 *    Jan van Katwijk (J.vanKatwijk@gmail.com)
 *    Lazy Chair Computing
 *
 *    This file is part of the DAB library
 *
 *    DAB library is free software; you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation; either version 2 of the License, or
 *    (at your option) any later version.
 *
 *    DAB library is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with DAB library; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#include	"band-handler.h"

#include <string.h>

struct dabFrequencies {
	const char	*key;
	int	fHz;
};

static
dabFrequencies bandIII_frequencies [] = {
{"5A",	174928 *1000},
{"5B",	176640 *1000},
{"5C",	178352 *1000},
{"5D",	180064 *1000},
{"6A",	181936 *1000},
{"6B",	183648 *1000},
{"6C",	185360 *1000},
{"6D",	187072 *1000},
{"7A",	188928 *1000},
{"7B",	190640 *1000},
{"7C",	192352 *1000},
{"7D",	194064 *1000},
{"8A",	195936 *1000},
{"8B",	197648 *1000},
{"8C",	199360 *1000},
{"8D",	201072 *1000},
{"9A",	202928 *1000},
{"9B",	204640 *1000},
{"9C",	206352 *1000},
{"9D",	208064 *1000},
{"10A",	209936 *1000},
{"10B", 211648 *1000},
{"10C", 213360 *1000},
{"10D", 215072 *1000},
{"11A", 216928 *1000},
{"11B",	218640 *1000},
{"11C",	220352 *1000},
{"11D",	222064 *1000},
{"12A",	223936 *1000},
{"12B",	225648 *1000},
{"12C",	227360 *1000},
{"12D",	229072 *1000},
{"13A",	230748 *1000},
{"13B",	232496 *1000},
{"13C",	234208 *1000},
{"13D",	235776 *1000},
{"13E",	237488 *1000},
{"13F",	239200 *1000},
{NULL, 0}
};

static
dabFrequencies Lband_frequencies [] = {
{"LA", 1452960 *1000},
{"LB", 1454672 *1000},
{"LC", 1456384 *1000},
{"LD", 1458096 *1000},
{"LE", 1459808 *1000},
{"LF", 1461520 *1000},
{"LG", 1463232 *1000},
{"LH", 1464944 *1000},
{"LI", 1466656 *1000},
{"LJ", 1468368 *1000},
{"LK", 1470080 *1000},
{"LL", 1471792 *1000},
{"LM", 1473504 *1000},
{"LN", 1475216 *1000},
{"LO", 1476928 *1000},
{"LP", 1478640 *1000},
{NULL, 0}
};


//	find the frequency for a given channel in a given band
int bandHandler::DABfrequency(const char * channel, unsigned dabBand)
{
	const dabFrequencies *finger = (dabBand == BAND_III) ? bandIII_frequencies : Lband_frequencies;

	for (int i = 0; finger[i]. key != NULL; ++i)
	{
		if ( !strcmp(finger[i].key, channel) )
			return finger[i].fHz;
	}
	return finger[0].fHz;
}

int bandHandler::DABfrequency(int idx, unsigned dabBand)
{
	const dabFrequencies *finger = (dabBand == BAND_III) ? bandIII_frequencies : Lband_frequencies;
	return finger[idx].fHz;
}

int bandHandler::DABidx(const char * channel, unsigned dabBand)
{
	const dabFrequencies *finger = (dabBand == BAND_III) ? bandIII_frequencies : Lband_frequencies;
	for (int i = 0; finger[i]. key != NULL; ++i)
	{
		if ( !strcmp(finger[i].key, channel) )
			return i;
	}
	return 0;
}

int bandHandler::DABlen(unsigned dabBand)
{
	const dabFrequencies *finger = (dabBand == BAND_III) ? bandIII_frequencies : Lband_frequencies;
	int i = 0;
	for ( ; finger[i]. key != NULL; ++i)
	{ }
	return i;
}

