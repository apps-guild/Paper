//
//  PAPath.h
//  spelling
//
//  Created by Nathaniel Brown on 10/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PASegment.h"

@interface PAPath : NSObject

+ (id)withSegments:(PASegment *)segments length:(NSUInteger)length;

- (CGPoint)firstPoint;
- (CGPoint)lastPoint;

- (void)getCurves:(PACurve *)curves;
- (void)getSegments:(PASegment *)segments;
- (void)setSegments:(PASegment *)segments length:(NSUInteger)length;
- (UIBezierPath *)asBezier;
- (void)stroke;
- (void)drawPoints:(CGContextRef)ctx;
- (void)drawHandles:(CGContextRef)ctx;

- (PACurveLocation)nearestLocationToPoint:(CGPoint)point;
- (CGFloat)distanceToPoint:(CGPoint)point;
- (CGPoint)nearestPoint:(CGPoint)point;
- (PACurveLocation)locationAt:(CGFloat)offset;
- (CGPoint)pointAt:(CGFloat)offset;
- (CGFloat)compare:(PAPath *)path withTolerance:(CGFloat)tolerance;
- (BOOL)containedBy:(PAPath *)path withTolerance:(CGFloat)tolerance;

@property (readonly) NSUInteger segmentsLength;
@property (readonly) NSUInteger curvesLength;
@property (readonly) CGFloat length;
@property (readwrite) BOOL closed;

@end
