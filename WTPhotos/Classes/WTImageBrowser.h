//
//  WTImageBrowser.h
//  WTPhotos_Example
//
//  Created by weijiewen on 2020/11/16.
//  Copyright © 2020 txywjw@icloud.com. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/**
 图片浏览器
 */
@interface WTImageBrowser : UIViewController

/**
 浏览图片
 
 @param imageCount 图片总数
 @param browserIndex 当前显示图片下标
 @param setImage （此处对imageView.image赋值 或 sd_setImage...）
 @param longPress 长按图片回调
 @return return value description
 */
- (instancetype)initWithImageCount:(NSInteger)imageCount
                      browserIndex:(NSInteger)browserIndex
                          setImage:(void(^)(UIImageView *imageView, NSInteger index))setImage
                         longPress:(nullable void(^)(NSInteger index, UIImage *image, WTImageBrowser *imageBrowser))longPress;

/// 动画开启浏览器
/// @param imageView imageView description
/// @param image image description
/// @param longPress longPress description
+ (void)animationOpenFromImageView:(UIImageView *)imageView
                             image:(void(^)(UIImageView *imageView, NSInteger index))image
                         longPress:(nullable void(^)(NSInteger index, UIImage *image, WTImageBrowser *imageBrowser))longPress;

/// 动画开启浏览器
/// @param imageCount imageCount description
/// @param browserIndex browserIndex description
/// @param fromImageViews fromImageView description
/// @param setImage setImage description
/// @param longPress longPress description
+ (void)animationOpenImageCount:(NSInteger)imageCount
                   browserIndex:(NSInteger)browserIndex
                 fromImageViews:(NSArray <UIView *> *)fromImageViews
                       setImage:(void(^)(UIImageView *imageView, NSInteger index))setImage
                      longPress:(nullable void(^)(NSInteger index, UIImage *image, WTImageBrowser *imageBrowser))longPress;

@end

NS_ASSUME_NONNULL_END
