//
//  WTAlbumController+Collection.m
//  WTPhotos
//
//  Created by weijiewen on 2020/12/13.
//

#import "WTAlbumController+Collection.h"

#import "WTAlbumController+Category.h"

#import "WTAlbumController+Configuration.h"

#import "WTAlbumController+Asset.h"

#pragma mark --------------------------------- 相册列表 implementation ---------------------------------

@interface WTAlbumViewController() <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) WTAlbumConfiguration *configuration;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray <PHAssetCollection *> *collections;
@property (nonatomic, assign) BOOL isLimit;
@end
@implementation WTAlbumViewController

- (instancetype)initWithConfiguration:(WTAlbumConfiguration *)configuration
                      assetController:(WTAlbumAssetsController *)controller

{
    self = [super init];
    if (self) {
        self.configuration = configuration;
        [self configurationCollectionWithController:controller collection:nil];
    }
    return self;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
    CGFloat bottom = 0.f;
    if (@available(iOS 11.0, *)) {
        bottom = self.view.safeAreaInsets.bottom;
    }
    self.tableView.tableFooterView.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, bottom);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    NSString *text = kWTAlbumTextCancel;
    if ([self.albumDelegate respondsToSelector:@selector(albumWillShowText:)]) {
        text = [self.albumDelegate albumWillShowText:text];
    }
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:text style:UIBarButtonItemStylePlain target:self action:@selector(action_cancel)];
    self.navigationItem.leftBarButtonItems = @[cancelItem];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.backgroundColor = self.view.backgroundColor;
    tableView.showsVerticalScrollIndicator = false;
    tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 0)];
    tableView.delegate = self;
    tableView.dataSource = self;
    if (@available(iOS 11.0, *)) {
        tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
    }
    [self.view addSubview:tableView];
}

- (void)configurationCollectionWithController:(WTAlbumAssetsController *)controller collection:(nullable PHAssetCollection *)collection {
    
    dispatch_block_t noAuthorization = ^(void) {
        [controller noAuthorizationHidden:false];
    };
    void(^completion)(PHAssetCollection *collection, BOOL isLimit) = ^(PHAssetCollection *collection, BOOL isLimit) {
        self.isLimit = isLimit;
        if (isLimit) {
            [controller loadMorePhotosItemHidden:!isLimit];
        }
        controller.collection = collection;
    };
    
    if (!collection) {
        PHFetchOptions *options = [[PHFetchOptions alloc] init];
        NSMutableString *predicateString = [NSMutableString string];
        switch (self.configuration.pickType) {
            case WTAlbumConfigurationTypeOnlyImage:
                [predicateString appendFormat:@"mediaType == %ld", (long)PHAssetMediaTypeImage];
                break;
            case WTAlbumConfigurationTypeOnlyVideo:
                [predicateString appendFormat:@"mediaType == %ld", (long)PHAssetMediaTypeVideo];
                break;
            default:
                [predicateString appendFormat:@"mediaType == %ld || mediaType == %ld", (long)PHAssetMediaTypeImage, (long)PHAssetMediaTypeVideo];
                break;
        }
        options.predicate = [NSPredicate predicateWithFormat:predicateString];
        [PHAssetCollection wt_loadCollectionWithOptions:options noAuthorization:noAuthorization finish:^(NSArray<PHAssetCollection *> * _Nonnull collections, BOOL isLimit) {
            self.collections = collections;
            [self.tableView reloadData];
            completion(collections.firstObject, isLimit);
        }];
    }
    else {
        [PHAssetCollection wt_photosAuthorization:noAuthorization completion:^(BOOL isLimit) {
            completion(collection, isLimit);
        }];
    }
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
    WTAlbumAssetsController *controller = [[WTAlbumAssetsController alloc] initConfiguration:self.configuration];
    [self configurationCollectionWithController:controller collection:self.collections[indexPath.item]];
    [self.navigationController pushViewController:controller animated:true];
}

- (void)action_cancel {
    [self.navigationController dismissViewControllerAnimated:true completion:nil];
}

- (void)action_chooseMore {
    if (@available(iOS 14, *)) {
        [PHPhotoLibrary.sharedPhotoLibrary presentLimitedLibraryPickerFromViewController:self];
    }
}

@end
