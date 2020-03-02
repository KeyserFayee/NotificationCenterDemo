//
//  KSNotificationCenter.m
//  YBNotificationDemo
//
//  Created by keyser_soz on 2020/1/18.
//  Copyright © 2020 杨波. All rights reserved.
//

#import "KSNotificationCenter.h"

@interface KSNotification ()

@property (copy) NSString *name;
@property (copy) NSDictionary *userInfo;
@property (strong) id object;

@end

@implementation KSNotification

- (instancetype)initWithName:(NSString *)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo {
    if (self = [super init]) {
        _name = name;
        _userInfo = userInfo;
        _object = object;
    }
    return self;
}

@end

@interface KSObserverInfoModel : NSObject

@property (weak) id observer;
@property (assign) SEL selector;
@property (strong) NSString *observerId;
@property (strong) id observer_strong;
@property (copy) NSString *name;
@property (strong) id object;
@property (strong) NSOperationQueue *queue;
@property (copy) void(^block)(KSNotification *noti);
@end
@implementation KSObserverInfoModel

- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
}

@end

static NSString *const key_observersDic_noContent = @"key_observersDic_noContent";
@interface KSNotificationCenter ()

@property (strong) NSMutableDictionary *observersDic;

@end


@implementation KSNotificationCenter
static KSNotificationCenter *_defaultCenter = nil;

+ (KSNotificationCenter *)defaultCenter {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultCenter = [[self alloc] initSingleton];
    });
    return _defaultCenter;
}

- (instancetype)initSingleton
{
    if (self = [super init]) {
        _observersDic = [NSMutableDictionary dictionary];
    }
    return self;
}



- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSString *)aName object:(nullable id)anObject {
    if (!observer || !aSelector) {
        return;
    }
    KSObserverInfoModel *observerInfo = [KSObserverInfoModel new];
    observerInfo.observer = observer;
    observerInfo.selector = aSelector;
    observerInfo.name = aName;
    observerInfo.object = anObject;
    observerInfo.observerId = [NSString stringWithFormat:@"%@",observer];
    
    [self addObserverInfo:observerInfo];
}

- (id<NSObject>)addObserverForName:(NSString *)name object:(id)obj queue:(NSOperationQueue *)queue usingBlock:(void (^)(KSNotification * _Nonnull))block {
    if (!block) {
        return nil;
    }
    KSObserverInfoModel *observerInfo = [KSObserverInfoModel new];
    observerInfo.object = obj;
    observerInfo.name = name;
    observerInfo.queue = queue;
    observerInfo.block = block;
    NSObject *observer = [NSObject new];
    observerInfo.observer_strong = observer;
    observerInfo.observerId = [NSString stringWithFormat:@"%@", observer];
    
    [self addObserverInfo:observerInfo];
    return observer;
}


- (void)addObserverInfo:(KSObserverInfoModel *)observerInfo {
    NSMutableDictionary *observersDic = KSNotificationCenter.defaultCenter.observersDic;
    @synchronized(observersDic) {
        NSString *key = (observerInfo.name && [observerInfo.name isKindOfClass:NSString.class]) ? observerInfo.name : key_observersDic_noContent;
        if ([observersDic objectForKey:key]) {
            NSMutableArray *tempArr = [observersDic objectForKey:key];
            [tempArr addObject:observerInfo];
        } else {
            NSMutableArray *tempArr = [NSMutableArray array];
            [tempArr addObject:observerInfo];
            [observersDic setObject:tempArr forKey:key];
        }
    }
}

- (void)postNotificationName:(NSString *)aName object:(id)anObject {
    KSNotification *notification = [[KSNotification alloc] initWithName:aName object:anObject userInfo:nil];
    [self postNotification:notification];
}

- (void)postNotificationName:(NSString *)aName object:(nullable id)anObject userInfo:(nullable NSDictionary *)aUserInfo {
    KSNotification *notification = [[KSNotification alloc] initWithName:aName object:anObject userInfo:aUserInfo];
    [self postNotification:notification];
}

- (void)postNotification:(KSNotification *)notification {
    if (!notification) {
        return;
    }
    NSMutableDictionary *observersDic = KSNotificationCenter.defaultCenter.observersDic;
    @synchronized(observersDic) {
        NSMutableArray *tempArray = [observersDic objectForKey:notification.name];
        if (tempArray) {
            [tempArray enumerateObjectsUsingBlock:^(KSObserverInfoModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.block) {
                    if (obj.queue) {
                        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
                            obj.block(notification);
                        }];
                        NSOperationQueue *queue = obj.queue;
                        [queue addOperation:operation];
                    } else {
                        obj.block(notification);
                    }
                } else {
                    if (!obj.object || obj.object == notification.object) {
                        #pragma clang diagnostic push
                        #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        [obj.observer performSelector:obj.selector withObject:notification];
                        #pragma clang diagnostic pop
                    }
                }
            }];
        }
    }
}

- (void)removeObserver:(id)observer {
    [self removeObserver:observer name:nil object:nil];
}

- (void)removeObserver:(id)observer name:(nullable NSString *)aName object:(nullable id)anObject {
    if (!observer) {
        return;
    }
    [self removeObserverId:[NSString stringWithFormat:@"%@",observer] name:aName object:anObject];
}

- (void)removeObserverId:(NSString *)observerId name:(NSString *)aName object:(id)anObject {
    if (!observerId) {
        return;
    }
    NSMutableDictionary *observersDic = KSNotificationCenter.defaultCenter.observersDic;
    @synchronized (observersDic) {
        if (aName && [aName isKindOfClass:[NSString class]]) {
            NSMutableArray *tempArray = [KSNotificationCenter.defaultCenter.observersDic objectForKey:aName];
            [self arrayRemoveObserverId:observerId object:anObject array:tempArray];
        }else {
            [observersDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSMutableArray *obj, BOOL * _Nonnull stop) {
                [self arrayRemoveObserverId:observerId object:anObject array:obj];
            }];
        }
    }
}

- (void)arrayRemoveObserverId:(NSString *)observerId object:(id)anObject array:(NSMutableArray *)array {
    @autoreleasepool {
        [array.copy enumerateObjectsUsingBlock:^(KSObserverInfoModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.observerId isEqualToString:observerId] && (!anObject || anObject == obj.object)) {
                [array removeObject:obj];
            }
        }];
    }
}

@end
