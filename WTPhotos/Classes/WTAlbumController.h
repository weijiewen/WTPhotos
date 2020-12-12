//
//  WTAlbumController.h
//  WTPhotos_Example
//
//  Created by weijiewen on 2020/11/10.
//  Copyright © 2020 txywjw@icloud.com. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WTAlbumAssetType) {
    WTAlbumAssetImage = 1 << 0,
//    WTAlbumAssetVideo = 1 << 1,
};

@interface WTAssetData : NSObject
@property (nonatomic, strong, readonly) NSData *assetData;
@property (nonatomic, assign, readonly) WTAlbumAssetType assetType;
@end

@interface WTAlbumController : UINavigationController

/// 默认true
@property (nonatomic, assign) BOOL imageAndViodeOnlyOne;

- (instancetype)initAlbumPickImageWithEditPath:(nullable UIBezierPath *(^)(CGRect editRect))editPath
                                 selectedImage:(void(^)(UIImage *editImage))selectedImage;

- (instancetype)initWithAlbumTypes:(WTAlbumAssetType)types
                  maxSelectedCount:(NSUInteger)maxSelectedCount
                     selectedDatas:(void(^)(NSArray <WTAssetData *> *datas))selectedDatas;
@end

NS_ASSUME_NONNULL_END
