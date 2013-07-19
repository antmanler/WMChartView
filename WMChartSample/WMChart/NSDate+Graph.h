//
//  NSDate+Graph.h
//  WMChart
//
//  Created by Antmanler on 7/12/13.
//  Copyright (c) 2013 iwishow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Graph)

+ (NSInteger)daysBetweenDateOne:(NSDate *)dt1 dateTwo:(NSDate *)dt2;
+ (NSInteger)daysBetweenUnixDateOne:(NSTimeInterval)unixDate1 unixDateTwo:(NSTimeInterval)unixDate2;

- (NSDate *)nextDay;
- (NSDate *)previousDay;
- (NSDate *)dateWithDaysAhead:(NSInteger)days;

- (NSInteger)dayNumber;
- (NSInteger)monthNumber;
- (NSString *)monthShortStringDescription;
- (NSString *)weekStringDescription;

- (NSDate *)midnightTime;
- (NSInteger)midnightUnixTime;

- (NSDate *)localDate;
- (NSDate *)globalDate;

@end
