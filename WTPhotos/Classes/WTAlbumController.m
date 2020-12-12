//
//  WTAlbumController.m
//  WTPhotos_Example
//
//  Created by weijiewen on 2020/11/10.
//  Copyright © 2020 txywjw@icloud.com. All rights reserved.
//

#import <objc/runtime.h>

#import <Photos/Photos.h>

#import <PhotosUI/PHPhotoLibrary+PhotosUISupport.h>

#import "WTAlbumController.h"

#import "WTImageBrowser.h"

#pragma mark --------------------------------- WTAssetImageCache ---------------------------------
@interface WTAssetImageCache : NSObject
@property (nonatomic, strong) NSMutableDictionary <NSString *, UIImage *> *caches;
+ (nullable UIImage *)getImageWithIdentifier:(NSString *)identifier size:(CGSize)size;
+ (void)setImage:(UIImage *)image identifier:(NSString *)identifier size:(CGSize)size;
+ (void)clearCache;
@end
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
@interface PHAssetCollection (WTAlbumCollection)
@property (nonatomic, strong) PHFetchResult <PHAsset *> *wt_assets;
@end
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
    void(^getStatus)(PHAuthorizationStatus status) = ^(PHAuthorizationStatus status) {
        switch (status) {
            case PHAuthorizationStatusNotDetermined: {
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                    [self wt_loadCollectionWithOptions:options noAuthorization:noAuthorization finish:finish];
                }];
            }
                break;
            case PHAuthorizationStatusDenied:
            case PHAuthorizationStatusRestricted: {
                !noAuthorization ?: noAuthorization();
            }
                break;
            case PHAuthorizationStatusLimited:
            case PHAuthorizationStatusAuthorized: {
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
                        if (@available(iOS 14, *)) {
                            !finish ?: finish(collections, status == PHAuthorizationStatusLimited);
                        } else {
                            !finish ?: finish(collections, false);
                        }
                    });
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
@interface PHAsset (WTAlbumAsset)
@property (nonatomic, copy) void(^wt_getData)(NSData *data);
@property (nonatomic, strong) NSData *wt_assetData;
@property (nonatomic, assign) PHImageRequestID wt_imageRequestID;
@end
@implementation PHAsset (WTAlbumAsset)
- (void)setWt_getData:(void (^)(NSData *))wt_getData {
    objc_setAssociatedObject(self, @selector(wt_getData), wt_getData, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (void (^)(NSData *))wt_getData {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setWt_assetData:(NSData *)wt_assetData {
    objc_setAssociatedObject(self, @selector(wt_assetData), wt_assetData, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSData *)wt_assetData {
    return objc_getAssociatedObject(self, _cmd);
}
- (void)setWt_imageRequestID:(PHImageRequestID)wt_imageRequestID {
    objc_setAssociatedObject(self, @selector(wt_imageRequestID), @(wt_imageRequestID), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (PHImageRequestID)wt_imageRequestID {
    return [objc_getAssociatedObject(self, _cmd) intValue];
}
- (PHImageRequestID)wt_imageWithSize:(CGSize)size
                  resultImageHandler:(nullable void(^)(UIImage *image))resultImageHandler {
    return [self wt_imageWithSize:size resultHandler:^(UIImage *image, BOOL isiCloud) {
        !resultImageHandler ?: resultImageHandler(image);
    }];
}
- (PHImageRequestID)wt_imageWithSize:(CGSize)size
                       resultHandler:(nullable void(^)(UIImage *image,
                                                       BOOL isiCloud))resultHandler {
    PHAsset *asset = [PHAsset fetchAssetsWithLocalIdentifiers:@[self.localIdentifier] options:nil].firstObject;
    BOOL isOriginal = CGSizeEqualToSize(size, CGSizeZero);
    CGSize targetSize = isOriginal ? PHImageManagerMaximumSize : CGSizeMake(size.width * 2, size.height * 2);
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.version = PHImageRequestOptionsVersionCurrent;
    options.deliveryMode = isOriginal ? PHImageRequestOptionsDeliveryModeHighQualityFormat : PHImageRequestOptionsDeliveryModeOpportunistic;
    options.resizeMode = isOriginal ? PHImageRequestOptionsResizeModeNone : PHImageRequestOptionsResizeModeExact;
    options.networkAccessAllowed = true;
    return [PHImageManager.defaultManager requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        !resultHandler ?: resultHandler(result, info[PHImageResultIsInCloudKey] != nil);
    }];
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
                    !self.wt_getData ?: self.wt_getData(self.wt_assetData);
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
                    !self.wt_getData ?: self.wt_getData(self.wt_assetData);
                    self.wt_getData = nil;
                });
            });
        }];
    }
}
- (void)wt_getData:(void(^)(NSData *data))getData {
    if (self.wt_assetData) {
        getData(self.wt_assetData);
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
@interface UIImageView (WTAlbumAsset)
@property (nonatomic, copy) NSString *wt_assetLocalIdentifier;
@property (nonatomic, assign) PHImageRequestID wt_imageReusetID;
@end
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
    [self wt_imageAsset:asset resultHandler:^(UIImage *image, BOOL isiCloud) {
        weak_self.image = image;
    }];
}
- (void)wt_imageAsset:(PHAsset *)asset resultHandler:(nullable void(^)(UIImage *image,
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
        !resultHandler ?: resultHandler(image, isiCloud);
        weak_self.wt_imageReusetID = 0;
    }];
}
@end
#pragma mark --------------------------------- WTAlbumAssetCollectionCell ---------------------------------
static UIImage *kWTAssetSelectedImage;
@interface WTAlbumAssetCollectionCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *selectedButton;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic, assign) BOOL canSelected;
@end
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
#pragma mark --------------------------------- WTAlbumAssetTableViewCell ---------------------------------
@interface WTAlbumAssetTableViewCell : UITableViewCell
@property (nonatomic, strong) UIImageView *thumbImageView;
@property (nonatomic, strong) UILabel *albumTitleLabel;
@property (nonatomic, strong) UIView *lineView;
@end
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
#pragma mark --------------------------------- WTAssetData ---------------------------------
@interface WTAssetData ()
@property (nonatomic, strong) NSData *assetData;
@property (nonatomic, assign) WTAlbumAssetType assetType;
@end
@implementation WTAssetData

