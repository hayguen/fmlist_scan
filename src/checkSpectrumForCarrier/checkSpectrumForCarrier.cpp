
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include <string.h>

#include <string>

#include <liquid/liquid.h>


template <class T>
static inline T power( const liquid_float_complex & x )
{
	return ( T(x.real) * x.real + T(x.imag) * x.imag );
}


static inline bool isPowerOf2(unsigned n)
{
	return ( 0 == (n & (n - 1)) );
}

static inline unsigned nextPowerOf2(unsigned n)
{
	// already power of 2 ?
	if ( n && isPowerOf2(n) )
		return n;

	unsigned count = 0;
	while ( n )
	{
		n >>= 1;
		++count;
	}
	return (1 << count);
}

double powerDensity( const float * pwr, int first, int last )
{
	double s = 0.0;
	for ( int k = first; k <= last; ++k )
		s += pwr[k];
	const int n = last - first + 1;
	return s / n;
}



int main(int argc, char *argv[])
{
	if ( 1 >= argc )
	{
		fprintf(stderr, "usage: %s <filename> <samplerate> <length in ms> <channel bw> <main channel bw> <min pwr ratio> <cpwr filename> - <relfreq 1> .. <relfreq n>\n", argv[0]);
		fprintf(stderr, "\tfilename:        input filename - binary I/Q file with 16 bit per sample\n");
		fprintf(stderr, "\tsamplerate:      samplerate of input file in Hz. default: 2394999 Hz\n");
		fprintf(stderr, "\tlength in ms:    how many milliseconds of file's head to be processed. default: 200 ms\n");
		fprintf(stderr, "\tchannel bw:      channel bandwidth to analyse. default: 150000 Hz\n");
		fprintf(stderr, "\tmain channel bw: main channel bandwidth. default: 100000 Hz\n");
		fprintf(stderr, "\tmin pwr ratio:   minimum power ratio in dB: power(main channel) / power(non-main). non-main = channel bw - main. default: 6.0\n");
		fprintf(stderr, "\tcpwr filename:   optional filename to write compressed power values as .CSV. default: empty\n");
		fprintf(stderr, "\trelfreq n:       frequencies for each channel to analyze - relative to I/Q DC as 0 Hz.\n");
		return 1;
	}

	// set default parameters
	const char * fileName = nullptr;
	double fs = 2394000.0;
	double lenMillis = 200;
	double chanBw = 150000.0;
	double chanMainBw = 100000.0;
	double minPwrRatioLevel = 6.0;
	bool bothRequireMinPwrRatio = true;
	const char * cPwrFilename = nullptr;

	int nextArgNo = 1;
	do
	{
		// filename ist mandatory
		fileName = argv[nextArgNo++];

		// all following arguments are optional - frequencies are introduced with '-'
		if (!strcmp(argv[nextArgNo], "-"))
			break;
		fs = atof(argv[nextArgNo++]);

		if (!strcmp(argv[nextArgNo], "-"))
			break;
		lenMillis = atof(argv[nextArgNo++]);

		if (!strcmp(argv[nextArgNo], "-"))
			break;
		chanBw = atof(argv[nextArgNo++]);

		if (!strcmp(argv[nextArgNo], "-"))
			break;
		chanMainBw = atof(argv[nextArgNo++]);

		if (!strcmp(argv[nextArgNo], "-"))
			break;
		if ( argv[nextArgNo][0] == '+' )
			bothRequireMinPwrRatio = false;
		minPwrRatioLevel = atof(argv[nextArgNo++]);

		if (!strcmp(argv[nextArgNo], "-"))
			break;
		cPwrFilename = argv[nextArgNo++];

	}
	while (0);
	const int iFirstFreqArg = (!strcmp(argv[nextArgNo], "-")) ? ( nextArgNo + 1 ) : nextArgNo;

	unsigned numSmp = unsigned( fs * (lenMillis / 1000.0) );
	fprintf(stderr, "%f ms @ samplerate %f == %u samples\n", lenMillis, fs, numSmp);
	if ( numSmp <= 0 )
	{
		fprintf(stderr, "Error: zero or negative samplecount!\n");
		return 2;
	}
	const unsigned N = nextPowerOf2(numSmp);
	lenMillis = N * 1000.0 / fs;
	double rbw = fs / N;
	fprintf(stderr, "next power of 2: %u samples == %f ms --> rbw %f Hz\n", N, lenMillis, rbw);

	uint8_t * rawinp = new uint8_t[ 2*N ];
	liquid_float_complex *inp = new liquid_float_complex[N];
	liquid_float_complex *out = new liquid_float_complex[N];
	float *win = new float[ N ];

	// read 8 bit I/Q samples
	{
		FILE * f = fopen( fileName, "rb" );
		if (!f)
		{
			fprintf(stderr, "Error: cannot open file!\n");
			return 3;
		}
		const size_t nr = fread( rawinp, sizeof(uint8_t), 2*N, f );
		if (nr != 2*N)
		if (!f)
		{
			fprintf(stderr, "Error: cannot read raw sample data!\n");
			return 4;
		}
		fclose(f);
	}


	// convert 8 bit to 32-bit float
	do
	{
		float scale = 1.0F / 128.0F;
		for ( unsigned k = 0; k < N; ++k )
		{
			inp[k].real = ( int(rawinp[k+k+0]) - 128 ) * scale;
			inp[k].imag = ( int(rawinp[k+k+1]) - 128 ) * scale;
		}

		if (0)
		{
			FILE * fi = fopen("inp_full.csv", "w");
			if (!fi)
				break;
			for ( unsigned n = 0; n < N; ++n )
				fprintf(fi, "%f, %f\n", inp[n].real, inp[n].imag);
			fclose(fi);
		}
	} while (0);


	// apply hann() windowing
	do
	{
		for ( unsigned k = 0; k < N; ++k )
		{
			win[k] = hann( k, N );
			inp[k].real *= win[k];
			inp[k].imag *= win[k];
		}

		if (0)
		{
			FILE * fw = fopen("hann.csv", "w");
			if (!fw)
				break;
			for ( unsigned n = 0; n < N; ++n )
				fprintf(fw, "%f\n", win[n]);
			fclose(fw);
		}
	} while (0);


	// apply fft()
	{
		fftplan pf = fft_create_plan(N, inp, out, LIQUID_FFT_FORWARD, 0);
		fft_execute(pf);
		fft_destroy_plan(pf);
		fft_shift(out, N);


		if (0)
		{
			do
			{
				FILE * ff = fopen("fft_full.csv", "w");
				if (!ff)
					break;
				for ( unsigned n = 0; n < N; ++n )
					fprintf(ff, "%f, %f\n", out[n].real, out[n].imag);
				fclose(ff);
			} while (0);
		}
	}


	// calculate power
	const unsigned H = N / 2;
	float *pwr = win;
	{
		for ( unsigned n = 0; n < N; ++n )
			pwr[n] = power<float>( out[n] );

		// remove DC
		pwr[ H-1 ] = 0.0F;
		pwr[ H ] = 0.0F;
		pwr[ H+1 ] = 0.0F;
	}


	// compressed power spectrum
	const int compFactor = int( floor( 1000.0 / rbw ) );
	const double compressedRbw = compFactor * rbw;
	fprintf(stderr, "compression factor %d => compressed power spectrum rbw: %f Hz\n", compFactor, compressedRbw);
	if ( compFactor <= 1 )
		return 5;
	const unsigned CN = 1 + N / compFactor;
	const unsigned CH = CN / 2;
	float *cpwr = new float[ CN ];
	do
	{
		unsigned d = 0;
		unsigned k = 0;
		while ( k + compFactor < N )
		{
			double s = 0.0;
			for ( int n = 0; n < compFactor; ++n )
				s += pwr[k++];
			cpwr[d++] = s / compFactor;
		}

		const unsigned D = d;

		if (cPwrFilename)
		{
			do
			{
				FILE * fp = fopen(cPwrFilename, "w");
				if (!fp)
					break;
				for ( unsigned n = 0; n < D; ++n )
					fprintf(fp, "%f\n", cpwr[n]);
				fclose(fp);
			} while (0);
		}

	} while (0);


	// per channel
	//  -75k   -50k          +50k    +75k    @ chanBw = 150000, chanMainBw = 100000
	const int chanCornerBinDistA = int( (chanBw / 2.0) / rbw );
	const int chanCornerBinDistB = int( (chanMainBw / 2.0) / rbw );

	std::string sfrq( "carrier_frq=( " );
	std::string sprL( "carrier_pwr_ratioL=( " );
	std::string sprR( "carrier_pwr_ratioR=( " );
	std::string sprMin( "carrier_pwr_ratioMin=( " );
	std::string sprMax( "carrier_pwr_ratioMax=( " );
	std::string sdet( "carrier_det=( " );
	std::string sdbgPwr( "dbgPwrLevel=( " );

	double *dbgPwr = new double[ argc ];

	int numDet = 0;
	int argidx;
	for ( argidx = iFirstFreqArg; argidx < argc; ++argidx )
	{
		const int cfreq = atoi( argv[argidx] );
		const int chanCenter = H + int( round(cfreq / rbw) );
		const double pwrLeft  = powerDensity( pwr, chanCenter-chanCornerBinDistA, chanCenter-chanCornerBinDistB );
		const double pwrMid   = powerDensity( pwr, chanCenter-chanCornerBinDistB, chanCenter+chanCornerBinDistB );
		const double pwrRight = powerDensity( pwr, chanCenter+chanCornerBinDistB, chanCenter+chanCornerBinDistA );
		const double pwrRatioLeft  = ( pwrMid < 0.001 * pwrLeft ) ? 0.001 : (pwrMid / pwrLeft);
		const double pwrRatioRight = ( pwrMid < 0.001 * pwrRight ) ? 0.001 : (pwrMid / pwrRight);
		const double pwrRatioLeftLevel  = 10.0 * log10( pwrRatioLeft );
		const double pwrRatioRightLevel = 10.0 * log10( pwrRatioRight );
		const double pwrRatioMinLevel   = ( pwrRatioLeftLevel < pwrRatioRightLevel ) ? pwrRatioLeftLevel : pwrRatioRightLevel;
		const double pwrRatioMaxLevel   = ( pwrRatioLeftLevel > pwrRatioRightLevel ) ? pwrRatioLeftLevel : pwrRatioRightLevel;
		const bool carrierThere = bothRequireMinPwrRatio
				? ( (pwrRatioLeftLevel >= minPwrRatioLevel) && (pwrRatioRightLevel >= minPwrRatioLevel) )
				: ( (pwrRatioLeftLevel >= minPwrRatioLevel) || (pwrRatioRightLevel >= minPwrRatioLevel) );
		// fprintf(stderr, "%d, %f, %f, %s\n", cfreq, pwrRatioLeft, pwrRatioRight, (carrierThere ? ">= 10" : "<") );
		dbgPwr[ argidx ] = pwrMid;
		sfrq += std::to_string( cfreq );
		sfrq += " ";
		sprL += std::to_string( int(pwrRatioLeftLevel*10.0) );
		sprL += " ";
		sprR += std::to_string( int(pwrRatioRightLevel*10.0) );
		sprR += " ";
		sprMin += std::to_string( int(pwrRatioMinLevel*10.0) );
		sprMin += " ";
		sprMax += std::to_string( int(pwrRatioMaxLevel*10.0) );
		sprMax += " ";
		sdet += (carrierThere ? "1 " : "0 ");
		numDet += (carrierThere ? 1 : 0);
	}
	sfrq += ")";
	sprL += ")";
	sprR += ")";
	sprMin += ")";
	sprMax += ")";
	sdet += ")";
	std::string ndet = "carrier_num_det=" + std::to_string(numDet);
	std::string srbw = "compressed_rbw=\"" + std::to_string( compressedRbw ) + "\"";

	double dbgMaxPwr = dbgPwr[ iFirstFreqArg ];
	for ( argidx = iFirstFreqArg; argidx < argc; ++argidx )
	{
		if ( dbgMaxPwr < dbgPwr[ argidx ] )
			dbgMaxPwr = dbgPwr[ argidx ];
	}
	for ( argidx = iFirstFreqArg; argidx < argc; ++argidx )
	{
		const double pwrRatio  = dbgPwr[ argidx ] / dbgMaxPwr;
		const double pwrRatioLevel  = 10.0 * log10( pwrRatio );
		sdbgPwr += std::to_string( int(pwrRatioLevel*10.0) );
		//sdbgPwr += std::to_string( pwrRatioLevel );
		sdbgPwr += " ";
	}
	sdbgPwr += ")";

	fprintf(stdout, "%s\n", srbw.c_str());
	fprintf(stdout, "%s\n", sfrq.c_str());
	fprintf(stdout, "# carrier power ratio left / right corner in dB * 10: 60 == 6.0 dB\n");
	fprintf(stdout, "%s\n", sprL.c_str());
	fprintf(stdout, "%s\n", sprR.c_str());
	fprintf(stdout, "%s\n", sprMin.c_str());
	fprintf(stdout, "%s\n", sprMax.c_str());
	fprintf(stdout, "%s\n", sdet.c_str());
	fprintf(stdout, "%s\n", ndet.c_str());
	fprintf(stdout, "%s\n", sdbgPwr.c_str());
	return 0;
}
