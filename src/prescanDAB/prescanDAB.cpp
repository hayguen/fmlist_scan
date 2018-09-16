/*
 * rtl-sdr, turns your Realtek RTL2832 based DVB dongle into a SDR receiver
 * Copyright (C) 2012 by Steve Markgraf <steve@steve-m.de>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <errno.h>
#include <signal.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef _WIN32
#include <unistd.h>
#else
#include <windows.h>
#include <io.h>
#include <fcntl.h>
#include "getopt/getopt.h"
#endif

#include <complex>
#include <algorithm>
#include <string>

#include "rtl-sdr.h"
#include "convenience/convenience.h"
#include "band-handler.h"

#define DEFAULT_SAMPLE_RATE		2048000
#define DEFAULT_BANDWIDTH		0	/* automatic bandwidth */
#define DEFAULT_BUF_LENGTH		(16 * 16384)
#define MINIMAL_BUF_LENGTH		512
#define MAXIMAL_BUF_LENGTH		(256 * 16384)

static int do_exit = 0;
static rtlsdr_dev_t *dev = NULL;
static uint32_t samp_rate = DEFAULT_SAMPLE_RATE;

static char chanListInit[] = "5A,5B,5C,5D,6A,6B,6C,6D,7A,7B,7C,7D,8A,8B,8C,8D,9A,9B,9C,9D,10A,10B,10C,10D,11A,11B,11C,11D,12A,12B,12C,12D,13A,13B,13C,13D,13E,13F";
static char * chanListStr = chanListInit;
static char * chanList[256];
static float chanCorrCoeff[256] = { 0.0F };
static float chanNullSymbDist[256] = { -1.0F };

static float chanNullSymbMaxPwr[256] = { -1.0F };
static float chanNullSymbAvgPwr[256] = { 0.0F };
static float chanFrameSymbMinPwr[256] = { 0.0F };
static float chanFrameSymbAvgPwr[256] = { 0.0F };
static float chanFrameSymbStdPwr[256] = { 0.0F };
static int   chanNullNumFrames[256] = { 0 };

static int numChannels = 0;
static char initChanInit[] = "5A";
static char * initChan = initChanInit;
static int initChanIdx = 0;

static float minAutoCorrCoeff = 0.15F;
static float waitMillisAfterSetFreq = 100.0F;
static uint32_t waitSmpAfterSetFreq = 0;

static int verbosity = 0;


void usage(void)
{
	fprintf(stderr,
		"scan_next_dab_channel, for RTL2832 based DVB-T receivers\n\n"
		"Usage:\t -c <ch> continue from this last channel. frequency will be next channel.\n"
		"\t[-L comma seperated channel list (default: '5A-13F')]\n"
		"\t[-C minimum autocorrelation coefficient in distance 1 ms - for 1 kHz subcarrier distance. default: 0.15\n"
		"\t[-W wait milliseconds after setting frequency. default: 100 ms\n"
		"\t[-s samplerate (default: 2048000 Hz)]\n"
		"\t[-w tuner_bandwidth (default: automatic)]\n"
		"\t[-d device_index (default: 0)]\n"
		"\t[-g gain (default: 0 for auto)]\n"
		"\t[-p ppm_error (default: 0)]\n"
		"\t[-b output_block_size (default: 16 * 16384)]\n"
		"\t[-S force sync output (default: async)]\n" );
	exit(1);
}

#ifdef _WIN32
BOOL WINAPI
sighandler(int signum)
{
	if (CTRL_C_EVENT == signum) {
		fprintf(stderr, "Signal caught, exiting!\n");
		do_exit = 1;
		rtlsdr_cancel_async(dev);
		return TRUE;
	}
	return FALSE;
}
#else
static void sighandler(int signum)
{
	fprintf(stderr, "Signal caught, exiting!\n");
	do_exit = 1;
	rtlsdr_cancel_async(dev);
}
#endif


// std::min_element not before C++17
template<class ForwardIt>
ForwardIt min_element(ForwardIt first, ForwardIt last)
{
    if (first == last) return last;

    ForwardIt smallest = first;
    ++first;
    for (; first != last; ++first) {
        if (*first < *smallest) {
            smallest = first;
        }
    }
    return smallest;
}


static int tauSmp = 2048;
static int totalCorrLen = 200 * 2048;
static std::complex<float> * corrBuf = NULL;
static float * powerBuf = NULL;
static float powerExpAvgAlfa = 0.0F;
static int corrBufLen = 0;
static std::complex<double> cumCorrCoeff = 0.0;
static double cumLen = 0;
static double corrCoeff = 0.0;
static int chanIdx = 0;
static int corrAlgo = 3;

