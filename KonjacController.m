/*

File:KonjacController.m

Abstract: Number input controller class.

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
#import "KonjacController.h"
#import "ConversionEngine.h"
#import "KonjacApplicationDelegate.h"


@implementation KonjacController

/*
Implement one of the three ways to receive input from the client. 
Here are the three approaches:
                 
                 1.  Support keybinding.  
                        In this approach the system takes each keydown and trys to map the keydown to an action method that the input method has implemented.  If an action is found the system calls didCommandBySelector:client:.  If no action method is found inputText:client: is called.  An input method choosing this approach should implement
                        -(BOOL)inputText:(NSString*)string client:(id)sender;
                        -(BOOL)didCommandBySelector:(SEL)aSelector client:(id)sender;
                        
                2. Receive all key events without the keybinding, but do "unpack" the relevant text data.
                        Key events are broken down into the Unicodes, the key code that generated them, and modifier flags.  This data is then sent to the input method's inputText:key:modifiers:client: method.  For this approach implement:
                        -(BOOL)inputText:(NSString*)string key:(NSInteger)keyCode modifiers:(NSUInteger)flags client:(id)sender;
                        
                3. Receive events directly from the Text Services Manager as NSEvent objects.  For this approach implement:
                        -(BOOL)handleEvent:(NSEvent*)event client:(id)sender;
*/

/*!
	@method     
    @abstract   Receive incoming text.
	@discussion This method receives key board input from the client application.  The method receives the key input as an NSString. The string will have been created from the keydown event by the InputMethodKit.
*/
-(BOOL)inputText:(NSString*)string client:(id)sender
{
		BOOL					inputHandled = NO;
		if (! [string isEqualToString:@"."] ) {
			[self originalBufferAppend:string client:sender];
			inputHandled = YES;
		}
		else {
			inputHandled = [self convert:string client:sender];
		}
        return inputHandled;
}

/*!
    @method     
    @abstract   Called when a user action was taken that ends an input session.   Typically triggered by the user selecting a new input method or keyboard layout.
    @discussion When this method is called your controller should send the current input buffer to the client via a call to insertText:replacementRange:.  Additionally, this is the time to clean up if that is necessary.
*/

-(void)commitComposition:(id)sender 
{
	NSString*		text = [self composedBuffer];

	if ( text == nil || [text length] == 0 ) {
		text = [self originalBuffer];
	}
	
	[sender insertText:text replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
	
	[self setComposedBuffer:@""];
	[self setOriginalBuffer:@""];
	_insertionIndex = 0;
	_didConvert = NO;
}

// Return the composed buffer.  If it is NIL create it.  
-(NSMutableString*)composedBuffer;
{
	if ( _composedBuffer == nil ) {
		_composedBuffer = [[NSMutableString alloc] init];
	}
	return _composedBuffer;
}

// Change the composed buffer.
-(void)setComposedBuffer:(NSString*)string
{
	NSMutableString*		buffer = [self composedBuffer];
	[buffer setString:string];
}


// Get the original buffer.
-(NSMutableString*)originalBuffer
{
	if ( _originalBuffer == nil ) {
		_originalBuffer = [[NSMutableString alloc] init];
	}
	return _originalBuffer;
}

// Add newly input text to the original buffer.
-(void)originalBufferAppend:(NSString*)string client:(id)sender
{
	NSMutableString*		buffer = [self originalBuffer];
	[buffer appendString: string];
	_insertionIndex++;
	[sender setMarkedText:buffer selectionRange:NSMakeRange(0, [buffer length]) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
}

// Change the original buffer.
-(void)setOriginalBuffer:(NSString*)string
{
	NSMutableString*		buffer = [self originalBuffer];
	[buffer setString:string];
}

// This method is called to see if your input method handles an NSResponder action.
-(BOOL)didCommandBySelector:(SEL)aSelector client:(id)sender
{
    if ([self respondsToSelector:aSelector]) {
		// The NSResponder methods like insertNewline: or deleteBackward: are
		// methods that return void. didCommandBySelector method requires
		// that you return YES if the command is handled and NO if you do not. 
		// This is necessary so that unhandled commands can be passed on to the
		// client application. For that reason we need to test in the case where
		// we might not handle the command.
		
		// The test here is simple.  Test to see if any text has been aded to the original buffer.
		NSString*		bufferedText = [self originalBuffer];
		
		if ( bufferedText && [bufferedText length] > 0 ) {
			if (aSelector == @selector(insertNewline:) ||
				aSelector == @selector(deleteBackward:) ) {
					[self performSelector:aSelector withObject:sender];
					return YES; 
			}
		}
		
    }
	
	return NO;
}

// When a new line is input we commit the composition.
- (void)insertNewline:(id)sender
{
	[self commitComposition:sender];
	
}

// If backspace is entered remove the preceding character and update the marked text.
- (void)deleteBackward:(id)sender
{
	NSMutableString*		originalText = [self originalBuffer];
	NSString*				convertedString;

	if ( _insertionIndex > 0 && _insertionIndex <= [originalText length] ) {
		--_insertionIndex;
		[originalText deleteCharactersInRange:NSMakeRange(_insertionIndex,1)];
		convertedString = [[[NSApp delegate] conversionEngine] convert:originalText];
		[self setComposedBuffer:convertedString];
		[sender setMarkedText:convertedString selectionRange:NSMakeRange(_insertionIndex, 0) replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
	}
}

// This method converts buffered text based on the trigger string.  If we did convert the text previously insert the converted text with
// the trigger string appended to the converted text.  
// If we have not done a previous conversion check to see if the input string is a space.  If it is convert the text mark it in the client, and remember that we did do a conversion.
// If the input text is not a string.  Commit the composition, and then insert the input string.
- (BOOL)convert:(NSString*)trigger client:(id)sender
{
	NSString*				originalText = [self originalBuffer];
	NSString*				convertedString = [self composedBuffer];
	BOOL					handled = NO;
	
	if ( _didConvert && convertedString && [convertedString length] > 0  ) {
		
		
			NSString*		completeString = [convertedString stringByAppendingString:trigger];
			[sender insertText:completeString replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
			
			[self setComposedBuffer:@""];
			[self setOriginalBuffer:@""];
			_insertionIndex = 0;
			_didConvert = NO;
			handled = YES;

	}
	else if ( originalText && [originalText length] > 0 ) {
		
			convertedString = [[[NSApp delegate] conversionEngine] convert:originalText];
			[self setComposedBuffer:convertedString];
			
			if ( [trigger isEqual: @" "] ) {
				[sender setMarkedText:convertedString selectionRange:NSMakeRange(_insertionIndex, 0) replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
				_didConvert = YES;
			}
			else {
				[self commitComposition:sender];
				[sender insertText:trigger replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
			}
			handled = YES;
	}
	return handled;
}

//This method is called by the InputMethodKit when the user as selected a new input mode from the text input menu.
-(void)setValue:(id)value forTag:(unsigned long)tag client:(id)sender
{
	NSString*		newModeString = [(NSString*)value retain];
	NSString*   	currentMode = [[[NSApp delegate] conversionEngine] translateMode];
    NSString *newMode;
	
	if ( [newModeString isEqual:kDecimalMode] ) {
		newMode = k_en_ja;
	}
	else if ( [newModeString isEqual:kCurrencyMode] ) {
		newMode = k_en_fr;
	}
	
	if ( currentMode != newMode ) {
		[[[NSApp delegate] conversionEngine] setTranslateMode:newMode];
	}
}

-(void)dealloc 
{
	[_composedBuffer release];
	[_originalBuffer release];
	[super dealloc];
}

 
@end