@end
#pragma mark --------------------------------- WTAlbumAssetsController interface ---------------------------------
@interface WTAlbumAssetsController : UIViewController
@property (nonatomic, weak) PHAssetCollection *collection;
@property (nonatomic, assign) BOOL imageAndViodeOnlyOne;
@property (nonatomic, copy) void(^selectedDatas)(NSArray <WTAssetData *> *datas);
- (instancetype)initWithMaxSelectedCount:(NSUInteger)maxSelectedCount;
- (void)noAuthorization;
- (void)loadMorePhotosItem;
@end
#pragma mark --------------------------------- WTAlbumViewController interface ---------------------------------
@interface WTAlbumViewController : UIViewController
@property (nonatomic, weak) WTAlbumAssetsController *assetController;
- (instancetype)initWithAssetController:(WTAlbumAssetsController *)controller
                             albumTypes:(WTAlbumAssetType)types
                       maxSelectedCount:(NSUInteger)maxSelectedCount
                          selectedDatas:(void(^)(NSArray <WTAssetData *> *datas))selectedDatas
                               editPath:(nullable UIBezierPath *(^)(CGRect editRect))editPath;
@end
#pragma mark --------------------------------- WTAlbumController ---------------------------------
@interface WTAlbumController ()
@property (nonatomic, weak) WTAlbumViewController *wtRootControoler;
@end
@implementation WTAlbumController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (instancetype)initAlbumPickImageWithEditPath:(nullable UIBezierPath *(^)(CGRect editRect))editPath
                                 selectedImage:(void(^)(UIImage *editImage))selectedImage
{
    return [self initAlbumTypes:WTAlbumAssetImage maxSelectedCount:1 selectedDatas:^(NSArray<WTAssetData *> *datas) {
        selectedImage([UIImage.alloc initWithData:datas.firstObject.assetData]);
    } editPath:editPath];
}

- (instancetype)initWithAlbumTypes:(WTAlbumAssetType)types
                  maxSelectedCount:(NSUInteger)maxSelectedCount
                     selectedDatas:(void(^)(NSArray <WTAssetData *> *datas))selectedDatas
{
    return [self initAlbumTypes:types maxSelectedCount:maxSelectedCount selectedDatas:selectedDatas editPath:nil];
}

