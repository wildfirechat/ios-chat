/* Copyright (C) 2012 IGN Entertainment, Inc. */

#import "FullScreenView.h"

@implementation FullScreenView

- (id)init
{
    if ((self = [super init])) {
        self.autoresizesSubviews = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = [UIColor blackColor];
    }
    
    return self;
}

@end
