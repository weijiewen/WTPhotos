//
//  WTAlbumController+Collection.h
//  WTPhotos
//
//  Created by weijiewen on 2020/12/13.
//

#import <WTAlbumController.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark --------------------------------- 相册列表 Interface ---------------------------------

@class WTAlbumAssetsController;
@interface WTAlbumViewController : UIViewController
@property (nonatomic, weak) id <WTAlbumControllerDelegate> albumDelegate;
- (instancetype)initWithConfiguration:(WTAlbumConfiguration *)configuration
                      assetController:(WTAlbumAssetsController *)controller;
@end


NS_ASSUME_NONNULL_END
