//
//  PALine.m
//  spelling
//
//  Created by Nathaniel Brown on 10/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PALine.h"

BOOL PALineIntersect(const PALine this, const PALine line, CGPoint *point)
{
  CGFloat cross = CGPointCross(this.vector, line.vector);
  // Avoid divisions by 0, and errors when getting too close to 0
  if (fabs(cross) <= NUMERICAL_EPSILON)
    return false;
  CGPoint v = CGPointSubtract(line.point, this.point);
  CGFloat t1 = CGPointCross(v, line.vector) / cross,
          t2 = CGPointCross(v, this.vector) / cross;
  // Check the ranges of t parameters if the line is not allowed to
  // extend beyond the definition points.
  if ((this.infinite || (0 <= t1 && t1 <= 1)) && (line.infinite || (0 <= t2 && t2 <= 1))) {
    if (point) {
      *point = CGPointAdd(this.point, CGPointMultiply(this.vector, t1));
    }
    return true;
  }
  return false;
}

CGFloat PALineDistanceToPoint(const PALine this, const CGPoint point)
{
  CGFloat m = this.vector.y / this.vector.x, // slope
          b = this.point.y - (m * this.point.x); // y offset
  // Distance to the linear equation
  CGFloat dist = fabs(point.y - (m * point.x) - b) / sqrt(m * m + 1);
  if (this.infinite) {
    return dist;
  }
  CGFloat dist2 = CGPointDistance(point, this.point);
  CGFloat dist3 = CGPointDistance(point, CGPointAdd(this.point, this.vector));
  return MIN(MIN(dist, dist2), dist3);
}