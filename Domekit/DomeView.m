//
//  DomeView -  project Dome objects
//
//  DomeView knows:
//   - dome's rotation from normals (x, y, z)
//     and the location of the rotated points
//   Invisible Lines, which opens up new calculations:
//     - how many visible points / struts
//
//  DomeView does not store:
//   - geometry of dome

#import "DomeView.h"

@interface DomeView()
{
    Dome *dome;
    double scale;    // scale for rendering
    CGPoint sliceLine;
    BOOL sliceMode;
    Point3D *r;  // angle of rotation in view from normals
    NSArray *projectedPoints_;      // rotated points
    int polaris, octantis;
    BOOL sphere;  // during calculateInvisibles, updates wether a dome or a sphere
}

@end

@implementation DomeView
@synthesize dome;
@synthesize polaris;
@synthesize octantis;

-(id) init
{
    r = [[Point3D alloc] initWithCoordinatesX:0 Y:0 Z:0];
    scale = 65;
    sliceLine.y = 2;
    sliceMode = false;
    
    dome = [[Dome alloc] init];
    projectedPoints_ = [[NSArray alloc] initWithArray:dome.points_];
    
    [self calculateInvisibles];
    [self capturePoles];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return [self init];
}

-(BOOL) getSliceMode { return sliceMode; }
-(void) setSliceMode:(BOOL) slice { sliceMode = slice; }
-(CGFloat) getSliceY { return sliceLine.y; }  //can be float instead of double, little precision involved
-(void) setSliceY:(CGFloat)y { sliceLine.y = y; }
-(double) getScale { return scale; }
-(void) setScale:(double) s { scale = s; }
-(Point3D*) getRotation{ return r; }
-(void) setRotationX:(double)rX Y:(double)rY Z:(double)rZ { r = [[Point3D alloc] initWithCoordinatesX:rX Y:rY Z:rZ]; }
-(BOOL) isSphere{return sphere;}

-(double) getDomeHeight  /* returns value between 0 and 1, visible dome only*/
{
    double lowest = -2;
    double max = sqrt( ((1 + sqrt(5)) / 2 ) + 2 );
    for(int i = 0; i < dome.points_.count; i++)
    {
        if([dome.invisiblePoints_[i] boolValue] == FALSE && [projectedPoints_[i] getY] > lowest)
            lowest = [projectedPoints_[i] getY];
    }
    lowest = ( lowest + max ) / (2 * max);
    if(lowest < 0) lowest = 0;
    return lowest;
}

// calling this before drawing diagram centers the top point (polaris) in the middle of the diagram
-(double) getDomeHeightAutoAlignOff  /* returns value between 0 and 1, visible dome only*/
{
    NSArray *points = [[NSMutableArray alloc] initWithArray:dome.points_];
    NSMutableArray *container = [[NSMutableArray alloc] init];
    Point3D *rotated = [[Point3D alloc] init];
    double offset =  atan2([points[octantis] getX], [points[octantis] getY]);
    double distance, angle;
    for(int i = 0; i < points.count; i++)
    {
        angle = atan2([points[i] getX], [points[i] getY]);
        distance = sqrt( pow([points[i] getX], 2) + pow([points[i] getY], 2) );
        rotated = [[Point3D alloc] initWithCoordinatesX:distance*sin(angle-offset)
                                                      Y:distance*cos(angle-offset)
                                                      Z:[points[i] getZ]];
        [container addObject:rotated];
    }
    points = [[NSArray alloc] initWithArray:container];
    container = [[NSMutableArray alloc] init];
    offset =  atan2([points[octantis] getZ], [points[octantis] getY]);
    for(int i = 0; i < points.count; i++)
    {
        angle = atan2([points[i] getZ], [points[i] getY]);
        distance = sqrt( pow([points[i] getZ], 2) + pow([points[i] getY], 2) );
        rotated = [[Point3D alloc] initWithCoordinatesX:[points[i] getX]
                                                      Y:distance*cos(angle-offset)
                                                      Z:distance*sin(angle-offset)];
        [container addObject:rotated];
    }
    points = [[NSArray alloc] initWithArray:container];

    double lowest = -2;
    double max = sqrt( ((1 + sqrt(5)) / 2 ) + 2 );
    for(int i = 0; i < points.count; i++)
    {
        if([dome.invisiblePoints_[i] boolValue] == FALSE && [points[i] getY] > lowest)
            lowest = [points[i] getY];
    }
    lowest = ( lowest + max ) / (2 * max);
    if(lowest < 0) lowest = 0;
    return lowest;
}

