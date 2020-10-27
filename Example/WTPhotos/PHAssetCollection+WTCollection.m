//
//  PHCollection+WTCollection.m
//  WTPhotos_Example
//
//  Created by weijiewen on 2020/9/26.
//  Copyright © 2020 txywjw@icloud.com. All rights reserved.
//

#import <objc/runtime.h>

#import "PHAssetCollection+WTCollection.h"

@implementation PHAssetCollection (WTCollection)

- (void)setWt_assets:(PHFetchResult<PHAsset *> *)assets {
    objc_setAssociatedObject(self, @selector(wt_assets), assets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (PHFetchResult<PHAsset *> *)wt_assets {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)wt_loadAssets {
    self.wt_assets = [PHAsset fetchAssetsInAssetCollection:self options:nil];
}

+ (void)wt_loadCollectionWithNoAuthorization:(dispatch_block_t)noAuthorization finish:(void(^)(NSArray <PHAssetCollection *> *))finish {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status) {
        case PHAuthorizationStatusNotDetermined: {
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                [self wt_loadCollectionWithNoAuthorization:noAuthorization finish:finish];
            }];
        }
            break;
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted: {
            !noAuthorization ?: noAuthorization();
        }
            break;
        case PHAuthorizationStatusAuthorized: {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSMutableArray *collections = [NSMutableArray array];
                PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
                PHAssetCollection *cameraAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].firstObject;
                [cameraAlbum wt_loadAssets];
                if (cameraAlbum.wt_assets.count > 0) {
                    [collections addObject:cameraAlbum];
                }
                for (NSInteger i = 0; i < collectionResult.count; i++) {
                    PHAssetCollection *collection = collectionResult[i];
                    if (![collection.localIdentifier isEqualToString:cameraAlbum.localIdentifier]) {
                        [collection wt_loadAssets];
                        if (collection.wt_assets.count > 0) {
                            [collections addObject:collection];
                        }
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    !finish ?: finish(collections);
                });
            });
        }
            break;
        default:
            break;
    }

}

@end
