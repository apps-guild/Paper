//
//  PAPathFitter.m
//  
//
//  Created by Nathaniel Brown on 10/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PAPathFitter.h"
#import "PAPath.h"
#import "PASegment.h"

// An Algorithm for Automatically Fitting Digitized Curves
// by Philip J. Schneider
// from "Graphics Gems", Academic Press, 1990
// Modifications and optimisations of original algorithm by Juerg Lehni.
// Conversion to Objective-C by Nat Brown.

typedef struct {
  CGFloat maxDist;
  NSUInteger index;
} PAFitError;

@interface PAPathFitter () {
@private
  CGFloat    _error;
  CGPoint    *_points;
  NSUInteger _numPoints;
  PASegment  *_segments;
  PASegment  *_currentSegment;
}
- (void)fit;
- (void)fitCubicToFirst:(NSUInteger)first last:(NSUInteger)last tan1:(CGPoint)tan1 tan2:(CGPoint)tan2;
- (void)addCurve:(PACurve)curve;
- (void)generateBezier:(PACurve)curve forFirst:(NSUInteger)first last:(NSUInteger)last uPrime:(CGFloat *)uPrime tan1:(CGPoint)tan1 tan2:(CGPoint)tan2;
- (void)reparameterizeForFirst:(NSUInteger)first last:(NSUInteger)last uPrime:(CGFloat *)u curve:(PACurve)curve;
- (CGFloat)findRootForCurve:(PACurve)curve point:(CGPoint)point u:(CGFloat)u;
- (CGPoint)evaluateCurve:(PACurve)curve ofDegree:(NSUInteger)degree at:(CGFloat)t;
- (void)chordLengthParameterizeForFirst:(NSUInteger)first last:(NSUInteger)last uPrime:(CGFloat *)u;
- (PAFitError)findMaxErrorForCurve:(PACurve)curve first:(NSUInteger)first last:(NSUInteger)last u:(CGFloat *)u;
@end

@implementation PAPathFitter

#pragma mark PAPathFitter public methods
#pragma mark -

- (void)internalInit
{
  _points = nil;
  _numPoints = 0;
  _segments = nil;
  _currentSegment = nil;
}

- (id)init
{
  if (self = [super init]) {
    [self internalInit];
  }
  return self;
}

- (void)dealloc
{
  free(_points);
  free(_segments);
}

- (id)initWithSegments:(PASegment *)segments length:(NSUInteger)length andError:(CGFloat)error
{
  if (self = [super init])
  {
    [self internalInit];
    // Copy over points from path and filter out adjacent duplicates.
    _points = malloc(length*sizeof(CGPoint));
    CGPoint *cur = _points,
            *prev = nil;
    for (PASegment *segment = segments; length > 0; segment++, length--) {
      if (!prev || !CGPointEqualToPoint(*prev, segment->point)) {
        *cur = segment->point;
        prev = cur++;
      }
    }
    _numPoints = cur - _points;
    _error = error;
  }
  return self;
}

+ (id)withPath:(PAPath *)path andError:(CGFloat)error
{
  NSUInteger numSegments = [path segmentsLength];
  PASegment segments[numSegments];
  [path getSegments:segments];

  return [[PAPathFitter alloc] initWithSegments:segments length:numSegments andError:error];
}

+ (id)withPoints:(NSArray *)path andError:(CGFloat)error
{
  return [[PAPathFitter alloc] initWithPoints:path andError:error];
}

- (id)initWithPoints:(NSArray *)path andError:(CGFloat)error
{
  if (self = [super init])
  {
    [self internalInit];
    // Copy over points from path and filter out adjacent duplicates.
    _points = malloc([path count]*sizeof(CGPoint));
    CGPoint *cur = _points;
    NSValue *prev = nil;
    for (NSValue *pointVal in path) {
      if (!prev || !CGPointEqualToPoint([prev CGPointValue], [pointVal CGPointValue])) {
        *cur++ = [pointVal CGPointValue];
        prev = pointVal;
      }
    }
    _numPoints = cur - _points;
    _error = error;
  }
  return self;
}

- (UIBezierPath *)asBezier
{
  UIBezierPath *bezier = [UIBezierPath bezierPath];

  [self fit];
  for (PASegment *s = _segments, *prev = nil; s != _currentSegment;) {
    if (nil == prev) {
      [bezier moveToPoint:s->point];
    }
    prev = s++;
    [bezier addCurveToPoint:s->point controlPoint1:CGPointAdd(prev->point,prev->handleOut) controlPoint2:CGPointAdd(s->point, s->handleIn)];
  }
  return bezier;
}

- (PAPath *)fit:(CGFloat)error
{
  _error = error;
  [self fit];
  return [PAPath withSegments:_segments length:(_currentSegment - _segments) + 1];
}

#pragma mark PAPathFitter private methods
#pragma mark -

