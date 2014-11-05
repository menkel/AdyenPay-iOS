//
//  PKPayment+AdyenPay.h
//  Pods
//
//  Created by Taras Kalapun on 10/27/14.
//
//

#import <PassKit/PassKit.h>

@interface PKPayment (AdyenPay)

- (NSDictionary *)ady_toDictionary;

@end
