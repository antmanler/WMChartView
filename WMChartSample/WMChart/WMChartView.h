//
//  GraphScrollableArea.h
//  WMChart
//
//  Created by Antmanler on 7/12/13.
//  Copyright (c) 2013 iwishow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GraphConstants.h"

@class WMChartView;

@protocol WMChartViewDelegate <NSObject>

@optional
- (void)graphScrollableView:(WMChartView *)view didChangeZoomRate:(NSInteger)newZoomRate;
- (void)graphScrollableViewDidStartUpdateZoomRate:(WMChartView *)view;
- (void)graphScrollableViewDidEndUpdateZoomRate:(WMChartView *)view;
@end

@interface WMChartView : UIView

/*
  Graph zoom rate
  Calculated in days
  MIN 7 days
  MAX number of total days interval (days between endDate and startDate)
*/
@property (nonatomic, unsafe_unretained) NSInteger zoomRate;

- (id)initWithGraphDataObjectsArray:(NSArray *)objectsArray startDate:(NSDate *)startDate endDate:(NSDate *)endDate delegate:(id<WMChartViewDelegate>)theDelegate;

- (void)reload;

@end
