//
//  NSDate+Addition.m
//  WMChart
//
//  Created by Antmanler on 7/12/13.
//  Copyright (c) 2013 iwishow. All rights reserved.
//

#import "NSDate+Graph.h"

@implementation NSDate (Graph)

+ (NSInteger)daysBetweenDateOne:(NSDate *)dt1 dateTwo:(NSDate *)dt2{
    NSUInteger unitFlags = NSDayCalendarUnit;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:unitFlags fromDate:dt1 toDate:dt2 options:0];
    return [components day];
}

+ (NSInteger)daysBetweenUnixDateOne:(NSTimeInterval)unixDate1 unixDateTwo:(NSTimeInterval)unixDate2{
    
    NSUInteger unitFlags = NSDayCalendarUnit;
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *components = [calendar components:unitFlags fromDate:[NSDate dateWithTimeIntervalSince1970:unixDate1] toDate:[NSDate dateWithTimeIntervalSince1970:unixDate2] options:0];
    return [components day]+1;
}

- (NSDate *)dateWithDaysAhead:(NSInteger)days{
    
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = days;
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate *newDate = [theCalendar dateByAddingComponents:dayComponent toDate:self options:0];
    
    return newDate;
}

- (NSDate *)nextDay{
    
    return [self dateWithDaysAhead:1];
}

- (NSDate *)previousDay{
    
    return [self dateWithDaysAhead:-1];
}

- (NSInteger)dayNumber{
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:self];
    
    return [components day];
}

- (NSInteger)monthNumber {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:kCFCalendarUnitMonth fromDate:self];
    
    return [components month];
}

- (NSString *)monthShortStringDescription{
    
//    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    
//    [formatter setDateFormat:@"MMM"];
//    
//    return [formatter stringFromDate: self];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MM/yyyy";
    
    NSTimeZone *gmt = [NSTimeZone localTimeZone];
    [dateFormatter setTimeZone:gmt];
    return [dateFormatter stringFromDate:self];
}

- (NSString *)weekStringDescription{
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:@"EEE"];
    
    return [formatter stringFromDate: self];
}

- (NSDate *)midnightTime{
    
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *todayComponents =
    [gregorian components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSHourCalendarUnit) fromDate:self];
    //[todayComponents setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [todayComponents setHour:0];
    [todayComponents setMinute:0];
    [todayComponents setSecond:0];
    
    return [gregorian dateFromComponents:todayComponents];
}

- (NSInteger)midnightUnixTime{
    
    return [[self midnightTime] timeIntervalSince1970];
}

- (NSDate*)localDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm";
    
    NSTimeZone *gmt = [NSTimeZone localTimeZone];
    [dateFormatter setTimeZone:gmt];
    NSString *timeStamp = [dateFormatter stringFromDate:self];
    
    return [dateFormatter dateFromString: timeStamp];
    
    //NSTimeZone *tz = [NSTimeZone localTimeZone];
    //NSInteger seconds = [tz secondsFromGMTForDate: self];
    //return [NSDate dateWithTimeInterval: seconds sinceDate: self];
}

- (NSDate*)globalDate{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm";
    
    NSTimeZone *gmt = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    [dateFormatter setTimeZone:gmt];
    NSString *timeStamp = [dateFormatter stringFromDate:self];
    
    return [dateFormatter dateFromString: timeStamp];
    
    //NSTimeZone *tz = [NSTimeZone timeZoneWithName:@"GMT"];
    //NSInteger seconds = [tz secondsFromGMTForDate: self];
    //return [NSDate dateWithTimeInterval: seconds sinceDate: self];
}

@end
