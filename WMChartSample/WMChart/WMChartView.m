//
//  GraphScrollableArea.m
//  WMChart
//
//  Created by Antmanler on 7/12/13.
//  Copyright (c) 2013 iwishow. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "EasyTableView.h"
#import "NSDate+Graph.h"
#import "UIColor+Graph.h"
#import "UIFont+Graph.h"
#import "WMChartDataObject.h"
#import "WMChartView.h"

#define BEZIER_PATH_WIDTH     (5)
#define GRAPH_HEIGHT          (300)
#define GRAPH_FRAME_WIDTH     (320)
#define GRAPH_DATA_HEIGHT     (245)
#define GRAPH_POINT_SIZE      CGSizeMake(70, 70)
#define GRAPH_VISIBLE_FRAME   CGRectMake(0, 75, 320, GRAPH_HEIGHT)
#define VISIBLE_CIRCLE_WITHD  (32)

#define INTERVAL_BETWEEN_DRAWNING_DATE_POINT (40)

#define TOP_Y_OFFSET_FOR_GRAPH_POINTS (35)
#define BOTTOM_Y_OFFSET_FOR_GRAPH_POINTS (GRAPH_HEIGHT - GRAPH_DATA_HEIGHT + 18)

#define MONTH_LABEL_YOFFSET (35)
#define MONTH_LABEL_SIZE CGSizeMake(80, 30)

#define DEF_VIEW_FRAME CGRectMake(0, 0, 320, 400)

#pragma mark - GraphPoint
@class GraphPoint;

@protocol GraphPointDelegate <NSObject>

@optional
- (void)graphPointClicked:(GraphPoint *)point withObject:(WMChartDataObject *)object;

@end

@interface GraphPoint : UIView

@property (nonatomic, weak) id<GraphPointDelegate> delegate;
@property (nonatomic, strong) WMChartDataObject *associatedObject;
@property (nonatomic, unsafe_unretained) BOOL isTouchesEnabled;

- (id)initWithFrame:(CGRect)frame associatedObject:(WMChartDataObject *)theAssociatedObject delegate:(id<GraphPointDelegate>)theDelegate;

@end

#pragma mark - GraphDataView
@interface GraphDataView : UIView {
    UIColor                     *lineColor;
    UIColor                     *gradientColor;
    UIColor                     *todayHighlightColor;
    UILabel                     *dayLabel;
    UILabel                     *monthLabel;
    BOOL                        isToday;
    
    NSMutableArray              *dataPos;
    GraphPoint                  *graphPoint;
    __weak WMChartView  *controller;
}

@property (nonatomic, strong) WMChartDataObject *dataObject;

-(void) updateGraphDate:(WMChartDataObject*)data;

@end


@interface WMChartView() <UIGestureRecognizerDelegate, EasyTableViewDelegate> {
    NSTimeInterval startUNIXDate;
    NSTimeInterval endUNIXDate;
    NSDate         *startDate;
    NSDate         *endDate;
    NSInteger      numberOfDays;
    
    NSInteger newZoomRate;
    Float32   maximumZoomRate;
    Float32   minimumZoomRate;
    
    EasyTableView    *graphTableView;
    UILabel          *leftMouthLabel;
    UILabel          *rightMouthLabel;
}

@property (nonatomic, strong) NSArray *objectsArray;
@property (nonatomic, unsafe_unretained) float dayIntervalWidth;
@property (nonatomic, unsafe_unretained) float minimumYValue;
@property (nonatomic, unsafe_unretained) float maximumYValue;
@property (nonatomic, weak) id<WMChartViewDelegate> delegate;

-(Float32) pointYValueForDataObject:(WMChartDataObject *)data;
-(Float32) pointYValueForDataValue:(Float32)data;

@end

@interface GraphPoint() {
    CALayer *nodeLayer;
}

@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, strong) UILabel *valueLabel;

@end

#pragma mark - implementation GraphPoint
@implementation GraphPoint

