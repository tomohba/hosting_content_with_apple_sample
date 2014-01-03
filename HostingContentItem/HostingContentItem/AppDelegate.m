//
//  AppDelegate.m
//  HostingContentItem
//
//  Created by Tomonori Ohba on 2013/11/04.
//  Copyright (c) 2013年 Purchase and Advertising. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // updatedTransactionsを受け取るための登録
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // updatedTransactionsを受け取るための登録
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // updatedTransactionsの解除
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

// StoreKit
// 購入、リストアなどのトランザクションの都度、通知される
- (void)   paymentQueue:(SKPaymentQueue *)queue
    updatedTransactions:(NSArray *)transactions {
    NSLog(@"paymentQueue:updatedTransactions");
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
                // 購入処理中
            case SKPaymentTransactionStatePurchasing:
            {
                NSLog(@"SKPaymentTransactionStatePurchasing");
                break;
            }
                
                // 購入処理完了
            case SKPaymentTransactionStatePurchased:
            {
                NSLog(@"SKPaymentTransactionStatePurchased");
                
                if (transaction.downloads) {
                    [queue startDownloads:transaction.downloads];
                }
                else {
                    // unlock features
                    [queue finishTransaction:transaction];
                }
                break;
            }
                
                // 購入処理エラー
                // ユーザが購入処理をキャンセルした場合も含む
            case SKPaymentTransactionStateFailed:
            {
                NSLog(@"SKPaymentTransactionStateFailed");
                [queue finishTransaction:transaction];
                
                // エラーメッセージを表示
                NSError *error = transaction.error;
                NSString *errormsg = [NSString stringWithFormat:@"%@ [%ld]", error.localizedDescription, (long)error.code];
                [[[UIAlertView alloc] initWithTitle:@"エラー"
                                            message:errormsg
                                           delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
                
                // エラーの詳細
                // 支払いがキャンセルされた
                if (transaction.error.code != SKErrorPaymentCancelled) {
                    NSLog(@"SKPaymentTransactionStateFailed - SKErrorPaymentCancelled");
                }
                // 請求先情報の入力画面に移り、購入処理が強制終了した
                else if (transaction.error.code == SKErrorUnknown) {
                    NSLog(@"SKPaymentTransactionStateFailed - SKErrorUnknown");
                }
                // その他エラー
                else {
                    NSLog(@"SKPaymentTransactionStateFailed - error.code:%ld",
                          (long)transaction.error.code);
                }
                
                // 購入処理エラーを通知する
                [[NSNotificationCenter defaultCenter] postNotificationName:@"Failed"
                                                                    object:transaction];
                
                break;
            }
                
                // リストア処理
            case SKPaymentTransactionStateRestored:
            {
                NSLog(@"SKPaymentTransactionStateRestored");
                if (transaction.downloads) {
                    [queue startDownloads:transaction.downloads];
                }
                else {
                    // unlock features
                    [queue finishTransaction:transaction];
                }
                break;
            }
                
            default:
                break;
        }
    }
}

// ダウンロード通知処理
- (void)paymentQueue:(SKPaymentQueue *)queue
    updatedDownloads:(NSArray *)downloads {
    for (SKDownload *download in downloads) {
        if (download.downloadState == SKDownloadStateFinished) {
            [self processDownload:download]; // ダウンロード処理
            //
            [queue finishTransaction:download.transaction];
        }
        else if (download.downloadState == SKDownloadStateActive) {
            NSTimeInterval remaining = download.timeRemaining; // secs
            float progress = download.progress; // 0.0 -> 1.0
            NSLog(@"%lf%% (残り %lf 秒)", progress, remaining);
        }
        else { // waiting, paused, failed, cancelled
            NSLog(@"ダウンロード一時停止またはキャンセルを検出: %ld", (long)download.downloadState);
        }
    }
}

- (void)processDownload:(SKDownload *)download {
    // NSFileManager
    NSString *path = [download.contentURL path];
    
    // コンテンツのディレクトリ
    path = [path stringByAppendingPathComponent:@"Contents"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *files = [fileManager contentsOfDirectoryAtPath:path error:&error];
    NSString *dir = [self downloadableContentPath];
    
    for (NSString *file in files) {
        NSString *fullPathSrc = [path stringByAppendingPathComponent:file];
        NSString *fullPathDst = [dir stringByAppendingPathComponent:file];
        
        // 上書きできないので一旦削除
        [fileManager removeItemAtPath:fullPathDst error:NULL];
        
        //
        if ([fileManager moveItemAtPath:fullPathSrc toPath:fullPathDst error:&error] == NO) {
            NSLog(@"Error: ファイルの移動に失敗: %@", error);
        }
        
        // 設定にプロダクトIDを保持
        [[NSUserDefaults standardUserDefaults] setObject:fullPathDst
                                                  forKey:download.transaction.payment.productIdentifier];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (NSString *)downloadableContentPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths objectAtIndex:0];
    directory = [directory stringByAppendingPathComponent:@"Downloads"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:directory] == NO) {
        NSError *error;
        if ([fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error] == NO) {
            NSLog(@"Error: ディレクトリ作成失敗: %@", error);
        }
        
        NSURL *url = [NSURL fileURLWithPath:directory];
        // iCloud backupからダウンロードしたコンテンツを排除しないと、リジェクト対象になるので注意
        if ([url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&error] == NO) {
            NSLog(@"Error: iCloud backup対象除外が失敗: %@", error);
        }
    }
    
    return directory;
}

// 購入処理の終了
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions {
    NSLog(@"paymentQueue:removedTransactions");
    
    // 購入処理が全て成功したことを通知する
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PurchaseCompleted"
                                                        object:transactions];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    // 全てのリストア処理が終了
    NSLog(@"paymentQueueRestoreCompletedTransactionsFinished");
    
    // 全てのリストア処理が終了したことを通知する
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RestoreCompleted"
                                                        object:queue];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    // リストアの失敗
    NSLog(@"restoreCompletedTransactionsFailedWithError %@ [%ld]", error.localizedDescription, (long)error.code);
    
    // リストアが失敗したことを通知する
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RestoreFailed"
                                                        object:error];
}

@end
