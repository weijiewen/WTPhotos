//
//  WTAlbumController+Asset.h
//  WTPhotos
//
//  Created by weijiewen on 2020/12/13.
//

#import <WTAlbumController.h>

NS_ASSUME_NONNULL_BEGIN
@class PHAssetCollection;
@interface WTAlbumAssetsController : UIViewController
@property (nonatomic, weak) id <WTAlbumControllerDelegate> albumDelegate;
@property (nonatomic, weak) PHAssetCollection *collection;
- (instancetype)initConfiguration:(WTAlbumConfiguration *)configuration;
- (void)noAuthorizationHidden:(BOOL)hidden;
- (void)loadMorePhotosItemHidden:(BOOL)hidden;
@end

NS_ASSUME_NONNULL_END
