//
//  PALine.h
//  spelling
//
//  Created by Nathaniel Brown on 10/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PABase.h"

typedef struct {
  CGPoint point, vector;
  BOOL    infinite;
} PALine;

BOOL PALineIntersect(const PALine this, const PALine line, CGPoint *point);
CGFloat PALineDistanceToPoint(const PALine this, const CGPoint point);

 CG_INLINE
PALine __PALineMake(const CGPoint point1, const CGPoint point2)
{
  return (PALine){point1, point2, true};
}
#define PALineMake __PALineMake

 CG_INLINE
PALine __PALineMakeInfinite(const CGPoint point1, const CGPoint point2, const BOOL infinite)
{
  return (PALine){point1, CGPointSubtract(point2, point1), infinite};
}
#define PALineMakeInfinite __PALineMakeInfinite