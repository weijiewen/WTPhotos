//
//  WTAlbumCropController.h
//  WTPhotos
//
//  Created by weijiewen on 2020/12/19.
//

#import <UIKit/UIKit.h>
#import "WTAlbumDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface WTAlbumCropController : UIViewController
@property (nonatomic, weak) id <WTAlbumControllerDelegate> albumDelegate;
- (instancetype)initImage:(UIImage *)image
                 editRect:(nullable CGRect(^)(CGRect viewRect))editRect
                 editPath:(nullable UIBezierPath *(^)(CGSize editSize))editPath
               completion:(void(^)(WTAlbumCropController *controller, UIImage *editImage))completion;
@end

NS_ASSUME_NONNULL_END