- (void)fit
{
  if (nil != _segments) {
    free(_segments);
  }
  _segments = malloc(_numPoints * sizeof(PASegment));
  _currentSegment = _segments;
  *_currentSegment = (PASegment){_points[0], {0,0}, {0,0}};
  
  [self fitCubicToFirst:0 last:_numPoints - 1
                   // Left Tangent
                   tan1:CGPointNormalize(CGPointSubtract(_points[1], _points[0]))
                   // Right Tangent
                   tan2:CGPointNormalize(CGPointSubtract(_points[_numPoints-2], _points[_numPoints-1]))];
}

// Fit a Bezier curve to a (sub)set of digitized points
- (void)fitCubicToFirst:(NSUInteger)first last:(NSUInteger)last tan1:(CGPoint)tan1 tan2:(CGPoint)tan2
{
  // Use heuristic if region only has two points in it
  if (last - first == 1) {
    CGPoint  pt1 = _points[first],
    pt2 = _points[last];
    CGFloat  dist = CGPointDistance(pt1,pt2) / 3.0;
    [self addCurve:(PACurve){pt1,CGPointAdd(pt1,CGPointNormalizeToLength(tan1,dist)),CGPointAdd(pt2,CGPointNormalizeToLength(tan2,dist)),pt2}];
    return;
  }
  // Parameterize points, and attempt to fit curve
  CGFloat uPrime[last-first+1];
  [self chordLengthParameterizeForFirst:first last:last uPrime:uPrime];
  CGFloat maxError = MAX(_error, _error*_error);
  NSUInteger split;
  
  // Try 4 iterations
  for (NSUInteger i = 0; i <= 4; i++) {
    PACurve curve;
    [self generateBezier:curve forFirst:first last:last uPrime:uPrime tan1:tan1 tan2:tan2];
    // Find max deviation of points to fitted curve
    PAFitError max = [self findMaxErrorForCurve:curve first:first last:last u:uPrime];
    if (max.maxDist < _error) {
      [self addCurve:curve];
      return;
    }
    split = max.index;
    // If error not too Large, try reparameterization and iteration
    if (max.maxDist >= maxError) {
      break;
    }
    [self reparameterizeForFirst:first last:last uPrime:uPrime curve:curve];
    maxError = max.maxDist;
  }
  // Fitting failed -- split at max error point and fit recursively
  CGPoint V1 = CGPointSubtract(_points[split - 1], _points[split]),
          V2 = CGPointSubtract(_points[split], _points[split + 1]),
          tanCenter = CGPointNormalize(CGPointDivide(CGPointAdd(V1, V2), 2));
  [self fitCubicToFirst:first last:split tan1:tan1                     tan2:tanCenter];
  [self fitCubicToFirst:split last:last  tan1:CGPointNegate(tanCenter) tan2:tan2];
}

- (void)addCurve:(PACurve)curve
{
  _currentSegment->handleOut = CGPointSubtract(curve[1],curve[0]);
  *++_currentSegment = (PASegment){curve[3], CGPointSubtract(curve[2], curve[3]), {0,0}};

//  _currentSegment->handleOut = curve[1];
//  *++_currentSegment = (PASegment){curve[3], curve[2], {0,0}};
}

- (void)generateBezier:(PACurve)curve forFirst:(NSUInteger)first last:(NSUInteger)last uPrime:(CGFloat *)uPrime tan1:(CGPoint)tan1 tan2:(CGPoint)tan2  
{
  CGFloat epsilon = NUMERICAL_EPSILON;
  CGPoint pt1 = _points[first],
          pt2 = _points[last];
  // Create the C and X matrices
  CGFloat C[2][2] = {{0,0},{0,0}},
          X[2]    = {0,0};
  
  for (NSUInteger i = 0, l = last - first + 1; i < l; i++) {
    CGFloat u = uPrime[i],
            t = 1.0 - u,
            b = 3.0 * u * t,
            b0 = t * t * t,
            b1 = b * t,
            b2 = b * u,
            b3 = u * u * u;
    CGPoint a1 = CGPointNormalizeToLength(tan1,b1),
            a2 = CGPointNormalizeToLength(tan2,b2),
            tmp = CGPointSubtract(CGPointSubtract(_points[first + i], CGPointMultiply(pt1, b0 + b1)), CGPointMultiply(pt2, b2 + b3));
    C[0][0] += CGPointDot(a1,a1);
    C[0][1] += CGPointDot(a1,a2);
    // C[1][0] += CGPointDot(a1,a2);
    C[1][0] = C[0][1];
    C[1][1] += CGPointDot(a2,a2);
    X[0] += CGPointDot(a1,tmp);
    X[1] += CGPointDot(a2,tmp);
  }
  
  // Compute the determinants of C and X
  CGFloat detC0C1 = C[0][0] * C[1][1] - C[1][0] * C[0][1],
          alpha1, alpha2;
  if (fabs(detC0C1) > epsilon) {
    // Kramer's rule
    CGFloat detC0X = C[0][0] * X[1]    - C[1][0] * X[0],
    detXC1 = X[0]    * C[1][1] - X[1]    * C[0][1];
    // Derive alpha values
    alpha1 = detXC1 / detC0C1;
    alpha2 = detC0X / detC0C1;
  } else {
    // Matrix is under-determined, try assuming alpha1 == alpha2
    CGFloat c0 = C[0][0] + C[0][1],
    c1 = C[1][0] + C[1][1];
    if (fabs(c0) > epsilon) {
      alpha1 = alpha2 = X[0] / c0;
    } else if (fabs(c1) > epsilon) {
      alpha1 = alpha2 = X[1] / c1;
    } else {
      // Handle below
      alpha1 = alpha2 = 0.;
    }
  }
  
  // If alpha negative, use the Wu/Barsky heuristic (see text)
  // (if alpha is 0, you get coincident control points that lead to
  // divide by zero in any subsequent NewtonRaphsonRootFind() call.
  CGFloat segLength = CGPointDistance(pt2, pt1);
  epsilon *= segLength;
  if (alpha1 < epsilon || alpha2 < epsilon) {
    // fall back on standard (probably inaccurate) formula,
    // and subdivide further if needed.
    alpha1 = alpha2 = segLength / 3;
  }
  
  // First and last control points of the Bezier curve are
  // positioned exactly at the first and last data points
  // Control points 1 and 2 are positioned an alpha distance out
  // on the tangent vectors, left and right, respectively
  PACurve result = {pt1, CGPointAdd(pt1, CGPointNormalizeToLength(tan1, alpha1)),
    CGPointAdd(pt2, CGPointNormalizeToLength(tan2, alpha2)), pt2};
  memcpy(curve, result, sizeof(PACurve));
}

