//
//  WTAlbumController+Category.h
//  WTPhotos
//
//  Created by weijiewen on 2020/12/12.
//

#import <objc/runtime.h>

#import <Photos/Photos.h>

#import <PhotosUI/PHPhotoLibrary+PhotosUISupport.h>

#import "WTAlbumController.h"

NS_ASSUME_NONNULL_BEGIN

@interface WTAssetImageCache : NSObject
@property (nonatomic, strong) NSMutableDictionary <NSString *, UIImage *> *caches;
+ (nullable UIImage *)getImageWithIdentifier:(NSString *)identifier size:(CGSize)size;
+ (void)setImage:(UIImage *)image identifier:(NSString *)identifier size:(CGSize)size;
+ (void)clearCache;
@end
@interface PHAssetCollection (WTAlbumCollection)
@property (nonatomic, strong) PHFetchResult <PHAsset *> *wt_assets;
- (void)wt_loadAssets;
+ (void)wt_photosAuthorization:(dispatch_block_t)noAuthorization
                    completion:(void(^)(BOOL isLimit))completion;
+ (void)wt_loadCollectionWithOptions:(nullable PHFetchOptions *)options
                     noAuthorization:(dispatch_block_t)noAuthorization
                              finish:(void(^)(NSArray <PHAssetCollection *> *collections, BOOL isLimit))finish;
@end
@interface PHAsset (WTAlbumAsset)
@property (nonatomic, copy, nullable) void(^wt_getData)(NSData *data, BOOL isGif);
@property (nonatomic, assign) BOOL isGif;
@property (nonatomic, strong, nullable) NSData *wt_assetData;
@property (nonatomic, assign) PHImageRequestID wt_imageRequestID;
- (PHImageRequestID)wt_imageWithSize:(CGSize)size
                  resultImageHandler:(nullable void(^)(UIImage *image))resultImageHandler;
- (void)wt_requestData;
- (void)wt_cancelRequestData;
- (void)wt_getData:(void(^)(NSData *data, BOOL isGif))getData;
@end
@interface UIImageView (WTAlbumAsset)
@property (nonatomic, copy) NSString *wt_assetLocalIdentifier;
@property (nonatomic, assign) PHImageRequestID wt_imageReusetID;
- (void)wt_imageAsset:(PHAsset *)asset;
@end
@interface WTAlbumAssetTableViewCell : UITableViewCell
@property (nonatomic, strong) UIImageView *thumbImageView;
@property (nonatomic, strong) UILabel *albumTitleLabel;
@property (nonatomic, strong) UIView *lineView;
+ (CGFloat)wtAlbumCellHeight;
+ (NSString *)wtAlbumCellIdentifier;
@end
@interface WTAlbumAssetCollectionCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *selectedButton;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, assign) BOOL canSelected;
+ (NSString *)wtAssetCellIdentifier;
@end

@interface WTAssetData ()
@property (nonatomic, strong) NSData *data;
@property (nonatomic, assign) WTAlbumAssetType assetType;
@end

NS_ASSUME_NONNULL_END