- (id)initWithFrame:(CGRect)frame associatedObject:(WMChartDataObject *)theAssociatedObject delegate:(id<GraphPointDelegate>)theDelegate
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        
        // add  value label
        UILabel *lbl = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 70, 19)];
        [lbl setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLightItalic" size:12]];
        [lbl setTextColor:[UIColor wmGraphTextColor]];
        [lbl setAdjustsFontSizeToFitWidth:YES];
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
        [lbl setLineBreakMode:UILineBreakModeMiddleTruncation];
        [lbl setMinimumFontSize:8];
        [lbl setTextAlignment:UITextAlignmentCenter];
#else
        lbl.lineBreakMode = NSLineBreakByTruncatingTail;
        lbl.minimumScaleFactor = 8.f/12.f;
        lbl.textAlignment = NSTextAlignmentCenter;
#endif
        [lbl setShadowOffset:CGSizeMake(0, 0.1f)];
        [lbl setBackgroundColor:[UIColor clearColor]];
        [lbl setCenter:CGPointMake((frame.size.width)/2.f,  (frame.size.height - VISIBLE_CIRCLE_WITHD - 15.f)/2.f)];
        
        [self addSubview:lbl];
        
        nodeLayer = [CALayer layer];
        nodeLayer.contentsScale = [UIScreen mainScreen].scale;
        nodeLayer.contents = (id)[UIImage imageNamed:@"grap_point.png"].CGImage;
        nodeLayer.frame = CGRectMake((self.frame.size.width - VISIBLE_CIRCLE_WITHD)/2, (self.frame.size.height - VISIBLE_CIRCLE_WITHD)/2, VISIBLE_CIRCLE_WITHD, VISIBLE_CIRCLE_WITHD);
        [nodeLayer removeAnimationForKey:@"frame"];
        [self.layer addSublayer:nodeLayer];
        
        self.fillColor = [UIColor clearColor];
        self.valueLabel = lbl;
        self.delegate = theDelegate;
        self.associatedObject = theAssociatedObject;
    }
    return self;
}

- (void)setAssociatedObject:(WMChartDataObject *)associatedObject {
    _associatedObject = associatedObject;
    if (_associatedObject) {
        [self.valueLabel setText: [NSString stringWithFormat:@"%.1f%%", [self.associatedObject.value floatValue] ] ];
        [self setNeedsDisplay];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if([self.delegate respondsToSelector:@selector(graphPointClicked:withObject:)]){
        
        [self.delegate graphPointClicked:self withObject:self.associatedObject];
    }
}


@end

#pragma mark - implementation GraphDataView

@implementation GraphDataView

- (id)initWithFrame:(CGRect)frame associatedDataObject:(WMChartDataObject *)data andGraphController:(WMChartView*) theController {
    
    // expand the frame with a little, to avoid the tiny gap between cells
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width + 1, frame.size.height)];
    
    if (self) {
        controller = theController;
        
        self.backgroundColor = [UIColor wmViewBackgroundColor];//[UIColor clearColor];
        lineColor = [UIColor colorWithRed:152./255.f green:218./255.f blue:247./255.f alpha:0.4f]; //[UIColor graphLightGreenColor];
        UIImage *gradientImg = [UIImage imageNamed:@"graph_background.png"];
        gradientColor = [UIColor colorWithPatternImage:gradientImg];
        todayHighlightColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"graph_today_highlight.png"]];
        
        // add graph point to sub view
        if (frame.size.width >= GRAPH_POINT_SIZE.width/2) {
            if([controller.delegate conformsToProtocol:@protocol(GraphPointDelegate)]) {
                
                graphPoint = [[GraphPoint alloc] initWithFrame:CGRectMake(-12, 0, GRAPH_POINT_SIZE.width, GRAPH_POINT_SIZE.height)
                                              associatedObject:data
                                                      delegate:(id<GraphPointDelegate>)controller.delegate];
            } else {
                graphPoint = [[GraphPoint alloc] initWithFrame:CGRectMake(-12, 0, GRAPH_POINT_SIZE.width, GRAPH_POINT_SIZE.height)
                                              associatedObject:data
                                                      delegate: nil];
            }
            
            [self addSubview: graphPoint];
        }
        
        // data label
        dayLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, GRAPH_DATA_HEIGHT + 10, frame.size.width, 12)];
        [dayLabel setTextColor:[UIColor wmGraphTextColor]];
        [dayLabel setBackgroundColor:[UIColor clearColor]];
        dayLabel.adjustsFontSizeToFitWidth = YES;
        [dayLabel setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:16]];
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
        [dayLabel.textAlignment = UITextAlignmentCenter];
        dayLabel.minimumFontSize = 8;
#else 
        dayLabel.textAlignment = NSTextAlignmentCenter;
        dayLabel.minimumScaleFactor = 8.f/12.f;
