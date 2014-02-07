//
//  PACurve.h
//  spelling
//
//  Created by Nathaniel Brown on 10/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PABase.h"

typedef CGPoint PACurve[4];
typedef struct {
  PACurve curve;
  CGFloat t;
  CGPoint point;
  CGFloat distance;
} PACurveLocation;

CGPoint PACurvePointAt(const PACurve curve, const CGFloat t);
CGPoint PACurveTangentAt(const PACurve curve, const CGFloat t);
CGPoint PACurveNormalAt(const PACurve curve, const CGFloat t);
PACurveLocation PACurveLocationFromPoint(const PACurve curve, const CGPoint p);
CGFloat PACurveParameterAt(const PACurve curve, CGFloat offset, CGFloat start);
CGFloat PACurveLengthBetween(const PACurve curve, CGFloat a, CGFloat b);

CG_INLINE PACurveLocation
__PACurveLocationMake(const PACurve curve, CGFloat t)
{
  PACurveLocation result = (PACurveLocation){{}, t, CGPointMake(0, 0), 0};
  memcpy(&result.curve, curve, sizeof(PACurve));
  return result;
}
#define PACurveLocationMake __PACurveLocationMake

CG_INLINE PACurveLocation
__PACurveLocationMakeWithPoint(const PACurve curve, CGFloat t, CGPoint point, CGFloat distance)
{
  PACurveLocation result = (PACurveLocation){{}, t, point, distance};
  memcpy(&result.curve, curve, sizeof(PACurve));
  return result;
}
#define PACurveLocationMakeWithPoint __PACurveLocationMakeWithPoint

CG_INLINE CGFloat
__PACurveLength(const PACurve curve)
{
  return PACurveLengthBetween(curve, 0.0, 1.0);
}
#define PACurveLength __PACurveLength

CG_INLINE CGPoint
__PACurveNearestPoint(const PACurve curve, const CGPoint p)
{
  return PACurveLocationFromPoint(curve, p).point;
}
#define PACurveNearestPoint __PACurveNearestPoint

CG_INLINE CGFloat
__PACurveDistanceToPoint(const PACurve curve, const CGPoint p)
{
  return PACurveLocationFromPoint(curve, p).distance;
}
#define PACurveDistanceToPoint __PACurveDistanceToPoint