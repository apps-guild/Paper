# Paper

An Objective-C port of [paper.js](http://paperjs.org), still quite under construction. I found Core Graphics quite limited in its ability to manipulate Beziers, combine them, tweak their control points, etc, and paper.js quite good at it, so I started the port focusing on Bezier Curves.
The port was designed to follow paper.js source very closely at the function and even line level in some cases so that changes and bug-fixes are easier to incorporate from watching the changelog. So, for example, a Javascript function like:

    addCurve: function(curve) {
      var prev = this.segments[this.segments.length - 1];
      prev.setHandleOut(curve[1].subtract(curve[0]));
      this.segments.push(new Segment(curve[3], curve[2].subtract(curve[3])));
    }

might become

    - (void)addCurve:(PACurve)curve
    {
      _currentSegment->handleOut = CGPointSubtract(curve[1],curve[0]);
      *++_currentSegment = (PASegment){curve[3], CGPointSubtract(curve[2], curve[3]), {0,0}};
    }

## Usage

The Example project implements the iOS version of the [paperjs.org's Path Simplification](http://paperjs.org/examples/path-simplification/) example page. It is a simple single-view iOS application which lets you touch and drag to create a set of points - when you release it simplifies the point set into a bezier curve and redraws the shape using a UIBezierCurve stroke. The core work is found in the `BezierView`, which converts an `NSArray` of `CGPoint`'s stored in `NSValue`'s into a `UIBezierCurve`.

    #include "PAPath.h"
    #include "PAPathFitter.h"
    
    NSMutableArray points = ...;
    PAPathFitter *pathFitter = [PAPathFitter withPoints:points andError:5.0];
    PAPath *path = [pathFitter fit:5.5];
    UIBezierCurve *bezier = [path asBezier];
    ...
    [bezier stroke];


## Installation

Paper *looks* like it is available through [CocoaPods](http://cocoapods.org), but I haven't yet finished podifying it. Once it is to install it simply add the following line to your Podfile:

    pod "Paper"

until then, just clone this repo and run the sample project.

## Author

Nat Brown, natbro@gmail.com

## License

Paper is available under the MIT license. See the LICENSE file for more info.

