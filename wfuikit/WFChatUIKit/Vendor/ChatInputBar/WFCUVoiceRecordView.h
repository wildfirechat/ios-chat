
#import <UIKit/UIKit.h>

typedef enum{
    VoiceRecordViewTypeTouchDown,
    VoiceRecordViewTypeTouchUpInside,
    VoiceRecordViewTypeTouchUpOutside,
    VoiceRecordViewTypeDragInside,
    VoiceRecordViewTypeDragOutside,
}VoiceRecordViewType;

@interface WFCUVoiceRecordView : UIView

@property (nonatomic) NSArray *voiceMessageAnimationImages UI_APPEARANCE_SELECTOR;

@property (nonatomic) NSString *upCancelText UI_APPEARANCE_SELECTOR;

@property (nonatomic) NSString *loosenCancelText UI_APPEARANCE_SELECTOR;

-(void)setCountdown:(int)countdown;
-(void)setVoiceImage:(double)voiceMeter;

-(void)recordButtonTouchDown;
-(void)recordButtonTouchUpInside;
-(void)recordButtonTouchUpOutside;
-(void)recordButtonDragInside;
-(void)recordButtonDragOutside;
@end
