//
//  PHAsset+WTAsset.h
//  WTPhotos_Example
//
//  Created by weijiewen on 2020/9/25.
//  Copyright © 2020 txywjw@icloud.com. All rights reserved.
//

#import <Photos/PHAsset.h>
#import <Photos/PHImageManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHAsset (WTAsset)

- (PHImageRequestID)wt_imageWithSize:(CGSize)size
                  resultImageHandler:(nullable void(^)(UIImage *image))resultImageHandler;

- (PHImageRequestID)wt_imageWithSize:(CGSize)size
                       resultHandler:(nullable void(^)(UIImage *image,
                                                       BOOL isiCloud))resultHandler;

+ (void)wt_cancelImageRequestWithID:(PHImageRequestID)imageRequestID;

@end

NS_ASSUME_NONNULL_END