-(double) getLongestStrutLength:(BOOL)visibleOnly
{
    double distance;
    double longest = 0;
    for(int i = 0; i < dome.lines_.count; i+=2)
    {
        if(visibleOnly)
        {
            if( [dome.invisibleLines_[i] boolValue] == FALSE)
            {
                distance= sqrt(
                               pow( [dome.points_[ [dome.lines_[i] integerValue] ]getX] - [dome.points_[ [dome.lines_[i+1] integerValue] ]getX], 2) +
                               pow( [dome.points_[ [dome.lines_[i] integerValue] ]getY] - [dome.points_[ [dome.lines_[i+1] integerValue] ]getY], 2) +
                               pow( [dome.points_[ [dome.lines_[i] integerValue] ]getZ] - [dome.points_[ [dome.lines_[i+1] integerValue] ]getZ], 2) );
                
                if(longest < distance) longest = distance;
            }
        }
        else{
            distance= sqrt(
                           pow( [dome.points_[ [dome.lines_[i] integerValue] ]getX] - [dome.points_[ [dome.lines_[i+1] integerValue] ]getX], 2) +
                           pow( [dome.points_[ [dome.lines_[i] integerValue] ]getY] - [dome.points_[ [dome.lines_[i+1] integerValue] ]getY], 2) +
                           pow( [dome.points_[ [dome.lines_[i] integerValue] ]getZ] - [dome.points_[ [dome.lines_[i+1] integerValue] ]getZ], 2) );
            
            if(longest < distance) longest = distance;
        }
    }
    // length = ratio to dome diameter, which is 1
    return longest / (2*sqrt( ((1 + sqrt(5)) / 2 ) + 2 ));  // (2 * 1.90211)
}

-(int) getPointCount  /* only visible points */
{
    int count = 0;
    for(int i = 0; i < dome.invisiblePoints_.count; i++)
        if([dome.invisiblePoints_[i] boolValue] == FALSE) count++;
    return count;
}

-(int) getLineCount /* only visible lines */
{
    int count = 0;
    for(int i = 0; i < dome.invisibleLines_.count; i++)
        if([dome.invisibleLines_[i] boolValue] == FALSE) count++;
    count = count/2.0;  // lines are stored as pairs of points, so divide by 2
    return count;
}


// question, should this include invisible lines, and just have 0s associated with them, or
//    have them missing entirely?
-(NSArray*) getVisibleLineSpeciesCount  /* how many of each type of strut length do we have? */
{
    int i;
    int speciesCount[dome.lineClass_.count];
    for(i = 0; i < dome.lineClass_.count; i++) speciesCount[i] = 0;
    for(i = 0; i < dome.lineClass_.count; i++)
    {
        if(![dome.invisibleLines_[i*2] boolValue])speciesCount[[dome.lineClass_[i] integerValue]]++;
    }
    NSMutableArray *mutable = [[NSMutableArray alloc] init];
    for(i = 0; i < dome.lineClass_.count; i++)
    {
        if(speciesCount[i] != 0) mutable[i] = [[NSNumber alloc] initWithInt:speciesCount[i]];
        else mutable[i] = [[NSNumber alloc] initWithInt:0];
    }
    return [[NSArray alloc] initWithArray:mutable];
}

-(NSArray*) getLengthOrder
{
    NSMutableArray *lengthOrder = [[NSMutableArray alloc] initWithCapacity:dome.lineClassLengths_.count];
    int i, j, index;
    for(i = 0; i < dome.lineClassLengths_.count; i++) [lengthOrder addObject:[[NSNumber alloc] initWithInt:0]];
    for(i = 0; i < dome.lineClassLengths_.count; i++){
        index = 0;
        for(j = 0; j < dome.lineClassLengths_.count; j++){
            if(i!=j && [dome.lineClassLengths_[i] doubleValue] > [dome.lineClassLengths_[j] doubleValue]) index++;
        }
        lengthOrder[index] = [[NSNumber alloc] initWithInt:i];
    }
    return [[NSArray alloc] initWithArray:lengthOrder];
}

-(void) capturePoles
{
    double shortest;
    double tallest;
    for(int i = 0; i < projectedPoints_.count; i++)
    {
        if(i == 0 || [projectedPoints_[i] getY] < tallest)
        {
            tallest = [projectedPoints_[i] getY];
            polaris = i;
        }
        if(i == 0 || [projectedPoints_[i] getY] > shortest)
        {
            shortest = [projectedPoints_[i] getY];
            octantis = i;
        }
    }
}

-(void) align
{
    r = [[Point3D alloc] initWithCoordinatesX:0 Y:0 Z:0];
    projectedPoints_ = [[NSArray alloc] initWithArray:dome.points_];
}

-(void) generate:(int)domeV
{
    [dome geodecise:domeV];
    [self projectPoints];
    [self capturePoles];
    [self calculateInvisibles];
    [self setNeedsDisplay];
}

-(void) refresh
{
    [self projectPoints];
    [self setNeedsDisplay];
}

