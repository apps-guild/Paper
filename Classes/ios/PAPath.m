//
//  PAPath.m
//  spelling
//
//  Created by Nathaniel Brown on 10/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PAPath.h"

@interface PAPath () {
@private
  BOOL _closed;
  CGFloat _length;
  PASegment *_segments;
  NSUInteger _segmentsLength;
}
@end

@implementation PAPath
@synthesize segmentsLength = _segmentsLength, closed = _closed;

- (void)internalInit
{
  _closed = NO;
  _length = NAN;
  _segments = nil;
  _segmentsLength = 0;
}

- (id)init
{
  if (self = [super init]) {
    [self internalInit];
  }
  return self;
}

- (id)initWithSegments:(PASegment *)segments length:(NSUInteger)length
{
  if (self = [super init]) {
    [self internalInit];
    [self setSegments:segments length:length];
  }
  return self;
}

+ (id)withSegments:(PASegment *)segments length:(NSUInteger)length
{
  return [[PAPath alloc] initWithSegments:segments length:length];
}

- (UIBezierPath *)asBezier
{
  UIBezierPath *bezier = [UIBezierPath bezierPath];
  NSUInteger length = _segmentsLength;
  
  for (PASegment *s = _segments, *prev = nil; --length > 0;) {
    if (nil == prev) {
      [bezier moveToPoint:s->point];
    }
    prev = s++;
    [bezier addCurveToPoint:s->point controlPoint1:CGPointAdd(prev->point, prev->handleOut) controlPoint2:CGPointAdd(s->point, s->handleIn)];
  }
  
  return bezier;
}

- (CGPoint)firstPoint
{
  return _segments[0].point;
}

- (CGPoint)lastPoint
{
  return _segments[_segmentsLength - 1].point;
}


- (void)getSegments:(PASegment *)segments
{
  memcpy(segments, _segments, _segmentsLength*sizeof(PASegment));
}

- (void)setSegments:(PASegment *)segments length:(NSUInteger)length
{
  if (nil != _segments) {
    free(_segments);
  }
  _segments = malloc(length * sizeof(PASegment));
  memcpy(_segments, segments, length*sizeof(PASegment));
  _segmentsLength = length;
  _length = NAN;
  _closed = NO;
}

-(NSUInteger)curvesLength
{
  NSUInteger length = self.segmentsLength;

  // Reduce length by one if it's an open path
  if (!_closed && length > 0) {
    length--;
  }
  return length;
}

- (void)getCurves:(PACurve *)curves
{
  NSUInteger length = self.segmentsLength;
  
  // Reduce Length by one if it's an open path:
  if (!_closed && length > 0) {
    length--;
  }
  
  for (NSUInteger i = 0; i < length;) {
    PACurve curve = (PACurve){_segments[i].point, _segments[i].handleOut, _segments[i+1].handleIn, _segments[i+1].point};
    memcpy(&curves[i++], curve, sizeof(PACurve));
  }
  
  return;
}

- (CGFloat)length
{
  NSUInteger l = self.curvesLength;
  PACurve curves[l];
  
  if (_length != _length) {    
    [self getCurves:curves];
    _length = 0.0;
    for (NSUInteger i = 0; i < l;) {
      _length += PACurveLength(curves[i++]);
    }
  }
  return _length;
}

- (PACurveLocation)nearestLocationToPoint:(CGPoint)point
{
  NSUInteger l = self.curvesLength;
  PACurve curves[l];
  CGFloat minDist = INFINITY;
  PACurveLocation minLoc;
  
  [self getCurves:curves];
  for (NSUInteger i = 0; i < l;) {
    PACurveLocation loc = PACurveLocationFromPoint(curves[i++], point);
    if (loc.distance < minDist) {
      minDist = loc.distance;
      minLoc = loc;
    }
  }
  return minLoc;
}

- (CGFloat)distanceToPoint:(CGPoint)point
{
  return [self nearestLocationToPoint:point].distance;
}

- (CGPoint)nearestPoint:(CGPoint)point
{
  return [self nearestLocationToPoint:point].point;
}

- (PACurveLocation)locationAt:(CGFloat)offset
{
  NSUInteger l = self.curvesLength;
  PACurve curves[l];
  PACurveLocation result;
  CGFloat length = 0;
  
  [self getCurves:curves];
  for (NSUInteger i = 0; i < l; i++) {
    CGFloat start = length;
    length += PACurveLength(curves[i]);
    if (length >= offset) {
      // Found the segment within which the length lies
      return PACurveLocationMake(curves[i], PACurveParameterAt(curves[i], offset - start, 0));
    }
    // It may be that through impreciseness of getLength, that the end
    // of the curves was missed:
    if (offset <= self.length) {
      return PACurveLocationMake(curves[l-1], 1);
    }
  }
  return result;
}

- (CGPoint)pointAt:(CGFloat)offset
{
  PACurveLocation loc = [self locationAt:offset];
  return PACurvePointAt(loc.curve, loc.t);
}

// bi-compares two paths to determine how close to tolerance units
// they are overall to one another.
// TODO: break up each path according to its length, not just 10 chunks
- (CGFloat)compare:(PAPath *)path withTolerance:(CGFloat)tolerance
{
  double diff = 0.0;
  CGFloat l1 = self.length, l2 = path.length;
  
  for (NSUInteger i = 0; i <= 9; i++) {
    CGPoint pt = [self pointAt:l1*((float)i / 9.0)];
    diff += [path distanceToPoint:pt];
    pt = [path pointAt:l2 * ((float)i / 10.0)];
    diff += [self distanceToPoint:pt];
  }

  // average distance of the 10 different points on each of 2 curves
  // scaled to tolerance
  return (CGFloat)(diff / ((double)2.0 * 10.0 * tolerance));
}

// returns true if this path lies fully within tolerance units of the
// second path
// TODO: break up the path according to its length, not just 10 chunks
- (BOOL)containedBy:(PAPath *)path withTolerance:(CGFloat)tolerance
{
  double diff = 0.0;
  
  for (NSUInteger i = 0; i <= 9; i++) {
    CGPoint pt = [self pointAt:self.length * ((float)i / 9.0)];
    diff += [path distanceToPoint:pt];
  }
  return (diff / ((double)10.0 * tolerance)) < tolerance;
}

- (void)stroke
{
  [[self asBezier] stroke];
}

- (void)drawPoints:(CGContextRef)ctx
{
  for (NSUInteger i = 0, l = self.segmentsLength; i < l; i++) {
    CGContextFillRect(ctx, CGRectMake(_segments[i].point.x-1, _segments[i].point.y-1, 2, 2));
  }
}

- (void)drawHandles:(CGContextRef)ctx
{
  for (NSUInteger i = 0, l = self.segmentsLength; i < l; i++) {
    CGPoint pt = _segments[i].point,
            handleIn = CGPointAdd(pt, _segments[i].handleIn),
            handleOut = CGPointAdd(pt, _segments[i].handleOut);
    CGPoint segments[4] = { handleIn, pt, pt, handleOut };
    CGContextStrokeLineSegments(ctx, segments, 4);
    CGContextFillRect(ctx, CGRectMake(handleIn.x-2, handleIn.y-2, 4, 4));
    CGContextFillRect(ctx, CGRectMake(handleOut.x-2, handleOut.y-2, 4, 4));
  }
}

@end