#endif
        [self addSubview:dayLabel];
        
        // month label
        monthLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, dayLabel.frame.origin.y + dayLabel.frame.size.height + 5, frame.size.width, 16)];
        [monthLabel setTextColor:[UIColor wmGraphTextColor]];
        [monthLabel setBackgroundColor:[UIColor clearColor]];
        monthLabel.adjustsFontSizeToFitWidth = YES;
        [monthLabel setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:14]];
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
        [monthLabel.textAlignment = UITextAlignmentCenter];
        monthLabel.minimumFontSize = 8;
#else
        monthLabel.textAlignment = NSTextAlignmentCenter;
        monthLabel.minimumScaleFactor = 8.f/12.f;
#endif
        [self addSubview:monthLabel];
        
        [self updateGraphDate:data];
        
    }
    return self;
}

- (void)updateGraphDate:(WMChartDataObject *)data {
    
    if (data) {
        self.dataObject = data;
        graphPoint.associatedObject = data;
        // day label
        NSDate *localDateForDayNumber = [_dataObject.time localDate];
        NSInteger day = [localDateForDayNumber dayNumber];
        dayLabel.text = [NSString stringWithFormat: @"%@%d", (day < 10) ? @"0" : @"", day];
        // month label
        monthLabel.text = [[localDateForDayNumber weekStringDescription] uppercaseString];
        isToday = [NSDate daysBetweenDateOne:data.time dateTwo:[NSDate dateWithTimeIntervalSinceNow:0]] == 0;
    }
    
    if (graphPoint) {
        CGRect newFrame = graphPoint.frame;
        newFrame.origin.x = (self.frame.size.width - newFrame.size.width)/2;
        newFrame.origin.y = [controller pointYValueForDataObject:_dataObject] - GRAPH_POINT_SIZE.height/2;
        graphPoint.frame = newFrame;
    }
    
    //TODO: consider the average value
    if (_dataObject) {
        dataPos = [[NSMutableArray alloc]init];
        Float32 frameWidth = controller.dayIntervalWidth;
        CGFloat minX = frameWidth/2, maxX = frameWidth/2, minY = MAXIMUM_GRAPH_Y_VALUE, y = NAN;
        
        if (_dataObject.prev) {
            minX = -frameWidth/2;
            minY = [controller pointYValueForDataObject:_dataObject.prev];
            [dataPos addObject: [NSValue valueWithCGPoint:CGPointMake(minX, minY)]];
        }
        
        y = [controller pointYValueForDataObject:_dataObject];
        minY = y > minY ? y : minY;
        [dataPos addObject: [NSValue valueWithCGPoint:CGPointMake(maxX, y)]];
        
        if (_dataObject.next) {
            maxX = frameWidth+frameWidth/2;
            y = [controller pointYValueForDataObject:_dataObject.next];
            minY = y > minY ? y : minY;
            [dataPos addObject: [NSValue valueWithCGPoint:CGPointMake(maxX, y)]];
        }
        
        if ([dataPos count] <= 1) {
            // do not plot line if there is only one data
            dataPos = nil;
        } else {
            minY = GRAPH_DATA_HEIGHT;//[controller pointYValueForDataValue:controller.minimumYValue];
            [dataPos insertObject:[NSValue valueWithCGPoint:CGPointMake(minX, minY)] atIndex:0];
            [dataPos addObject:[NSValue valueWithCGPoint:CGPointMake(maxX, minY)]];
        }
        
        [self setNeedsDisplay];
    }
}

