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

@interface WTViewController ()
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
        NSInteger index = [self.imageViews indexOfObject:imageView];
        [WTImageBrowser showImageCount:self.datas.count browserIndex:index fromImageViews:self.imageViews setImage:^(UIImageView * _Nonnull imageView, NSInteger index) {
            imageView.image = self.imageViews[index].image;
        } longPress:nil];
    }
}

- (void)action_album {
    __weak typeof(self) weakSelf = self;
    WTAlbumController *controller = [[WTAlbumController alloc] initAlbumPickImageWithEditPath:^UIBezierPath * _Nonnull(CGRect editRect) {
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path addArcWithCenter:CGPointMake(editRect.size.width / 2, editRect.size.height / 2) radius:editRect.size.width / 2 startAngle:0 endAngle:M_PI * 2 clockwise:true];
        return path;
    } selectedImage:^(UIImage * _Nonnull editImage) {
        weakSelf.imageViews.firstObject.image = editImage;
    }];
//    WTAlbumController *controller = [[WTAlbumController alloc] initWithAlbumTypes:WTAlbumAssetImage maxSelectedCount:9 selectedDatas:^(NSArray<WTAssetData *> * _Nonnull datas) {
//        weakSelf.datas = datas;
//        for (NSInteger i = 0; i < weakSelf.imageViews.count; i ++) {
//            if (i < datas.count) {
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                    UIImage *image = [[UIImage alloc] initWithData:datas[i].assetData];
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        weakSelf.imageViews[i].image = image;
//                    });
//                });
//            }
//            else {
//                weakSelf.imageViews[i].image = nil;
//            }
//        }
//    }];
//    controller.imageAndViodeOnlyOne = false;
    [self presentViewController:controller animated:true completion:^{
            
    }];
}

@end
