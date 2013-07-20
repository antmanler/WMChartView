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
#define VISIBLE_CIRCLE_WITHD  (32)
#define GRAPH_POINT_SIZE      CGSizeMake(70, 70)
#define GRAPH_VISIBLE_FRAME   CGRectMake(0, 75, 320, GRAPH_HEIGHT)

#define INTERVAL_BETWEEN_DRAWNING_DATE_POINT (40)

#define TOP_Y_OFFSET_FOR_GRAPH_POINTS (35)
#define BOTTOM_Y_OFFSET_FOR_GRAPH_POINTS (GRAPH_HEIGHT - GRAPH_DATA_HEIGHT + 18)

#define MONTH_LABEL_YOFFSET (15)
#define MONTH_LABEL_SIZE CGSizeMake(90, 40)

#define DEF_VIEW_FRAME_HEIGHT  (400)
#define DEF_VIEW_FRAME CGRectMake(0, 0, 320, 400)

#pragma mark - GraphDataView
@interface GraphDataView : UIView {
    UIColor             *lineColor;
    UIColor             *gradientColor;
    UIColor             *todayHighlightColor;
    UILabel             *valueLabel;
    UILabel             *dayLabel;
    UILabel             *monthLabel;
    Float32             barY;
    BOOL                isToday;
    
    NSMutableArray      *dataPos;
    __weak WMChartView  *controller;
}

@property (nonatomic, strong) WMChartDataObject *dataObject;

-(void) updateGraphDate:(WMChartDataObject*)data;

@end


@interface WMChartView() <UIGestureRecognizerDelegate, EasyTableViewDelegate> {
    NSTimeInterval  startUNIXDate;
    NSTimeInterval  endUNIXDate;
    NSDate          *startDate;
    NSDate          *endDate;
    NSInteger       numberOfDays;
    
    NSInteger       newZoomRate;
    Float32         maximumZoomRate;
    Float32         minimumZoomRate;
    
    EasyTableView   *graphTableView;
    UILabel         *leftMouthLabel;
    UILabel         *rightMouthLabel;
}

@property (nonatomic, strong)            NSArray    *objectsArray;
@property (nonatomic, unsafe_unretained) Float32    dayIntervalWidth;
@property (nonatomic, unsafe_unretained) Float32    minimumYValue;
@property (nonatomic, unsafe_unretained) Float32    maximumYValue;

@property (nonatomic, weak)              id<WMChartViewDelegate>    delegate;

-(Float32) pointYValueForDataObject:(WMChartDataObject *)data;
-(Float32) pointYValueForDataValue:(Float32)data;

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
        
        // data label
        dayLabel = [self createLegendLabelWithFrame:CGRectMake(0, GRAPH_DATA_HEIGHT + 6, frame.size.width, 14)
                                            andFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:15.0f]];
        [dayLabel setTextColor:[UIColor wmGraphTextColor]];
        [self addSubview:dayLabel];
        
        // month label
        monthLabel = [self createLegendLabelWithFrame:CGRectMake(0, dayLabel.frame.origin.y + dayLabel.frame.size.height, frame.size.width, 16)
                                              andFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:14.0f]];
        [self addSubview:monthLabel];
        
        //value label
        valueLabel = [self createLegendLabelWithFrame:CGRectMake(0, 0, frame.size.width, 19)
                                              andFont:[UIFont fontWithName:@"HelveticaNeue-UltraLightItalic" size:12.0f]];
        [valueLabel setCenter:CGPointMake((valueLabel.frame.size.width)/2.f,  (valueLabel.frame.size.height)/2.f)];
        [self addSubview:valueLabel];
        
        
        [self updateGraphDate:data];
        
    }
    return self;
}

- (UILabel*) createLegendLabelWithFrame:(CGRect) frame andFont:(UIFont*)font{
    
    UILabel *lbl = [[UILabel alloc]initWithFrame:frame];
    [lbl setFont:font];
    [lbl setTextColor:[UIColor wmGraphTextColor]];
    [lbl setAdjustsFontSizeToFitWidth:YES];
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
    [lbl setLineBreakMode:UILineBreakModeMiddleTruncation];
    [lbl setMinimumFontSize:8];
    [lbl setTextAlignment:UITextAlignmentCenter];
#else
    lbl.lineBreakMode = NSLineBreakByTruncatingTail;
    lbl.minimumScaleFactor = 8.f/font.pointSize;
    lbl.textAlignment = NSTextAlignmentCenter;
#endif
    [lbl setShadowOffset:CGSizeMake(0, 0.1f)];
    [lbl setBackgroundColor:[UIColor clearColor]];
    
    return lbl;
}

- (void)updateGraphDate:(WMChartDataObject *)data {
    
    if (data) {
        self.dataObject = data;
        // day label
        NSDate *localDateForDayNumber = [_dataObject.time localDate];
        NSInteger day = [localDateForDayNumber dayNumber];
        dayLabel.text = [NSString stringWithFormat: @"%@%d", (day < 10) ? @"0" : @"", day];
        // month label
        monthLabel.text = [[localDateForDayNumber weekStringDescription] uppercaseString];
        isToday = [NSDate daysBetweenDateOne:data.time dateTwo:[NSDate dateWithTimeIntervalSinceNow:0]] == 0;
        
        CGRect newFrame = valueLabel.frame;
        barY = [controller pointYValueForDataObject:_dataObject];
        newFrame.origin.y = barY - newFrame.size.height;
        valueLabel.frame = newFrame;
        [valueLabel setText: [NSString stringWithFormat:@"%.1f%%", [data.value floatValue] ] ];
        
        [self setNeedsDisplay];
        
    }
    
    //TODO: consider the average value
}

- (void)drawRect:(CGRect)rect {
    if (!_dataObject) {
        return;
    }
    
//    CGContextRef context = UIGraphicsGetCurrentContext();
    Float32 frameWidth = controller.dayIntervalWidth;
    
    CGRect rectangle = CGRectMake(frameWidth*0.05, barY, frameWidth*0.9, GRAPH_DATA_HEIGHT + 13 - barY);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rectangle
                                               byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight cornerRadii:CGSizeMake(5.f, 5.f)];
    
    [gradientColor setFill];
    [path fill];
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
    
    CGRect defFrame = CGRectMake(0, 0.5*([UIScreen mainScreen].bounds.size.height - DEF_VIEW_FRAME_HEIGHT), 320.f, DEF_VIEW_FRAME_HEIGHT);
    if(self = [super initWithFrame: defFrame]){
        
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
        rightMouthLabel = [self makeMonthLabel];
        leftMouthLabel  = [self makeMonthLabel];
        
        UIPinchGestureRecognizer *pinchRecogniser = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(userDidUsePinchGesture:)];        
        [self addGestureRecognizer:pinchRecogniser];
    }
    
    return self;

}

- (void)dealloc{
    
    self.delegate = nil;
}

#pragma mark makeMonthLabel

- (UILabel*) makeMonthLabel {
    
    UILabel *label  = [[UILabel alloc] init];
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
    label.textAlignment = UITextAlignmentCenter;
#else
    label.textAlignment	= NSTextAlignmentCenter;
#endif
    CGSize labelSize = MONTH_LABEL_SIZE;
    label.frame = CGRectMake((self.frame.size.width-labelSize.width)/2, MONTH_LABEL_YOFFSET, labelSize.width, labelSize.height);
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24];
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
	graphTableView.cellBackgroundColor          = [UIColor clearColor];
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
    
    if (dataCnt > minimumZoomRate * interval) {
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
    _dayIntervalWidth = self.frame.size.width / ((float)_zoomRate + .2f);
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
