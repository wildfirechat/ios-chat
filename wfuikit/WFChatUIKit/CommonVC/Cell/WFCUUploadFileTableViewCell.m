//
//  WFCUUploadFileTableViewCell.m
//  WFChatUIKit
//
//  Created by heavyrain.lee on 2021/3/6.
//  Copyright © 2021 Wildfire Chat. All rights reserved.
//

#import "WFCUUploadFileTableViewCell.h"
#import "WFCUUploadBigFilesViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import "WFCUUtilities.h"


@interface WFCUUploadFileTableViewCell ()
@property(nonatomic, strong)UIImageView *fileTypeImageView;
@property(nonatomic, strong)UILabel *fileTitleLabel;
@property(nonatomic, strong)UILabel *fileSizeLabel;
@property(nonatomic, strong)UIProgressView *uploadProgressView;
@property(nonatomic, strong)UILabel *fileStateLabel;
@property(nonatomic, strong)UIButton *fileActionButton;
@end

#define SIZE_WIDTH 60
#define BUTTON_WIDTH 80

@implementation WFCUUploadFileTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (void)updateUI {
    WFCCFileMessageContent *fileContent = self.bigFileModel.bigFileContent;
    NSString *ext = [[fileContent.name pathExtension] lowercaseString];
    
    self.fileTypeImageView.image = [WFCUUtilities imageForExt:ext];
    self.fileTitleLabel.text = fileContent.name;
    self.fileSizeLabel.text = [WFCUUtilities formatSizeLable:fileContent.size];
    
    self.fileStateLabel.hidden = NO;
    self.uploadProgressView.hidden = YES;
    if(self.bigFileModel.state == 0) {
        self.fileStateLabel.text = @"请先点击上传按钮上传文件";
        [self.fileActionButton setTitle:@"上传" forState:UIControlStateNormal];
        [self.fileActionButton setBackgroundColor:[UIColor grayColor]];
    } else if(self.bigFileModel.state == 1) {
        self.fileStateLabel.hidden = YES;
        self.uploadProgressView.hidden = NO;
        self.uploadProgressView.progress = self.bigFileModel.uploadProgress;
        [self.fileActionButton setTitle:@"取消" forState:UIControlStateNormal];
        [self.fileActionButton setBackgroundColor:[UIColor redColor]];
    } else if(self.bigFileModel.state == 2) {
        self.fileStateLabel.text = @"上传成功";
        [self.fileActionButton setTitle:@"发送" forState:UIControlStateNormal];
        [self.fileActionButton setBackgroundColor:[UIColor greenColor]];
    } else if(self.bigFileModel.state == 3) {
        self.fileStateLabel.text = @"已取消";
        [self.fileActionButton setTitle:@"重新上传" forState:UIControlStateNormal];
        [self.fileActionButton setBackgroundColor:[UIColor redColor]];
    } else if(self.bigFileModel.state == 4) {
        self.fileStateLabel.text = @"网络错误，上传失败";
        [self.fileActionButton setTitle:@"重新上传" forState:UIControlStateNormal];
        [self.fileActionButton setBackgroundColor:[UIColor grayColor]];
    } else if(self.bigFileModel.state == 5) {
        self.fileStateLabel.text = @"消息已发送";
        [self.fileActionButton setTitle:@"已发送" forState:UIControlStateDisabled];
        [self.fileActionButton setBackgroundColor:[UIColor grayColor]];
        self.fileActionButton.enabled = NO;
    }
}

-(void)setBigFileModel:(WFCUUploadFileModel *)bigFileModel {
    if(_bigFileModel) {
        [self.bigFileModel removeObserver:self forKeyPath:@"state"];
        [self.bigFileModel removeObserver:self forKeyPath:@"uploadProgress"];
    }
    
    _bigFileModel = bigFileModel;
    
    [self.bigFileModel addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
    [self.bigFileModel addObserver:self forKeyPath:@"uploadProgress" options:NSKeyValueObservingOptionNew context:nil];
    [self updateUI];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    [self updateUI];
}

- (void)didTapActionBtn:(id)sender {
    if(self.bigFileModel.state == 0) {
        [self.delegate didTapUpload:self model:self.bigFileModel];
    } else if(self.bigFileModel.state == 1) {
        [self.delegate didTapCancelUpload:self model:self.bigFileModel];
    } else if(self.bigFileModel.state == 2) {
        [self.delegate didTapSend:self model:self.bigFileModel];
    } else if(self.bigFileModel.state == 3) {
        [self.delegate didTapUpload:self model:self.bigFileModel];
    } else if(self.bigFileModel.state == 4) {
        [self.delegate didTapForward:self model:self.bigFileModel];
    }
}

- (UIImageView *)fileTypeImageView {
    if(!_fileTypeImageView) {
        _fileTypeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 48, 48)];
        [self.contentView addSubview:_fileTypeImageView];
    }
    return _fileTypeImageView;
}

- (UILabel *)fileTitleLabel {
    if(!_fileTitleLabel) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _fileTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 8, width - 64 - BUTTON_WIDTH, 32)];
        [self.contentView addSubview:_fileTitleLabel];
    }
    return _fileTitleLabel;
}

-(UILabel *)fileSizeLabel {
    if(!_fileSizeLabel) {
        _fileSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(64, 40, SIZE_WIDTH, 16)];
        _fileSizeLabel.font = [UIFont systemFontOfSize:12];
        _fileSizeLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:_fileSizeLabel];
    }
    return _fileSizeLabel;
}

-(UILabel *)fileStateLabel {
    if(!_fileStateLabel) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _fileStateLabel = [[UILabel alloc] initWithFrame:CGRectMake(64+SIZE_WIDTH+8, 40, width - (64+SIZE_WIDTH+8) - BUTTON_WIDTH, 16)];
        _fileStateLabel.font = [UIFont systemFontOfSize:12];
        _fileStateLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:_fileStateLabel];
    }
    return _fileStateLabel;
}

-(UIProgressView *)uploadProgressView {
    if(!_uploadProgressView) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _uploadProgressView = [[UIProgressView alloc] initWithFrame:CGRectMake(64+SIZE_WIDTH+8, 46, width - (64+SIZE_WIDTH+8) - BUTTON_WIDTH, 4)];
        _uploadProgressView.progress = 0;
        [self.contentView addSubview:_uploadProgressView];
    }
    return _uploadProgressView;
}

- (UIButton *)fileActionButton {
    if(!_fileActionButton) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _fileActionButton = [[UIButton alloc] initWithFrame:CGRectMake(width - BUTTON_WIDTH + 8, 18, BUTTON_WIDTH - 16, 32)];
        [_fileActionButton addTarget:self action:@selector(didTapActionBtn:) forControlEvents:UIControlEventTouchUpInside];
        [_fileActionButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        _fileActionButton.layer.cornerRadius = 5.f;
        _fileActionButton.layer.masksToBounds = YES;
        [self.contentView addSubview:_fileActionButton];
    }
    return _fileActionButton;
}
-(void)dealloc {
    [self.bigFileModel removeObserver:self forKeyPath:@"state"];
    [self.bigFileModel removeObserver:self forKeyPath:@"uploadProgress"];
}
@end
