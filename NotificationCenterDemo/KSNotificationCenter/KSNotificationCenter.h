//
//  KSNotificationCenter.h
//  YBNotificationDemo
//
//  Created by keyser_soz on 2020/1/18.
//  Copyright © 2020 杨波. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KSNotification : NSObject

@property (readonly, copy) NSString *name;
@property (readonly, copy) NSDictionary *userInfo;
@property (readonly, strong) id object;

- (instancetype)initWithName:(NSString *)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo;

@end

@interface KSNotificationCenter : NSObject

+ (KSNotificationCenter *)defaultCenter;
//添加
- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSString *)aName object:(nullable id)anObject;
- (id<NSObject>)addObserverForName:(nullable NSString *)name object:(nullable id)obj queue:(nullable NSOperationQueue *)queue usingBlock:(void (^)(KSNotification *note))block;

//发送
- (void)postNotification:(KSNotification *)notification;
- (void)postNotificationName:(NSString *)aName object:(nullable id)anObject;
- (void)postNotificationName:(NSString *)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo;
//删除
- (void)removeObserver:(id)observer;
- (void)removeObserver:(id)observer name:(nullable NSString *)aName object:(nullable id)anObject;

@end

NS_ASSUME_NONNULL_END
