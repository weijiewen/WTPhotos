//
//  WTAlbumController+Category.m
//  WTPhotos
//
//  Created by weijiewen on 2020/12/12.
//

#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "WTAlbumController+Category.h"


#pragma mark --------------------------------- WTAssetImageCache ---------------------------------

@implementation WTAssetImageCache
+ (instancetype)imageCache {
    static WTAssetImageCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[WTAssetImageCache alloc] init];
        cache.caches = [NSMutableDictionary dictionary];
        [NSNotificationCenter.defaultCenter addObserver:cache selector:@selector(action_momoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    });
    return cache;
}
+ (nullable UIImage *)getImageWithIdentifier:(NSString *)identifier size:(CGSize)size {
    return [WTAssetImageCache imageCache].caches[[NSString stringWithFormat:@"%@_%@", identifier, NSStringFromCGSize(size)]];
}
+ (void)setImage:(UIImage *)image identifier:(NSString *)identifier size:(CGSize)size {
    if (!image) {
        return;
    }
    [[WTAssetImageCache imageCache].caches setObject:image forKey:[NSString stringWithFormat:@"%@_%@", identifier, NSStringFromCGSize(size)]];
}
+ (void)clearCache {
    [WTAssetImageCache imageCache].caches = [NSMutableDictionary dictionary];
}
- (void)action_momoryWarning {
    [self.caches removeObjectsForKeys:[self.caches.allKeys subarrayWithRange:NSMakeRange(0, self.caches.allKeys.count / 2)]];
}
@end
#pragma mark --------------------------------- PHAssetCollection (WTAlbumCollection) ---------------------------------

@implementation PHAssetCollection (WTAlbumCollection)
- (void)setWt_assets:(PHFetchResult<PHAsset *> *)assets {
    objc_setAssociatedObject(self, @selector(wt_assets), assets, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (PHFetchResult<PHAsset *> *)wt_assets {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)wt_loadAssets {
    [self wt_loadAssetsWithOptions:nil];
}
- (void)wt_loadAssetsWithOptions:(nullable PHFetchOptions *)options {
    PHFetchResult <PHAsset *> *assets = [PHAsset fetchAssetsInAssetCollection:self options:options];
    self.wt_assets = assets;
}
+ (void)wt_loadCollectionWithOptions:(nullable PHFetchOptions *)options
                     noAuthorization:(dispatch_block_t)noAuthorization
                              finish:(void(^)(NSArray <PHAssetCollection *> *collections, BOOL isLimit))finish {
    [self wt_photosAuthorization:noAuthorization completion:^(BOOL isLimit) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *collections = [NSMutableArray array];
            PHFetchResult *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
            for (NSInteger i = 0; i < collectionResult.count; i++) {
                PHAssetCollection *collection = collectionResult[i];
                [collection wt_loadAssetsWithOptions:options];
                if (collection.wt_assets.count > 0) {
                    [collections addObject:collection];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                !finish ?: finish(collections, isLimit);
            });
        });
    }];
}
+ (void)wt_photosAuthorization:(dispatch_block_t)noAuthorization
                    completion:(void(^)(BOOL isLimit))completion
{
    void(^getStatus)(PHAuthorizationStatus status) = ^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusNotDetermined: {
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                    [self wt_photosAuthorization:noAuthorization completion:completion];
                }];
            }
                break;
            case PHAuthorizationStatusDenied:
            case PHAuthorizationStatusRestricted: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    !noAuthorization ?: noAuthorization();
                });
            }
                break;
            case PHAuthorizationStatusLimited:
            case PHAuthorizationStatusAuthorized: {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (@available(iOS 14, *)) {
                        !completion ?: completion(status == PHAuthorizationStatusLimited);
                    } else {
                        !completion ?: completion(false);
                    }
                });
            }
                break;
        }
    };
    if (@available(iOS 14.0, *)) {
        [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
            getStatus(status);
        }];
    }
    else {
        getStatus([PHPhotoLibrary authorizationStatus]);
    }

}
@end
#pragma mark --------------------------------- PHAsset (WTAlbumAsset) ---------------------------------

@implementation PHAsset (WTAlbumAsset)

