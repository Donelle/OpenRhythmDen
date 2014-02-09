//
//  BitlyDebug.h
//  BitlyLib
//
//  Created by Tracy Pesin on 8/5/11.
//  Copyright 2011 Betaworks. All rights reserved.
//

#import <Foundation/Foundation.h>

//#define BITLYDEBUG 1

#ifdef BITLYDEBUG
#define BitlyLog(format...) BitlyDebug(__FILE__, __LINE__, format)
#else
#define BitlyLog(format...)
#endif

void BitlyDebug(const char *fileName, int lineNumber, NSString *fmt, ...);
