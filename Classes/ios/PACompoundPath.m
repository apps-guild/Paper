//
//  PACompoundPath.m
//
//  Created by Nathaniel Brown on 10/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PACompoundPath.h"

@interface PACompoundPath () {
@private
  NSMutableArray *_paths;
  CGFloat _length;
}
- (void)_changed;
@end

@implementation PACompoundPath
@synthesize paths = _paths, length = _length;

- (id)init
{
  if (self = [super init]) {
    _paths = [NSMutableArray arrayWithCapacity:4];
    _length = NAN;
  }
  return self;
}

+ (PACompoundPath *)withPath:(PAPath *)path
{
  return [PACompoundPath withPaths:[NSArray arrayWithObject:path]];
}

+ (PACompoundPath *)withPaths:(NSArray *)paths
{
  PACompoundPath *compoundPath = [[PACompoundPath alloc] init];
  [compoundPath addPaths:paths];
  return compoundPath;
}

- (void)_changed
{
  _length = NAN;
}

- (void)addPath:(PAPath *)path
{
  [_paths addObject:[path copy]];
  [self _changed];
}

- (void)addPaths:(NSArray *)paths
{
  for (PAPath *path in paths) {
    [_paths addObject:[path copy]];
  }
  [self _changed];
}

- (CGFloat)length
{
  if (_length != _length) {
    _length = 0.0;
    for (PAPath *path in _paths) {
      _length += path.length;
    }
  }
  return _length;
}

+ (NSArray *)foldPaths:(NSDictionary *)paths withTolerance:(CGFloat)tolerance
{
  return nil;
}

// compacts a compound path by joining paths whose starting and ending points
// are within tolerance units, and eliminates paths which are on average within
// tolerance of other (possibly compacted) paths.
//  ** note this does not always create optimally joined paths - that is a
//     traveling salesman problem **
- (PACompoundPath *)compactWithTolerance:(CGFloat)tolerance
{
  PACompoundPath *newPath = [[PACompoundPath alloc] init];
  NSMutableDictionary *toFold = [NSMutableDictionary dictionaryWithCapacity:_paths.count];
  NSMutableArray *currentPathSet = _paths,
                 *nextPathSet = [NSMutableArray arrayWithCapacity:_paths.count];
  
  // tolerance:NaN or too close to zero get default tolerance
  if (tolerance != tolerance || tolerance < NUMERICAL_TOLERANCE) tolerance = 2.0;

  do {
    // compare all pair combinations of the paths
    // TODO: replace with an NSArray#Combination(2) type enumerator in a category to
    //  make this less obtuse
    for (PAPath *pathA in currentPathSet) {
      if (pathA.closed) {
        [nextPathSet addObject:pathA];
        continue;
      }
      BOOL skip = YES;
      NSString *nameA = [NSString stringWithFormat:@"%p", pathA];
      for (PAPath *pathB in currentPathSet) {
        if (pathA == pathB) {
          skip = NO;
          continue;
        }
        if (YES == skip) continue;
        CGFloat combinedLength = pathA.length + pathB.length;
        NSArray *already = [toFold objectForKey:nameA];
        
        // there is a longer compaction already - we prefer it, even though there could be
        // a better compaction with a different combination of multiple paths
        if (already && [[already objectAtIndex:0] floatValue] > combinedLength) continue;
        
        if (CGPointNearPoint(pathA.firstPoint, pathB.firstPoint, tolerance) ||
            CGPointNearPoint(pathA.firstPoint, pathB.lastPoint, tolerance) ||
            CGPointNearPoint(pathA.lastPoint, pathB.firstPoint, tolerance) ||
            CGPointNearPoint(pathA.lastPoint, pathB.lastPoint, tolerance)) {
          [toFold setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:combinedLength], pathB, pathA, nil]
                     forKey:nameA];
        }
      }
      // didn't find a way to fold A, propagate it
      if (![toFold objectForKey:nameA]) {
        [nextPathSet addObject:pathA];
      }
    }
    [nextPathSet addObjectsFromArray:[PACompoundPath foldPaths:toFold withTolerance:tolerance]];
  } while (toFold.count > 0);
  
  
  
  return newPath;
}

- (CGFloat)compactCompare:(PACompoundPath *)compoundPath withTolerance:(CGFloat)tolerance
{
  return [[self compactWithTolerance:tolerance] compare:[compoundPath compactWithTolerance:tolerance] withTolerance:tolerance];
}

// compare this compound path (A) to another compound path (B), weighing the overall match
// according to how much each path contributes to the total length of the compound path
- (CGFloat)compare:(PACompoundPath *)compoundPath withTolerance:(CGFloat)tolerance
{
  double  overallDiff = 0.0;

  // compare all pair combinations of the paths of A and B
  for (PAPath *pathA in _paths) {
    CGFloat minBDiff = INFINITY,
            minBLength = 0.0;
    for (PAPath *pathB in compoundPath.paths) {
      CGFloat diff = [pathA compare:pathB withTolerance:tolerance];
      if (diff < minBDiff) {
        minBDiff = diff;
        minBLength = pathB.length;
      }
    }
    overallDiff += (pathA.length + minBLength) * minBDiff;
  }
  return (CGFloat)(overallDiff / (double)(self.length + compoundPath.length));
}

- (void)stroke
{
  for (PAPath *path in _paths) {
    [path stroke];
  }
}

@end
