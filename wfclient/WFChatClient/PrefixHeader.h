//
//  PrefixHeader.pch
//  WFChatClient
//
//  Created by Tom Lee on 2020/11/14.
//  Copyright © 2020 WildFireChat. All rights reserved.
//

#ifndef PrefixHeader_pch
#define PrefixHeader_pch

// Include any system framework and library headers here that should be included in all compilation units.
// You will also need to set the Prefix Header build setting of one or more of your targets to reference this file.
#define WFCCString(key) NSLocalizedStringFromTable(key, @"wfc", nil)

#endif /* PrefixHeader_pch */
