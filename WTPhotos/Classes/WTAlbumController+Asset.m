//
//  WTAlbumController+Asset.m
//  WTPhotos
//
//  Created by weijiewen on 2020/12/13.
//

#import "WTAlbumController+Asset.h"

#import "WTAlbumController+Configuration.h"

#import "WTAlbumController+Category.h"

#import "WTAlbumCropController.h"

#import "WTImageBrowser.h"

#pragma mark --------------------------------- 照片列表 implementation ---------------------------------
@interface WTAlbumAssetsController () <UICollectionViewDelegate, UICollectionViewDataSource, PHPhotoLibraryChangeObserver>
@property (nonatomic, weak) WTAlbumConfiguration *configuration;
@property (nonatomic, strong) UIView *noAuthorizationView;
@property (nonatomic, strong) UIActivityIndicatorView *loading;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) NSMutableArray <PHAsset *> *selectedAssets;
@property (nonatomic, strong) UIButton *previewButton;
@property (nonatomic, strong) UIButton *confirmButton;
@property (nonatomic, assign) NSUInteger imageCount;
@property (nonatomic, assign) NSUInteger videoCount;
@property (nonatomic, strong) UIView *bottomView;
@end

@implementation WTAlbumAssetsController

- (void)dealloc {
    [PHPhotoLibrary.sharedPhotoLibrary unregisterChangeObserver:self];
}

- (instancetype)initConfiguration:(WTAlbumConfiguration *)configuration
{
    self = [super init];
    if (self) {
        self.configuration = configuration;
        self.selectedAssets = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat bottom = 0;
    if (@available(iOS 11.0, *)) {
        bottom = self.view.safeAreaInsets.bottom;
    }
    self.bottomView.frame = CGRectMake(0, self.view.bounds.size.height - self.bottomView.bounds.size.height - bottom, self.bottomView.bounds.size.width, self.bottomView.bounds.size.height);
    self.collectionView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - self.bottomView.bounds.size.height - bottom);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    self.navigationController.navigationBar.backItem.title = @"";
    self.navigationController.navigationBar.translucent = NO;
    self.loading = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.loading.frame = self.view.bounds;
    [self.view addSubview:self.loading];
    [self.loading startAnimating];
    
    CGRect bottomFrame = CGRectMake(0, self.view.bounds.size.height, self.view.bounds.size.width, 0);
    if (self.configuration.allTypeMaxCount > 1 || self.configuration.imageMaxCount > 1 || self.configuration.videoMaxCount > 1) {
        bottomFrame = CGRectMake(0, self.view.bounds.size.height - 49, self.view.bounds.size.width, 49);
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
        self.bottomView = bottomView;
        
        NSString *previewText = kWTAlbumTextPreview;
        if ([self.albumDelegate respondsToSelector:@selector(albumWillShowText:)]) {
            previewText = [self.albumDelegate albumWillShowText:previewText];
        }
        UIButton *previewButton = [UIButton buttonWithType:UIButtonTypeCustom];
        previewButton.frame = CGRectMake(5, 9, 50, 31);
        previewButton.backgroundColor = UIColor.clearColor;
        previewButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [previewButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.4] forState:UIControlStateNormal];
        [previewButton setTitleColor:[UIColor colorWithWhite:1 alpha:1] forState:UIControlStateSelected];
        [previewButton setTitle:previewText forState:UIControlStateNormal];
        [previewButton addTarget:self action:@selector(action_preview) forControlEvents:UIControlEventTouchUpInside];
        [bottomView addSubview:previewButton];
        self.previewButton = previewButton;
        
        NSString *confirmText = kWTAlbumTextConfirm;
        if ([self.albumDelegate respondsToSelector:@selector(albumWillShowText:)]) {
            confirmText = [self.albumDelegate albumWillShowText:confirmText];
        }
        CGFloat width = [confirmText boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15]} context:nil].size.width + 16;
        UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
        confirmButton.frame = CGRectMake(bottomView.bounds.size.width - width - 10, 9, width, 31);
        confirmButton.layer.cornerRadius = 4;
        confirmButton.clipsToBounds = true;
        confirmButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
        confirmButton.titleLabel.font = [UIFont systemFontOfSize:15];
        [confirmButton setTitleColor:[UIColor colorWithWhite:1 alpha:0.4] forState:UIControlStateNormal];
        [confirmButton setTitleColor:UIColor.whiteColor forState:UIControlStateSelected];
        [confirmButton setTitle:confirmText forState:UIControlStateNormal];
        [confirmButton addTarget:self action:@selector(ation_sure) forControlEvents:UIControlEventTouchUpInside];
        [bottomView addSubview:confirmButton];
        self.confirmButton = confirmButton;
    }
    
    [PHPhotoLibrary.sharedPhotoLibrary registerChangeObserver:self];
}

