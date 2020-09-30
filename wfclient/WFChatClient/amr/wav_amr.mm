#import "wav_amr.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "interf_enc.h"
#include "interf_dec.h"
#include "wavreader.h"
#include "wavwriter.h"


const int sizes[] = { 12, 13, 15, 17, 19, 20, 26, 31, 5, 6, 5, 5, 0, 0, 0, 0 };

int decode_amr(const char* infile, NSMutableData *outData) {
	FILE* in = fopen(infile, "rb");
	if (!in) {
		return 1;
	}
	char header[6];
	ssize_t n = fread(header, 1, 6, in);
	if (n != 6 || memcmp(header, "#!AMR\n", 6)) {
		fprintf(stderr, "Bad header\n");
		return 1;
	}
    NSMutableData *body = [[NSMutableData alloc] init];
    void* wav = wav_write_open(outData, body, 8000, 16, 1);

	void* amr = Decoder_Interface_init();
	while (1) {
		uint8_t buffer[500];
		/* Read the mode byte */
		n = fread(buffer, 1, 1, in);
		if (n <= 0)
			break;
		/* Find the packet size */
		int size = sizes[(buffer[0] >> 3) & 0x0f];
		if (size <= 0)
            continue;
		n = fread(buffer + 1, 1, size, in);
		if (n != size)
			break;
		/* Decode the packet */
		int16_t outbuffer[160];
		Decoder_Interface_Decode(amr, buffer, outbuffer, 0);
		/* Convert to little endian and write to wav */
		uint8_t littleendian[320];
		uint8_t* ptr = littleendian;
		for (int i = 0; i < 160; i++) {
			*ptr++ = (outbuffer[i] >> 0) & 0xff;
			*ptr++ = (outbuffer[i] >> 8) & 0xff;
		}
        wav_write_data(wav, littleendian, 320);
	}
	fclose(in);
	Decoder_Interface_exit(amr);
    wav_write_close(wav);
    
    [outData appendData:body];
	return 0;
}

int encode_amr(const char* infile, const char* outfile) {
    enum Mode mode = MR122;
    FILE *out;
    void *wav, *amr;
    int format, sampleRate, channels, bitsPerSample;
    int inputSize;
    uint8_t* inputBuf;

    wav = wav_read_open(infile);
    if (!wav) {
        fprintf(stderr, "Unable to open wav file %s\n", infile);
        return 1;
    }
    if (!wav_get_header(wav, &format, &channels, &sampleRate, &bitsPerSample, NULL)) {
        fprintf(stderr, "Bad wav file %s\n", infile);
        return 1;
    }
    if (format != 1) {
        fprintf(stderr, "Unsupported WAV format %d\n", format);
        return 1;
    }
    if (bitsPerSample != 16) {
        fprintf(stderr, "Unsupported WAV sample depth %d\n", bitsPerSample);
        return 1;
    }
    if (channels != 1)
        fprintf(stderr, "Warning, only compressing one audio channel\n");
    if (sampleRate != 8000)
        fprintf(stderr, "Warning, AMR-NB uses 8000 Hz sample rate (WAV file has %d Hz)\n", sampleRate);
    
    inputSize = channels*2*160;
    inputBuf = (uint8_t*) malloc(inputSize);
    
    amr = Encoder_Interface_init(0);
    out = fopen(outfile, "wb");
    if (!out) {
        free(inputBuf);
        perror(outfile);
        return 1;
    }
    
    fwrite("#!AMR\n", 1, 6, out);
    while (1) {
        short buf[160];
        uint8_t outbuf[500];
        int read, i, n;
        read = wav_read_data(wav, inputBuf, inputSize);
        read /= channels;
        read /= 2;
        if (read < 160)
            break;
        for (i = 0; i < 160; i++) {
            const uint8_t* in = &inputBuf[2*channels*i];
            buf[i] = in[0] | (in[1] << 8);
        }
        n = Encoder_Interface_Encode(amr, mode, buf, outbuf, 0);
        fwrite(outbuf, 1, n, out);
    }
    free(inputBuf);
    fclose(out);
    Encoder_Interface_exit(amr);
    wav_read_close(wav);
    
    return 0;
}