- (instancetype)initAlbumTypes:(WTAlbumAssetType)types
              maxSelectedCount:(NSUInteger)maxSelectedCount
                 selectedDatas:(void(^)(NSArray <WTAssetData *> *datas))selectedDatas
                      editPath:(nullable UIBezierPath *(^)(CGRect editRect))editPath
{
    WTAlbumAssetsController *assetController = [[WTAlbumAssetsController alloc] initWithMaxSelectedCount:maxSelectedCount];
    WTAlbumViewController *controller = [[WTAlbumViewController alloc] initWithAssetController:assetController
                                                                                    albumTypes:types
                                                                              maxSelectedCount:maxSelectedCount
                                                                                 selectedDatas:selectedDatas
                                                                                      editPath:editPath];
    self = [super initWithRootViewController:controller];
    if (self) {
        self.imageAndViodeOnlyOne = true;
        assetController.imageAndViodeOnlyOne = true;
        self.wtRootControoler = controller;
        self.navigationBar.tintColor = UIColor.whiteColor;
        self.navigationBar.barStyle = UIBarStyleBlack;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self.navigationBar.barTintColor = UIColor.blackColor;
        [self pushViewController:assetController animated:false];
    }
    return self;
}

- (void)setImageAndViodeOnlyOne:(BOOL)imageAndViodeOnlyOne {
    _imageAndViodeOnlyOne = imageAndViodeOnlyOne;
    self.wtRootControoler.assetController.imageAndViodeOnlyOne = imageAndViodeOnlyOne;
}
@end
#pragma mark --------------------------------- WTAlbumViewController ---------------------------------
@interface WTAlbumViewController() <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray <PHAssetCollection *> *collections;
@property (nonatomic, assign) BOOL isLimit;
@property (nonatomic, assign) NSUInteger maxSelectedCount;
@property (nonatomic, assign) WTAlbumAssetType types;
@property (nonatomic, assign) CGRect editRect;
@property (nonatomic, strong) UIBezierPath *editPath;
@end

@implementation WTAlbumViewController

