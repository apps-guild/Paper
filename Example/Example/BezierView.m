//
//  BezierView.m
//
//  Created by @natbro on 2/6/14.
//

#import "BezierView.h"
#import "PAPathFitter.h"
#import "PAPath.h"

@interface BezierView ()
@property NSMutableArray *points;
@property BOOL done;
@property UIBezierPath *bezier;
@end

@implementation BezierView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  _bezier = nil;
  _points = [NSMutableArray arrayWithObject:[NSValue valueWithCGPoint:[[touches anyObject] locationInView:self]]];
  _done = false;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  [_points addObject:[NSValue valueWithCGPoint:[[touches anyObject] locationInView:self]]];
  [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [_points addObject:[NSValue valueWithCGPoint:[[touches anyObject] locationInView:self]]];
  _done = true;
  [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  _points = nil;
  _done = false;
}

- (void)drawRect:(CGRect)rect
{
  CGColorRef strokeColor = _done ? [UIColor redColor].CGColor : [UIColor blackColor].CGColor;
  CGContextRef c = UIGraphicsGetCurrentContext();
  CGContextClipToRect(c, rect);
  CGContextSetStrokeColorSpace(c, CGColorGetColorSpace(strokeColor));
  CGContextSetStrokeColor(c, CGColorGetComponents(strokeColor));
  
  if (_done) {
    if (!_bezier) {
      // touches done, convert to a bezier and draw
      PAPathFitter *pathFitter = [PAPathFitter withPoints:_points andError:5.0];
      PAPath *path = [pathFitter fit:5.5];
      _bezier = [path asBezier];
    }
    [_bezier stroke];
  } else {
    // touches still happening, just draw as a bunch of lines
    CGContextBeginPath(c);
    CGMutablePathRef path = CGPathCreateMutable();
    BOOL firstPoint = true;
    for (NSValue *pointVal in _points) {
      CGPoint p = [pointVal CGPointValue];
      if (firstPoint) {
        CGPathMoveToPoint(path, nil, p.x, p.y);
        firstPoint = false;
      } else {
        CGPathAddLineToPoint(path, nil, p.x, p.y);
      }
      CGPathAddRect(path, nil, CGRectMake(p.x-2.0, p.y-2.0, 4.0, 4.0));
    }
    CGContextAddPath(c,path);
    CGContextStrokePath(c);
    CGPathRelease(path);
  }
}

@end
