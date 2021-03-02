//
//  WTImageBrowser.m
//  WTPhotos_Example
//
//  Created by weijiewen on 2020/11/16.
//  Copyright © 2020 txywjw@icloud.com. All rights reserved.
//

#import "WTImageBrowser.h"

@protocol WTBrowserImageViewDelegate <NSObject>
@required
@optional
- (void)imageChange:(UIImageView *)imageView;
@end
@interface HXBrowserImageView : UIImageView
@property (nonatomic, weak) id <WTBrowserImageViewDelegate> delegate;
@end
@implementation HXBrowserImageView

- (void)setImage:(UIImage *)image {
    [super setImage:image];
    if (image && self.delegate && [self.delegate respondsToSelector:@selector(imageChange:)]) {
        [self.delegate imageChange:self];
    }
}

@end


@class WTImageBrowserCollectionViewCell;
@protocol WTImageBrowserCollectionViewCellDelegate <NSObject>
@required
@optional
- (void)browserCell:(WTImageBrowserCollectionViewCell *)cell didLongPressWithImage:(UIImage *)image;
- (void)browserCellTouch;
@end
@interface WTImageBrowserCollectionViewCell : UICollectionViewCell <UIScrollViewDelegate, WTBrowserImageViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) HXBrowserImageView *imageView;
@property (nonatomic, weak) id <WTImageBrowserCollectionViewCellDelegate> delegate;
@end
@implementation WTImageBrowserCollectionViewCell

- (void)dealloc {
    [self.imageView removeObserver:self forKeyPath:@"image"];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        self.scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        self.scrollView.minimumZoomScale = 1;
        self.scrollView.maximumZoomScale = 8;
        self.scrollView.delegate = self;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.bounces = NO;
        self.scrollView.clipsToBounds = NO;
        [self.contentView addSubview:self.scrollView];
        
        self.imageView = [[HXBrowserImageView alloc] initWithFrame:self.scrollView.bounds];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.clipsToBounds = NO;
        self.imageView.delegate = self;
        [self.imageView addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];
        [self.scrollView addSubview:self.imageView];
        
        UITapGestureRecognizer *twoTouchTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(action_twoTap)];
        twoTouchTap.numberOfTapsRequired = 2;
        twoTouchTap.numberOfTouchesRequired = 1;
        [self.scrollView addGestureRecognizer:twoTouchTap];
        
        UITapGestureRecognizer *onceTouchTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(action_onceTap)];
        onceTouchTap.numberOfTapsRequired = 1;
        onceTouchTap.numberOfTouchesRequired = 1;
        [self.scrollView addGestureRecognizer:onceTouchTap];
        [onceTouchTap requireGestureRecognizerToFail:twoTouchTap];
        
        [self.scrollView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(action_longPress:)]];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"image"]) {
        self.scrollView.contentOffset = CGPointMake(0, self.scrollView.contentSize.height / 2 - self.scrollView.bounds.size.height / 2);
    }
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

- (void)imageChange:(UIImageView *)imageView {
    CGFloat imageHeight = imageView.image.size.height / imageView.image.size.width * self.scrollView.bounds.size.width;
    CGFloat y = imageHeight > self.scrollView.bounds.size.height ? 0 : self.scrollView.bounds.size.height / 2 - imageHeight / 2;
    self.imageView.frame = CGRectMake(0, y, self.scrollView.bounds.size.width, imageHeight);
    CGFloat scrollHeight = imageHeight > self.scrollView.bounds.size.height ? imageHeight : self.scrollView.bounds.size.height;
    self.scrollView.contentSize = CGSizeMake(self.scrollView.bounds.size.width, scrollHeight);
}

- (void)action_twoTap {
    if (self.scrollView.zoomScale == 2) {
        [self.scrollView setZoomScale:1 animated:YES];
    }
    else {
        [self.scrollView setZoomScale:2 animated:YES];
    }
}

- (void)action_longPress:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan && self.delegate && [self.delegate respondsToSelector:@selector(browserCell:didLongPressWithImage:)]) {
        [self.delegate browserCell:self didLongPressWithImage:self.imageView.image];
    }
}

- (void)action_onceTap {
    if (self.delegate && [self.delegate respondsToSelector:@selector(browserCellTouch)]) {
        [self.delegate browserCellTouch];
    }
}

+ (NSString *)identifier {
    return NSStringFromClass(self);
}

- (void)reloadCell {
    [self.scrollView setZoomScale:1 animated:YES];
}

@end


@interface WTImageBrowser () <UIScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, WTImageBrowserCollectionViewCellDelegate>
@property (nonatomic, strong) NSArray <UIImageView *> *fromImageViews;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIPageControl *pageControl;
@property (nonatomic, assign) NSInteger imageCount;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, copy) void(^setImage)(UIImageView *imageView, NSInteger index);
@property (nonatomic, copy) void(^longPress)(NSInteger index, UIImage *image, WTImageBrowser *imageBrowser);
@property (nonatomic, assign) BOOL navigationBarHidden;
@property (nonatomic, assign) BOOL interactivePopGestureRecognizerEnable;
@property (nonatomic, strong) UIButton *chooseButton;
@property (nonatomic, copy) void(^chooseImage)(UIViewController *controller, NSInteger index, UIImage *image);
@end