- (instancetype)initWithAssetController:(WTAlbumAssetsController *)controller
                             albumTypes:(WTAlbumAssetType)types
                       maxSelectedCount:(NSUInteger)maxSelectedCount
                          selectedDatas:(void(^)(NSArray <WTAssetData *> *datas))selectedDatas
                               editRect:(nullable CGRect(^)(CGRect viewRect))editRect
                               editPath:(nullable UIBezierPath *(^)(CGRect editRect))editPath
{
    self = [super init];
    if (self) {
        self.types = types;
        self.maxSelectedCount = maxSelectedCount;
        self.assetController = controller;
        self.assetController.selectedDatas = selectedDatas;
        
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        NSMutableString *predicateString = [NSMutableString string];
        if (types & WTAlbumAssetImage) {
            [predicateString appendFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
        }
//        if (types & WTAlbumAssetVideo) {
//            if (predicateString.length) {
//                [predicateString appendString:@" || "];
//            }
//            [predicateString appendFormat:@"mediaType == %ld", PHAssetMediaTypeVideo];
//        }
        options.predicate = [NSPredicate predicateWithFormat:predicateString];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        [PHAssetCollection wt_loadCollectionWithOptions:options noAuthorization:^{
            [self.assetController noAuthorization];
        } finish:^(NSArray<PHAssetCollection *> * _Nonnull collections, BOOL isLimit) {
            self.isLimit = isLimit;
            UIBarButtonItem *chooseMoreItem = [[UIBarButtonItem alloc] initWithTitle:@"授权更多" style:UIBarButtonItemStylePlain target:self action:@selector(action_chooseMore)];
            self.navigationItem.rightBarButtonItems = @[chooseMoreItem];
            self.collections = collections;
            [self.tableView reloadData];
            self.assetController.collection = collections.firstObject;
            [self.assetController loadMorePhotosItem];
        }];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(action_cancel)];
    self.navigationItem.leftBarButtonItems = @[cancelItem];
    
    CGFloat y = UIApplication.sharedApplication.statusBarFrame.size.height + 44;
    CGFloat bottom = 0.f;
    if (y > 44) {
        bottom = 24;
    }
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, y, self.view.bounds.size.width, self.view.bounds.size.height - y - bottom) style:UITableViewStylePlain];
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.backgroundColor = self.view.backgroundColor;
    tableView.showsVerticalScrollIndicator = false;
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 20)];
    tableView.delegate = self;
    tableView.dataSource = self;
    if (@available(iOS 11.0, *)) {
        tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    }
    [self.view addSubview:tableView];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.collections.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [WTAlbumAssetTableViewCell wtAlbumCellHeight];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    WTAlbumAssetTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[WTAlbumAssetTableViewCell wtAlbumCellIdentifier]];
    if (!cell) {
        cell = [[WTAlbumAssetTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[WTAlbumAssetTableViewCell wtAlbumCellIdentifier]];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    PHAssetCollection *collection = self.collections[indexPath.item];
    [cell.thumbImageView wt_imageAsset:self.collections[indexPath.item].wt_assets.firstObject];
    cell.albumTitleLabel.text = collection.localizedTitle;
    cell.lineView.hidden = indexPath.row == self.collections.count - 1;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    WTAlbumAssetsController *assetController = [[WTAlbumAssetsController alloc] initWithMaxSelectedCount:self.maxSelectedCount];
    assetController.collection = self.collections[indexPath.item];
    if (self.isLimit) {
        [assetController loadMorePhotosItem];
    }
    [self.navigationController pushViewController:assetController animated:true];
}

- (void)action_cancel {
    self.assetController.selectedDatas = nil;
    [self.navigationController dismissViewControllerAnimated:true completion:nil];
}

- (void)action_chooseMore {
    if (@available(iOS 14, *)) {
        [PHPhotoLibrary.sharedPhotoLibrary presentLimitedLibraryPickerFromViewController:self];
    }
}

@end
#pragma mark --------------------------------- WTAlbumCropController ---------------------------------
@interface WTAlbumCropController : UIViewController
- (instancetype)initWithImage:(UIImage *)image
                     editRect:(nullable CGRect(^)(CGRect viewRect))editRect
                     editPath:(UIBezierPath *(^)(CGRect editRect))editPath;
@end
#pragma mark --------------------------------- WTAlbumAssetsController ---------------------------------
@interface WTAlbumAssetsController () <UICollectionViewDelegate, UICollectionViewDataSource, PHPhotoLibraryChangeObserver>
@property (nonatomic, strong) UIView *noAuthorizationView;
@property (nonatomic, strong) UIActivityIndicatorView *loading;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, assign) NSUInteger maxSelectedCount;
@property (nonatomic, strong) NSMutableArray <PHAsset *> *selectedAssets;
@property (nonatomic, strong) UIButton *previewButton;
@property (nonatomic, strong) UIButton *sureButton;
@end

@implementation WTAlbumAssetsController

- (void)dealloc {
    [PHPhotoLibrary.sharedPhotoLibrary unregisterChangeObserver:self];
}

