//
//  PHAsset+WTAsset.m
//  WTPhotos_Example
//
//  Created by weijiewen on 2020/9/25.
//  Copyright © 2020 txywjw@icloud.com. All rights reserved.
//

#import "PHAsset+WTAsset.h"

@implementation PHAsset (WTAsset)

- (PHImageRequestID)wt_imageWithSize:(CGSize)size
                  resultImageHandler:(nullable void(^)(UIImage *image))resultImageHandler {
    return [self wt_imageWithSize:size resultHandler:^(UIImage *image, BOOL isiCloud) {
        !resultImageHandler ?: resultImageHandler(image);
    }];
}

- (PHImageRequestID)wt_imageWithSize:(CGSize)size
                       resultHandler:(nullable void(^)(UIImage *image,
                                                       BOOL isiCloud))resultHandler {
    
    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[self.localIdentifier] options:nil].firstObject;
    BOOL isOriginal = CGSizeEqualToSize(size, CGSizeZero);
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.version = PHImageRequestOptionsVersionCurrent;
    options.deliveryMode = isOriginal ? PHImageRequestOptionsDeliveryModeHighQualityFormat : PHImageRequestOptionsDeliveryModeFastFormat;
    options.resizeMode = isOriginal ? PHImageRequestOptionsResizeModeNone : PHImageRequestOptionsResizeModeFast;
    options.networkAccessAllowed = YES;
    return [PHImageManager.defaultManager requestImageForAsset:asset targetSize:CGSizeMake(size.width * 2, size.height * 2) contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        !resultHandler ?: resultHandler(result, info[PHImageResultIsInCloudKey] != nil);
    }];
}

+ (void)wt_cancelImageRequestWithID:(PHImageRequestID)imageRequestID {
    if (imageRequestID > 0) {
        [[PHImageManager defaultManager] cancelImageRequest:imageRequestID];
    }
}


@end
