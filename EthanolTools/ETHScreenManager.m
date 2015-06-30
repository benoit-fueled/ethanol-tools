//
//  ETHScreenManager.m
//  Ethanol
//
//  Created by Stephane Copin on 1/12/15.
//  Copyright (c) 2015 Fueled. All rights reserved.
//

#import "ETHScreenManager.h"
#import <notify.h>
#import <UIKit/UIKit.h>

#define TIMEOUT_GUARD_INTERVAL 0.1f

NSString * ETHScreenDidTurnOffNotification = @"ETHScreenDidTurnOffNotification";
NSString * ETHScreenDidTurnOnNotification  = @"ETHScreenDidTurnOnNotification";

@interface ETHScreenManager (PrivateMethods)

@property (nonatomic, assign) ETHScreenStatus screenStatus;

- (void)fireDelegate;

@end

@interface ETHSingletonScreenManager : ETHScreenManager

@end

@implementation ETHSingletonScreenManager

- (id<ETHScreenManagerDelegate>)delegate {
  return nil;
}

- (void)setDelegate:(id<ETHScreenManagerDelegate>)delegate {
  
}

- (instancetype)initWithScreenStatus:(ETHScreenStatus)screenStatus delegate:(id<ETHScreenManagerDelegate>)delegate {
  self = [super initWithScreenStatus:ETHScreenStatusUnknown delegate:nil];
  if(self != nil) {

  }
  return self;
}

- (void)fireDelegate {
  switch (self.screenStatus) {
    case ETHScreenStatusOff:
      [[NSNotificationCenter defaultCenter] postNotificationName:ETHScreenDidTurnOffNotification object:self];
      break;
    case ETHScreenStatusOn:
      [[NSNotificationCenter defaultCenter] postNotificationName:ETHScreenDidTurnOnNotification object:self];
      break;
    default:
      break;
  }
}

@end

@interface ETHScreenManager () {
  int screenTurnedOffNotificationToken;
}

@property (nonatomic, assign) ETHScreenStatus screenStatus;

@end

@implementation ETHScreenManager

+ (instancetype)sharedManager {
  static ETHScreenManager * instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[ETHSingletonScreenManager alloc] init];
  });
  return instance;
}

- (instancetype)init {
  return [self initWithScreenStatus:ETHScreenStatusUnknown];
}

- (instancetype)initWithScreenStatus:(ETHScreenStatus)screenStatus {
  return [self initWithScreenStatus:screenStatus delegate:nil];
}

- (instancetype)initWithScreenStatus:(ETHScreenStatus)screenStatus delegate:(id<ETHScreenManagerDelegate>)delegate {
  self = [super init];
  if (self) {
    _screenStatus = screenStatus;
    _delegate = delegate;
    screenTurnedOffNotificationToken = NOTIFY_TOKEN_INVALID;
    
    if(screenStatus != ETHScreenStatusUnknown) {
      [self fireDelegate];
    }
  }
  return self;
}

- (void)startUpdatingScreenStatus {
  if(screenTurnedOffNotificationToken == NOTIFY_TOKEN_INVALID) {
    notify_register_dispatch("com.apple.springboard.hasBlankedScreen",
                             &screenTurnedOffNotificationToken,
                             dispatch_get_main_queue(), ^(int t) {
                               uint64_t state;
                               int result = notify_get_state(screenTurnedOffNotificationToken, &state);
                               if(result == NOTIFY_STATUS_OK) {
                                 self.screenStatus = state ? ETHScreenStatusOff : ETHScreenStatusOn;
                               }
                             });
  }
}

- (void)setScreenStatus:(ETHScreenStatus)screenStatus {
  ETHScreenStatus oldScreenStatus = _screenStatus;
  _screenStatus = screenStatus;
  if(oldScreenStatus != screenStatus) {
    [self fireDelegate];
  }
}

- (void)fireDelegate {
  switch (self.screenStatus) {
    case ETHScreenStatusOff:
      [self.delegate screenManagerDidScreenTurnOff:self];
      break;
    case ETHScreenStatusOn:
      [self.delegate screenManagerDidScreenTurnOn:self];
      break;
    default:
      break;
  }
}

- (void)stopUpdatingScreenStatus {
  if(screenTurnedOffNotificationToken != NOTIFY_TOKEN_INVALID) {
    notify_cancel(screenTurnedOffNotificationToken);
    screenTurnedOffNotificationToken = -1;
  }
}

+ (void)wakeUpScreen {
  [self wakeUpScreenWithMessage:@" "];
}

+ (void)wakeUpScreenWithMessage:(NSString *)message {
  [self wakeUpScreenWithMessage:message timeout:0.0];
}

+ (void)wakeUpScreenWithMessage:(NSString *)message timeout:(NSTimeInterval)timeout {
  if([ETHScreenManager sharedManager].screenStatus == ETHScreenStatusOff) {
    UILocalNotification *notice = [[UILocalNotification alloc] init];
    notice.alertBody = [NSString stringWithFormat:NSLocalizedString(message, @"")];
    notice.hasAction = NO;
    [[UIApplication sharedApplication] presentLocalNotificationNow:notice];
    if(timeout != HUGE_VALF) {
      if(timeout == 0.0f) {
        [[UIApplication sharedApplication] cancelLocalNotification:notice];
      } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
          [[UIApplication sharedApplication] cancelLocalNotification:notice];
        });
      }
      
      if(timeout < HUGE_VALF - TIMEOUT_GUARD_INTERVAL) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((timeout + TIMEOUT_GUARD_INTERVAL) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
          [[UIApplication sharedApplication] cancelLocalNotification:notice];
        });
      }
    }
  }
}

@end