- (void)noAuthorizationHidden:(BOOL)hidden {
    [self.noAuthorizationView removeFromSuperview];
    self.noAuthorizationView = nil;
    if (hidden) {
        return;
    }
    
    UIView *noAuthorizationView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:noAuthorizationView];
    
    NSString *noAuthorizationText = kWTAlbumTextNoAuthorization;
    if ([self.albumDelegate respondsToSelector:@selector(albumWillShowText:)]) {
        noAuthorizationText = [self.albumDelegate albumWillShowText:noAuthorizationText];
    }
    UILabel *noAuthorizationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, noAuthorizationView.bounds.size.height / 2 - 40, noAuthorizationView.bounds.size.width, 20)];
    noAuthorizationLabel.textColor = UIColor.blackColor;
    noAuthorizationLabel.font = [UIFont systemFontOfSize:18];
    noAuthorizationLabel.textAlignment = NSTextAlignmentCenter;
    noAuthorizationLabel.text = noAuthorizationText;
    [noAuthorizationView addSubview:noAuthorizationLabel];
    
    NSString *goAuthorizationText = kWTAlbumTextGoAuthorization;
    if ([self.albumDelegate respondsToSelector:@selector(albumWillShowText:)]) {
        goAuthorizationText = [self.albumDelegate albumWillShowText:goAuthorizationText];
    }
    CGFloat goWidth = [goAuthorizationText boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16]} context:nil].size.width + 20;
    UIButton *goAppSettingButton = [UIButton buttonWithType:UIButtonTypeCustom];
    goAppSettingButton.frame = CGRectMake(noAuthorizationView.bounds.size.width / 2 - goWidth / 2, CGRectGetMaxY(noAuthorizationLabel.frame) + 10, goWidth, 35);
    goAppSettingButton.backgroundColor = [UIColor colorWithRed:40.f / 255.f green:132.f / 255.f blue:240.f / 255.f alpha:1];
    goAppSettingButton.layer.cornerRadius = 8;
    goAppSettingButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [goAppSettingButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [goAppSettingButton setTitle:goAuthorizationText forState:UIControlStateNormal];
    [goAppSettingButton addTarget:self action:@selector(action_goAppSetting) forControlEvents:UIControlEventTouchUpInside];
    [noAuthorizationView addSubview:goAppSettingButton];
    self.noAuthorizationView = noAuthorizationView;
}

