//
//  WTAlbumController.m
//  WTPhotos_Example
//
//  Created by weijiewen on 2020/11/10.
//  Copyright © 2020 txywjw@icloud.com. All rights reserved.
//


#import "WTAlbumController.h"

#import "WTAlbumController+Category.h"

#import "WTAlbumController+Configuration.h"

#import "WTAlbumController+Collection.h"

#import "WTAlbumController+Asset.h"

#pragma mark --------------------------------- 导航控制器 Interface ---------------------------------

@class WTAlbumViewController;
@interface WTAlbumController () <WTAlbumControllerDelegate>
@end

@implementation WTAlbumController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (instancetype)initAlbumPickHeaderWithSelectedImage:(void (^)(UIImage * _Nonnull))selectedImage {
    return [self initAlbumPickImageWithEditRect:^CGRect(CGRect viewRect) {
        return CGRectMake(0, CGRectGetHeight(viewRect) / 2 - CGRectGetWidth(viewRect) / 2, CGRectGetWidth(viewRect), CGRectGetWidth(viewRect));
    } editPath:^UIBezierPath * _Nonnull(CGSize editSize) {
        return [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, editSize.width, editSize.height)];
    } selectedImage:selectedImage];
}

- (instancetype)initAlbumPickImageWithEditRect:(nullable CGRect(^)(CGRect viewRect))editRect
                                      editPath:(nullable UIBezierPath *(^)(CGSize editSize))editPath
                                 selectedImage:(void(^)(UIImage *editImage))selectedImage {
    WTAlbumConfiguration *configuration = [[WTAlbumConfiguration alloc] initWithImageMaxCount:1];
    [configuration loadBlockSelectedDatas:^(NSArray<WTAssetData *> * _Nonnull datas) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [[UIImage alloc] initWithData:datas.firstObject.data];
            dispatch_async(dispatch_get_main_queue(), ^{
                !selectedImage ?: selectedImage(image);
            });
        });
    } editRect:editRect editPath:editPath];
    self.configuration = configuration;
    WTAlbumAssetsController *assetController = [[WTAlbumAssetsController alloc] initConfiguration:configuration];
    WTAlbumViewController *controller = [[WTAlbumViewController alloc] initWithConfiguration:configuration assetController:assetController];
    assetController.albumDelegate = self;
    controller.albumDelegate = self;
    self = [super initWithRootViewController:controller];
    if (self) {
        self.navigationBar.tintColor = UIColor.whiteColor;
        self.navigationBar.barStyle = UIBarStyleBlack;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self.navigationBar.barTintColor = UIColor.blackColor;
        [self pushViewController:assetController animated:false];
    }
    return self;
}

- (instancetype)initWithConfiguration:(WTAlbumConfiguration *)configuration
                        selectedDatas:(void(^)(NSArray <WTAssetData *> *datas))selectedDatas {
    [configuration loadBlockSelectedDatas:selectedDatas editRect:nil editPath:nil];
    WTAlbumAssetsController *assetController = [[WTAlbumAssetsController alloc] initConfiguration:configuration];
    WTAlbumViewController *controller = [[WTAlbumViewController alloc] initWithConfiguration:configuration assetController:assetController];
    assetController.albumDelegate = self;
    controller.albumDelegate = self;
    self = [super initWithRootViewController:controller];
    if (self) {
        self.configuration = configuration;
        self.navigationBar.tintColor = UIColor.whiteColor;
        self.navigationBar.barStyle = UIBarStyleBlack;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self.navigationBar.barTintColor = UIColor.blackColor;
        [self pushViewController:assetController animated:false];
    }
    return self;
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [super dismissViewControllerAnimated:flag completion:completion];
    [self.configuration clearBlack];
}

- (NSString *)albumWillShowText:(WTAlbumText)text {
    if ([self.albumDelegate respondsToSelector:@selector(albumWillShowText:)]) {
        return [self.albumDelegate albumWillShowText:text];
    }
    return text;
}

@end


