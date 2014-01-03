//
//  ViewController.h
//  HostingContentItem
//
//  Created by Tomonori Ohba on 2013/11/04.
//  Copyright (c) 2013年 Purchase and Advertising. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface ViewController : UIViewController
<SKProductsRequestDelegate>
{
    SKProductsRequest *myProductRequest; // プロダクト情報リクエスト用
    SKProduct *myProduct;                // 取得したプロダクト情報
}

@property (weak, nonatomic) IBOutlet UILabel *productTitle;
@property (weak, nonatomic) IBOutlet UILabel *productPrice;
@property (weak, nonatomic) IBOutlet UILabel *productDescription;
@property (weak, nonatomic) IBOutlet UIImageView *mapImage;
@property (weak, nonatomic) IBOutlet UIButton *purchaseButton;
@property (weak, nonatomic) IBOutlet UIButton *restoreButton;
@property (weak, nonatomic) IBOutlet UIView *indicator;

- (IBAction)purchaseButtonOnTouch:(id)sender;
- (IBAction)restoreButtonOnTouch:(id)sender;
@end
