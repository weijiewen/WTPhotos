//
//  WTAlbumController+Configuration.m
//  WTPhotos
//
//  Created by weijiewen on 2020/12/13.
//

#import <objc/runtime.h>

#import "WTAlbumController+Configuration.h"

@implementation WTAlbumConfiguration

- (instancetype)initWithAllTypeMaxCount:(NSUInteger)allTypeMaxCount {
    if (allTypeMaxCount == 0) {
        allTypeMaxCount = 1;
    }
    return [self initWithType:WTAlbumConfigurationTypeImageAndVideo
              allTypeMaxCount:allTypeMaxCount
                imageMaxCount:0
                videoMaxCount:0];
}

- (instancetype)initWithImageMaxCount:(NSUInteger)imageMaxCount {
    if (imageMaxCount == 0) {
        imageMaxCount = 1;
    }
    return [self initWithType:WTAlbumConfigurationTypeOnlyImage
              allTypeMaxCount:0
                imageMaxCount:imageMaxCount
                videoMaxCount:0];
}

- (instancetype)initWithVideoMaxCount:(NSUInteger)videoMaxCount {
    if (videoMaxCount == 0) {
        videoMaxCount = 1;
    }
    return [self initWithType:WTAlbumConfigurationTypeOnlyVideo
              allTypeMaxCount:0
                imageMaxCount:0
                videoMaxCount:videoMaxCount];
}

- (instancetype)initWithImageMaxCount:(NSUInteger)imageMaxCount
                        videoMaxCount:(NSUInteger)videoMaxCount {
    WTAlbumConfigurationPickType type;
    if (imageMaxCount == 0 && videoMaxCount == 0) {
        imageMaxCount = 1;
        type = WTAlbumConfigurationTypeOnlyImage;
    }
    else if (imageMaxCount == 0) {
        type = WTAlbumConfigurationTypeOnlyVideo;
    }
    else if (videoMaxCount == 0) {
        type = WTAlbumConfigurationTypeOnlyImage;
    }
    else {
        type = WTAlbumConfigurationTypeImageCountAndVideoCount;
    }
    return [self initWithType:type
              allTypeMaxCount:0
                imageMaxCount:imageMaxCount
                videoMaxCount:videoMaxCount];
}

- (instancetype)initCountBetweenImageMaxCount:(NSUInteger)imageMaxCount
                                VideoMaxCount:(NSUInteger)videoMaxCount
{
    WTAlbumConfigurationPickType type;
    if (imageMaxCount == 0 && videoMaxCount == 0) {
        imageMaxCount = 1;
        type = WTAlbumConfigurationTypeOnlyImage;
    }
    else if (imageMaxCount == 0) {
        type = WTAlbumConfigurationTypeOnlyVideo;
    }
    else if (videoMaxCount == 0) {
        type = WTAlbumConfigurationTypeOnlyImage;
    }
    else {
        type = WTAlbumConfigurationTypeImageOrVideo;
    }
    return [self initWithType:type
              allTypeMaxCount:0
                imageMaxCount:imageMaxCount
                videoMaxCount:videoMaxCount];
}

- (void)loadBlockSelectedDatas:(void(^)(NSArray <WTAssetData *> *datas))selectedDatas
                      editRect:(nullable CGRect(^)(CGRect viewRect))editRect
                      editPath:(nullable UIBezierPath *(^)(CGSize editSize))editPath {
    self.selectedDatas = selectedDatas;
    self.editRect = editRect;
    self.editPath = editPath;
}

- (void)clearBlack {
    self.selectedDatas = nil;
    self.editRect = nil;
    self.editPath = nil;
}

- (instancetype)initWithType:(WTAlbumConfigurationPickType)pickType allTypeMaxCount:(NSUInteger)allTypeMaxCount imageMaxCount:(NSUInteger)imageMaxCount videoMaxCount:(NSUInteger)videoMaxCount
{
    self = [super init];
    if (self) {
        self.pickType = pickType;
        self.allTypeMaxCount = (NSUInteger)abs((int)allTypeMaxCount);
        self.imageMaxCount = (NSUInteger)abs((int)imageMaxCount);
        self.videoMaxCount = (NSUInteger)abs((int)videoMaxCount);
    }
    return self;
}

@end

@implementation WTAlbumController (Configuration)

- (void)setConfiguration:(WTAlbumConfiguration *)configuration {
    objc_setAssociatedObject(self, @selector(configuration), configuration, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (WTAlbumConfiguration *)configuration {
    return objc_getAssociatedObject(self, _cmd);
}

@end