- (void)loadMorePhotosItemHidden:(BOOL)hidden {
    if (hidden) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    else {
        NSString *authorizationMoreText = kWTAlbumTextAuthorizationMore;
        if ([self.albumDelegate respondsToSelector:@selector(albumWillShowText:)]) {
            authorizationMoreText = [self.albumDelegate albumWillShowText:authorizationMoreText];
        }
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:authorizationMoreText style:UIBarButtonItemStylePlain target:self action:@selector(action_chooseMore)];
    }
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
    PHAsset *asset = self.collection.wt_assets[self.collection.wt_assets.count - indexPath.item - 1];
    [cell.imageView wt_imageAsset:asset];
    cell.selectedButton.selected = [self.selectedAssets containsObject:asset];
    BOOL isImage = asset.mediaType == PHAssetMediaTypeImage;
    if (isImage) {
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
    if (cell.selectedButton.selected) {
        cell.canSelected = true;
    }
    else {
        switch (self.configuration.pickType) {
            case WTAlbumConfigurationTypeImageAndVideo:
                cell.canSelected = self.configuration.allTypeMaxCount > 1 && self.selectedAssets.count < self.configuration.allTypeMaxCount;
                break;
            case WTAlbumConfigurationTypeOnlyImage:
                cell.canSelected = self.configuration.imageMaxCount > 1 && self.selectedAssets.count < self.configuration.imageMaxCount;
                break;
            case WTAlbumConfigurationTypeOnlyVideo:
                cell.canSelected = self.configuration.videoMaxCount > 1 && self.selectedAssets.count < self.configuration.videoMaxCount;
                break;
            case WTAlbumConfigurationTypeImageCountAndVideoCount:
                cell.canSelected = isImage ? self.imageCount < self.configuration.imageMaxCount : self.videoCount < self.configuration.videoMaxCount;
                break;
            case WTAlbumConfigurationTypeImageOrVideo:
                if (self.selectedAssets.count) {
                    if (self.selectedAssets.firstObject.mediaType == PHAssetMediaTypeImage) {
                        cell.canSelected = isImage ? self.selectedAssets.count < self.configuration.imageMaxCount : false;
                    }
                    else {
                        cell.canSelected = isImage ? false : self.selectedAssets.count < self.configuration.videoMaxCount;
                    }
                }
                else {
                    cell.canSelected = true;
                }
                break;
        }
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    WTAlbumAssetCollectionCell *cell = (WTAlbumAssetCollectionCell *)[collectionView cellForItemAtIndexPath:indexPath];
    PHAsset *asset = self.collection.wt_assets[self.collection.wt_assets.count - indexPath.item - 1];
    BOOL isOnlyOne = false;
    switch (self.configuration.pickType) {
        case WTAlbumConfigurationTypeImageAndVideo:
            isOnlyOne = self.configuration.allTypeMaxCount == 1;
            break;
        case WTAlbumConfigurationTypeOnlyImage:
            isOnlyOne = self.configuration.imageMaxCount == 1;
            break;
        case WTAlbumConfigurationTypeOnlyVideo:
            isOnlyOne = self.configuration.videoMaxCount == 1;
            break;
        default:
            break;
    }
    if (isOnlyOne) {
        self.view.userInteractionEnabled = false;
        UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityIndicatorView.frame = UIScreen.mainScreen.bounds;
        activityIndicatorView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
        [activityIndicatorView startAnimating];
        [self.view addSubview:activityIndicatorView];
        [asset wt_requestData];
        [asset wt_getData:^(NSData * _Nonnull data, BOOL isGif) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if (self.configuration.editPath) {
                    UIImage *image = [[UIImage alloc] initWithData:data];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [activityIndicatorView removeFromSuperview];
                        WTAlbumCropController *controller = [[WTAlbumCropController alloc] initImage:image editRect:self.configuration.editRect editPath:self.configuration.editPath completion:^(WTAlbumCropController *controller, UIImage * _Nonnull editImage) {
                            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                WTAssetData *assetData = [[WTAssetData alloc] init];
                                assetData.data = UIImagePNGRepresentation(editImage);
                                assetData.assetType = isGif ? WTAlbumAssetGif : WTAlbumAssetImage;
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    self.configuration.selectedDatas(@[assetData]);
                                    [self.navigationController dismissViewControllerAnimated:true completion:nil];
                                });
                            });
                        }];
                        controller.albumDelegate = self.albumDelegate;
                        [self.navigationController pushViewController:controller animated:true];
                        self.view.userInteractionEnabled = true;
                    });
                }
                else {
                    WTAssetData *assetData = [[WTAssetData alloc] init];
                    assetData.data = data;
                    assetData.assetType = isGif ? WTAlbumAssetGif : WTAlbumAssetImage;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [activityIndicatorView removeFromSuperview];
                        self.configuration.selectedDatas(@[assetData]);
                        [self.navigationController dismissViewControllerAnimated:true completion:nil];
                    });
                }
            });
        }];
        return;
    }
    if (!cell.canSelected) {
        return;
    }
    cell.selectedButton.selected = !cell.selectedButton.selected;
    if (cell.selectedButton.selected) {
        if (asset.mediaType == PHAssetMediaTypeImage) {
            self.imageCount += 1;
        }
        else {
            self.videoCount += 1;
        }
        [self.selectedAssets addObject:asset];
        [asset wt_requestData];
    }
    else {
        if (asset.mediaType == PHAssetMediaTypeImage) {
            self.imageCount -= 1;
        }
        else {
            self.videoCount -= 1;
        }
        [asset wt_cancelRequestData];
        [self.selectedAssets removeObject:asset];
    }
    NSString *confirmText = kWTAlbumTextConfirm;
    if ([self.albumDelegate respondsToSelector:@selector(albumWillShowText:)]) {
        confirmText = [self.albumDelegate albumWillShowText:confirmText];
    }
    if (self.selectedAssets.count > 0) {
        self.previewButton.selected = true;
        self.confirmButton.selected = true;
        confirmText = [NSString stringWithFormat:@"%@(%ld)", confirmText, (long)self.selectedAssets.count];
        self.confirmButton.backgroundColor = [UIColor colorWithRed:35.f / 255.f green:190.f / 255.f blue:56.f / 255.f alpha:1];
    }
    else {
        self.previewButton.selected = false;
        self.confirmButton.selected = false;
        self.confirmButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    }
    [self.confirmButton setTitle:confirmText forState:UIControlStateSelected];
    CGFloat width = [confirmText boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15]} context:nil].size.width + 16;
    self.confirmButton.frame = CGRectMake(self.confirmButton.superview.bounds.size.width - width - 10, 9, width, 31);
    [self.collectionView reloadData];
}

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    [self.collection wt_loadAssets];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
    });
}

- (void)action_goAppSetting {
    if (@available(iOS 11.0, *)) {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }
    else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
#pragma clang diagnostic pop
    }
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
    [self.view addSubview:activityIndicatorView];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray <WTAssetData *> *assetDatas = [NSMutableArray arrayWithArray:self.selectedAssets];
        dispatch_group_t group = dispatch_group_create();
        for (NSInteger i = 0; i < self.selectedAssets.count; i ++) {
            dispatch_group_enter(group);
            PHAsset *asset = self.selectedAssets[i];
            [asset wt_getData:^(NSData *data, BOOL isGif) {
                WTAssetData *assetData = [[WTAssetData alloc] init];
                assetData.data = data;
                if (asset.mediaType == PHAssetMediaTypeImage) {
                    assetData.assetType = isGif ? WTAlbumAssetGif : WTAlbumAssetImage;
                }
                else {
                    assetData.assetType = WTAlbumAssetVideo;
                }
                assetDatas[i] = assetData;
                dispatch_group_leave(group);
            }];
        }
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            [activityIndicatorView removeFromSuperview];
            !self.configuration.selectedDatas ?: self.configuration.selectedDatas(assetDatas);
            [self.navigationController dismissViewControllerAnimated:true completion:nil];
        });
    });
}

@end