@implementation WTImageBrowser

- (void)dealloc {
    
}

- (instancetype)initWithImageCount:(NSInteger)imageCount
                      browserIndex:(NSInteger)browserIndex
                          setImage:(void(^)(UIImageView *imageView, NSInteger index))setImage
                         longPress:(nullable void(^)(NSInteger index, UIImage *image, WTImageBrowser *imageBrowser))longPress {
    return [self initWithImageCount:imageCount browserIndex:browserIndex fromImageViews:nil setImage:setImage longPress:longPress];
}

+ (void)showImageCount:(NSInteger)imageCount
                  browserIndex:(NSInteger)browserIndex
                fromImageViews:(NSArray <UIImageView *> *)fromImageViews
                      setImage:(void(^)(UIImageView *imageView, NSInteger index))setImage
                     longPress:(nullable void(^)(NSInteger index, UIImage *image, WTImageBrowser *imageBrowser))longPress {
    WTImageBrowser *browser = [[WTImageBrowser alloc] initWithImageCount:imageCount browserIndex:browserIndex fromImageViews:fromImageViews setImage:setImage longPress:longPress];
    [UIApplication.sharedApplication.keyWindow.rootViewController addChildViewController:browser];
    [UIApplication.sharedApplication.keyWindow.rootViewController.view addSubview:browser.view];
}

- (instancetype)initWithImageCount:(NSInteger)imageCount
                      browserIndex:(NSInteger)browserIndex
                    fromImageViews:(nullable NSArray <UIImageView *> *)fromImageViews
                          setImage:(void(^)(UIImageView *imageView, NSInteger index))setImage
                         longPress:(nullable void(^)(NSInteger index, UIImage *image, WTImageBrowser *imageBrowser))longPress
{
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self.fromImageViews = fromImageViews;
        self.currentIndex = browserIndex;
        if (self.currentIndex >= imageCount) {
            self.currentIndex = imageCount - 1;
        }
        self.imageCount = imageCount;
        self.setImage = setImage;
        self.longPress = longPress;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self creatUI];
}

- (void)setCurrentIndex:(NSInteger)currentIndex {
    _currentIndex = currentIndex;
    self.pageControl.currentPage = currentIndex;
}

- (void)creatUI {
    if (self.fromImageViews.count) {
        CGRect toWindowRect = [self.fromImageViews[self.currentIndex] convertRect:self.fromImageViews[self.currentIndex].bounds toView:UIApplication.sharedApplication.keyWindow];
        CGFloat scaleWidth = self.fromImageViews[self.currentIndex].bounds.size.width;
        if (self.fromImageViews[self.currentIndex].image.size.width > self.fromImageViews[self.currentIndex].image.size.height) {
            scaleWidth = self.fromImageViews[self.currentIndex].image.size.width / self.fromImageViews[self.currentIndex].image.size.height * self.fromImageViews[self.currentIndex].bounds.size.height;
        }
        CGFloat scale = scaleWidth / self.view.bounds.size.width;
        self.view.maskView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width * (self.fromImageViews[self.currentIndex].bounds.size.width / scaleWidth), self.fromImageViews[self.currentIndex].bounds.size.height / self.fromImageViews[self.currentIndex].bounds.size.width * self.view.bounds.size.width * (self.fromImageViews[self.currentIndex].bounds.size.width / scaleWidth))];
        self.view.maskView.backgroundColor = UIColor.blackColor;
        self.view.maskView.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
        self.view.maskView.layer.cornerRadius = self.fromImageViews[self.currentIndex].layer.cornerRadius / self.fromImageViews[self.currentIndex].bounds.size.width * self.view.maskView.bounds.size.width;
        self.view.transform = CGAffineTransformMakeScale(scale, scale);
        self.view.center = CGPointMake(CGRectGetMidX(toWindowRect), CGRectGetMidY(toWindowRect));
    }
    self.view.backgroundColor = [UIColor blackColor];
    
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.itemSize = CGSizeMake(self.view.bounds.size.width - 2, self.view.bounds.size.height);
    layout.minimumLineSpacing = 2;
    layout.minimumInteritemSpacing = 2;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.pagingEnabled = YES;
    self.collectionView.showsVerticalScrollIndicator = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    [self.collectionView registerClass:[WTImageBrowserCollectionViewCell class] forCellWithReuseIdentifier:[WTImageBrowserCollectionViewCell identifier]];
    [self.view addSubview:self.collectionView];
    
    if (@available(iOS 11.0, *)) {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        self.automaticallyAdjustsScrollViewInsets = NO;
#pragma clang diagnostic pop
    }
    if (self.navigationController && !self.fromImageViews.count) {
        self.navigationBarHidden = self.navigationController.navigationBar.hidden;
        self.interactivePopGestureRecognizerEnable = self.navigationController.interactivePopGestureRecognizer.isEnabled;
        self.navigationController.navigationBar.hidden = YES;
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    if (self.imageCount > 1) {
        self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.collectionView.frame) - UIApplication.sharedApplication.statusBarFrame.size.height - 10, self.collectionView.bounds.size.width, 10)];
        self.pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:35.f / 255.f green:190.f / 255.f blue:56.f / 255.f alpha:1];
        self.pageControl.pageIndicatorTintColor = [UIColor colorWithWhite:1 alpha:0.5];
        self.pageControl.numberOfPages = self.imageCount;
        self.pageControl.currentPage = self.currentIndex;
        [self.view addSubview:self.pageControl];
    }
    
    if (self.imageCount > 0) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView layoutIfNeeded];
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:self.currentIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:NO];
                if (self.fromImageViews[self.currentIndex]) {
                    self.view.userInteractionEnabled = false;
                    [UIView animateWithDuration:0.3 animations:^{
                        self.view.transform = CGAffineTransformIdentity;
                        self.view.center = UIApplication.sharedApplication.keyWindow.center;
                        self.view.maskView.bounds = self.view.bounds;
                        self.view.maskView.center = self.view.center;
                        self.view.maskView.layer.cornerRadius = 0;
                    } completion:^(BOOL finished) {
                        self.view.userInteractionEnabled = true;
                    }];
                }
            });
        });
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([scrollView isEqual:self.collectionView]) {
        NSInteger index = scrollView.contentOffset.x / scrollView.bounds.size.width;
        NSInteger loseWidth = (NSInteger)scrollView.contentOffset.x % (NSInteger)scrollView.bounds.size.width;
        if (loseWidth > scrollView.bounds.size.width / 2) {
            index += 1;
        }
        if (index != self.currentIndex) {
            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:self.currentIndex inSection:0]]];
            self.currentIndex = index;
        }
    }
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    WTImageBrowserCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[WTImageBrowserCollectionViewCell identifier] forIndexPath:indexPath];
    cell.delegate = self;
    [cell reloadCell];
    if (self.setImage) {
        self.setImage(cell.imageView, indexPath.item);
    }
    return cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imageCount;
}

