//
//  PACurve.m
//  spelling
//
//  Created by Nathaniel Brown on 10/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PACurve.h"
#import "PALine.h"

typedef CGFloat PACurveValues[8];
typedef CGPoint PACurvePoints[4];
typedef CGPoint PACurveBezierForm[6];

void PACurveGetValues(const PACurve curve, PACurveValues v);
void PACurveGetPoints(const PACurve curve, PACurvePoints v);
CGPoint PACurveEvaluate(const PACurve curve, CGFloat t, NSUInteger type);
CGFloat getIterations(CGFloat a, CGFloat b);
PANumericalFunction getLengthIntegrand(PACurveValues v);

void toBezierForm(const PACurvePoints v, CGPoint point, PACurveBezierForm w);
void findRoots(PACurveBezierForm w, NSUInteger depth, NSMutableArray *roots);
NSUInteger countCrossings(PACurveBezierForm v);
BOOL isFlatEnough(PACurveBezierForm v);

static const NSUInteger maxDepth = 32;
static const CGFloat epsilon = 1.1641532182693481e-10; // 2 ^ (-maxDepth - 1)

void PACurveGetValues(const PACurve curve, PACurveValues v)
{
  v[0] = curve[0].x;
  v[1] = curve[0].y;
  v[2] = curve[0].x + curve[1].x;
  v[3] = curve[0].y + curve[1].y;
  v[4] = curve[3].x + curve[2].x;
  v[5] = curve[3].y + curve[2].y;
  v[6] = curve[3].x;
  v[7] = curve[3].y;
}

void PACurveGetPoints(const PACurve curve, PACurvePoints points)
{
    PACurveGetValues(curve, (void *)points);
}

CGPoint PACurvePointAt(const PACurve curve, const CGFloat t)
{
  return PACurveEvaluate(curve, t, 0);
}

CGPoint PACurveTangentAt(const PACurve curve, const CGFloat t)
{
  return PACurveEvaluate(curve, t, 1);
}

CGPoint PACurveNormalAt(const PACurve curve, const CGFloat t)
{
  return PACurveEvaluate(curve, t, 2);
}

CGPoint PACurveEvaluate(const PACurve curve, CGFloat t, NSUInteger type)
{
  PACurveValues v;
  PACurveGetValues(curve, v);

  CGFloat p1x = v[0], p1y = v[1],
          c1x = v[2], c1y = v[3],
          c2x = v[4], c2y = v[5],
          p2x = v[6], p2y = v[7],
          x, y;
  
  // Handle special case at beginning / end of curve
  // PORT: Change in Sg too, so 0.000000000001 won't be
  // required anymore
  if (type == 0 && (t == 0 || t == 1)) {
    x = t == 0 ? p1x : p2x;
    y = t == 0 ? p1y : p2y;
  } else {
    // TODO: Find a better solution for this:
    // Prevent tangents and normals of length 0:
    CGFloat tMin = NUMERICAL_TOLERANCE;
    if (t < tMin && c1x == p1x && c1y == p1y)
      t = tMin;
    else if (t > 1.0 - tMin && c2x == p2x && c2y == p2y)
      t = 1.0 - tMin;
    // Calculate the polynomial coefficients.
    CGFloat cx = 3.0 * (c1x - p1x),
            bx = 3.0 * (c2x - c1x) - cx,
            ax = p2x - p1x - cx - bx,
    
            cy = 3.0 * (c1y - p1y),
            by = 3.0 * (c2y - c1y) - cy,
            ay = p2y - p1y - cy - by;
    
    switch (type) {
      case 0: // point
        // Calculate the curve point at parameter value t
        x = ((ax * t + bx) * t + cx) * t + p1x;
        y = ((ay * t + by) * t + cy) * t + p1y;
        break;
      case 1: // tangent
      case 2: // normal
        // Simply use the derivation of the bezier function for both
        // the x and y coordinates:
        x = (3.0 * ax * t + 2.0 * bx) * t + cx;
        y = (3.0 * ay * t + 2.0 * by) * t + cy;
        break;
    }
  }
  // The normal is simply the rotated tangent:
  // TODO: Rotate normals the other way in Scriptographer too?
  // (Depending on orientation, I guess?)
  return type == 2 ? CGPointMake(y, -x) : CGPointMake(x, y);
}

PANumericalFunction getLengthIntegrand(PACurveValues v)
{
  // Calculate the coefficients of a Bezier derivative.
  CGFloat p1x = v[0], p1y = v[1],
          c1x = v[2], c1y = v[3],
          c2x = v[4], c2y = v[5],
          p2x = v[6], p2y = v[7],
  
          ax = 9.0 * (c1x - c2x) + 3.0 * (p2x - p1x),
          bx = 6.0 * (p1x + c2x) - 12.0 * c1x,
          cx = 3.0 * (c1x - p1x),
  
          ay = 9.0 * (c1y - c2y) + 3.0 * (p2y - p1y),
          by = 6.0 * (p1y + c2y) - 12.0 * c1y,
          cy = 3.0 * (c1y - p1y);
  
  return (PANumericalFunction)^(CGFloat t){
    // Calculate quadratic equations of derivatives for x and y
    CGFloat dx = (ax * t + bx) * t + cx,
            dy = (ay * t + by) * t + cy;
    return sqrt(dx * dx + dy * dy);
  };
}

