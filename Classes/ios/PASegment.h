//
//  PASegment.h
//  spelling
//
//  Created by Nathaniel Brown on 10/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "PACurve.h"

typedef struct PASegment {
  CGPoint point, handleIn, handleOut;
} PASegment;