- (void)setWt_getData:(void (^)(NSData *data, BOOL isGif))wt_getData {
    objc_setAssociatedObject(self, @selector(wt_getData), wt_getData, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (void (^)(NSData *data, BOOL isGif))wt_getData {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setWt_assetData:(NSData *)wt_assetData {
    objc_setAssociatedObject(self, @selector(wt_assetData), wt_assetData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSData *)wt_assetData {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setIsGif:(BOOL)isGif {
    objc_setAssociatedObject(self, @selector(isGif), @(isGif), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isGif {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}
- (void)setWt_imageRequestID:(PHImageRequestID)wt_imageRequestID {
    objc_setAssociatedObject(self, @selector(wt_imageRequestID), @(wt_imageRequestID), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (PHImageRequestID)wt_imageRequestID {
    return [objc_getAssociatedObject(self, _cmd) intValue];
}

- (PHImageRequestID)wt_imageWithSize:(CGSize)size
                  resultImageHandler:(nullable void(^)(UIImage *image))resultImageHandler {
    return [self wt_imageWithSize:size resultImageHandler:resultImageHandler gifResultHandler:nil];
}

- (PHImageRequestID)wt_imageWithSize:(CGSize)size
                  resultImageHandler:(nullable void(^)(UIImage *image))resultImageHandler
                    gifResultHandler:(nullable void(^)(NSData *imageData))gifResultHandler {
    return [self wt_imageWithSize:size resultHandler:^(UIImage *image, BOOL isiCloud) {
        !resultImageHandler ?: resultImageHandler(image);
    } gifResultHandler:^(NSData *imageData, BOOL isiCloud) {
        !gifResultHandler ?: gifResultHandler(imageData);
    }];
}
- (PHImageRequestID)wt_imageWithSize:(CGSize)size
                       resultHandler:(nullable void(^)(UIImage *image,
                                                       BOOL isiCloud))resultHandler
                    gifResultHandler:(nullable void(^)(NSData *imageData,
                                                       BOOL isiCloud))gifResultHandler {
    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[self.localIdentifier] options:nil].firstObject;
    BOOL isOriginal = CGSizeEqualToSize(size, CGSizeZero);
    CGSize targetSize = isOriginal ? PHImageManagerMaximumSize : CGSizeMake(size.width * 2, size.height * 2);
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.version = PHImageRequestOptionsVersionCurrent;
    options.deliveryMode = isOriginal ? PHImageRequestOptionsDeliveryModeHighQualityFormat : PHImageRequestOptionsDeliveryModeOpportunistic;
    options.resizeMode = isOriginal ? PHImageRequestOptionsResizeModeNone : PHImageRequestOptionsResizeModeExact;
    options.networkAccessAllowed = true;
    if (gifResultHandler && [[PHAssetResource assetResourcesForAsset:self].firstObject.originalFilename.pathExtension isEqualToString:@"gif"]) {
        if (self.wt_assetData) {
            !gifResultHandler ?: gifResultHandler(self.wt_assetData, NO);
            return 0;
        }
        return [PHImageManager.defaultManager requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            self.wt_assetData = imageData;
            !gifResultHandler ?: gifResultHandler(imageData, info[PHImageResultIsInCloudKey] != nil);
        }];
    }
    else {
        return [PHImageManager.defaultManager requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            !resultHandler ?: resultHandler(result, info[PHImageResultIsInCloudKey] != nil);
        }];
    }
}
- (void)wt_requestData {
    if (self.wt_assetData) {
        return;
    }
    if (self.mediaType == PHAssetMediaTypeVideo || self.mediaType == PHAssetMediaTypeAudio) {
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionCurrent;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
        
        PHImageManager *manager = [PHImageManager defaultManager];
        self.wt_imageRequestID = [manager requestAVAssetForVideo:self options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                AVURLAsset *urlAsset = (AVURLAsset *)asset;
                NSURL *url = urlAsset.URL;
                NSData *data = [NSData dataWithContentsOfURL:url];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.wt_assetData = data;
                    self.isGif = NO;
                    !self.wt_getData ?: self.wt_getData(self.wt_assetData, NO);
                    self.wt_getData = nil;
                });
            });
        }];
    }
    else {
        [self wt_imageWithSize:CGSizeZero resultImageHandler:^(UIImage *image) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *data = UIImagePNGRepresentation(image);
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.wt_assetData = data;
                    self.isGif = NO;
                    !self.wt_getData ?: self.wt_getData(self.wt_assetData, NO);
                    self.wt_getData = nil;
                });
            });
        } gifResultHandler:^(NSData *imageData) {
            self.isGif = YES;
            self.wt_assetData = imageData;
            !self.wt_getData ?: self.wt_getData(self.wt_assetData, NO);
            self.wt_getData = nil;
        }];
    }
}
- (void)wt_getData:(void(^)(NSData *data, BOOL isGif))getData {
    if (self.wt_assetData) {
        getData(self.wt_assetData, self.isGif);
    }
    else {
        self.wt_getData = getData;
    }
}
- (void)wt_cancelRequestData {
    [PHAsset wt_cancelImageRequestWithID:self.wt_imageRequestID];
    self.wt_imageRequestID = 0;
    self.wt_assetData = nil;
    self.wt_getData = nil;
}
+ (void)wt_cancelImageRequestWithID:(PHImageRequestID)imageRequestID {
    if (imageRequestID > 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[PHImageManager defaultManager] cancelImageRequest:imageRequestID];
        });
    }
}

