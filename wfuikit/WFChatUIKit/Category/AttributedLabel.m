//
//  AttributedLabel.m
//  WildFireChat
//
//  Created by heavyrain.lee on 2018/5/15.
//  Copyright © 2018 WildFireChat. All rights reserved.
//

#import "AttributedLabel.h"
#import <CoreText/CoreText.h>


@interface AttributedLabel()
@property(nonatomic, strong)NSMutableArray *stringArray;
@property(nonatomic, strong)NSMutableArray *rangeArray;
@end

@implementation AttributedLabel
- (void)setText:(NSString *)text {
    self.attributedText = [self subStr:text];
    self.userInteractionEnabled = YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    NSUInteger index = [self characterIndexAtPoint:[touch locationInView:self]];
    for(NSValue *value in self.rangeArray) {
        
        NSRange range=[value rangeValue];
        if (range.location <= index && (range.location+range.length) >= index) {
            NSInteger i=[self.rangeArray indexOfObject:value];
            NSString *str = self.stringArray[i];
            NSLog(@"touch url %@", str);
            
            NSString *pattern =@"[0-9]{5,12}";
            
            
            NSPredicate*pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",pattern];
            
            BOOL isNumber = [pred evaluateWithObject:str];
            
            if (isNumber) {
                if ([self.attributedLabelDelegate respondsToSelector:@selector(didSelectPhoneNumber:)]) {
                    [self.attributedLabelDelegate didSelectPhoneNumber:str];
                }
            } else {
                if ([self.attributedLabelDelegate respondsToSelector:@selector(didSelectUrl:)]) {
                    [self.attributedLabelDelegate didSelectUrl:str];
                }
            }
        }
    }
    [super touchesBegan:touches withEvent:event];
}


-(NSMutableAttributedString*)subStr:(NSString *)string {
    if (!string) {
        return nil;
    }
    NSError *error;
    
    //可以识别url的正则表达式
    NSString *regulaStr = @"((http[s]{0,1}|ftp)://[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)|(www.[a-zA-Z0-9\\.\\-]+\\.([a-zA-Z]{2,4})(:\\d+)?(/[a-zA-Z0-9\\.\\-~!@#$%^&*+?:_/=<>]*)?)";
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regulaStr
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    
    NSArray *arrayOfAllMatches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    NSMutableArray *arr=[[NSMutableArray alloc]init];
    NSMutableArray *rangeArr=[[NSMutableArray alloc]init];

    self.stringArray = arr;
    self.rangeArray = rangeArr;
    
    for (NSTextCheckingResult *match in arrayOfAllMatches) {
        NSString* substringForMatch;
        substringForMatch = [string substringWithRange:match.range];
        [arr addObject:substringForMatch];
    }
    
    NSString *subStr=string;
    for (NSString *str in arr) {
        [rangeArr addObject:[self rangesOfString:str inString:subStr]];
    }
    
    NSString *pattern =@"[0-9]{5,11}";
    regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                      options:NSRegularExpressionCaseInsensitive
                                                        error:&error];
    
    arrayOfAllMatches = [regex matchesInString:string options:0 range:NSMakeRange(0, [string length])];
    
    NSMutableArray *telArr = [[NSMutableArray alloc] init];
    for (NSTextCheckingResult *match in arrayOfAllMatches) {
        NSString* substringForMatch;
        substringForMatch = [string substringWithRange:match.range];
        [arr addObject:substringForMatch];
        [telArr addObject:substringForMatch];
    }
    
    subStr=string;
    for (NSString *str in telArr) {
        [rangeArr addObject:[self rangesOfString:str inString:subStr]];
    }
    
    
    NSMutableAttributedString *attributedText;
    attributedText=[[NSMutableAttributedString alloc]initWithString:subStr attributes:@{NSFontAttributeName :self.font}];
    
    for(NSValue *value in rangeArr) {
        NSInteger index=[rangeArr indexOfObject:value];
        NSRange range=[value rangeValue];
        [attributedText addAttribute:NSLinkAttributeName value:[NSURL URLWithString:[[arr objectAtIndex:index] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]] range:range];
        [attributedText addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:range];
    }
    
    return attributedText;
}

//获取查找字符串在母串中的NSRange
- (NSValue *)rangesOfString:(NSString *)searchString inString:(NSString *)str {
    NSRange searchRange = NSMakeRange(0, [str length]);
    NSRange range;

    if ((range = [str rangeOfString:searchString options:0 range:searchRange]).location != NSNotFound) {
        searchRange = NSMakeRange(NSMaxRange(range), [str length] - NSMaxRange(range));
    }
    return [NSValue valueWithRange:range];
}

- (NSUInteger)characterIndexAtPoint:(CGPoint)location {
    NSMutableAttributedString* attributedString = [self.attributedText mutableCopy];

    NSString *text = self.text;
    UIFont *font = self.font;
    if (!text || !font) return NSNotFound;
  
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
    CGSize constraintSize = CGSizeMake(self.bounds.size.width, CGFLOAT_MAX);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), CGPathCreateWithRect(CGRectMake(0, 0, constraintSize.width, CGFLOAT_MAX), NULL), NULL);
  
    CFRelease(framesetter);
  
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithSize:constraintSize];
    textContainer.lineFragmentPadding = 0.0;
    textContainer.lineBreakMode = self.lineBreakMode;
    textContainer.maximumNumberOfLines = self.numberOfLines;
    [layoutManager addTextContainer:textContainer];
  
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:attributedString];
    [textStorage addLayoutManager:layoutManager];

    CGFloat xOffset = location.x;
    CGFloat yOffset = location.y;
    NSRange glyphRange;
    CGFloat partialFraction;
    NSUInteger charIndex = [layoutManager characterIndexForPoint:CGPointMake(xOffset, yOffset) inTextContainer:textContainer fractionOfDistanceBetweenInsertionPoints:&partialFraction];
    
    CFRelease(frame);
    
    return partialFraction==1?NSNotFound:charIndex;
}
@end
