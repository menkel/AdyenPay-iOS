//
//  ApplePayViewController.m
//  Wallet
//
//  Created by Taras Kalapun on 9/25/14.
//  Copyright (c) 2014 Adyen. All rights reserved.
//

#import "PayViewController.h"
#import "AdyenPay.h"
#import <PassKit/PassKit.h>
#import "ShippingManager.h"

@interface PayViewController ()<PKPaymentAuthorizationViewControllerDelegate>
@property (nonatomic, strong) NSDecimalNumber *totalAmount;
@property (nonatomic, strong) PKPaymentRequest *paymentRequest;

@end


@implementation PayViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSLog(@"App: Configuring AdyenPay lib");
    [AdyenPay initializeWithOptions:@{
                                      ADYApplePayMerchantIdentifier: @"merchant.com.adyen",
                                      ADYEnableLog: @(YES)
                                      }];
    
    
    self.title = @"AdyenPay";
    [self createForm];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Pay" style:UIBarButtonItemStylePlain target:self action:@selector(startPayment)];
    
    self.tableView.tableFooterView = [self tableFooterView];
    
}

- (UIView *)tableFooterView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 64)];

    CGFloat x = (self.view.bounds.size.width - 140)/2;
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(x, 20, 140, 44)];
    UIImage *payImg = [UIImage imageNamed:@"ApplePayBTN_44pt__black_logo_"];
    [btn setBackgroundImage:payImg forState:UIControlStateNormal];
    
    [btn addTarget:self action:@selector(startPayment) forControlEvents:UIControlEventTouchUpInside];
    [v addSubview:btn];
    return v;
}


- (void)createForm {
    TKForm *form = self.form;
    TKFormSection *section;
    TKFormRow *row;
    
    
    NSString *ref = [NSString stringWithFormat:@"TMRef%.0f", [NSDate timeIntervalSinceReferenceDate]];
    
    section = [form addSectionWithTitle:@"Payment"];
    [section addRow:[TKFormRow inputWithTag:@"merchantIdentifier" type:TKFormRowInputTypeText title:@"Merchant ID" value:@"merchant.com.adyen"]];
    [section addRow:[TKFormRow inputWithTag:@"countryCode" type:TKFormRowInputTypeText title:@"Country" value:@"US"]];
    [section addRow:[TKFormRow inputWithTag:@"currencyCode" type:TKFormRowInputTypeText title:@"Currency" value:@"USD"]];
    [section addRow:[TKFormRow inputWithTag:@"reference" type:TKFormRowInputTypeText title:@"Reference" value:ref]];
    [section addRow:[TKFormRow switchWithTag:@"shipping" title:@"Shipping" value:YES]];
    
    section = [form addSectionWithTitle:@"Payment items"];
    [section addRow:[TKFormRow inputWithTag:@"p_item_1" type:TKFormRowInputTypeText title:@"Goods" value:@"10.1"]];
    [section addRow:[TKFormRow inputWithTag:@"p_item_2" type:TKFormRowInputTypeText title:@"Tax" value:@"5.0"]];
    
}

- (IBAction)startPayment {
    
    [self.view resignFirstResponder];
    
    NSLog(@"App: Starting payment");
    
    self.paymentRequest = nil;
    
    NSDictionary *d = self.formValues;
    BOOL doShipping = [d[@"shipping"] boolValue];
    

    NSLog(@"App: Getting payment request");
    ADYPaymentRequest *request = [AdyenPay paymentRequest];
    
    NSLog(@"App: Preparing order lines");
    PKShippingMethod *shippingMethod = (doShipping) ? [ShippingManager defaultShippingMethod] : nil;
    NSArray *summaryItems = [self summaryItemsForShippingMethod:shippingMethod];
    
    NSLog(@"App: Customizing ADYPaymentRequest");
    
    request.paymentSummaryItems = summaryItems;
    request.countryCode = d[@"countryCode"];
    request.currencyCode = d[@"currencyCode"];
    
    request.merchantReference = d[@"reference"];
    
    
    if (doShipping) request.requiredShippingAddressFields = PKAddressFieldAll;
    
    NSLog(@"App: Saving paymentRequest to keep track");
    self.paymentRequest = request;
    
    NSLog(@"App: finished customizing ADYPaymentRequest");
    NSLog(@"App: Getting Payment ViewController for paymentRequest");
    
    UIViewController *vc = [AdyenPay paymentViewControllerWithRequest:request delegate:self];
    
    if (!vc) {
        [[[UIAlertView alloc] initWithTitle:@"" message:@"Cannot start payments" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        return;
    }
    
    NSLog(@"App: presenting Payment ViewControler");
    [self presentViewController:vc animated:YES completion:nil];
}

- (NSDictionary *)combinedDictionaryForPayment:(PKPayment *)payment {
    NSLog(@"App: Gathering data from PKPayment, paymentRequest and totalAmount");

    PKPaymentRequest *request = self.paymentRequest;
    NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:payment.ady_toDictionary];
    
    NSDecimalNumber *amount = self.totalAmount;
    if (amount) d[@"amount"] = amount.stringValue;
    
    d[@"currencyCode"] = request.currencyCode;
    d[@"countryCode"]  = request.countryCode;
    d[@"merchantIdentifier"] = request.merchantIdentifier;
    
    if ([request isKindOfClass:[ADYPaymentRequest class]]) {
        d[@"merchantReference"] = [(ADYPaymentRequest *)request merchantReference];
    }
    
    if (request.applicationData) d[@"applicationData"] = [request.applicationData base64EncodedStringWithOptions:0];
    
    return d;
}

- (void)sendPaymentToMerchant:(PKPayment *)payment completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    
    NSLog(@"App: Preparing to send payment to merchant backend");
    
    NSDictionary *paymentDict = [self combinedDictionaryForPayment:payment];
    if (!paymentDict[@"paymentData"]) {
        completion(PKPaymentAuthorizationStatusFailure);
        return;
    }
    
    NSLog(@"App: Creating the JSON object to send to Merchant backend");
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:paymentDict options:NSJSONWritingPrettyPrinted error:nil];
    
    NSMutableURLRequest *request =
    [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://madyen.mrt.io/payments"]
                            cachePolicy:NSURLRequestReloadIgnoringCacheData
                        timeoutInterval:30.0];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request setHTTPBody:jsonData];
    
    NSLog(@"App: Sending the JSON object to Merchant backend");
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSString *x = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSLog(@"App: Received from Merchant backend: %@", x);
        NSLog(@"App: Sending callback with status Success");
        completion(PKPaymentAuthorizationStatusSuccess);
    }];
}