@end
#pragma mark --------------------------------- UIImageView (WTAlbumAsset) ---------------------------------

@implementation UIImageView (WTAlbumAsset)
- (void)setWt_assetLocalIdentifier:(NSString *)wt_assetLocalIdentifier {
    objc_setAssociatedObject(self, @selector(wt_assetLocalIdentifier), wt_assetLocalIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (NSString *)wt_assetLocalIdentifier {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setWt_imageReusetID:(PHImageRequestID)wt_imageReusetID {
    objc_setAssociatedObject(self, @selector(wt_imageReusetID), @(wt_imageReusetID), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (PHImageRequestID)wt_imageReusetID {
    return [objc_getAssociatedObject(self, _cmd) intValue];
}
- (void)wt_imageAsset:(PHAsset *)asset {
    __weak typeof(self) weak_self = self;
    [self wt_imageAsset:asset resultHandler:^(UIImage *image, NSData *imageData, BOOL isiCloud) {
        if (image) {
            weak_self.image = image;
        }
        else if (imageData) {
            weak_self.image = [UIImageView wt_animatedGIFWithData:imageData];
        }
    }];
}
- (void)wt_imageAsset:(PHAsset *)asset resultHandler:(nullable void(^)(UIImage *image,
                                                                       NSData *imageData,
                                                                       BOOL isiCloud))resultHandler {
    CGSize assetImageSize = CGSizeMake(self.bounds.size.width, self.bounds.size.height);
    UIImage *cacheImage = [WTAssetImageCache getImageWithIdentifier:asset.localIdentifier size:assetImageSize];
    if (cacheImage) {
        self.image = cacheImage;
        return;
    }
    self.image = nil;
    if (self.wt_imageReusetID > 0) {
        [PHAsset wt_cancelImageRequestWithID:self.wt_imageReusetID];
        self.wt_imageReusetID = 0;
    }
    NSString *assetLocalIdentifier = asset.localIdentifier.copy;
    self.wt_assetLocalIdentifier = assetLocalIdentifier.copy;
    __weak typeof(self) weak_self = self;
    self.image = nil;
    self.wt_imageReusetID = [asset wt_imageWithSize:assetImageSize resultHandler:^(UIImage * _Nonnull image, BOOL isiCloud) {
        [WTAssetImageCache setImage:image identifier:assetLocalIdentifier size:assetImageSize];
        !resultHandler ?: resultHandler(image, nil, isiCloud);
        weak_self.wt_imageReusetID = 0;
    } gifResultHandler:^(NSData *imageData, BOOL isiCloud) {
        !resultHandler ?: resultHandler(nil, imageData, isiCloud);
        weak_self.wt_imageReusetID = 0;
    }];
}

+ (UIImage *)wt_animatedGIFWithData:(NSData *)data {
    if (!data) {
        return nil;
    }

    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);

    size_t count = CGImageSourceGetCount(source);

    UIImage *animatedImage;

    if (count <= 1) {
        animatedImage = [[UIImage alloc] initWithData:data];
    }
    else {
        NSMutableArray *images = [NSMutableArray array];

        NSTimeInterval duration = 0.0f;

        for (size_t i = 0; i < count; i++) {
            CGImageRef image = CGImageSourceCreateImageAtIndex(source, i, NULL);

//            duration += 100.f / 30.f;

            [images addObject:[UIImage imageWithCGImage:image scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp]];

            CGImageRelease(image);
        }

        if (!duration) {
            duration = (1.0f / 10.0f) * count;
        }

        animatedImage = [UIImage animatedImageWithImages:images duration:duration];
    }

    CFRelease(source);

    return animatedImage;
}

@end

#pragma mark --------------------------------- WTAlbumAssetTableViewCell ---------------------------------

@implementation WTAlbumAssetTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        CGFloat cellHeight = [WTAlbumAssetTableViewCell wtAlbumCellHeight];
        
        self.thumbImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 5, cellHeight - 10, cellHeight - 10)];
        self.thumbImageView.clipsToBounds = true;
        self.thumbImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:self.thumbImageView];
        
        self.albumTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(CGRectGetMaxX(self.thumbImageView.frame) + 10, 0, UIScreen.mainScreen.bounds.size.width - CGRectGetMaxX(self.thumbImageView.frame) - 20, cellHeight)];
        self.albumTitleLabel.textColor = UIColor.blackColor;
        self.albumTitleLabel.font = [UIFont systemFontOfSize:16];
        [self.contentView addSubview:self.albumTitleLabel];
        
        self.lineView = [[UIView alloc] initWithFrame:CGRectMake(10, cellHeight - 1, UIScreen.mainScreen.bounds.size.width - 10, 1)];
        self.lineView.backgroundColor = [UIColor colorWithRed:175.f / 255.f green:175.f / 255.f blue:175.f / 255.f alpha:1];
        [self.contentView addSubview:self.lineView];
    }
    return self;
}

