//
//  XZPerson.m
//  XZCustomKVO
//
//  Created by Alan on 4/29/20.
//  Copyright © 2020 zhaixingzhi. All rights reserved.
//

#import "XZPerson.h"
static XZPerson *_instance = nil;

@implementation XZPerson
+ (instancetype)shareInstance{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init] ;
    }) ;
    return _instance ;
}

+(id)allocWithZone:(struct _NSZone *)zone{
    return [XZPerson shareInstance] ;
}

-(id)copyWithZone:(struct _NSZone *)zone{
    return [XZPerson shareInstance] ;
}

- (void)setNickName:(NSString *)nickName{
    NSLog(@"来到 LGPerson 的setter方法 :%@",nickName);
    _nickName = nickName;
}

@end