// Given set of points and their parameterization, try to find
// a better parameterization.
- (void)reparameterizeForFirst:(NSUInteger)first last:(NSUInteger)last uPrime:(CGFloat *)u curve:(PACurve)curve
{
  for (NSUInteger i = first; i <= last; i++) {
    u[i-first] = [self findRootForCurve:curve point:_points[i] u:u[i - first]];
  }
}

// Use Newton-Raphson iteration to find better root.
- (CGFloat)findRootForCurve:(PACurve)curve point:(CGPoint)point u:(CGFloat)u
{
  PACurve curve1, curve2;
  // Generate control vertices for Q'
  for (NSUInteger i = 0; i <= 2; i++) {
    curve1[i] = CGPointSubtract(curve[i + 1], CGPointMultiply(curve[i], 3));
  }
  // Generate control vertices for Q''
  for (NSUInteger i = 0; i <= 1; i++) {
    curve2[i] = CGPointSubtract(curve[i + 1], CGPointMultiply(curve[i], 2));
  }
  // Compute Q(u), Q'(u) and Q''(u)
  CGPoint pt = [self evaluateCurve:curve ofDegree:3 at:u],
  pt1 = [self evaluateCurve:curve ofDegree:2 at:u],
  pt2 = [self evaluateCurve:curve ofDegree:1 at:u];
  CGPoint diff = CGPointSubtract(pt, point);
  CGFloat df = CGPointDot(pt1, pt1) + CGPointDot(diff, pt2);
  // Compute f(u) / f'(u)
  if (fabs(df) < NUMERICAL_TOLERANCE) {
    return u;
  }
  // u = u - f(u) / f'(u)
  return u - CGPointDot(diff, pt1) / df;
}

- (CGPoint)evaluateCurve:(PACurve)curve ofDegree:(NSUInteger)degree at:(CGFloat)t
{
  // Copy array 
  PACurve tmp;
  memcpy(tmp, curve, sizeof(tmp));
  // Triangle computation
  for (NSUInteger i = 1; i <= degree; i++) {
    for (NSUInteger j = 0; j <= degree - i; j++) {
      tmp[j] = CGPointAdd(CGPointMultiply(tmp[j], 1.0 - t), CGPointMultiply(tmp[j + 1], t));
    }
  }
  return tmp[0];
}

// Assign parameter values to digitized points
// using relative distances between points.
- (void)chordLengthParameterizeForFirst:(NSUInteger)first last:(NSUInteger)last uPrime:(CGFloat *)u
{
  for (NSUInteger i = first + 1; i <= last; i++) {
    u[i - first] = u[i - first - 1]
    + CGPointDistance(_points[i], _points[i - 1]);
  }
  for (NSUInteger i = 1, m = last - first; i <= m; i++) {
    u[i] /= u[m];
  }
}

// Find the maximum squared distance of digitized points to fitted curve
- (PAFitError)findMaxErrorForCurve:(PACurve)curve first:(NSUInteger)first last:(NSUInteger)last u:(CGFloat *)u
{
  PAFitError result = { 0, floor((last - first + 1) / 2.0) };
  for (NSUInteger i = first + 1; i < last; i++) {
    CGPoint P = [self evaluateCurve:curve ofDegree:3 at:u[i - first]],
    v = CGPointSubtract(P, _points[i]);
    CGFloat dist = v.x * v.x + v.y * v.y; // squared
    if (dist >= result.maxDist) {
      result.maxDist = dist;
      result.index = i;
    }
  }
  return result;
}

@end