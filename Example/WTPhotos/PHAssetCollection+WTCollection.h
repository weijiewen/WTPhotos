//
//  PHCollection+WTCollection.h
//  WTPhotos_Example
//
//  Created by weijiewen on 2020/9/26.
//  Copyright © 2020 txywjw@icloud.com. All rights reserved.
//

#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface PHAssetCollection (WTCollection)

@property (nonatomic, strong) PHFetchResult <PHAsset *> *wt_assets;

- (void)wt_loadAssets;

@end

NS_ASSUME_NONNULL_END