- (instancetype)initWithMaxSelectedCount:(NSUInteger)maxSelectedCount
{
    self = [super init];
    if (self) {
        self.maxSelectedCount = maxSelectedCount;
        self.selectedAssets = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithEditRect:(nullable CGRect(^)(CGRect viewRect))editRect
                        editPath:(UIBezierPath *(^)(CGRect editRect))editPath;
{
    self = [super init];
    if (self) {
        self.
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.navigationController.navigationBar.backItem.title = @"";
    self.loading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.loading.frame = self.view.bounds;
    [self.view addSubview:self.loading];
    [self.loading startAnimating];
    
    CGRect bottomFrame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 0);
    if (self.maxSelectedCount > 1) {
        bottomFrame = CGRectMake(0, self.view.bounds.size.height - 49, self.view.bounds.size.width, 49);
        if (UIApplication.sharedApplication.statusBarFrame.size.height > 20) {
            bottomFrame.origin.y -= 24;
        }
    }
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake((self.view.bounds.size.width - 2) / 3, (self.view.bounds.size.width - 2) / 3);
    layout.minimumLineSpacing = 1;
    layout.minimumInteritemSpacing = 1;
    layout.footerReferenceSize = CGSizeMake(self.view.bounds.size.width, 1);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, bottomFrame.origin.y) collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = self.view.backgroundColor;
    self.collectionView.showsVerticalScrollIndicator = false;
    [self.collectionView registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:NSStringFromClass(self.class)];
    [self.collectionView registerClass:WTAlbumAssetCollectionCell.class forCellWithReuseIdentifier:[WTAlbumAssetCollectionCell wtAssetCellIdentifier]];
    [self.view addSubview:self.collectionView];
    
    if (bottomFrame.size.height > 0) {
        UIView *bottomView = [[UIView alloc] initWithFrame:bottomFrame];
        bottomView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
        [self.view addSubview:bottomView];
        
        UIButton *previewButton = [UIButton buttonWithType:UIButtonTypeCustom];
        previewButton.frame = CGRectMake(5, 9, 50, 31);
        previewButton.backgroundColor = UIColor.clearColor;
        previewButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [previewButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.4] forState:UIControlStateNormal];
        [previewButton setTitleColor:[UIColor colorWithWhite:1 alpha:1] forState:UIControlStateSelected];
        [previewButton setTitle:@"预览" forState:UIControlStateNormal];
        [previewButton addTarget:self action:@selector(action_preview) forControlEvents:UIControlEventTouchUpInside];
        [bottomView addSubview:previewButton];
        self.previewButton = previewButton;
        
        CGFloat width = [@"发送" boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18]} context:nil].size.width + 12;
        UIButton *sureButton = [UIButton buttonWithType:UIButtonTypeCustom];
        sureButton.frame = CGRectMake(bottomView.bounds.size.width - width - 10, 9, width, 31);
        sureButton.layer.cornerRadius = 4;
        sureButton.clipsToBounds = true;
        sureButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
        sureButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [sureButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.4] forState:UIControlStateNormal];
        [sureButton setTitleColor:UIColor.whiteColor forState:UIControlStateSelected];
        [sureButton setTitle:@"发送" forState:UIControlStateNormal];
        [sureButton addTarget:self action:@selector(ation_sure) forControlEvents:UIControlEventTouchUpInside];
        [bottomView addSubview:sureButton];
        self.sureButton = sureButton;
    }
    
    [PHPhotoLibrary.sharedPhotoLibrary registerChangeObserver:self];
}

- (void)noAuthorization {
    UIView *noAuthorizationView = [[UIView alloc] initWithFrame:self.view.bounds];
    
    UILabel *noAuthorizationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, noAuthorizationView.bounds.size.height / 2 - 40, noAuthorizationView.bounds.size.width, 20)];
    noAuthorizationLabel.textColor = UIColor.blackColor;
    noAuthorizationLabel.font = [UIFont systemFontOfSize:14];
    noAuthorizationLabel.textAlignment = NSTextAlignmentCenter;
    noAuthorizationLabel.text = @"未授权相册权限";
    [noAuthorizationView addSubview:noAuthorizationLabel];
    
    UIButton *goAppSettingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    goAppSettingButton.frame = CGRectMake(noAuthorizationView.bounds.size.width / 2 - 30, CGRectGetMaxY(noAuthorizationLabel.frame) + 2, 60, 40);
    goAppSettingButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [goAppSettingButton setTitleColor:[UIColor colorWithRed:176.f / 255.f green:224.f / 255.f blue:230.f / 255.f alpha:1] forState:UIControlStateNormal];
    [goAppSettingButton setTitle:@"前往授权" forState:UIControlStateNormal];
    [goAppSettingButton addTarget:self action:@selector(action_goAppSetting) forControlEvents:UIControlEventTouchUpInside];
    [noAuthorizationView addSubview:goAppSettingButton];
    [self.noAuthorizationView removeFromSuperview];
    self.noAuthorizationView = noAuthorizationView;
}

- (void)loadMorePhotosItem {
    UIBarButtonItem *chooseMoreItem = [[UIBarButtonItem alloc] initWithTitle:@"授权更多" style:UIBarButtonItemStylePlain target:self action:@selector(action_chooseMore)];
    self.navigationItem.rightBarButtonItems = @[chooseMoreItem];
}

