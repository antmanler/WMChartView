//
//  WMViewController.m
//  WMChartSample
//
//  Created by Antmanler on 7/19/13.
//  Copyright (c) 2013 iwishow. All rights reserved.
//

#import "WMChartDataObject.h"
#import "WMChartView.h"
#import "WMViewController.h"

@interface WMViewController ()<WMChartViewDelegate>

@property(nonatomic, strong) WMChartView *chartView;

@end

@implementation WMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSDate *startDate = [NSDate dateWithTimeIntervalSinceNow:-900*NUMBER_OF_SECONDS_IN_DAY];
        NSDate *endDate = [NSDate dateWithTimeIntervalSinceNow: 0];
        
        NSArray *graphObjects = [NSArray arrayWithArray: [WMChartDataObject randomGraphDataObjectsArrayFromStartDate:startDate toEndDate:endDate]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if([graphObjects count] > 0){
                
                self.chartView = [[WMChartView alloc] initWithGraphDataObjectsArray:graphObjects startDate:startDate endDate:endDate delegate:self];
                
                [self.view insertSubview:self.chartView atIndex:0];
                [self.chartView reload];
            }
        });
    });

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark WMChartViewDelegate

- (void)graphScrollableView:(WMChartView *)view willUpdateFrame:(CGRect)newFrame{
    
    //    self.graphScrollView.contentSize = newFrame.size;
}

- (void)graphScrollableView:(WMChartView *)view didChangeZoomRate:(NSInteger)newZoomRate{
    
    //    self.zoomRateLabel.text = [NSString stringWithFormat:@"%d days", newZoomRate];
}

- (void)graphScrollableViewDidStartUpdateZoomRate:(WMChartView *)view{
    //
    //    [UIView animateWithDuration:.5f animations:^{
    //
    //        self.zoomRateLabel.alpha = 1.f;
    //    }];
}

- (void)graphScrollableViewDidEndUpdateZoomRate:(WMChartView *)view{
    
    //    [UIView animateWithDuration:.5f animations:^{
    //
    //        self.zoomRateLabel.alpha = 0.f;
    //    }];
}

- (void)graphScrollableViewDidEndRedraw:(WMChartView *)view{
    
    //    if(!self.isGraphViewInialized){
    //
    //        [self scrollToRecentObjects];
    //
    //        self.isGraphViewInialized = YES;
    //    }
    //
    //    if([self.delegate respondsToSelector:@selector(graphViewDidUpdate:)]){
    //
    //        [self.delegate graphViewDidUpdate: self];
    //    }
}

- (void)graphScrollableViewDidStartRedraw:(WMChartView *)view{
    
    //    if([self.delegate respondsToSelector:@selector(graphViewWillUpdate:)]){
    //        
    //        [self.delegate graphViewWillUpdate: self];
    //    }
}

@end
