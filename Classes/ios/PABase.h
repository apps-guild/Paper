//
//  PABase.h
//
//  Created by Nathaniel Brown on 10/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef PABase_h
#define PABase_h

static const CGFloat NUMERICAL_TOLERANCE = 10e-6;
static const CGFloat NUMERICAL_EPSILON   = 10e-12;

typedef double (^PANumericalFunction)(CGFloat t);
CGFloat PANumericalIntegrate(PANumericalFunction f, CGFloat a, CGFloat b, NSUInteger n);
CGFloat PANumericalFindRoot(PANumericalFunction f, PANumericalFunction df, CGFloat x, CGFloat a, CGFloat b, NSUInteger n, CGFloat tolerance);

CG_INLINE CGPoint
__CGPointNegate(const CGPoint p)
{
  return CGPointMake(-p.x, -p.y);
}
#define CGPointNegate __CGPointNegate

CG_INLINE CGPoint
__CGPointNormalize(const CGPoint p)
{
  CGFloat current = sqrt(p.x * p.x + p.y * p.y);
  CGFloat scale = current != 0 ? 1.0/current : 0;
  return CGPointMake(p.x * scale, p.y * scale);
}
#define CGPointNormalize __CGPointNormalize

CG_INLINE CGPoint
__CGPointNormalizeToLength(const CGPoint p, const CGFloat length)
{
  CGFloat current = sqrt(p.x * p.x + p.y * p.y);
  CGFloat scale = current != 0 ? length / current : 0;
  return CGPointMake(p.x * scale, p.y * scale);  
}
#define CGPointNormalizeToLength __CGPointNormalizeToLength

CG_INLINE CGFloat
__CGPointDistance(const CGPoint p1, const CGPoint p2)
{
  CGFloat x = p1.x - p2.x,
  y = p1.y - p2.y;
  return sqrt(x * x + y * y);
}
#define CGPointDistance __CGPointDistance

CG_INLINE CGPoint
__CGPointAdd(const CGPoint p1, const CGPoint p2)
{
  return CGPointMake(p1.x+p2.x, p1.y+p2.y);
}
#define CGPointAdd __CGPointAdd

CG_INLINE CGPoint
__CGPointSubtract(const CGPoint p1, const CGPoint p2)
{
  return CGPointMake(p1.x-p2.x, p1.y-p2.y);
}
#define CGPointSubtract __CGPointSubtract

CG_INLINE CGPoint
__CGPointMultiply(const CGPoint p, const CGFloat s)
{
  return CGPointMake(p.x*s, p.y*s);
}
#define CGPointMultiply __CGPointMultiply
#define CGPointScale __CGPointMultiply

CG_INLINE CGPoint
__CGPointDivide(const CGPoint p1, const CGFloat s)
{
  return CGPointMake(p1.x / s, p1.y / s);
}
#define CGPointDivide __CGPointDivide

CG_INLINE CGPoint
__CGPointMidpoint(const CGPoint p1, const CGPoint p2)
{
  return CGPointMultiply(CGPointAdd(p1, p2), 0.5f);
}
#define CGPointMidpoint __CGPointMidpoint

CG_INLINE CGFloat
__CGPointDot(const CGPoint p1, const CGPoint p2)
{
  return p1.x*p2.x + p1.y*p2.y;
}
#define CGPointDot __CGPointDot

CG_INLINE CGFloat
__CGPointCross(const CGPoint p1, const CGPoint p2)
{
  return p1.x*p2.y - p1.y*p2.x;
}
#define CGPointCross __CGPointCross

CG_INLINE CGFloat
__CGPointLength(const CGPoint p, BOOL squared)
{
  CGFloat l = p.x * p.x + p.y * p.y;
  return squared ? l : sqrt(l);
}
#define CGPointLength __CGPointLength

CG_INLINE BOOL
__CGPointNearPoint(const CGPoint p1, CGPoint p2, CGFloat tolerance)
{
  return CGRectContainsPoint(CGRectMake(p2.x-tolerance, p2.y-tolerance, 2.0*tolerance, 2.0*tolerance), p1);
}
#define CGPointNearPoint __CGPointNearPoint

#endif