- (void)setCollection:(PHAssetCollection *)collection {
    _collection = collection;
    [self.noAuthorizationView removeFromSuperview];
    self.noAuthorizationView = nil;
    if (collection.wt_assets.count) {
        [self.loading stopAnimating];
    }
    [self.collectionView reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.collection.wt_assets.count;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *view = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:NSStringFromClass(self.class) forIndexPath:indexPath];
    return view;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WTAlbumAssetCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WTAlbumAssetCollectionCell wtAssetCellIdentifier] forIndexPath:indexPath];
    PHAsset *asset = self.collection.wt_assets[indexPath.item];
    [cell.imageView wt_imageAsset:asset];
    if (self.maxSelectedCount > 1) {
        cell.selectedButton.selected = [self.selectedAssets containsObject:asset];
        if (self.selectedAssets.count < self.maxSelectedCount) {
            if (self.imageAndViodeOnlyOne) {
                if (!self.selectedAssets.count) {
                    cell.canSelected = true;
                }
                else if (cell.selectedButton.selected) {
                    cell.canSelected = true;
                }
                else if (asset.mediaType != self.selectedAssets.firstObject.mediaType) {
                    cell.canSelected = false;
                }
                else {
                    cell.canSelected = true;
                }
            }
            else {
                cell.canSelected = true;
            }
        }
        else {
            cell.canSelected = cell.selectedButton.selected;
        }
        if (asset.mediaType == PHAssetMediaTypeImage) {
            cell.timeLabel.text = @"";
        }
        else {
            NSInteger totalSeconds = asset.duration;
            NSInteger seconds = totalSeconds % 60;
            NSInteger totalMinute = totalSeconds / 60;
            NSInteger minute = totalMinute % 60;
            NSInteger hour = totalMinute / 60;
            
            NSString *time = [NSString stringWithFormat:@"%02ld:%02ld", (long)minute, (long)seconds];
            if (hour) {
                time = [NSString stringWithFormat:@"%ld:%@", (long)hour, time];
            }
            cell.timeLabel.text = time;
        }
    }
    else {
        cell.canSelected = false;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    WTAlbumAssetCollectionCell *cell = (WTAlbumAssetCollectionCell *)[collectionView cellForItemAtIndexPath:indexPath];
    PHAsset *asset = self.collection.wt_assets[indexPath.item];
    if (self.maxSelectedCount == 1) {
        [asset wt_imageWithSize:CGSizeZero resultImageHandler:^(UIImage *image) {
            WTAlbumCropController *controller = [[WTAlbumCropController alloc] initWithImage:image editRect:<#^CGRect(CGRect viewRect)editRect#> editPath:<#^UIBezierPath *(CGRect editRect)editPath#>
            [self.navigationController pushViewController:controller animated:true];
        }];
        return;
    }
    if ((!cell.selectedButton.selected && self.selectedAssets.count == self.maxSelectedCount) || !cell.canSelected) {
        return;
    }
    BOOL reloadCollectionView = self.selectedAssets.count == self.maxSelectedCount;
    cell.selectedButton.selected = !cell.selectedButton.selected;
    if (cell.selectedButton.selected) {
        [self.selectedAssets addObject:asset];
        [asset wt_requestData];
        reloadCollectionView = self.selectedAssets.count == self.maxSelectedCount;
    }
    else {
        [asset wt_cancelRequestData];
        [self.selectedAssets removeObject:asset];
    }
    NSString *sureTitle = @"发送";
    if (self.selectedAssets.count > 0) {
        self.previewButton.selected = true;
        self.sureButton.selected = true;
        sureTitle = [NSString stringWithFormat:@"发送(%ld)", self.selectedAssets.count];
        [self.sureButton setTitle:sureTitle forState:UIControlStateSelected];
        self.sureButton.backgroundColor = [UIColor colorWithRed:35.f / 255.f green:190.f / 255.f blue:56.f / 255.f alpha:1];
    }
    else {
        self.previewButton.selected = false;
        self.sureButton.selected = false;
        self.sureButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    }
    CGFloat width = [sureTitle boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:18]} context:nil].size.width + 12;
    self.sureButton.frame = CGRectMake(self.sureButton.superview.bounds.size.width - width - 10, 9, width, 31);
    if (self.imageAndViodeOnlyOne || reloadCollectionView) {
        [self.collectionView reloadData];
    }
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    [self.collection wt_loadAssets];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
    });
}