- (void)drawRect:(CGRect)rect {
    if (!_dataObject) {
        return;
    }
    
    Float32 frameWidth = controller.dayIntervalWidth;
    
    // drawing background for data
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect rectangle = CGRectMake(0.25, 0.5, frameWidth - 0.5, GRAPH_DATA_HEIGHT);
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(context, rectangle);
    
    // top and bottom border
    [[UIColor colorWithRed:240./255.f green:240./255.f blue:240./255.f alpha:1.0] set];
    CGPoint points[2] = {CGPointMake(0.f, 0.f), CGPointMake(frameWidth, 0.f)};
    CGContextStrokeLineSegments(context, points, 2);
    
    if (isToday) {
        [todayHighlightColor set];
        rectangle = CGRectMake(0.0f, GRAPH_DATA_HEIGHT - 2.0, frameWidth, 2.f);
        CGContextFillRect(context, rectangle);
    } else {
        points[0] = CGPointMake(0.f, GRAPH_DATA_HEIGHT); points[1] = CGPointMake(frameWidth, GRAPH_DATA_HEIGHT);
        CGContextStrokeLineSegments(context, points, 2);
    }
    
    // drawing line
    if (dataPos) {
        UIBezierPath *path = [[UIBezierPath alloc] init];
        [path setLineWidth: BEZIER_PATH_WIDTH];
        [path setLineCapStyle:kCGLineCapRound];
        [path setLineJoinStyle:kCGLineJoinRound];
        
        // close path
        CGContextSaveGState(context);
        int i = 0;
        [path moveToPoint: [[dataPos objectAtIndex:i] CGPointValue]];
        for (; i < [dataPos count]; ++i) {
            [path addLineToPoint:[[dataPos objectAtIndex:i] CGPointValue]];
        }
        [path closePath];
        [path addClip];
        [gradientColor set];
        [path fill];
        CGContextRestoreGState(context);
        
        [path removeAllPoints];
        i = 1;
        [path moveToPoint: [[dataPos objectAtIndex:i] CGPointValue]];
        for (; i < [dataPos count] - 1; ++i) {
            [path addLineToPoint:[[dataPos objectAtIndex:i] CGPointValue]];
        }
        
        // set line color
        [[UIColor whiteColor] set];
        [path stroke];
        [lineColor set];
        [path stroke];

    }
}

@end

#pragma mark - implementation WMChartView

@implementation WMChartView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithGraphDataObjectsArray:(NSArray *)objectsArray startDate:(NSDate *)theStartDate endDate:(NSDate *)theEndDate delegate:(id<WMChartViewDelegate>)theDelegate {
    
    if(self = [super initWithFrame: DEF_VIEW_FRAME]){
        
        self.backgroundColor = [UIColor wmViewBackgroundColor];
        
        self.delegate     = theDelegate;
        self.objectsArray = objectsArray;
        
        startUNIXDate = [startDate timeIntervalSince1970];
        endUNIXDate = [endDate timeIntervalSince1970];
        
        startDate = theStartDate;
        endDate = theEndDate;
        
        numberOfDays = [NSDate daysBetweenDateOne:startDate dateTwo:endDate] + 1;
        maximumZoomRate = numberOfDays < 14.0 ? (numberOfDays < MINIMUM_ZOOM_RATE ? MINIMUM_ZOOM_RATE : numberOfDays) : 14.0;
        minimumZoomRate = MINIMUM_ZOOM_RATE;
        _zoomRate = MINIMUM_ZOOM_RATE;
        
        _minimumYValue = MINIMUM_GRAPH_Y_VALUE;
        _maximumYValue = MAXIMUM_GRAPH_Y_VALUE;
        
        self.userInteractionEnabled = YES;
        
        // add table view as scroller
        graphTableView = nil;
        
        // mouth label
        rightMouthLabel = [self makeMouthLabel];
        leftMouthLabel  = [self makeMouthLabel];
        
        UIPinchGestureRecognizer *pinchRecogniser = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(userDidUsePinchGesture:)];        
        [self addGestureRecognizer:pinchRecogniser];
    }
    
    return self;

}

- (void)dealloc{
    
    self.delegate = nil;
}

- (UILabel*) makeMouthLabel {
    UILabel *label  = [[UILabel alloc] init];
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
    label.textAlignment = UITextAlignmentCenter;
#else
    label.textAlignment	= NSTextAlignmentCenter;
#endif
    CGSize labelSize = MONTH_LABEL_SIZE;
    label.frame = CGRectMake((self.frame.size.width-labelSize.width)/2, MONTH_LABEL_YOFFSET, labelSize.width, labelSize.height);
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue-UltraLight" size:20];
    label.textColor = [UIColor wmGraphTextColor];
    [self addSubview:label];
    return label;
}

#pragma mark PinchGesture

