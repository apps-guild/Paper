//
//  PAPathFitter.h
//
//  This file is part of Paper.Framework, an Objective-C port of Paper.js, a JavaScript
//  Vector Graphics Library based on Scriptographer.org.
//  http://paperjs.org
//  http://scriptographer.org
//  Which are Copyright (c) 2011, Juerg Lehni & Jonathan Puckey
//  http://lehni.org/ & http://jonathanpuckey.com/
//
//  (specifically PAPathFitter is a port of PathFitter,
//   https://github.com/paperjs/paper.js/blob/master/src/path/PathFitter.js)
// 
//  Port Copyright (c) 2012 Nat Brown. All rights reserved.
// 

#import <Foundation/Foundation.h>

@class PAPath;

@interface PAPathFitter : NSObject
+ (id)withPath:(PAPath *)path andError:(CGFloat)error;
+ (id)withPoints:(NSArray *)path andError:(CGFloat)error;
- (id)initWithPoints:(NSArray *)path andError:(CGFloat)error;
- (UIBezierPath *)asBezier;
- (PAPath *)fit:(CGFloat)error;
@end