- (void)action_goAppSetting {
    [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
}

- (void)action_chooseMore {
    if (@available(iOS 14, *)) {
        [PHPhotoLibrary.sharedPhotoLibrary presentLimitedLibraryPickerFromViewController:self];
    }
}

- (void)action_preview {
    WTImageBrowser *controller = [[WTImageBrowser alloc] initWithImageCount:self.selectedAssets.count browserIndex:0 setImage:^(UIImageView * _Nonnull imageView, NSInteger index) {
        [imageView wt_imageAsset:self.selectedAssets[index]];
    } longPress:nil];
    [self presentViewController:controller animated:true completion:nil];
}

- (void)ation_sure {
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.frame = UIScreen.mainScreen.bounds;
    activityIndicatorView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    [activityIndicatorView startAnimating];
    [UIApplication.sharedApplication.keyWindow addSubview:activityIndicatorView];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray <WTAssetData *> *assetDatas = [NSMutableArray arrayWithArray:self.selectedAssets];
        dispatch_group_t group = dispatch_group_create();
        for (NSInteger i = 0; i < self.selectedAssets.count; i ++) {
            dispatch_group_enter(group);
            PHAsset *asset = self.selectedAssets[i];
            [asset wt_getData:^(NSData *data) {
                WTAssetData *assetData = [[WTAssetData alloc] init];
                assetData.assetData = data;
                assetData.assetType = WTAlbumAssetImage;
//                assetData.assetType = asset.mediaType == PHAssetMediaTypeImage ? WTAlbumAssetImage : WTAlbumAssetVideo;
                assetDatas[i] = assetData;
                dispatch_group_leave(group);
            }];
        }
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            [activityIndicatorView removeFromSuperview];
            !self.selectedDatas ?: self.selectedDatas(assetDatas);
            self.selectedDatas = nil;
            [self.navigationController dismissViewControllerAnimated:true completion:nil];
        });
    });
}

@end

@interface WTAlbumCropController () <UIScrollViewDelegate>
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *cropMaskView;
@property (nonatomic, assign) CGRect cropRect;
@property (nonatomic, strong) UIBezierPath *editPath;
@end
@implementation WTAlbumCropController

- (instancetype)initWithImage:(UIImage *)image
                     editRect:(nullable CGRect(^)(CGRect viewRect))editRect
                     editPath:(UIBezierPath *(^)(CGRect editRect))editPath
{
    self = [super init];
    if (self) {
        self.image = image;
        self.cropRect = editRect ? editRect(self.view.bounds) : self.view.bounds;
        self.editPath = editPath(self.cropRect);
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.navigationController) {
        self.navigationController.navigationBar.hidden = true;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.interactivePopGestureRecognizer.enabled = false;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.navigationController) {
        self.navigationController.navigationBar.hidden = false;
    }
    self.navigationController.interactivePopGestureRecognizer.enabled = true;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.view.clipsToBounds = YES;
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = 4;
    self.scrollView.delegate = self;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.bounces = true;
    self.scrollView.clipsToBounds = NO;
    [self.view addSubview:self.scrollView];
    
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    else {
        self.automaticallyAdjustsScrollViewInsets = false;
    }
    
    UITapGestureRecognizer *twoTouchTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(action_twoTap)];
    twoTouchTap.numberOfTapsRequired = 2;
    twoTouchTap.numberOfTouchesRequired = 1;
    [self.scrollView addGestureRecognizer:twoTouchTap];
    
    CGFloat imageHeight = self.scrollView.bounds.size.width / self.image.size.width * self.image.size.height;
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.scrollView.bounds.size.height / 2 - imageHeight / 2, self.scrollView.bounds.size.width, imageHeight)];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.image = self.image;
    [self.scrollView addSubview:self.imageView];
    
    
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGFloat imageX = (scrollView.bounds.size.width - self.imageView.frame.size.width) / 2.0;
    CGFloat imageY = (scrollView.bounds.size.height - self.imageView.frame.size.height) / 2.0;
    CGRect imageViewFrame = self.imageView.frame;
    if (imageX > 0) {
        imageViewFrame.origin.x = imageX;
    }
    else {
        imageViewFrame.origin.x = 0;
    }
    if (imageY > 0) {
        imageViewFrame.origin.y = imageY;
    }
    else {
        imageViewFrame.origin.y = 0;
    }
    self.imageView.frame = imageViewFrame;
}

- (void)action_twoTap {
    if (self.scrollView.zoomScale == 4) {
        [self.scrollView setZoomScale:1 animated:YES];
    }
    else if (1 <= self.scrollView.zoomScale && self.scrollView.zoomScale < 2) {
        [self.scrollView setZoomScale:2 animated:YES];
    }
    else if (2 <= self.scrollView.zoomScale && self.scrollView.zoomScale < 3) {
        [self.scrollView setZoomScale:3 animated:YES];
    }
    else {
        [self.scrollView setZoomScale:4 animated:YES];
    }
}

@end