- (void)handlePaymentAuthorizationWithPayment:(PKPayment *)payment completion:(void (^)(PKPaymentAuthorizationStatus))completion {
    [self sendPaymentToMerchant:payment completion:completion];
}

#pragma mark - PKPaymentAuthorizationViewControllerDelegate

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus status))completion
{
    NSLog(@"App: User agreed paying");
    NSLog(@"App: paymentAuthorizationViewController: didAuthorizePayment: completion");
    [self handlePaymentAuthorizationWithPayment:payment completion:completion];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                  didSelectShippingAddress:(ABRecordRef)address
                                completion:(void (^)(PKPaymentAuthorizationStatus status, NSArray *shippingMethods, NSArray *summaryItems))completion {
    NSLog(@"App: OPTIONAL User selected shipping address");
    NSLog(@"App: paymentAuthorizationViewController: didSelectShippingAddress: completion");
    
    NSLog(@"App: Fetching shipping methods for selected shipping address");
    [ShippingManager fetchShippingCostsForAddress:address completion:^(NSArray *shippingMethods, NSError *error) {
       if (error) {
           completion(PKPaymentAuthorizationStatusFailure, nil, nil);
           return;
       }
       NSArray *summaryItems = [self summaryItemsForShippingMethod:shippingMethods.firstObject];
       completion(PKPaymentAuthorizationStatusSuccess, shippingMethods, summaryItems);
    }];
}

- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController *)controller
                   didSelectShippingMethod:(PKShippingMethod *)shippingMethod
                                completion:(void (^)(PKPaymentAuthorizationStatus, NSArray *summaryItems))completion {
    NSLog(@"App: OPTIONAL User selected shipping method");
    NSLog(@"App: paymentAuthorizationViewController: didSelectShippingMethod: completion");
    NSArray *summaryItems = [self summaryItemsForShippingMethod:shippingMethod];
    completion(PKPaymentAuthorizationStatusSuccess, summaryItems);
}

- (void)paymentAuthorizationViewControllerDidFinish:(PKPaymentAuthorizationViewController *)controller
{
    NSLog(@"App: paymentAuthorizationViewControllerDidFinish");
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Helpers

- (NSArray *)summaryItemsForShippingMethod:(PKShippingMethod *)shippingMethod {
    NSLog(@"App: Calculating summaryItems");
    NSArray *summaryItems =  [AdyenPay summaryItemsForItems:[self paymentItems]
                           shippingMethod:shippingMethod
                           withTotalLabel:@"Adyen"];
    
    self.totalAmount = [(PKPaymentSummaryItem *)summaryItems.lastObject amount];
    NSLog(@"App: Saving totalAmount: %@ %@", self.paymentRequest.currencyCode, self.totalAmount.stringValue);
    
    return summaryItems;
}

- (NSArray *)paymentItems {
    NSDictionary *d = self.formValues;

    NSString *s = nil;
    NSString *t = nil;
    NSDecimalNumber *amount = nil;
    
    t = @"Goods";
    s = d[@"p_item_1"];
    s = [s stringByReplacingOccurrencesOfString:@" " withString:@""];
    s = [s stringByReplacingOccurrencesOfString:@"," withString:@"."];
    s = [s stringByReplacingOccurrencesOfString:@"$" withString:@""];
    if (s.length == 0) s = @"0";
    amount = [NSDecimalNumber decimalNumberWithString:s];
    PKPaymentSummaryItem *item1 = [PKPaymentSummaryItem summaryItemWithLabel:t amount:amount];
    
    t = @"Tax";
    s = d[@"p_item_2"];
    s = [s stringByReplacingOccurrencesOfString:@" " withString:@""];
    s = [s stringByReplacingOccurrencesOfString:@"," withString:@"."];
    s = [s stringByReplacingOccurrencesOfString:@"$" withString:@""];
    if (s.length == 0) s = @"0";
    amount = [NSDecimalNumber decimalNumberWithString:s];
    PKPaymentSummaryItem *item2 = [PKPaymentSummaryItem summaryItemWithLabel:t amount:amount];
    
    return @[item1, item2];
}


@end
