//
//  UIImageView+WTAsset.m
//  WTPhotos_Example
//
//  Created by weijiewen on 2020/9/26.
//  Copyright © 2020 txywjw@icloud.com. All rights reserved.
//

#import <objc/runtime.h>

#import "UIImageView+WTAsset.h"

#import "PHAsset+WTAsset.h"

@interface UIImageView (WTAssetProperty)
@property (nonatomic, copy) NSString *wt_assetLocalIdentifier;
@property (nonatomic, assign) PHImageRequestID wt_imageReusetID;
@end
@implementation UIImageView (WTAssetProperty)

- (void)setWt_assetLocalIdentifier:(NSString *)wt_assetLocalIdentifier {
    objc_setAssociatedObject(self, @selector(wt_assetLocalIdentifier), wt_assetLocalIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)wt_assetLocalIdentifier {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setWt_imageReusetID:(PHImageRequestID)wt_imageReusetID {
    objc_setAssociatedObject(self, @selector(wt_imageReusetID), @(wt_imageReusetID), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (PHImageRequestID)wt_imageReusetID {
    return [objc_getAssociatedObject(self, _cmd) intValue];
}

@end


@implementation UIImageView (WTAsset)

- (void)wt_imageAsset:(PHAsset *)asset {
    __weak typeof(self) weak_self = self;
    [self wt_imageAsset:asset resultHandler:^(UIImage *image, BOOL isiCloud) {
        weak_self.image = image;
    }];
}

- (void)wt_imageAsset:(PHAsset *)asset resultHandler:(nullable void(^)(UIImage *image,
                                                                       BOOL isiCloud))resultHandler {
    if (self.wt_assetLocalIdentifier.length && [self.wt_assetLocalIdentifier isEqualToString:asset.localIdentifier]) {
        return;
    }
    self.image = nil;
    if (self.wt_imageReusetID > 0) {
        [PHAsset wt_cancelImageRequestWithID:self.wt_imageReusetID];
        self.wt_imageReusetID = 0;
    }
    self.wt_assetLocalIdentifier = asset.localIdentifier;
    __weak typeof(self) weak_self = self;
    self.image = nil;
    self.wt_imageReusetID = [asset wt_imageWithSize:CGSizeMake(self.bounds.size.width * 2, self.bounds.size.height * 2) resultHandler:^(UIImage * _Nonnull image, BOOL isiCloud) {
        !resultHandler ?: resultHandler(image, isiCloud);
        weak_self.wt_imageReusetID = 0;
    }];
}

@end
