//
//  GraphDataObject.m
//  WMChart
//
//  Created by Antmanler on 7/12/13.
//  Copyright (c) 2013 iwishow. All rights reserved.
//

#import "WMChartDataObject.h"
#import "GraphConstants.h"

@implementation WMChartDataObject

#pragma mark Helpers

+ (NSInteger)randomBetweenFirst:(int)first andSecond:(int)second{
    
    return arc4random_uniform(second - first) + first;
}

+ (NSArray *)randomGraphDataObjectsArray:(NSInteger)count startDate:(NSDate *)startDate endDate:(NSDate *)endDate{
    
    NSInteger startUnixDate = [startDate timeIntervalSince1970];
    NSInteger endUnixDate = [endDate timeIntervalSince1970];
    
    NSMutableArray *array = [NSMutableArray array];
    
    for(int i = 0; i < count; i++){
        
        WMChartDataObject *object = [[WMChartDataObject alloc] init];
        object.time = [NSDate dateWithTimeIntervalSince1970: [WMChartDataObject randomBetweenFirst: startUnixDate andSecond: endUnixDate]];
        object.value = [NSNumber numberWithInt: [WMChartDataObject randomBetweenFirst:MINIMUM_GRAPH_Y_VALUE andSecond:MAXIMUM_GRAPH_Y_VALUE]];
        
        [array addObject: object];
    }
    
    return array;
}

+ (NSArray *)randomGraphDataObjectsArrayFromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate {
    
    NSInteger startUnixDate = [startDate timeIntervalSince1970];
    NSInteger endUnixDate = [endDate timeIntervalSince1970];
    NSInteger dayIntervals = (endUnixDate - startUnixDate)/NUMBER_OF_SECONDS_IN_DAY;
    
    NSMutableArray *array = [NSMutableArray array];
    
    WMChartDataObject *lastObj = nil;
    for(int i = 0; i <= dayIntervals; ++i) {
        WMChartDataObject *object = [[WMChartDataObject alloc] init];
        object.time = [NSDate dateWithTimeIntervalSince1970: startUnixDate + i*NUMBER_OF_SECONDS_IN_DAY];
        object.value = [NSNumber numberWithFloat: ([WMChartDataObject randomBetweenFirst:MINIMUM_GRAPH_Y_VALUE andSecond:MAXIMUM_GRAPH_Y_VALUE*100])/100.0f];
        object.prev  = lastObj;
        if (lastObj) {
            lastObj.next = object;
        }
        lastObj = object;
        
        [array addObject: object];
    }
    
    return array;
}

@end
