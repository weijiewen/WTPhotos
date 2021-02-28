//
//  WTAlbumController+Configuration.h
//  WTPhotos
//
//  Created by weijiewen on 2020/12/13.
//

#import "WTAlbumController.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, WTAlbumConfigurationPickType) {
    WTAlbumConfigurationTypeImageAndVideo,
    WTAlbumConfigurationTypeOnlyImage,
    WTAlbumConfigurationTypeOnlyVideo,
    WTAlbumConfigurationTypeImageCountAndVideoCount,
    WTAlbumConfigurationTypeImageOrVideo,
};

@interface WTAlbumConfiguration ()
@property (nonatomic, assign) WTAlbumConfigurationPickType pickType;
@property (nonatomic, assign) NSUInteger allTypeMaxCount;
@property (nonatomic, assign) NSUInteger imageMaxCount;
@property (nonatomic, assign) NSUInteger videoMaxCount;
@property (nonatomic, copy, nullable) void(^selectedDatas)(NSArray <WTAssetData *> *datas);
@property (nonatomic, copy, nullable) CGRect(^editRect)(CGRect viewRect);
@property (nonatomic, copy, nullable) UIBezierPath *(^editPath)(CGSize editSize);
- (void)loadBlockSelectedDatas:(void(^)(NSArray <WTAssetData *> *datas))selectedDatas
                      editRect:(nullable CGRect(^)(CGRect viewRect))editRect
                      editPath:(nullable UIBezierPath *(^)(CGSize editSize))editPath;
- (void)clearBlack;
@end

@interface WTAlbumController (Configuration)
@property (nonatomic, strong) WTAlbumConfiguration *configuration;
@end


NS_ASSUME_NONNULL_END
