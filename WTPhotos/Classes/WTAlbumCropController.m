//
//  WTAlbumCropController.m
//  WTPhotos
//
//  Created by weijiewen on 2020/12/19.
//


#import "WTAlbumCropController.h"

//#import "WTAlbumController+Category.h"


@interface WTAlbumCropController () <UIScrollViewDelegate>
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *cropMaskView;
@property (nonatomic, assign) CGRect cropRect;
@property (nonatomic, strong) UIBezierPath *editPath;
@property (nonatomic, copy) void(^completion)(WTAlbumCropController *controller, UIImage *editImage);

@property (nonatomic, copy) CGRect(^editRect)(CGRect viewRect);
@property (nonatomic, copy) UIBezierPath *(^editPathBlock)(CGSize editSize);
@end
@implementation WTAlbumCropController

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (instancetype)initImage:(UIImage *)image
                 editRect:(nullable CGRect(^)(CGRect viewRect))editRect
                 editPath:(nullable UIBezierPath *(^)(CGSize editSize))editPath
               completion:(void(^)(WTAlbumCropController *controller, UIImage *editImage))completion;
{
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self.image = image;
        self.completion = completion;
        
        self.editRect = editRect;
        self.editPathBlock = editPath;
        
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:true animated:true];
    self.navigationController.interactivePopGestureRecognizer.enabled = false;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:false animated:true];
    self.navigationController.interactivePopGestureRecognizer.enabled = true;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;
    self.view.clipsToBounds = true;
    
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    self.cropRect = self.editRect ? self.editRect(self.view.bounds) : CGRectMake(0, height / 2 - width / 2, width, width);
    self.editPath = self.editPathBlock ? self.editPathBlock(self.cropRect.size) : nil;
    self.editRect = nil;
    self.editPathBlock = nil;
    [self creatUI];
}

- (void)creatUI {
    
    self.contentView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.contentView];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.editPath ? self.cropRect : self.contentView.bounds];
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = MAXFLOAT;
    self.scrollView.delegate = self;
    self.scrollView.showsHorizontalScrollIndicator = false;
    self.scrollView.showsVerticalScrollIndicator = false;
    self.scrollView.bounces = true;
    self.scrollView.clipsToBounds = false;
    [self.contentView addSubview:self.scrollView];
    
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    else {
        self.automaticallyAdjustsScrollViewInsets = false;
    }
    
    UITapGestureRecognizer *twoTouchTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(action_twoTap)];
    twoTouchTap.numberOfTapsRequired = 2;
    twoTouchTap.numberOfTouchesRequired = 1;
    [self.contentView addGestureRecognizer:twoTouchTap];
    
    CGFloat imageHeight = self.scrollView.bounds.size.width / self.image.size.width * self.image.size.height;
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.scrollView.bounds.size.height / 2 - imageHeight / 2, self.scrollView.bounds.size.width, imageHeight)];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.image = self.image;
    [self.scrollView addSubview:self.imageView];
    if (self.editPath && imageHeight < self.cropRect.size.height) {
        CGFloat scale = self.cropRect.size.height / imageHeight;
        self.scrollView.minimumZoomScale = scale;
        [self.scrollView setZoomScale:scale];
    }
    else {
        [self.scrollView setZoomScale:2 animated:false];
        [self.scrollView setZoomScale:1 animated:false];
    }
    if (self.editPath) {
        [self addShadowLayerWithRect:CGRectMake(0, 0, self.view.bounds.size.width, self.cropRect.origin.y)];
        [self addShadowLayerWithRect:CGRectMake(0, CGRectGetMaxY(self.cropRect), self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetMaxY(self.cropRect))];
        [self addCropLayer];
    }
    UIView *navigationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, UIApplication.sharedApplication.statusBarFrame.size.height + 44)];
    navigationView.backgroundColor = [UIColor colorWithRed:37.f / 255.f green:37.f / 255.f blue:37.f / 255.f alpha:1];
    [self.view addSubview:navigationView];
    NSString *cancelText = kWTAlbumTextCancel;
    if ([self.albumDelegate respondsToSelector:@selector(albumWillShowText:)]) {
        cancelText = [self.albumDelegate albumWillShowText:cancelText];
    }
    CGFloat cancelWidth = [cancelText boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16]} context:nil].size.width + 20;
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.frame = CGRectMake(0, navigationView.bounds.size.height - 44, cancelWidth, 44);
    cancelButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [cancelButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [cancelButton setTitle:cancelText forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(action_cancel) forControlEvents:UIControlEventTouchUpInside];
    [navigationView addSubview:cancelButton];
    
    NSString *confirmText = kWTAlbumTextConfirm;
    if ([self.albumDelegate respondsToSelector:@selector(albumWillShowText:)]) {
        confirmText = [self.albumDelegate albumWillShowText:confirmText];
    }
    CGFloat confirmWidth = [confirmText boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16]} context:nil].size.width + 20;
    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    confirmButton.frame = CGRectMake(navigationView.bounds.size.width - confirmWidth, navigationView.bounds.size.height - 44, confirmWidth, 44);
    confirmButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [confirmButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [confirmButton setTitle:confirmText forState:UIControlStateNormal];
    [confirmButton addTarget:self action:@selector(action_sure) forControlEvents:UIControlEventTouchUpInside];
    [navigationView addSubview:confirmButton];

}

