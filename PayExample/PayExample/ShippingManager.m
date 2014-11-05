//
//  PaymentManager.m
//  AdyenPay
//
//  Created by Taras Kalapun on 10/26/14.
//  Copyright (c) 2014 Taras Kalapun. All rights reserved.
//

#import "ShippingManager.h"


@implementation ShippingManager

+ (NSArray *)defaultShippingMethods {
    return [self localShippingMethods];
}

+ (PKShippingMethod *)defaultShippingMethod {
    return [self localShippingMethods][0];
}

+ (void)fetchShippingCostsForAddress:(ABRecordRef)address completion:(void (^)(NSArray *shippingMethods, NSError *error))completion
{
    
    ADYABRecord *record = [ADYABRecord recordFromABRecord:address];
    
    if (record.countryCode.length == 0) {
        completion(nil, [NSError new]);
    }
    if ([record.countryCode isEqualToString:@"US"]) {
        completion([self localShippingMethods], nil);
    } else {
        completion([self internationalShippingMethods], nil);
    }
}

+ (NSArray *)localShippingMethods {
    PKShippingMethod *normalItem = [PKShippingMethod summaryItemWithLabel:@"Local Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"0.00"]];
    normalItem.detail = @"3-5 Business Days";
    normalItem.identifier = @"local";
    
    PKShippingMethod *expressItem = [PKShippingMethod summaryItemWithLabel:@"Local Express Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"20.00"]];
    expressItem.detail = @"Next Day";
    expressItem.identifier = @"local_express";
    return @[normalItem, expressItem];
}

+ (NSArray *)internationalShippingMethods {
    PKShippingMethod *normalItem = [PKShippingMethod summaryItemWithLabel:@"International Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"20.00"]];
    normalItem.detail = @"3-5 Business Days";
    normalItem.identifier = @"international";
    
    PKShippingMethod *expressItem = [PKShippingMethod summaryItemWithLabel:@"International Express Shipping" amount:[NSDecimalNumber decimalNumberWithString:@"50.00"]];
    expressItem.detail = @"Next Day";
    expressItem.identifier = @"international_express";
    return @[normalItem, expressItem];
}

@end
