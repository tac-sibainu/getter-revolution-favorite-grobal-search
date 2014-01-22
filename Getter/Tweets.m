//
//  Tweets.m
//  Getter
//
//  Created by 大嶺 卓矢 on 2013/12/16.
//  Copyright (c) 2013年 大坪裕樹. All rights reserved.
//

#import "Tweets.h"

@implementation Candy
@synthesize category;
@synthesize name;

+ (id)candyOfCategory:(NSString *)category name:(NSString *)name
{
    Candy *newCandy = [[self alloc] init];
    [newCandy setCategory:category];
    [newCandy setName:name];
    return newCandy;
}

@end