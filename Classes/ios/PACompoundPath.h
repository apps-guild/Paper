//
//  PACompoundPath.h
//
//  Created by Nathaniel Brown on 10/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PAPath.h"

@interface PACompoundPath : NSObject

+ (PACompoundPath *)withPath:(PAPath *)path;
+ (PACompoundPath *)withPaths:(NSArray *)paths;

- (void)addPath:(PAPath *)path;
- (void)addPaths:(NSArray *)paths;
- (void)stroke;
- (PACompoundPath *)compactWithTolerance:(CGFloat)tolerance;
- (CGFloat)compactCompare:(PACompoundPath *)compoundPath withTolerance:(CGFloat)tolerance;
- (CGFloat)compare:(PACompoundPath *)compoundPath withTolerance:(CGFloat)tolerance;

@property (readwrite, retain) NSArray *paths;
@property (readonly) CGFloat length;

@end
