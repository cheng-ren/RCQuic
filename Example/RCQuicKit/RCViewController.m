//
//  RCViewController.m
//  RCQuicKit
//
//  Created by rencheng on 09/13/2024.
//  Copyright (c) 2024 rencheng. All rights reserved.
//

#import "RCViewController.h"
#import "RCQuicKit/RCQuic.h"
#import <Cronet/Cronet.h>

@interface RCViewController () <NSURLSessionDelegate>

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;

@property (assign, nonatomic) BOOL hasInitedCronet;

@end

@implementation RCViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    [RCQuic testHTTP3];
    

	// Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)segmentedControlChanged:(UISegmentedControl *)sender {
    NSLog(@"%@", [sender titleForSegmentAtIndex:sender.selectedSegmentIndex]);
    [self closeCronet];
    if (sender.selectedSegmentIndex == 1) {
        [self openCronet];
    }
    
}

- (IBAction)doRequest:(id)sender {
    // tquic
    if (self.segmentedControl.selectedSegmentIndex == 2) {
        return;
    }
    // 其他
    [self doRequestByCronet:self.segmentedControl.selectedSegmentIndex];
}

- (void)doRequestByCronet:(BOOL)byCronet {
    self.resultLabel.text = @"处理中";
    
    NSURLSessionConfiguration *config = NSURLSessionConfiguration.defaultSessionConfiguration;
    config.requestCachePolicy = NSURLRequestReloadIgnoringCacheData;
    if (@available(iOS 13.0, *)) {
        config.allowsExpensiveNetworkAccess = true;
    }
    config.allowsCellularAccess = true;
    if (byCronet) {
        [Cronet installIntoSessionConfiguration:config];
    }
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    


    NSURL *url = [NSURL URLWithString:@"https://cloudflare-quic.com"];
//       let url = URL(string: "https://litespeedtech.com")!
//        pgjones.dev
//        let url = URL(string: "https://quic.aiortc.org")!
//        aioquic
//        let url = URL(string: "https://pgjones.dev")!
//        let url = URL(string: "https://h2o.examp1e.net")!
//        let url = URL(string: "https://www.litespeedtech.com")!
//        let url = URL(string:"https://www.aliyun.com")!
//        let url = URL(string: "https://ccapi-h3.lbk.world")!
//        uuapi-h3.lbk.world
//        let url = URL(string: "https://uuapi-h3.lbk.world")!
//        let url = URL(string: "https://uuapi-h3.lbk.world/cfd/openApi/v1/pub/getTime")!
//        let url = URL(string: "https://ccapi-h3.lbk.world/cfd/openApi/v1/pub/getTime")!
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    
    [request setValue:@"URLSession" forHTTPHeaderField:@"User-Agent"];
    if (@available(iOS 14.5, *)) {
        if (byCronet) {
            request.assumesHTTP3Capable = false;
        } else {
            request.assumesHTTP3Capable = true;
        }
    }
    
//    print("task will start, url: \(url.absoluteString)")
    [[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *response1 = response;
        NSLog(@"%@", response1.allHeaderFields);
    }] resume];
    
}

- (void)openCronet {
    if (_hasInitedCronet) { return; }
    _hasInitedCronet = YES;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [Cronet setHttp2Enabled:true];
        [Cronet setQuicEnabled:false];
        [Cronet setBrotliEnabled:true];
        //        Cronet.setAcceptLanguages("en-US,en")
        //        Cronet.setUserAgent("CronetTest/1.0.0.0", partial: false)
        //        Cronet.addQuicHint("www.chromium.org", port: 443, altPort: 443)
        NSString *quicUrl = @"cloudflare-quic.com";
        [Cronet addQuicHint:quicUrl port:443 altPort:443];
        [Cronet setHttpCacheType:CRNHttpCacheTypeDisabled];
        [Cronet setMetricsEnabled:true];
        [Cronet setUserAgent:@"Cronet" partial:false];
    });
    [Cronet setRequestFilterBlock:^BOOL(NSURLRequest *request) {
        [(NSMutableURLRequest *)request setValue:@"Cronet" forHTTPHeaderField:@"User-Agent"];
        return false;
    }];
    
    [Cronet start];
    
    [Cronet registerHttpProtocolHandler];
//    let logFile = "cornetlog.log"
//    let result  = Cronet.startNetLog(toFile: logFile, logBytes: false)
//    let resultFile = Cronet.getNetLogPath(forFile: logFile)
//    //        (NSString*)getNetLogPathForFile:(NSString*)fileName
//    print("result:\(result),resultFile:\(resultFile!)")
    
}

- (void)closeCronet {
    if (!_hasInitedCronet) { return; }
    [Cronet setRequestFilterBlock:nil];
    [Cronet unregisterHttpProtocolHandler];
    _hasInitedCronet = false;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics {
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:2];
    for (NSURLSessionTaskTransactionMetrics *metric in metrics.transactionMetrics) {
        if (metric.resourceFetchType == NSURLSessionTaskMetricsResourceFetchTypeNetworkLoad) {
            if (metric.networkProtocolName != nil) {
                [ret addObject:metric.networkProtocolName];
            }
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.resultLabel.text = [NSString stringWithFormat:@"协议:%@", [ret componentsJoinedByString:@"-"]];
    });
    NSLog(@"UserAgent: %@", task.currentRequest.allHTTPHeaderFields[@"User-Agent"]);
    
    NSLog(@"protocols: %@", [ret componentsJoinedByString:@"-"]);
}

@end
