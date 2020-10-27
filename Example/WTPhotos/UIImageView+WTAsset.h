//
//  UIImageView+WTAsset.h
//  WTPhotos_Example
//
//  Created by weijiewen on 2020/9/26.
//  Copyright © 2020 txywjw@icloud.com. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Photos/PHAsset.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (WTAsset)

- (void)wt_imageAsset:(PHAsset *)asset;

- (void)wt_imageAsset:(PHAsset *)asset resultHandler:(nullable void(^)(UIImage *image,
                                                                       BOOL isiCloud))resultHandler;

@end

NS_ASSUME_NONNULL_END
