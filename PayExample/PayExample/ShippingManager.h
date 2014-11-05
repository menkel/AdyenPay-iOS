//
//  PaymentManager.h
//  AdyenPay
//
//  Created by Taras Kalapun on 10/26/14.
//  Copyright (c) 2014 Taras Kalapun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PassKit/PassKit.h>
#import <AdyenPay/AdyenPay.h>

@interface ShippingManager : NSObject

+ (NSArray *)defaultShippingMethods;
+ (PKShippingMethod *)defaultShippingMethod;
+ (void)fetchShippingCostsForAddress:(ABRecordRef)address completion:(void (^)(NSArray *shippingMethods, NSError *error))completion;

@end
