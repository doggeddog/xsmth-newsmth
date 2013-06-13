//
//  SMDefination.h
//  newsmth
//
//  Created by Maxwin on 13-5-29.
//  Copyright (c) 2013年 nju. All rights reserved.
//

#ifndef newsmth_SMDefination_h
#define newsmth_SMDefination_h

#define SM_DATA_SCHEMA @"newsmth://"
#define SM_ERROR_DOMAIN @"newsmth_error"

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)


typedef enum {
    SMNetworkErrorCodeParseFail = -1,
    SMNetworkErrorCodeRequestFail = 1,
}SMNetworkErrorCode;



#endif