static void rtlsdr_callback(unsigned char *buf, uint32_t len, void *ctx)
{
	static bool bNextFrequency = true;
	static uint32_t waitSmpAfterSetFreqLeft = 0;
	static int numFreqIncs = 0;
	static int numCorrParts = 0;

	if ( do_exit )
		return;

	while (1)
	{
		if ( bNextFrequency )
		{
			bNextFrequency = false;
			if ( numFreqIncs >= numChannels )
			{
				do_exit = 1;
				corrCoeff = 0.0;
				rtlsdr_cancel_async(dev);
				if (verbosity)
				{
					float blksizems = ( 1000.0F * (len/2.0F) /samp_rate );
					fprintf(stderr, "blocksize callback = %f ms\n", blksizems);
					fprintf(stderr, "\nscanned %d frequencies. abort.\n", numFreqIncs);
				}
				return;
			}
			++numFreqIncs;
			waitSmpAfterSetFreqLeft = waitSmpAfterSetFreq;
			chanIdx = ( chanIdx + 1 ) % numChannels;
			uint32_t f = (uint32_t)bandHandler::DABfrequency(chanList[chanIdx], bandHandler::BAND_III);
			if (verbosity)
				fprintf(stderr, "\nsetting frequency to %u for channel %s\n", f, chanList[chanIdx]);
			verbose_set_frequency(dev, f);
			corrBufLen = 0;
			cumCorrCoeff = std::complex<double>( 0.0, 0.0 );
			cumLen = 0.0;
			numCorrParts = 0;
			return;
		}

		uint32_t lenSmp = len /2;
		if ( waitSmpAfterSetFreqLeft >= lenSmp )
		{
			waitSmpAfterSetFreqLeft -= lenSmp;
			return;
		}

		lenSmp -= waitSmpAfterSetFreqLeft;
		buf += waitSmpAfterSetFreqLeft*2;
		waitSmpAfterSetFreqLeft = 0;

        const float alpha = powerExpAvgAlfa;
        const float beta = 1.0F - powerExpAvgAlfa;
        const int corrBufLenPre = corrBufLen;
		int bufIdx = 0;
        if ( !corrBufLen && lenSmp > 0 )
        {
            const float re = int(buf[bufIdx] - 127) / 128.0F;
            const float im = int(buf[bufIdx+1] - 127) / 128.0F;
            const float pwr = re * re + im * im;
            powerBuf[0] = pwr;
            powerBuf = powerBuf + 1;
        }
		while ( lenSmp > 0 )
		{
			const float re = int(buf[bufIdx++] - 127) / 128.0F;
			const float im = int(buf[bufIdx++] - 127) / 128.0F;
            const float pwr = re * re + im * im;
            corrBuf[corrBufLen] = std::complex<float>(re, im);
            powerBuf[corrBufLen] = alpha * pwr + beta * powerBuf[corrBufLen-1];
            ++corrBufLen;
			--lenSmp;
		}

		const int iStart = std::max( 0, corrBufLenPre - tauSmp );
		const int iEnd = std::min( std::max( 0, corrBufLen - tauSmp ), totalCorrLen );
		const float minA = 4.0F / 128.0F;
		for ( int i = iStart; i < iEnd; ++i )
		{
			auto c = ( std::conj( corrBuf[i] ) * corrBuf[i + tauSmp] );
			auto a = std::abs(c);
			if ( a >= minA )
			{
				cumLen += a;
				cumCorrCoeff += c;
				//cumCorrCoeff += ( c / a );
				++numCorrParts;
			}
		}

		if ( iEnd == totalCorrLen )
		{
			switch(corrAlgo)
			{
				case 0: corrCoeff = std::abs(cumCorrCoeff) / totalCorrLen;	break;
				case 1: corrCoeff = std::abs(cumCorrCoeff) / numCorrParts;	break;
				case 2: corrCoeff = std::abs(cumCorrCoeff) / cumLen;		break;
				default:
				case 3: corrCoeff = cumCorrCoeff.real() / cumLen;	break;
			}

			if (verbosity)
			{
				fprintf(stderr, "cumCorr = %f + i* %f, cumLen = %f,  # = %d\n", cumCorrCoeff.real(), cumCorrCoeff.imag(), cumLen, totalCorrLen);
				fprintf(stderr, "correlation coefficicent for channel %s = %f\n", chanList[chanIdx], corrCoeff);
			}
			if (verbosity >= 2)
			{
				//fprintf(stdout, "cumCorr = %f + i* %f, cumLen = %f,  # = %d\n", cumCorrCoeff.real(), cumCorrCoeff.imag(), cumLen, totalCorrLen);
				fprintf(stdout, "%f, %s, %d\n", corrCoeff, chanList[chanIdx], chanIdx+1);
			}

            chanCorrCoeff[chanIdx] = corrCoeff;

            if ( ( 1 || corrCoeff >= minAutoCorrCoeff ) && corrBufLen >= 2*196608 )
            {
                double nullSymbSumPwr = 0.0;
                double chanFrameSymbSumPwr = 0.0;
                int chanFrameSymbNumPwr = 0;
                const float * ptrMin = min_element( powerBuf+0, powerBuf+corrBufLen );
                const int iAbsMinIdx = ptrMin - powerBuf;
                const int iFirstMinIdx = iAbsMinIdx % 196608;
                float nullSymbMaxPwr = *ptrMin;
                float frameSymbMinPwr = 1000.0F;
                chanNullNumFrames[chanIdx] = 0;
                for ( int nullIdx = iFirstMinIdx; nullIdx + 196608 < corrBufLen; nullIdx += 196608 )
                {
                    ++chanNullNumFrames[chanIdx];
                    nullSymbSumPwr += powerBuf[nullIdx];

                    nullSymbMaxPwr = std::max( nullSymbMaxPwr, powerBuf[nullIdx] );
                    for ( int frameSymIdx = nullIdx + (2656+2552)/2; frameSymIdx < nullIdx + 196608; frameSymIdx += 2552 )
                    {
                        chanFrameSymbSumPwr += powerBuf[frameSymIdx];
                        ++chanFrameSymbNumPwr;
                        frameSymbMinPwr = std::min( frameSymbMinPwr, powerBuf[frameSymIdx] );
                    }
                }
                const float fLowestSamplePwr = (1.0F/128.0F) * (1.0F/128.0F);
                nullSymbMaxPwr = std::max( nullSymbMaxPwr, fLowestSamplePwr );

                chanNullSymbMaxPwr[chanIdx] = nullSymbMaxPwr;
                chanNullSymbAvgPwr[chanIdx] = nullSymbSumPwr / chanNullNumFrames[chanIdx];

                chanFrameSymbMinPwr[chanIdx] = frameSymbMinPwr;
                chanFrameSymbAvgPwr[chanIdx] = chanFrameSymbSumPwr / chanFrameSymbNumPwr;
                chanFrameSymbStdPwr[chanIdx] = 0.0F;

                if ( frameSymbMinPwr >= 0.1F * nullSymbMaxPwr )
                    chanNullSymbDist[chanIdx] = frameSymbMinPwr / nullSymbMaxPwr;
                else
                    chanNullSymbDist[chanIdx] = 0.0F;
            }

			if ( 0 && corrCoeff >= minAutoCorrCoeff )
			{
				do_exit = 1;
				rtlsdr_cancel_async(dev);
				if (verbosity)
					fprintf(stderr, "\nfound channel with good correlation. aborting scan.\n");
				return;
			}
			bNextFrequency = true;
			continue;
		}

		break;	// while (1)
	}

}


