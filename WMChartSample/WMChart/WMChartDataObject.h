//
//  GraphDataObject.h
//  WMChart
//
//  Created by Antmanler on 7/12/13.
//  Copyright (c) 2013 iwishow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WMChartDataObject : NSObject

@property (nonatomic, strong) NSDate *time;
@property (nonatomic, strong) NSNumber *value;
@property (nonatomic, weak)   WMChartDataObject *prev;
@property (nonatomic, weak)   WMChartDataObject *next;

+ (NSArray *)randomGraphDataObjectsArray:(NSInteger)count startDate:(NSDate *)startDate endDate:(NSDate *)endDate;

+ (NSArray *)randomGraphDataObjectsArrayFromStartDate:(NSDate *)startDate toEndDate:(NSDate *)endDate;

@end