- (void)userDidUsePinchGesture:(UIPinchGestureRecognizer *)recogniser{
    
    newZoomRate = self.zoomRate / [recogniser scale];
    
    if(newZoomRate > maximumZoomRate){
        newZoomRate = maximumZoomRate;
    } else if(newZoomRate < minimumZoomRate){
        newZoomRate = minimumZoomRate;
    }

    
    if([self.delegate respondsToSelector:@selector(graphScrollableView:didChangeZoomRate:)]){
        [self.delegate graphScrollableView:self didChangeZoomRate:newZoomRate];
    }
    
    switch (recogniser.state) {
        case UIGestureRecognizerStateEnded:{
            
            if([self.delegate respondsToSelector:@selector(graphScrollableViewDidEndUpdateZoomRate:)]){
                
                [self.delegate graphScrollableViewDidEndUpdateZoomRate: self];
            }
            
            if(self.zoomRate != newZoomRate) {
                
                self.zoomRate = newZoomRate;
                
                [self reload];
            }
            break;
        } case UIGestureRecognizerStateBegan:{
            
            if([self.delegate respondsToSelector:@selector(graphScrollableViewDidStartUpdateZoomRate:)]){
                
                [self.delegate graphScrollableViewDidStartUpdateZoomRate: self];
            }
            break;
        }
        default:
            break;
    }
}


#pragma mark Recent

- (CGRect)recentObjectsVisibleRect{
    
    CGRect rect = GRAPH_VISIBLE_FRAME;
    rect.origin.x = self.frame.size.width - GRAPH_VISIBLE_FRAME.size.width - 48.f / 2;
    
    return rect;
}

#pragma mark Zoom Rate

- (void)setZoomRate:(NSInteger)theZoomRate{
    
    if((theZoomRate >= minimumZoomRate && theZoomRate <= maximumZoomRate)){
        _zoomRate = theZoomRate;
    }
}

#pragma mark Reload

- (void)reload{
    
    if([self.delegate respondsToSelector:@selector(graphScrollableViewDidStartRedraw:)]){
        [self.delegate graphScrollableViewDidStartRedraw: self];
    }
    
    if (graphTableView) {
        [graphTableView removeFromSuperview];
        graphTableView = nil;
    }
    
    CGRect newFrame = [self frameForCurrentZoomRate];
    
    int dataCnt  = [_objectsArray count];
    int interval = [self daysIntervalBetweenGraphMark];
    
    graphTableView = [[EasyTableView alloc] initWithFrame:newFrame numberOfColumns:dataCnt/interval ofWidth:self.dayIntervalWidth];
    graphTableView.delegate                     = self;
	graphTableView.tableView.backgroundColor    = [UIColor clearColor];
	graphTableView.tableView.allowsSelection    = NO;
    graphTableView.tableView.separatorStyle     = UITableViewCellSeparatorStyleNone;
	graphTableView.cellBackgroundColor          = [UIColor whiteColor];
	graphTableView.autoresizingMask             = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	[self addSubview:graphTableView];
    
    // reset labels state
    leftMouthLabel.text   = @"";
    rightMouthLabel.text  = @"";
    leftMouthLabel.alpha  = 0.0;
    rightMouthLabel.alpha = 1.0;
    
    CGRect LabelFrame     = leftMouthLabel.frame;
    LabelFrame.origin.x   = -LabelFrame.size.width;
    leftMouthLabel.frame  = LabelFrame;
    LabelFrame.origin.x   = (newFrame.size.width - LabelFrame.size.width)/2;
    rightMouthLabel.frame = LabelFrame;
    
    // refresh the minimum and maximum value at current scale
    _minimumYValue = MINIMUM_GRAPH_Y_VALUE;
    _maximumYValue = MAXIMUM_GRAPH_Y_VALUE;
    
    if (dataCnt > 2) {
        _minimumYValue = _maximumYValue = [((WMChartDataObject *)[_objectsArray objectAtIndex:0]).value floatValue];
        
        for (int i = 1; i < dataCnt; i+=interval) {
            WMChartDataObject *obj = [self.objectsArray objectAtIndex:i];
            Float32 val = [obj.value floatValue];
            
            if (_maximumYValue < val) {
                _maximumYValue = val;
                
            } else if (_minimumYValue > val) {
                _minimumYValue = val;
            }
        }
    }
    
    if (dataCnt >= minimumZoomRate * interval) {
        
        [graphTableView.tableView layoutIfNeeded];
        CGPoint conetentOffset = graphTableView.contentOffset;
        conetentOffset.x = graphTableView.contentSize.width - GRAPH_FRAME_WIDTH;
        graphTableView.contentOffset = conetentOffset;
    } else {
        
        graphTableView.tableView.scrollEnabled = NO;
    }
    
    [self.delegate graphScrollableView:self willUpdateFrame:newFrame];
    [self.delegate graphScrollableViewDidEndRedraw: self];

}

#pragma mark - EasyTableViewDelegate