// Amount of integral evaluations for the interval 0 <= a < b <= 1
CGFloat getIterations(CGFloat a, CGFloat b) {
  // Guess required precision based and size of range...
  // TODO: There should be much better educated guesses for
  // this. Also, what does this depend on? Required precision?
  return MAX(2.0, MIN(16.0, ceil(fabs(b - a) * 32.0)));
}

CGFloat PACurveLengthBetween(const PACurve curve, CGFloat a, CGFloat b)
{
  if (a != a) a = 0.0;
  if (b != b) b = 1.0;
  // if (p1 == c1 && p2 == c2):
  if (CGPointEqualToPoint(curve[0], curve[2]) && CGPointEqualToPoint(curve[1], curve[3])) {
    // Straight Line
    CGFloat dx = curve[1].x - curve[0].x, // p2x - p1x
            dy = curve[1].y - curve[0].y; // p2y - p1y
    return (b - a) * sqrt(dx * dx + dy * dy);
  }
  PACurveValues v;
  PACurveGetValues(curve, v);
  PANumericalFunction ds = getLengthIntegrand(v);
  return PANumericalIntegrate(ds, a, b, getIterations(a, b));
}

CGFloat PACurveParameterAt(const PACurve curve, CGFloat offset, CGFloat start)
{
  if (offset == 0)
    return start;
  // See if we're going forward or backward, and handle cases
  // differently
  BOOL forward = offset > 0;
  CGFloat a = forward ? start : 0,
          b = forward ? 1 : start;
  offset = fabs(offset);
  
  // Use integrand to calculate both range length and part
  // lengths in f(t) below.
  PACurveValues v;
  PACurveGetValues(curve, v);
  PANumericalFunction ds = getLengthIntegrand(v);
  // Get length of total range
  CGFloat rangeLength = PANumericalIntegrate(ds, a, b,
                                             getIterations(a, b));
  if (offset >= rangeLength)
    return forward ? b : a;
  // Use offset / rangeLength for an initial guess for t, to
  // bring us closer:
  CGFloat guess = offset / rangeLength,
          __block length = 0,
          __block _start = start;
  // Iteratively calculate curve range lengths, and add them up,
  // using integration precision depending on the size of the
  // range. This is much faster and also more precise than not
  // modifing start and calculating total length each time.
  PANumericalFunction f = (PANumericalFunction)^(CGFloat t){
    CGFloat count = getIterations(_start, t);
    length += _start < t
                    ? PANumericalIntegrate(ds, _start, t, count)
                    : -PANumericalIntegrate(ds, t, _start, count);
    _start = t;
    return length - offset;
  };
  return PANumericalFindRoot(f, ds,
                            forward ? a + guess : b - guess, // Initial guess for x
                            a, b, 16, NUMERICAL_TOLERANCE);
}

void toBezierForm(const PACurvePoints v, CGPoint point, PACurveBezierForm w)
{
    static const CGFloat zCubic[3][4] = { {1.0, 0.6, 0.3, 0.1},
                                          {0.4, 0.6, 0.6, 0.4},
                                          {0.1, 0.3, 0.6, 1.0} };
    NSUInteger n = 3, // degree of B(t)
               degree = 5; // degree of B(t) . P
    PACurveBezierForm c, d;
    CGFloat    cd[3][4];

    for (NSUInteger i = 0; i <= n; i++) {
        // Determine the c's -- these are vectors created by subtracting
        // point point from each of the control points
        c[i] = CGPointSubtract(v[i], point);
        // Determine the d's -- these are vectors created by subtracting
        // each control point from the next
        if (i < n) {
            d[i] = CGPointMultiply(CGPointSubtract(v[i + 1],v[i]), n);
        }
    }

    // Create the c,d table -- this is a table of dot products of the
    // c's and d's
    for (NSUInteger row = 0; row < n; row++) {
        for (NSUInteger column = 0; column <= n; column++)
            cd[row][column] = CGPointDot(d[row], c[column]);
    }

    // Now, apply the z's to the dot products, on the skew diagonal
    // Also, set up the x-values, making these "points"
    for (NSUInteger i = 0; i <= degree; i++)
        w[i] = CGPointMake((CGFloat)i / degree, 0);

    for (NSInteger k = 0; k <= degree; k++) {
        NSUInteger lb = MAX(0, k - (NSInteger)n + 1),
                   ub = MIN(k, n);
        for (NSUInteger i = lb; i <= ub; i++) {
            NSUInteger j = k - i;
            w[k].y += cd[j][i] * zCubic[j][i];
        }
    }
}

