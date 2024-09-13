#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "RCQuic.h"
#import "tquic.h"
#import "tquic_def.h"

FOUNDATION_EXPORT double RCQuicKitVersionNumber;
FOUNDATION_EXPORT const unsigned char RCQuicKitVersionString[];

