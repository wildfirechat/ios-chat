//
//  ImagePreviewViewController.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/9/8.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "WFCUImagePreviewViewController.h"
#import "SDWebImage.h"

@interface WFCUImagePreviewViewController ()
@property (nonatomic, strong)UIScrollView *scrollView;
@property (nonatomic, strong)UIImageView *imageView;
@end

@implementation WFCUImagePreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_scrollView];
    
    
    _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _thumbnail.size.width, _thumbnail.size.height)];
    
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [_scrollView addSubview:_imageView];
    
    __weak typeof(self) weakSelf = self;
    if ([_imageUrl rangeOfString:@"http"].location == 0 || [_imageUrl rangeOfString:@"ftp"].location == 0) {
        [_imageView sd_setImageWithURL:[NSURL URLWithString:[_imageUrl stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] placeholderImage:_thumbnail completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.3 animations:^{
                    weakSelf.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
                    weakSelf.scrollView.contentSize = weakSelf.imageView.image.size;
                }];
            });
        }];
    } else {
        _imageView.image = _thumbnail;
        weakSelf.imageView.frame = CGRectMake(0, 0, _imageView.image.size.width, _imageView.image.size.height);
        weakSelf.scrollView.contentSize = weakSelf.imageView.image.size;
        dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
            UIImage *image = [UIImage imageWithContentsOfFile:weakSelf.imageUrl];
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.3 animations:^{
                    weakSelf.imageView.image = image;
                    weakSelf.imageView.frame = CGRectMake(0, 0, weakSelf.imageView.image.size.width, weakSelf.imageView.image.size.height);
                    weakSelf.scrollView.contentSize = weakSelf.imageView.image.size;
                }];
            });
        });
    }

    
    

    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClose:)];
    tap.numberOfTapsRequired = 1;
    
    UITapGestureRecognizer *tap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resize:)];
    tap2.numberOfTapsRequired = 2;
    
    [tap requireGestureRecognizerToFail:tap2];
    
    [self.imageView addGestureRecognizer:tap2];
    [self.imageView addGestureRecognizer:tap];
    self.imageView.userInteractionEnabled = YES;
}

- (void)resize:(id)sender {
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        if(weakSelf.scrollView.contentSize.width == weakSelf.view.bounds.size.width) {
            weakSelf.scrollView.contentSize = weakSelf.imageView.image.size;
            weakSelf.scrollView.contentInset = UIEdgeInsetsMake(20, 20, 20, 20);
            weakSelf.imageView.frame = CGRectMake(0, 0, weakSelf.imageView.image.size.width, weakSelf.imageView.image.size.height);
        } else {
            weakSelf.scrollView.contentSize = weakSelf.view.bounds.size;
            CGRect frame = weakSelf.scrollView.frame;
            weakSelf.imageView.frame = frame;
            weakSelf.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        }
    }];
}

- (void)onClose:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