+ (CGFloat)wtAlbumCellHeight {
    return 60;
}

+ (NSString *)wtAlbumCellIdentifier {
    return NSStringFromClass(self);
}

@end


#pragma mark --------------------------------- WTAlbumAssetCollectionCell ---------------------------------
static UIImage *kWTAssetSelectedImage;
@implementation WTAlbumAssetCollectionCell
+ (void)initialize {
    [super initialize];
    CGFloat width = 20;
    
    UIBezierPath *selectedPath = [UIBezierPath bezierPath];
    selectedPath.lineCapStyle = kCGLineCapRound;
    selectedPath.lineJoinStyle = kCGLineCapRound;
    [selectedPath moveToPoint:CGPointMake(width / 5, width / 2)];
    [selectedPath addLineToPoint:CGPointMake(width / 7 * 3, width / 4 * 3)];
    [selectedPath addLineToPoint:CGPointMake(width / 7 * 6, width / 3)];
    
    CAShapeLayer *selectedLayer = CAShapeLayer.layer;
    selectedLayer.frame = CGRectMake(0, 0, width, width);
    selectedLayer.backgroundColor = [UIColor colorWithRed:35.f / 255.f green:190.f / 255.f blue:56.f / 255.f alpha:1].CGColor;
    selectedLayer.fillColor = UIColor.clearColor.CGColor;
    selectedLayer.strokeColor = UIColor.whiteColor.CGColor;
    selectedLayer.lineWidth = 2;
    selectedLayer.path = selectedPath.CGPath;
    
    UIGraphicsBeginImageContextWithOptions(selectedLayer.frame.size, 1, 0);
    [selectedLayer renderInContext:UIGraphicsGetCurrentContext()];
    kWTAssetSelectedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        CGFloat width = 20;
        
        self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        self.imageView.clipsToBounds = true;
        self.imageView.layer.cornerRadius = 2;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:self.imageView];
        
        CAGradientLayer *colorLayer = [CAGradientLayer layer];
        colorLayer.frame = self.contentView.bounds;
        colorLayer.colors = @[
            (id)[UIColor colorWithWhite:0 alpha:0.3].CGColor,
            (id)UIColor.clearColor.CGColor,
            (id)[UIColor colorWithWhite:0 alpha:0.3].CGColor
        ];
        colorLayer.locations = @[
            @(0),
            @(0.5),
            @(1)
        ];
        colorLayer.startPoint = CGPointMake(0, 0);
        colorLayer.endPoint = CGPointMake(0, 1);
        [self.contentView.layer addSublayer:colorLayer];
        
        self.selectedButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.selectedButton.frame = CGRectMake(self.bounds.size.width - width - 5, self.bounds.size.height - width - 5, width, width);
        self.selectedButton.layer.cornerRadius = width / 2;
        self.selectedButton.clipsToBounds = true;
        self.selectedButton.layer.borderWidth = 1;
        self.selectedButton.layer.borderColor = UIColor.whiteColor.CGColor;
        self.selectedButton.backgroundColor = UIColor.clearColor;
        [self.selectedButton setImage:nil forState:UIControlStateNormal];
        [self.selectedButton setImage:kWTAssetSelectedImage forState:UIControlStateSelected];
        [self.contentView addSubview:self.selectedButton];
        
        self.timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, self.contentView.bounds.size.height - 15 - 5, self.contentView.bounds.size.width - 16, 15)];
        self.timeLabel.textColor = UIColor.whiteColor;
        self.timeLabel.font = [UIFont systemFontOfSize:14];
        [self.contentView addSubview:self.timeLabel];
    }
    return self;
}
+ (NSString *)wtAssetCellIdentifier {
    return NSStringFromClass(self);
}
- (void)setCanSelected:(BOOL)canSelected {
    _canSelected = canSelected;
    self.selectedButton.hidden = !canSelected;
}
@end

@implementation WTAssetData
@end