-(void) calculateInvisibles
{
    NSMutableArray *invisiblePoints = [[NSMutableArray alloc] init];
    NSMutableArray *invisibleLines = [[NSMutableArray alloc] init];
    int count;
    for(count = 0; count < dome.lines_.count; count+=2)
    {
        if( ([projectedPoints_[ [dome.lines_[count] integerValue] ] getY] > sliceLine.y) ||
           ([projectedPoints_[ [dome.lines_[count+1] integerValue] ] getY] > sliceLine.y) )
        {
            [invisibleLines addObject:[[NSNumber alloc] initWithBool:TRUE]];
            [invisibleLines addObject:[[NSNumber alloc] initWithBool:TRUE]];
        }
        else{
            [invisibleLines addObject:[[NSNumber alloc] initWithBool:FALSE]];
            [invisibleLines addObject:[[NSNumber alloc] initWithBool:FALSE]];
        }
    }
    for(count = 0; count < dome.points_.count; count++)
    {
        if([projectedPoints_[count] getY] > sliceLine.y){
            [invisiblePoints addObject:[[NSNumber alloc] initWithBool:TRUE]];
            if(count == octantis) sphere = false;
        }
        else{
            [invisiblePoints addObject:[[NSNumber alloc] initWithBool:FALSE]];
            if(count == octantis) sphere = true;
        }
    }
    dome.invisibleLines_ = [[NSArray alloc] initWithArray:invisibleLines];
    dome.invisiblePoints_ = [[NSArray alloc] initWithArray:invisiblePoints];
}