- (void)addShadowLayerWithRect:(CGRect)rect {
    CALayer *shadowLayer = CALayer.layer;
    shadowLayer.frame = rect;
    shadowLayer.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6].CGColor;
    [self.view.layer addSublayer:shadowLayer];
}

- (void)addCropLayer {
    UIBezierPath *cropPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.cropRect.size.width, self.cropRect.size.height)];
    [cropPath appendPath:self.editPath];
    cropPath.usesEvenOddFillRule = YES;
    CAShapeLayer *cropLayer = CAShapeLayer.layer;
    cropLayer.frame = self.cropRect;
    cropLayer.path = cropPath.CGPath;
    cropLayer.fillRule = kCAFillRuleEvenOdd;
    cropLayer.fillColor = [UIColor colorWithWhite:0 alpha:0.6].CGColor;
    [self.view.layer addSublayer:cropLayer];
    
    CAShapeLayer *borderLayer = CAShapeLayer.layer;
    borderLayer.frame = cropLayer.frame;
    borderLayer.path = self.editPath.CGPath;
    borderLayer.lineWidth = 1;
    borderLayer.strokeColor = [UIColor colorWithWhite:1 alpha:0.6].CGColor;
    borderLayer.fillColor = UIColor.clearColor.CGColor;
    [self.view.layer addSublayer:borderLayer];
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
        [self.scrollView setZoomScale:1 animated:true];
    }
    else if (1 <= self.scrollView.zoomScale && self.scrollView.zoomScale < 2) {
        [self.scrollView setZoomScale:2 animated:true];
    }
    else {
        [self.scrollView setZoomScale:4 animated:true];
    }
}

- (void)action_cancel {
    self.completion = nil;
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:true];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)action_sure {
    self.view.userInteractionEnabled = false;
    UIImage *image = self.image;
    if (self.editPath) {
        CGRect bounds = self.contentView.bounds;
        CALayer *layer = self.contentView.layer;
        CAShapeLayer *cropLayer = CAShapeLayer.layer;
        cropLayer.frame = self.cropRect;
        cropLayer.fillColor = UIColor.blackColor.CGColor;
        cropLayer.path = self.editPath.CGPath;
        self.contentView.layer.mask = cropLayer;
        
        UIGraphicsBeginImageContextWithOptions(bounds.size, NO, 1);
        [layer renderInContext:UIGraphicsGetCurrentContext()];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, self.cropRect);
        image = [UIImage imageWithCGImage:imageRef scale:1 orientation:UIImageOrientationUp];
        CGImageRelease(imageRef);

        self.contentView.layer.mask = nil;
    }
    !self.completion ?: self.completion(self, image);
    self.completion = nil;
}

@end