// These delegate methods support both example views - first delegate method creates the necessary views
- (UIView *)easyTableView:(EasyTableView *)easyTableView viewForRect:(CGRect)rect {
    
	GraphDataView *gdv = [[GraphDataView alloc]initWithFrame:rect associatedDataObject:nil andGraphController:self];
    return gdv;
}

// Second delegate populates the views with data from a data source
- (void)easyTableView:(EasyTableView *)easyTableView setDataForView:(UIView *)view forIndexPath:(NSIndexPath *)indexPath {
	GraphDataView *gdv = (GraphDataView*)view;
    int interval = [self daysIntervalBetweenGraphMark];
    int row = indexPath.row;
    
    WMChartDataObject* obj = nil;
    if (row*interval > [_objectsArray count]) {
        obj = [_objectsArray lastObject];
    } else {
        obj = [_objectsArray objectAtIndex:indexPath.row*[self daysIntervalBetweenGraphMark]];
    }
    
    if (interval > 1) {
        WMChartDataObject *newObj = [[WMChartDataObject alloc]init];
        newObj.time = obj.time;
        newObj.value = obj.value;
        
        if (row > 0) {
            newObj.prev = [_objectsArray objectAtIndex:(row-1)*interval];
        }
        
        if ((row+1)*interval < [_objectsArray count]) {
            newObj.next = [_objectsArray objectAtIndex:(row+1)*interval];
        }
        obj = newObj;
    }
    
    [gdv updateGraphDate:obj];
}

- (void)easyTableView:(EasyTableView *)easyTableView scrolledToOffset:(CGPoint)contentOffset {
    
    static float sDir = 0.01f;
    static float sLastDir = -0.01f;
    // finding current movment's direction, to left < 0 and to right > 0
    sDir = contentOffset.x - sDir;
    
    NSArray *dataViews = easyTableView.visibleViews;
    NSInteger lastMonthNumber = 0;
    NSInteger currMonthNumber = 0;
    
    GraphDataView *view = [dataViews objectAtIndex:0];
    lastMonthNumber = currMonthNumber = [view.dataObject.time monthNumber];
    leftMouthLabel.text = [view.dataObject.time monthShortStringDescription];
    int cnt = [dataViews count];
    int idx = 1;
    for (; idx < cnt; ++idx) {
        view = [dataViews objectAtIndex:idx];
        currMonthNumber = [view.dataObject.time monthNumber];
        if (currMonthNumber != lastMonthNumber) {
            break;
        }
        lastMonthNumber = currMonthNumber;
    }
    rightMouthLabel.text = [view.dataObject.time monthShortStringDescription];
    
    if (idx != cnt) {
        // there contains diffrent months
        Float32 viewWidth = view.frame.size.width;
        Float32 tableWidth = self.frame.size.width;
        Float32 alphaInterval = 1.0/(tableWidth-viewWidth);
        
        Float32 offset4Left  = [easyTableView offsetForView:view].x;
    
        leftMouthLabel.alpha = offset4Left*alphaInterval;
        rightMouthLabel.alpha = (tableWidth-offset4Left)*alphaInterval;
        
        // from left to right
        CGRect oldFrameL = leftMouthLabel.frame;
        CGRect oldFrameR = rightMouthLabel.frame;
        Float32 labelCenter2X = tableWidth - oldFrameL.size.width;
        
        if (sDir < 0) {
            
            if (2*oldFrameL.origin.x < labelCenter2X) {
                // left label
                oldFrameL.origin.x -= sDir;
                if (2*oldFrameL.origin.x > labelCenter2X) {
                    oldFrameL.origin.x = labelCenter2X/2.f;
                }
                
                leftMouthLabel.frame = oldFrameL;
                
                if (oldFrameL.origin.x + oldFrameL.size.width >= oldFrameR.origin.x) {
                    // right label                    
                    oldFrameR.origin.x = oldFrameL.origin.x + oldFrameL.size.width;
                    rightMouthLabel.frame = oldFrameR;
                    
                }
                
            } else {
                // right label
                oldFrameR.origin.x -= sDir;
                rightMouthLabel.frame = oldFrameR;
            }
            
        } else if(sDir > 0) {
            
            // from right to left
            if (2*oldFrameR.origin.x > tableWidth - oldFrameR.size.width) {
                // left label
                oldFrameR.origin.x -= sDir;
                if (2*oldFrameR.origin.x < labelCenter2X) {
                    oldFrameR.origin.x = labelCenter2X/2.f;
                }
                rightMouthLabel.frame = oldFrameR;
                
                if (oldFrameL.origin.x + oldFrameL.size.width >= oldFrameR.origin.x) {
                    // right label
                    oldFrameL.origin.x = oldFrameR.origin.x - oldFrameR.size.width;
                    leftMouthLabel.frame = oldFrameL;
                }
            } else {
                // left label
                oldFrameL.origin.x -= sDir;
                leftMouthLabel.frame = oldFrameL;
            }
        }
        
        sLastDir = -sDir;
        
    } else {
        if (sLastDir*sDir < 0) {
            UILabel *centerLabel = nil;
            if (sDir < 0) {
                leftMouthLabel.alpha  = 0.0;
                rightMouthLabel.alpha = 1.0;
                CGRect LabelFrame = leftMouthLabel.frame;
                LabelFrame.origin.x = -LabelFrame.size.width;
                leftMouthLabel.frame = LabelFrame;
                centerLabel = rightMouthLabel;
            } else {
                leftMouthLabel.alpha  = 1.0;
                rightMouthLabel.alpha = 0.0;
                CGRect LabelFrame = leftMouthLabel.frame;
                LabelFrame.origin.x = self.frame.size.width;
                rightMouthLabel.frame = LabelFrame;
                centerLabel = leftMouthLabel;
            }
            CGRect LabelFrame = leftMouthLabel.frame;
            LabelFrame.origin.x = (self.frame.size.width - LabelFrame.size.width)/2;
            centerLabel.frame = LabelFrame;
        }
        
        sLastDir = sDir;
    }
    sDir = contentOffset.x;
    
    
//    self.minimumYValue = MAXIMUM_GRAPH_Y_VALUE;
//    self.maximumYValue = MINIMUM_GRAPH_Y_VALUE;
//    NSArray *data = easyTableView.visibleViews;
//    for (GraphDataView *view in data) {
//        if (self.minimumYValue > [view.dataObject.value floatValue]) {
//            self.minimumYValue = [view.dataObject.value floatValue];
//        }
//        if (self.maximumYValue < [view.dataObject.value floatValue]) {
//            self.maximumYValue = [view.dataObject.value floatValue];
//        }
//    }
//    // update data view
//    for (GraphDataView *view in data) {
//        [view updateGraphDate:nil];
//    }
}

