//
//  DNAlbum.m
//  DNImagePicker
//
//  Created by Ding Xiao on 16/7/6.
//  Copyright © 2016年 Dennis. All rights reserved.
//

#import <Photos/Photos.h>
#import "DNAlbum.h"
#import "DNImagePickerHelper.h"
#import "DNAsset.h"

@interface DNAlbum ()
@property (nonatomic, strong) NSAttributedString *albumAttributedString;
@end

@implementation DNAlbum

- (instancetype)init {
    self = [super init];
    if (self) {
        _albumTitle = @"";
        _identifier = @"";
        _count = 0;
    }
    return self;
}

+ (DNAlbum *)albumWithAssetCollection:(PHAssetCollection *)collection results:(PHFetchResult *)results{
    DNAlbum *album = [[DNAlbum alloc] init];
    if (!collection || !results) {
        return album;
    }
    album.count = results.count;
    album.results = results;
    album.albumTitle = collection.localizedTitle;
    album.identifier = collection.localIdentifier;
    return album;
}

- (void)fetchPostImageWithSize:(CGSize)size
             imageResutHandler:(void (^)(UIImage *))handler {
    [DNImagePickerHelper fetchImageWithAsset:[DNAsset assetWithPHAsset:self.results.lastObject]
                                  targetSize:size
                           imageResutHandler:^(UIImage *postImage) {
                               handler(postImage);
                           }];
}

- (NSAttributedString *)albumAttributedString {
    if (!_albumAttributedString) {
        NSString *numberString = [NSString stringWithFormat:@"  (%@)",@(self.count)];
        NSString *cellTitleString = [NSString stringWithFormat:@"%@%@",self.albumTitle,numberString];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:cellTitleString];
        [attributedString setAttributes: @{
                                           NSFontAttributeName : [UIFont systemFontOfSize:16.0f],
                                           NSForegroundColorAttributeName : [UIColor blackColor],
                                           }
                                  range:NSMakeRange(0, self.albumTitle.length)];
        [attributedString setAttributes:@{
                                          NSFontAttributeName : [UIFont systemFontOfSize:16.0f],
                                          NSForegroundColorAttributeName : [UIColor grayColor],
                                          } range:NSMakeRange(self.albumTitle.length, numberString.length)];
        _albumAttributedString = attributedString;
    }
    return _albumAttributedString;
}

@end
