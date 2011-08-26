/*

File:ConversionEngine.m

Abstract: A simple conversion engine.  This converts number strings into one of the formats supported by NSNumberFormatter.

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
Apple Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Inc. 
may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2007 Apple Inc. All Rights Reserved.

*/
#import "ConversionEngine.h"
#import "Private.h"

#if !(defined(k_api_key) || defined(k_bing_api_key))
#error "Store your Google API key in Private.h"
#endif

@implementation ConversionEngine

-(void)awakeFromNib
{
    [self setTranslateMode:k_en_ja];
}

-(NSString*)convert:(NSString*)string
{
    // Using Google Translate API
    if ([translateMode isEqualToString:k_en_ja] || [translateMode isEqualToString:k_en_fr]) {
        NSString *src = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        src = [NSString stringWithFormat:@"http://api.microsofttranslator.com/v2/Http.svc/Translate?appId=%@&text=%@&from=en&to=ja", k_bing_api_key, src];
        NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:src]];
        NSURLResponse *res = nil;
        NSError *err = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
        NSString *ret = @"";
        if (err != nil)
            return ret;
        
        NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSRange match = [jsonString rangeOfString:@"translatedText.*\n" options:NSRegularExpressionSearch];
        if (match.location != NSNotFound) {
            NSString *line = [jsonString substringWithRange:match];
            line = [line stringByReplacingOccurrencesOfString:@"translatedText\": \"" withString:@""];
            line = [line stringByReplacingOccurrencesOfString:@"\"\n" withString:@""];
            ret = [line copy];
        }
        [jsonString release];
        return ret;
    }

    // Using Bing Translate API
    if ([translateMode isEqualToString:k_bing_en_ja]) {
        NSString *src = [string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        src = [NSString stringWithFormat:@"http://api.microsofttranslator.com/v2/Http.svc/Translate?appId=%@&text=%@&from=en&to=ja", k_bing_api_key, src];
        NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:src]];
        NSURLResponse *res = nil;
        NSError *err = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&res error:&err];
        NSString *ret = @"";
        if (err != nil)
            return ret;

        NSString *xmlString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSString *result = [xmlString stringByReplacingOccurrencesOfString:@"<string xmlns=\"http://schemas.microsoft.com/2003/10/Serialization/\">" withString:@""];
        result = [result stringByReplacingOccurrencesOfString:@"</string>" withString:@""];
        ret = [result copy];
        [xmlString release];

        return ret;
    }

    return @"";
}

-(NSString *)translateMode
{
    return translateMode;
}

-(void)setTranslateMode:(NSString *)mode;
{
	translateMode = mode;
}

@end