#pragma mark Value to point convertion
-(Float32) pointYValueForDataObject:(WMChartDataObject *)data {
    return [self pointYValueForDataValue:[data.value floatValue]];
}

-(Float32) pointYValueForDataValue:(Float32)data {
    Float32 y = GRAPH_HEIGHT - BOTTOM_Y_OFFSET_FOR_GRAPH_POINTS -
    (data - _minimumYValue) * (GRAPH_HEIGHT - BOTTOM_Y_OFFSET_FOR_GRAPH_POINTS - TOP_Y_OFFSET_FOR_GRAPH_POINTS)/(_maximumYValue - _minimumYValue);
    
    return y;
}

#pragma mark Average

- (NSNumber *)averageObjectValueForKey:(NSString *)key inArray:(NSArray *)array{
    
    __block float sum = 0.;
    int count = [array count];
    
    if(count != 0){
        
        [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            
            sum += [[obj valueForKey: key] floatValue];
        }];
        
        float average = (float)sum / (float)count;
        
        return [NSNumber numberWithFloat: average];
    }
    
    return @0;
}

#pragma mark Size

- (CGRect)frameForCurrentZoomRate{
    _dayIntervalWidth = self.frame.size.width / (float)_zoomRate;
    float newGraphWidth = _dayIntervalWidth * numberOfDays;
    
    CGSize newSize = CGSizeMake(newGraphWidth, GRAPH_HEIGHT);
    CGRect frame = GRAPH_VISIBLE_FRAME;
    frame.size.width = (newSize.width <= GRAPH_FRAME_WIDTH) ? newSize.width : GRAPH_FRAME_WIDTH;
    frame.origin.x = 0.5*(GRAPH_FRAME_WIDTH - frame.size.width);
    return frame;
}

#pragma mark Number of days in width
- (NSInteger)daysIntervalBetweenGraphMark{
    return (int)(INTERVAL_BETWEEN_DRAWNING_DATE_POINT / _dayIntervalWidth + 0.5);
}

@end
