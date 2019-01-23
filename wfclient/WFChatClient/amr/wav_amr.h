#ifndef WORKSPACE_MOMO_CLASS_GLOBAL_WAV_AMR_H
#define WORKSPACE_MOMO_CLASS_GLOBAL_WAV_AMR_H


#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

extern int encode_amr(const char* infile, const char* outfile);
extern int decode_amr(const char* infile, NSMutableData *outData);
    
    
#ifdef __cplusplus
}
#endif

#endif