- (void)browserCellTouch {
    
    self.setImage = nil;
    self.longPress = nil;
    if (self.fromImageViews[self.currentIndex]) {
        self.navigationController.navigationBar.hidden = self.navigationBarHidden;
        self.navigationController.interactivePopGestureRecognizer.enabled = self.interactivePopGestureRecognizerEnable;
        CGRect toWindowRect = [self.fromImageViews[self.currentIndex] convertRect:self.fromImageViews[self.currentIndex].bounds toView:UIApplication.sharedApplication.keyWindow];
        CGFloat scaleWidth = self.fromImageViews[self.currentIndex].bounds.size.width;
        if (self.fromImageViews[self.currentIndex].image.size.width > self.fromImageViews[self.currentIndex].image.size.height) {
            scaleWidth = self.fromImageViews[self.currentIndex].image.size.width / self.fromImageViews[self.currentIndex].image.size.height * self.fromImageViews[self.currentIndex].bounds.size.height;
        }
        CGFloat scale = scaleWidth / self.view.bounds.size.width;
        WTImageBrowserCollectionViewCell *cell = (WTImageBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]];
        
        [UIView animateWithDuration:0.3 animations:^{
            cell.scrollView.contentOffset = CGPointMake(0, cell.scrollView.contentSize.height / 2 - cell.scrollView.bounds.size.height / 2);
            cell.scrollView.zoomScale = 1;
            self.view.maskView.bounds = CGRectMake(0, 0, self.view.bounds.size.width * (self.fromImageViews[self.currentIndex].bounds.size.width / scaleWidth), self.fromImageViews[self.currentIndex].bounds.size.height / self.fromImageViews[self.currentIndex].bounds.size.width * self.view.bounds.size.width * (self.fromImageViews[self.currentIndex].bounds.size.width / scaleWidth));
            self.view.maskView.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height / 2);
            self.view.maskView.layer.cornerRadius = self.fromImageViews[self.currentIndex].layer.cornerRadius / self.fromImageViews[self.currentIndex].bounds.size.width * self.view.maskView.bounds.size.width;
            self.view.transform = CGAffineTransformMakeScale(scale, scale);
            self.view.center = CGPointMake(CGRectGetMidX(toWindowRect), CGRectGetMidY(toWindowRect));
        } completion:^(BOOL finished) {
            [self.view removeFromSuperview];
            [self removeFromParentViewController];
        }];
    }
    else if (self.navigationController) {
        self.navigationController.navigationBar.hidden = self.navigationBarHidden;
        self.navigationController.interactivePopGestureRecognizer.enabled = self.interactivePopGestureRecognizerEnable;
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)browserCell:(WTImageBrowserCollectionViewCell *)cell didLongPressWithImage:(UIImage *)image {
    if (self.longPress) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        self.longPress(indexPath.item, image, self);
    }
}

- (void)action_choose {
    WTImageBrowserCollectionViewCell *cell = (WTImageBrowserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.currentIndex inSection:0]];
    !self.chooseImage ?: self.chooseImage(self, self.currentIndex, cell.imageView.image);
}

@end

