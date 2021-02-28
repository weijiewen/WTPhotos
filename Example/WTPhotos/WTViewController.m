//
//  WTViewController.m
//  WTPhotos
//
//  Created by txywjw@icloud.com on 09/25/2020.
//  Copyright (c) 2020 txywjw@icloud.com. All rights reserved.
//

#import "WTViewController.h"

#import "WTAlbumController.h"

#import "WTImageBrowser.h"

@interface WTViewController () <WTAlbumControllerDelegate>
@property (nonatomic, copy) NSArray <UIImageView *> *imageViews;
@property (nonatomic, strong) NSArray <WTAssetData *> *datas;
@end

@implementation WTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.redColor;
    NSMutableArray <UIImageView *> *imageViews = [NSMutableArray array];
    CGFloat imageWidth = (self.view.bounds.size.width - 20 - 15) / 3;
    for (NSInteger i = 0; i < 9; i ++) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10 + i % 3 * (imageWidth + 5), 70 + i / 3 * (imageWidth + 5), imageWidth, imageWidth)];
        imageView.backgroundColor = UIColor.lightGrayColor;
        imageView.clipsToBounds = true;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.userInteractionEnabled = true;
        [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(action_imageTap:)]];
        [imageViews addObject:imageView];
        [self.view addSubview:imageView];
    }
    self.imageViews = imageViews.copy;
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(self.view.bounds.size.width / 2 - 40, CGRectGetMaxY(imageViews.lastObject.frame) + 20, 80, 50);
    button.backgroundColor = UIColor.blueColor;
    [button addTarget:self action:@selector(action_album) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)action_imageTap:(UITapGestureRecognizer *)sender {
    UIImageView *imageView = (UIImageView *)sender.view;
    if (imageView.image) {
        UIImage *image = imageView.image;
        [WTImageBrowser animationOpenImageCount:1 browserIndex:0 fromImageViews:@[imageView] setImage:^(UIImageView * _Nonnull imageView, NSInteger index) {
            imageView.image = image;
        } longPress:nil];
    }
}

- (void)action_album {
    __weak typeof(self) weakSelf = self;
    WTAlbumConfiguration *configuration = [[WTAlbumConfiguration alloc] initWithImageMaxCount:3 videoMaxCount:1];
    WTAlbumController *controller = [[WTAlbumController alloc] initWithConfiguration:configuration selectedDatas:^(NSArray<WTAssetData *> * _Nonnull datas) {
        weakSelf.datas = datas;
        for (NSInteger i = 0; i < weakSelf.imageViews.count; i ++) {
            if (i < datas.count) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    UIImage *image = [[UIImage alloc] initWithData:datas[i].data];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakSelf.imageViews[i].image = image;
                    });
                });
            }
            else {
                weakSelf.imageViews[i].image = nil;
            }
        }

    }];
    
//    WTAlbumController *controller = [[WTAlbumController alloc] initAlbumPickHeaderWithSelectedImage:^(UIImage * _Nonnull editImage) {
//        self.imageViews.firstObject.image = editImage;
//    }];
    
    
    controller.albumDelegate = self;
    [self presentViewController:controller animated:true completion:^{

    }];
}

@end
