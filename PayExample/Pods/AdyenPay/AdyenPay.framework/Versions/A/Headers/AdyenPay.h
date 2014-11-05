//
//  AdyenKit.h
//  AdyenKit
//
//  Created by Taras Kalapun on 9/18/14.
//  Copyright (c) 2014 Adyen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PassKit/PassKit.h>

#import "ADYPaymentRequest.h"
#import "ADYABRecord.h"

#import "PKPayment+AdyenPay.h"

@interface AdyenPay : NSObject

+ (void)initializeWithOptions:(NSDictionary *)options;

+ (ADYPaymentRequest *)paymentRequest;
+ (NSArray *)summaryItemsForItems:(NSArray *)items shippingMethod:(PKShippingMethod *)shippingMethod withTotalLabel:(NSString *)totalLabel;

+ (UIViewController *)paymentViewControllerWithRequest:(ADYPaymentRequest *)request delegate:(id<PKPaymentAuthorizationViewControllerDelegate>)delegate;

+ (BOOL)loggingEnabled;


extern NSString *const ADYApplePayMerchantIdentifier;
extern NSString *const ADYEnableLog;

@end





