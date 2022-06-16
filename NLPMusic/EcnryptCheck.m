//
//  EcnryptCheck.m
//  NLPMusic
//
//  Created by Ярослав Стрельников on 29.04.2022.
//  Copyright © 2022 NP-Team. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <execinfo.h>
#import <mach-o/ldsyms.h>
#import "EncryptCheck.h"
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <TargetConditionals.h>

@implementation EncryptionCheck : NSObject 

+ (bool)executableEncryption {
    const uint8_t *command = (const uint8_t *) (&_mh_execute_header + 1);
    for (uint32_t idx = 0; idx < _mh_execute_header.ncmds; ++idx)
    {
        if (((const struct load_command *) command)->cmd == LC_ENCRYPTION_INFO)
        {
            struct encryption_info_command *crypt_cmd = (struct encryption_info_command *) command;
            if (crypt_cmd->cryptid < 1)
                return false;
            return true;
        }
        else
        {
            command += ((const struct load_command *) command)->cmdsize;
        }
    }
    return false;
}

@end
