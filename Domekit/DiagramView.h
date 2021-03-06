//
//  DiagramView.h
//  Domekit
//
//  Created by Robby on 2/4/13.
//  Copyright (c) 2013 Robby Kraft. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Dome.h"

@interface DiagramView : UIView

@property Dome *dome;
@property NSArray *colorTable;

-(id) initWithFrame:(CGRect)frame Dome:(Dome*)domeIn;
-(void) importDome:(Dome*)domeIn Polaris:(int)north Octantis:(int)south;
-(void) alignPoles;

-(void) setScale:(double)x;  /* roughly corrosponds to radius of diagram in pixels */
-(void) setLineWidth:(CGFloat)x;
-(NSArray*) getLengthOrder;

@end
