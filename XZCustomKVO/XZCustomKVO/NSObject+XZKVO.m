//
//  NSObject+XZKVO.m
//  XZCustomKVO
//
//  Created by Alan on 4/29/20.
//  Copyright © 2020 zhaixingzhi. All rights reserved.
//

#import "NSObject+XZKVO.h"
#import <objc/message.h>

static NSString *const kXZKVOPrefix = @"XZKVONotifying_";
static NSString *const kXZKVOAssiociateKey = @"kXZKVO_AssiociateKey";

@implementation NSObject (XZKVO)
- (void)xz_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
    // 指回给父类
    Class superClass = [self class];
    object_setClass(self, superClass);
}


- (void)xz_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context{

    // 1: 验证setter
    [self judgeSetterMethodFromKeyPath:keyPath];
    // 2: 动态生成子类
    Class newClass = [self createChildClassWithKeyPath:keyPath];
    // 3: isa 指向 isa_swizzling
    object_setClass(self, newClass);
    //4.保存观察者
    objc_setAssociatedObject(self, (__bridge const void * _Nonnull)(kXZKVOAssiociateKey), observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - 验证是否存在setter方法
- (void)judgeSetterMethodFromKeyPath:(NSString *)keyPath{
    Class superClass    = object_getClass(self);
    SEL setterSeletor   = NSSelectorFromString(setterForGetter(keyPath));
    Method setterMethod = class_getInstanceMethod(superClass, setterSeletor);
    if (!setterMethod) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"哥们没有当前 %@ 的setter",keyPath] userInfo:nil];
    }
}

#pragma mark -
- (Class)createChildClassWithKeyPath:(NSString *)keyPath{
    
    // 2.1 判断是否有了
    NSString *oldClassName = NSStringFromClass([self class]);
    NSString *newClassName = [NSString stringWithFormat:@"%@%@",kXZKVOPrefix,oldClassName];// XZKVONotifying_XZPerson
    Class newClass = NSClassFromString(newClassName);
    if (newClass) {
        return newClass;
    }
    /**
     * 如果内存不存在,创建生成
     * 参数一: 父类
     * 参数二: 新类的名字
     * 参数三: 新类的开辟的额外空间
     */

    // 2.1 申请类
    newClass = objc_allocateClassPair([self class], newClassName.UTF8String, 0);
    // 2.2 注册类
    objc_registerClassPair(newClass);
    // 2.3.1 添加class方法
    SEL classSEL = NSSelectorFromString(@"class");
    Method classMethod = class_getClassMethod([self class], @selector(class));
    const char *classType = method_getTypeEncoding(classMethod);
    class_addMethod(newClass, classSEL, (IMP)xz_class, classType);
    // 2.3.2 添加setter方法 setNickname
    //获取setNickName方法编号
    SEL setterSEL = NSSelectorFromString(setterForGetter(keyPath));
    Method setterMethod = class_getClassMethod([self class], setterSEL);
    //获取方法签名
    const char *setterType = method_getTypeEncoding(setterMethod);
    //添加setter方法，imp为xz_setter方法
    class_addMethod(newClass, setterSEL, (IMP)xz_setter, setterType);
    
    return newClass;
}

static void xz_setter(id self,SEL _cmd,id newValue){
    NSLog(@"来了:%@",newValue);
    
   //4：消息转发： 转发给父类
    //改变父类的值---可以强制类型转换
    void (*xz_msgSendSuper)(void *,SEL , id) = (void *)objc_msgSendSuper;
    /**
     newvalue 这里修改了子类的的值，父类值是没有改变的
     使用 objc_msgSendSuper给父类的setter方法发送消息修改值
    */
    // 回调给外界
    
    struct objc_super superStruct = {
        .receiver       = self,
        .super_class    = [self class]
    };
    //4.1转发给父类
    xz_msgSendSuper(&superStruct,_cmd,newValue);
    
    //4.2 获取观察者观察者
    id observer = objc_getAssociatedObject(self, (__bridge const void * _Nonnull)(kXZKVOAssiociateKey));
    //4.3消息发送观察者
    SEL observerSel = @selector(observeValueForKeyPath:ofObject:change:context:);
    NSString *keyPath = getterForSetter(NSStringFromSelector(_cmd));
    objc_msgSend(observer,observerSel,keyPath,self,@{keyPath:newValue},NULL);
}
//因为系统KVO中调用class时返回的是XZPerson类所以这里也返回父类指针节点
Class xz_class(id self,SEL _cmd){
    //这里返回父类的isa
    return class_getSuperclass(object_getClass(self));
}

#pragma mark - 从get方法获取set方法的名称 key ===>>> setKey:
static NSString *setterForGetter(NSString *getter){
    
    if (getter.length <= 0) { return nil;}
    //首字母大写获取出来
    NSString *firstString = [[getter substringToIndex:1] uppercaseString];
    //属性首字母后面字符串
    NSString *leaveString = [getter substringFromIndex:1];
    //转换为setNickName
    return [NSString stringWithFormat:@"set%@%@:",firstString,leaveString];
}

#pragma mark - 从set方法获取getter方法的名称 set<Key>:===> key
static NSString *getterForSetter(NSString *setter){
    
    if (setter.length <= 0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) { return nil;
        
    }
    //setter 值为setNickName
    NSRange range = NSMakeRange(3, setter.length-4);
    //去掉set和属性首字母
    NSString *getter = [setter substringWithRange:range];
    //首字母需要小写
    NSString *firstString = [[getter substringToIndex:1] lowercaseString];
    //转换为nickname
    return  [getter stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:firstString];
}

@end
