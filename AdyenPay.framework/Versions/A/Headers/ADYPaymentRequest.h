//
//  ADYPaymentRequest.h
//  Pods
//
//  Created by Taras Kalapun on 10/29/14.
//
//

#import <PassKit/PassKit.h>

@interface ADYPaymentRequest : PKPaymentRequest

@property (nonatomic, strong) NSString *merchantReference;
@property (nonatomic, assign) BOOL testingMode;


- (PKPaymentRequest *)pkPaymentRequest;

@end
