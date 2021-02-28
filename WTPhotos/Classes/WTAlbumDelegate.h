//
//  WTAlbumDelegate.h
//  Pods
//
//  Created by weijiewen on 2021/2/28.
//

#ifndef WTAlbumDelegate_h
#define WTAlbumDelegate_h

typedef NSString * WTAlbumText;

static WTAlbumText const kWTAlbumTextCancel             = @"取消";
static WTAlbumText const kWTAlbumTextConfirm            = @"确定";
static WTAlbumText const kWTAlbumTextPreview            = @"预览";
static WTAlbumText const kWTAlbumTextNoAuthorization    = @"未授权相册权限";
static WTAlbumText const kWTAlbumTextGoAuthorization    = @"前往授权";
static WTAlbumText const kWTAlbumTextAuthorizationMore  = @"授权更多";


@protocol WTAlbumControllerDelegate <NSObject>
@required
@optional
- (NSString *)albumWillShowText:(WTAlbumText)text;
@end

#endif /* WTAlbumDelegate_h */
