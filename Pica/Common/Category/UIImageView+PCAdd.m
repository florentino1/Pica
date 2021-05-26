//
//  UIImageView+PCAdd.m
//  Pica
//
//  Created by fancy on 2020/11/9.
//  Copyright © 2020 fancy. All rights reserved.
//

#import "UIImageView+PCAdd.h"
#import <QMUIKit/QMUIKit.h>
#import <SDWebImage/SDWebImage.h>

@implementation UIImageView (PCAdd)

static char kAssociatedObjectKey_PC_noFadeAnimation;

- (void)setPc_noFadeAnimation:(BOOL)pc_noFadeAnimation {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_PC_noFadeAnimation, @(pc_noFadeAnimation), OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)pc_noFadeAnimation {
    return [objc_getAssociatedObject(self, &kAssociatedObjectKey_PC_noFadeAnimation) boolValue];
}

- (void)pc_setImageWithURL:(NSString *)url {
    [self pc_setImageWithURL:url
            placeholderImage:[UIImage qmui_imageWithColor:UIColorMake(255, 192, 203)]
                   completed:nil];
}

- (void)pc_setImageWithURL:(NSString *)url
          placeholderImage:(UIImage *)placeholderImage {
    [self pc_setImageWithURL:url placeholderImage:placeholderImage completed:nil];
}

- (void)pc_setImageWithURL:(NSString *)url
                  completed:(void (^)(UIImage *image, NSError *error))completed {
    [self pc_setImageWithURL:url
            placeholderImage:[UIImage qmui_imageWithColor:UIColorMake(255, 192, 203)]
                   completed:completed];
}

- (void)pc_setImageWithURL:(NSString *)url
          placeholderImage:(UIImage *)placeholderImage
                 completed:(void (^)(UIImage *image, NSError *error))completed {
    [self pc_setImageWithURL:url
            placeholderImage:placeholderImage
                    progress:nil
                   completed:completed];
}

- (void)pc_setImageWithURL:(NSString *)url
          placeholderImage:(UIImage *)placeholderImage
                  progress:(void (^)(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL))progress
                 completed:(void (^)(UIImage *image, NSError *error))completed {
    NSURL *imageUrl = [NSURL URLWithString:url];

    [self sd_setImageWithURL:imageUrl
            placeholderImage:placeholderImage
                     options:0
                    progress:progress
                   completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
    
                        if (!image && error && error.code != SDWebImageErrorCancelled) {
                             
                        }
                    
                        !completed ? : completed(image, error);
                        if (image && !self.pc_noFadeAnimation) {
                            BOOL showed = [image qmui_getBoundObjectForKey:@"kFadeAnimation"];
                            if (!showed) {
                                CATransition *animation       = [CATransition animation];
                                animation.duration            = 0.5;
                                animation.timingFunction      = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                                animation.type                = kCATransitionFade;
                                animation.removedOnCompletion = YES;
                                [self.layer addAnimation:animation forKey:kCATransition];
                                [image qmui_bindBOOL:YES forKey:@"kFadeAnimation"];
                            }
                        }
    }];
}

@end
