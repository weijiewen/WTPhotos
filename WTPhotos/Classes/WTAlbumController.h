//
//  WTAlbumController.h
//  WTPhotos_Example
//
//  Created by weijiewen on 2020/11/10.
//  Copyright © 2020 txywjw@icloud.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WTAlbumDelegate.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WTAlbumAssetType) {
    WTAlbumAssetImage,
    WTAlbumAssetGif,
    WTAlbumAssetVideo,
};

@interface WTAssetData : NSObject
@property (nonatomic, strong, readonly) NSData *data;
@property (nonatomic, assign, readonly) WTAlbumAssetType assetType;
@end

@interface WTAlbumConfiguration : NSObject

/// 图片和视频共用最大值
/// @param allTypeMaxCount 一共选择 allTypeMaxCount 张
- (instancetype)initWithAllTypeMaxCount:(NSUInteger)allTypeMaxCount;

/// 只选择图片
/// @param imageMaxCount 图片最多数量
- (instancetype)initWithImageMaxCount:(NSUInteger)imageMaxCount;

/// 只选择视频
/// @param videoMaxCount 视频最多数量
- (instancetype)initWithVideoMaxCount:(NSUInteger)videoMaxCount;

/// 图片和视频分开计数选择
/// @param imageMaxCount 图片最多数量
/// @param videoMaxCount 视频最多数量
- (instancetype)initWithImageMaxCount:(NSUInteger)imageMaxCount
                        videoMaxCount:(NSUInteger)videoMaxCount;

/// 图片或者视频二者选一
/// @param imageMaxCount 图片最多数量
/// @param videoMaxCount 视频最多数量
- (instancetype)initCountBetweenImageMaxCount:(NSUInteger)imageMaxCount
                                VideoMaxCount:(NSUInteger)videoMaxCount;
@end

@interface WTAlbumController : UINavigationController

@property (nonatomic, weak) id <WTAlbumControllerDelegate> albumDelegate;

/// 正方形编辑图片
/// @param selectedImage selectedImage description
- (instancetype)initAlbumPickHeaderWithSelectedImage:(void(^)(UIImage *editImage))selectedImage;;

/// 选择照片
/// @param editRect 定义编辑区域
/// @param editPath 定义裁剪形状，editSize 为 editRect 中返回的 size  ，传 nil 不编辑
/// @param selectedImage selectedImage description
- (instancetype)initAlbumPickImageWithEditRect:(nullable CGRect(^)(CGRect viewRect))editRect
                                      editPath:(nullable UIBezierPath *(^)(CGSize editSize))editPath
                                 selectedImage:(void(^)(UIImage *editImage))selectedImage;

- (instancetype)initWithConfiguration:(WTAlbumConfiguration *)configuration
                     selectedDatas:(void(^)(NSArray <WTAssetData *> *datas))selectedDatas;
@end

NS_ASSUME_NONNULL_END