/**
 * Given a 5th-degree equation in Bernstein-Bezier form, find all of the
 * roots in the interval [0, 1].  Return the number of roots found.
 */
void findRoots(PACurveBezierForm w, NSUInteger depth, NSMutableArray *roots)
{
  switch (countCrossings(w)) {
    case 0:
      // No solutions here
      return;
    case 1:
      // Unique solution
      // Stop recursion when the tree is deep enough
      // if deep enough, return 1 solution at midpoint
      if (depth >= maxDepth) {
        [roots addObject:[NSNumber numberWithFloat:(0.5 * (w[0].x + w[5].x))]];
        return;
      }
      // Compute intersection of chord from first control point to last
      // with x-axis.
      if (isFlatEnough(w)) {
        PALine line = PALineMakeInfinite(w[0], w[5], true);
        // Compare the line's squared length with EPSILON. If we're
        // below, #intersect() will return null because of division
        // by near-zero.
        if (CGPointLength(line.vector, true) <= NUMERICAL_EPSILON) {
          [roots addObject:[NSNumber numberWithFloat:line.point.x]];
          return;
        }
        PALine xAxis = PALineMakeInfinite(CGPointMake(0, 0), CGPointMake(1, 0), true);
        CGPoint intersect;
        PALineIntersect(xAxis, line, &intersect);
        [roots addObject:[NSNumber numberWithFloat:intersect.x]];
        return;
      }
  }
  
  // Otherwise, solve recursively after
  // subdividing control polygon
  PACurveBezierForm p[6],
                    left,
                    right;
  for (NSUInteger j = 0; j <= 5; j++)
    p[0][j] = w[j];
  
  // Triangle computation
  for (NSUInteger i = 1; i <= 5; i++) {
    for (NSUInteger j = 0 ; j <= 5 - i; j++)
      p[i][j] = CGPointMultiply(CGPointAdd(p[i - 1][j], p[i - 1][j + 1]), 0.5);
  }
  for (NSUInteger j = 0; j <= 5; j++) {
    left[j]  = p[j][0];
    right[j] = p[5 - j][j];
  }
  
  findRoots(left, depth+1, roots);
  findRoots(right, depth+1, roots);
}

/**
 * Count the number of times a Bezier control polygon  crosses the x-axis.
 * This number is >= the number of roots.
 */
NSUInteger countCrossings(PACurveBezierForm v)
{
  NSUInteger crossings = 0;
  NSInteger  prevSign = 0;
  for (NSUInteger i = 0; i < 6; i++) {
    NSInteger sign = v[i].y < 0 ? -1 : 1;
    if (prevSign != 0 && sign != prevSign)
      crossings++;
    prevSign = sign;
  }
  return crossings;
}

/**
 * Check if the control polygon of a Bezier curve is flat enough for
 * recursive subdivision to bottom out.
 */
BOOL isFlatEnough(PACurveBezierForm v)
{
  // Find the  perpendicular distance from each interior control point to
  // line connecting v[0] and v[degree]
  
  // Derive the implicit equation for line connecting first
  // and last control points
  NSUInteger n = 6 - 1;
  CGFloat a = v[0].y - v[n].y,
          b = v[n].x - v[0].x,
          c = v[0].x * v[n].y - v[n].x * v[0].y,
          maxAbove = 0,
          maxBelow = 0;
  // Find the largest distance
  for (NSUInteger i = 1; i < n; i++) {
    // Compute distance from each of the points to that line
    CGFloat val = a * v[i].x + b * v[i].y + c,
            dist = val * val;
    if (val < 0 && dist > maxBelow) {
      maxBelow = dist;
    } else if (dist > maxAbove) {
      maxAbove = dist;
    }
  }
  // Compute intercepts of bounding box
  return fabs((maxAbove + maxBelow) / (2.0 * a * (a * a + b * b))) < epsilon;
}

PACurveLocation PACurveLocationFromPoint(const PACurve curve, const CGPoint point)
{
  // NOTE: If we allow #matrix on Path, we need to inverse-transform
  // point here first.
  // point = this._matrix.inverseTransform(point);
  
  PACurvePoints v;
  PACurveBezierForm w;
  PACurveGetPoints(curve, v);
  toBezierForm(v, point, w);
  // Also look at beginning and end of curve (t = 0 / 1)
  NSMutableArray *roots = [NSMutableArray arrayWithObjects:[NSNumber numberWithFloat:0], [NSNumber numberWithFloat:1], nil];
  findRoots(w, 0, roots);
  CGFloat minDist = INFINITY,
          minT;
  CGPoint minPoint;
  // There are always roots, since we add [0, 1] above.
  for (NSNumber *i in roots) {
    CGPoint pt = PACurvePointAt(curve, [i floatValue]);
    CGFloat dist = CGPointDistance(point, pt);
    // We're NOT comparing squared distances
    if (dist < minDist) {
      minDist = dist;
      minT = [i floatValue];
      minPoint = pt;
    }
  }
  return PACurveLocationMakeWithPoint(curve, minT, minPoint, minDist);
}