int main(int argc, char **argv)
{
#ifndef _WIN32
	struct sigaction sigact;
#endif
	int n_read;
	int r, opt;
	int gain = 0;
	int ppm_error = 0;
	FILE *file = NULL;
	uint8_t *buffer;
	int dev_index = 0;
	int dev_given = 0;
	uint32_t frequency = 100000000;
	uint32_t bandwidth = DEFAULT_BANDWIDTH;
	uint32_t out_block_size = DEFAULT_BUF_LENGTH;
    int numCorrs = 3 * 96; // => minimum 2 full frames from 1st minimum
	{
		for (int k = 0; k < 256; ++k)
			chanCorrCoeff[k] = -16.0F;
        for (int k = 0; k < 256; ++k)
        {
            chanNullSymbDist[k] = -1.0F;
            chanNullSymbMaxPwr[k] = 0.0F;
            chanNullSymbAvgPwr[k] = 0.0F;
            chanFrameSymbMinPwr[k] = 0.0F;
            chanFrameSymbAvgPwr[k] = 0.0F;
            chanFrameSymbStdPwr[k] = 0.0F;
            chanNullNumFrames[k] = 0;
        }
	}

	while ((opt = getopt(argc, argv, "c:L:C:A:N:W:s:w:d:g:p:b:v")) != -1)
	{
		switch (opt) {
		case 'c':
			initChan = optarg;
			frequency = (uint32_t)bandHandler::DABfrequency(optarg, bandHandler::BAND_III);
			break;
		case 'L':
			chanListStr = optarg;
			break;
		case 'C':
			minAutoCorrCoeff = atof(optarg);
			break;
		case 'A':
			corrAlgo = atoi(optarg);
			break;
		case 'N':
			numCorrs = atoi(optarg);
			break;
		case 'W':
			waitMillisAfterSetFreq = atof(optarg);
			break;
		case 's':
			samp_rate = (uint32_t)atofs(optarg);
			break;
		case 'w':
			bandwidth = (uint32_t)atofs(optarg);
			break;
		case 'd':
			dev_index = verbose_device_search(optarg);
			dev_given = 1;
			break;
		case 'g':
			gain = (int)(atof(optarg) * 10); /* tenths of a dB */
			break;
		case 'p':
			ppm_error = atoi(optarg);
			break;
		case 'b':
			out_block_size = (uint32_t)atof(optarg);
			break;
		case 'v':
			++verbosity;
			break;
		default:
			usage();
			break;
		}
	}

	numChannels = 0;
	char *pch = strtok(chanListStr, ",");
	while (pch)
	{
		if (!strcmp(pch, initChan))
			initChanIdx = numChannels;
		chanList[numChannels++] = pch;
		pch = strtok(NULL, ",");
	}
	chanIdx = ( initChanIdx + numChannels -1 ) % numChannels;

	waitSmpAfterSetFreq = uint32_t( waitMillisAfterSetFreq * samp_rate / 1000.0F );
	tauSmp = int( 0.5F + samp_rate / 1000.0F );
	totalCorrLen = int( 0.5F + float(numCorrs) * samp_rate / 1000.0F );

    const double expAvgFiveTau = 0.001246 / 3.0;    // 1/3 of symbol duration
    const double expAvgTau = expAvgFiveTau / 5.0;
    powerExpAvgAlfa = float( 1.0 - exp( -1.0 / (expAvgTau * samp_rate) ) );

	if (verbosity)
	{
		fprintf(stderr, "initial channel = %s\n", chanList[initChanIdx]);
        fprintf(stderr, "tau = correlation distance = %d smp\n", tauSmp);
        fprintf(stderr, "expAvg alpha = %f\n", powerExpAvgAlfa);
        fprintf(stderr, "#  channels = %d\n", numChannels);
		for (int k = 0; k < numChannels; ++k )
			fprintf(stderr, "[%d] = %s, ", k, chanList[k]);
		fprintf(stderr, "\n");
	}

	if(out_block_size < MINIMAL_BUF_LENGTH ||
	   out_block_size > MAXIMAL_BUF_LENGTH ){
		fprintf(stderr,
			"Output block size wrong value, falling back to default\n");
		fprintf(stderr,
			"Minimal length: %u\n", MINIMAL_BUF_LENGTH);
		fprintf(stderr,
			"Maximal length: %u\n", MAXIMAL_BUF_LENGTH);
		out_block_size = DEFAULT_BUF_LENGTH;
	}

	buffer = (uint8_t*)malloc(out_block_size * sizeof(uint8_t));
	corrBuf = new std::complex<float>[ totalCorrLen + tauSmp + out_block_size ];
    powerBuf = new float[ 1 + totalCorrLen + tauSmp + out_block_size ];

	if (!dev_given) {
		dev_index = verbose_device_search("0");
	}

	if (dev_index < 0) {
		exit(1);
	}

	r = rtlsdr_open(&dev, (uint32_t)dev_index);
	if (r < 0) {
		fprintf(stderr, "Failed to open rtlsdr device #%d.\n", dev_index);
		exit(1);
	}
#ifndef _WIN32
	sigact.sa_handler = sighandler;
	sigemptyset(&sigact.sa_mask);
	sigact.sa_flags = 0;
	sigaction(SIGINT, &sigact, NULL);
	sigaction(SIGTERM, &sigact, NULL);
	sigaction(SIGQUIT, &sigact, NULL);
	sigaction(SIGPIPE, &sigact, NULL);
#else
	SetConsoleCtrlHandler( (PHANDLER_ROUTINE) sighandler, TRUE );
#endif
	/* Set the sample rate */
	verbose_set_sample_rate(dev, samp_rate);

	/* Set the tuner bandwidth */
	verbose_set_bandwidth(dev, bandwidth);

	/* Set the frequency */
	verbose_set_frequency(dev, frequency);

	if (0 == gain) {
		 /* Enable automatic gain */
		verbose_auto_gain(dev);
	} else {
		/* Enable manual gain */
		gain = nearest_gain(dev, gain);
		verbose_gain_set(dev, gain);
	}

	verbose_ppm_set(dev, ppm_error);

	/* Reset endpoint before we start reading from it (mandatory) */
	verbose_reset_buffer(dev);

	if (verbosity)
	{
		float blksizems = ( 1000.0F * (out_block_size/2.0F) /samp_rate );
		fprintf(stderr, "blocksize = %f ms\n", blksizems);
	}

	if (1)
	{
		fprintf(stderr, "Reading samples in sync mode...\n");
		while (!do_exit)
		{
			r = rtlsdr_read_sync(dev, buffer, out_block_size, &n_read);
			if (r < 0) {
				fprintf(stderr, "WARNING: sync read failed.\n");
				break;
			}

			if ((uint32_t)n_read < out_block_size) {
				fprintf(stderr, "Short read, samples lost, exiting!\n");
				break;
			}

			rtlsdr_callback( buffer, n_read, NULL );
		}
	} else {
		fprintf(stderr, "Reading samples in async mode...\n");
		r = rtlsdr_read_async(dev, rtlsdr_callback, NULL, 0, out_block_size);
	}

	if (do_exit)
		fprintf(stderr, "\nUser cancel, exiting...\n");
	else
		fprintf(stderr, "\nLibrary error %d, exiting...\n", r);

	rtlsdr_close(dev);
	free (buffer);

	std::string corrs( "dabchancorrsK=( " );
	std::string chans( "dabchannels=( " );
    std::string frameNullRatio( "framenullratioK=( " );
    std::string frameNullRatioC( "# framenullratioK: " );
    std::string frameNullC_A( "# null symb max: " );
    std::string frameNullC_B( "# null symb avg: " );
    std::string frameNullC_C( "# framesymb min: " );
    std::string frameNullC_D( "# framesymb avg: " );
    std::string frameNullC_E( "# #frames: " );

    for ( int k = 0; k < numChannels; ++k )
	{
		if( chanCorrCoeff[k] >= minAutoCorrCoeff )
		{
			int corrCoeffI = int( 0.5 + chanCorrCoeff[k] * 1000.0 );
			corrs += std::to_string( corrCoeffI );
			corrs += " ";

			chans += chanList[k];
			chans += " ";
		}
        int chanNullSymbDistI = int( 0.5 + chanNullSymbDist[k] * 1000.0 );
        frameNullRatio += std::to_string( chanNullSymbDistI );
        frameNullRatio += " ";

        if ( chanNullSymbDistI > 0 )
        {
            frameNullRatioC += std::string(chanList[k]) + ": " + std::to_string( chanNullSymbDistI ) + "  ";
            frameNullC_A += std::string(chanList[k]) + ": " + std::to_string(chanNullSymbMaxPwr[k]) + "  ";  // "# null symb max: "
            frameNullC_B += std::string(chanList[k]) + ": " + std::to_string(chanNullSymbAvgPwr[k]) + "  ";  // "# null symb avg: "
            frameNullC_C += std::string(chanList[k]) + ": " + std::to_string(chanFrameSymbMinPwr[k]) + "  ";  // "# framesymb min: "
            frameNullC_D += std::string(chanList[k]) + ": " + std::to_string(chanFrameSymbAvgPwr[k]) + "  ";  // "# framesymb avg: "
            frameNullC_E += std::string(chanList[k]) + ": " + std::to_string(chanNullNumFrames[k]) + "  ";  // "# #frames: "
        }
	}
	corrs += ")";
	chans += ")";
    frameNullRatio += ")";
    fprintf(stdout, "%s\n", corrs.c_str());
    fprintf(stdout, "%s\n", frameNullRatio.c_str());
    fprintf(stdout, "%s\n", frameNullRatioC.c_str());
    fprintf(stdout, "%s\n", frameNullC_A.c_str());
    fprintf(stdout, "%s\n", frameNullC_B.c_str());
    fprintf(stdout, "%s\n", frameNullC_C.c_str());
    fprintf(stdout, "%s\n", frameNullC_D.c_str());
    fprintf(stdout, "%s\n", frameNullC_E.c_str());
    fprintf(stdout, "%s\n", chans.c_str());

out:
	return r >= 0 ? r : -r;
}
