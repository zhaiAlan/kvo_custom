//
//  XZPerson.h
//  XZCustomKVO
//
//  Created by Alan on 4/29/20.
//  Copyright © 2020 zhaixingzhi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XZPerson : NSObject{
    @public
    NSString *name;
}
@property (nonatomic, copy) NSString *nickName;

+ (instancetype)shareInstance;


@end

NS_ASSUME_NONNULL_END