// float calculations instead of double to speed up animation
-(void) projectPoints
{
    NSMutableArray *rotated = [[NSMutableArray alloc] init];
    CGFloat distance;
    CGFloat angle;
    Point3D *point = [[Point3D alloc] init];
    for(Point3D *i in dome.points_)
    {
        point = i;
        if([r getX] != 0)
        {
            distance = sqrt(pow([point getY], 2) + pow([point getZ], 2));
            angle = atan2f([point getY], [point getZ]) + [r getX];
            point = [[Point3D alloc] initWithCoordinatesX:[point getX] Y:distance*sinf(angle) Z:distance*cosf(angle)];
        }
        if([r getY] != 0)
        {
            distance = sqrt(pow([point getX], 2) + pow([point getZ], 2));
            angle = atan2f([point getX], [point getZ]) + [r getY];
            point = [[Point3D alloc] initWithCoordinatesX:distance*sinf(angle) Y:[point getY] Z:distance*cosf(angle)];
        }
        if([r getZ] != 0)
        {
            distance = sqrt(pow([point getX], 2) + pow([point getY], 2));
            angle = atan2f([point getX], [point getY]) + [r getZ];
            point = [[Point3D alloc] initWithCoordinatesX:distance*sinf(angle) Y:distance*cosf(angle) Z:[point getZ]];
        }
        [rotated addObject:point];
    }
    projectedPoints_ = [[NSArray alloc] initWithArray:rotated];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect canvas = [self bounds];
    int width = canvas.size.width;
    int height = canvas.size.height;
    int halfWidth = width/2;
    int halfHeight = height/2;
    
    //CGContextClearRect(context, [self bounds]);
    int count;
    NSNumber *connect;
    
    [[UIColor whiteColor] setStroke];
    
    if(sliceMode) [self calculateInvisibles];
    
    if(sliceMode)
    {
        for(count = 0; count < dome.lines_.count; count+=2)
        {
            if( [dome.invisibleLines_[count] boolValue] == TRUE)
            {
                [[UIColor colorWithWhite:1.0 alpha:0.2] setStroke];
            }
            else{
                [[UIColor whiteColor] setStroke];
            }
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, [projectedPoints_[ [dome.lines_[count] integerValue]] getX]*scale+halfWidth,
                                          [projectedPoints_[ [dome.lines_[count] integerValue]] getY]*scale+halfHeight);
            CGContextAddLineToPoint(context, [projectedPoints_[ [dome.lines_[count+1] integerValue]] getX]*scale+halfWidth,
                                             [projectedPoints_[ [dome.lines_[count+1] integerValue]] getY]*scale+halfHeight);
            CGContextClosePath(context);
            CGContextDrawPath(context, kCGPathFillStroke);
        }
    }
    else
    {
        count = 0;
        for (NSNumber *i in dome.lines_)
        {
            if (count%2==0) connect = i;
            else{
                if([dome.invisibleLines_[count] boolValue] == FALSE)
                {
                    CGContextBeginPath(context);
                    CGContextMoveToPoint(context, [projectedPoints_[connect.integerValue] getX]*scale+halfWidth,
                                                  [projectedPoints_[connect.integerValue] getY]*scale+halfHeight);
                    CGContextAddLineToPoint(context, [projectedPoints_[i.integerValue] getX]*scale+halfWidth,
                                                     [projectedPoints_[i.integerValue] getY]*scale+halfHeight);
                    CGContextClosePath(context);
                    CGContextDrawPath(context, kCGPathFillStroke);
                }
            }
            count++;
        }
    }
    [[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0] setStroke];
    [[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0] setFill];
    
    if(sliceMode){
        count = 0;
        for (Point3D *node in projectedPoints_)
        {
            if([dome.invisiblePoints_[count] boolValue] == TRUE){
                [[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.3] setStroke];
                [[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:0.3] setFill];
            }
            else{
                [[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0] setStroke];
                [[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0] setFill];            
            }
            CGContextFillRect(context, CGRectMake([node getX]*scale+halfWidth-1, [node getY]*scale+halfHeight-1, 3, 3));
            count++;
        }
    }
    else{
        count = 0;
        for (Point3D *node in projectedPoints_) {
            if([dome.invisiblePoints_[count] boolValue] == FALSE)
            {
                CGContextFillRect(context, CGRectMake([node getX]*scale+halfWidth-1, [node getY]*scale+halfHeight-1, 3, 3));
            }
            count++;
        }
    }

    /*CGPoint midpoint;
    [[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0] setStroke];
    for(count = 0; count < dome.faces_.count; count+=3)
    {
        CGContextBeginPath(context);

        midpoint = CGPointMake(( [projectedPoints_[[dome.faces_[count] intValue]] getX] +
                                     [projectedPoints_[[dome.faces_[count+1] intValue]] getX] +
                                     [projectedPoints_[[dome.faces_[count+2] intValue]] getX] )/3
                               , ( [projectedPoints_[[dome.faces_[count] intValue]] getY]  +
                                      [projectedPoints_[[dome.faces_[count+1] intValue]] getY] +
                                      [projectedPoints_[[dome.faces_[count+2] intValue]] getY])/3
                               );
        
        CGContextMoveToPoint(context, midpoint.x*scale+halfWidth, midpoint.y*scale+halfHeight);
        CGContextAddLineToPoint(context, midpoint.x*scale+halfWidth+1, midpoint.y*scale+halfHeight+1);
        CGContextClosePath(context);
        CGContextDrawPath(context, kCGPathFillStroke);
        
    }*/
    
    if(sliceMode)
    {
        [[UIColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:1.0] setStroke];
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, 0, sliceLine.y*scale+halfHeight);
        CGContextAddLineToPoint(context, canvas.size.width, sliceLine.y*scale+halfHeight);
        CGContextClosePath(context);
        CGContextDrawPath(context, kCGPathFillStroke);
        
        [[UIColor colorWithRed:0.0 green:0.8 blue:0.0 alpha:0.7] setFill];
        CGContextMoveToPoint(context, halfWidth-5, sliceLine.y*scale+halfHeight-3);
        CGContextAddLineToPoint(context, halfWidth+5, sliceLine.y*scale+halfHeight-3);
        CGContextAddLineToPoint(context, halfWidth, sliceLine.y*scale+halfHeight-11);
        CGContextFillPath(context);
        //CGContextSetLineWidth(context, 1.0);
        CGContextStrokePath(context);

        CGContextMoveToPoint(context, halfWidth-5, sliceLine.y*scale+halfHeight+3);
        CGContextAddLineToPoint(context, halfWidth+5, sliceLine.y*scale+halfHeight+3);
        CGContextAddLineToPoint(context, halfWidth, sliceLine.y*scale+halfHeight+11);
        CGContextFillPath(context);
        //CGContextSetLineWidth(context, 1.0);
        CGContextStrokePath(context);
    }
    
    /*[[UIColor colorWithRed:0.0 green:0.8 blue:0 alpha:1.0] setStroke];
    [[UIColor colorWithRed:0.0 green:0.8 blue:0 alpha:1.0] setFill];
    
    CGContextFillRect(context, CGRectMake([projectedPoints_[dome.polaris] getX]*scale+halfWidth-1, [projectedPoints_[dome.polaris] getY]*scale+halfHeight-1, 3, 3));

    [[UIColor colorWithRed:0.8 green:0 blue:0.8 alpha:1.0] setStroke];
    [[UIColor colorWithRed:0.8 green:0 blue:0.8 alpha:1.0] setFill];
    
    CGContextFillRect(context, CGRectMake([projectedPoints_[dome.octantis] getX]*scale+halfWidth-1, [projectedPoints_[dome.octantis] getY]*scale+halfHeight-1, 3, 3));
     */
}

-(void) report
{
    NSLog(@"points_: %i",dome.points_.count);
    NSLog(@"lines_: %i",dome.lines_.count/2);
    NSLog(@"faces_: %i",dome.faces_.count/3);
    //for(Point3D *i in dome.points_) NSLog(@"X:%f Y:%f Z:%f ",[i getX],[i getY], [i getZ]);
}


@end
