//
//  ColorLabelButton.m
//  Color Label Button
//
//  Created by Tony Arnold on 20/12/06.
//  Some rights reserved: <http://creativecommons.org/licenses/by/2.5/>
//

#import "ColorLabelButton.h"
#import "MemoryManagementMacros.h"

@interface ColorLabelButton (Private)
- (void) resetColorLabels: (NSArray*) colors; 
- (void) resetTrackingRects;
@end

@implementation ColorLabelButton
+ (void)initialize 
{ 
  [self exposeBinding: @"selectedColorLabel"]; 
  [self exposeBinding: @"displaysClearButton"];
}

#pragma mark -
#pragma mark Lifetime 
- (id) initWithFrame: (NSRect) frame {
	if (self = [super initWithFrame: frame]) {
		[self bootstrapView];
    [self setDisplaysClearButton: YES]; 
		return self; 
	}
	
	return nil;
}

- (void) bootstrapView {
  // attributes 
  NSArray* colors = [NSArray arrayWithObjects: 
    [NSColor redColor], 
    [NSColor orangeColor],
    [NSColor yellowColor],
    [NSColor greenColor], 
    [NSColor blueColor],
    [NSColor magentaColor],
    [NSColor grayColor],
    nil];
  
		mTrackingRects = [[NSMutableArray alloc] init]; 
		
		// create matrix 
		NSSize cellSpacing = NSMakeSize(2, 2); 
		
		// create the cell matrix 
		NSRect labelFrame = [self frame]; 
    labelFrame.origin = NSZeroPoint; 
		mColorLabels = [[NSMatrix alloc] initWithFrame: labelFrame]; 
		
		[mColorLabels setCellClass: [ColorLabelButtonCell class]]; 
		[mColorLabels setIntercellSpacing: cellSpacing]; 
		[mColorLabels setMode: NSRadioModeMatrix];
		[mColorLabels setAllowsEmptySelection: NO]; 
		[mColorLabels setSelectionByRect: NO];  
		[mColorLabels setTarget: self];
    [mColorLabels setAction: @selector(doAction:)];
    
		[self addSubview: mColorLabels];
    [self setColorLabels: colors];
}

- (void) doAction: (id) sender {
  [self setSelectedColorLabel: [[sender selectedCell] color]];
}

- (void) dealloc {
	// remove all tracking rects 
	while ([mTrackingRects count] > 0) 
		[self removeTrackingRect: [[mTrackingRects objectAtIndex: 0] intValue]]; 
	[mTrackingRects removeAllObjects];
  
  MMM_RELEASE(mTrackingRects);
  MMM_RELEASE(mColorLabels);
  MMM_RELEASE(mColorLabelColor);
  
	// delegate to super
	[super dealloc]; 
}

#pragma mark -
#pragma mark Coders 

- (id)initWithCoder:(NSCoder *)coder
{
  if (self = [super initWithCoder:coder]) {
    [self registerForDraggedTypes: [NSArray arrayWithObject: NSStringPboardType]];
    
    [self bootstrapView];
    if ([coder respondsToSelector:@selector(allowsKeyedCoding)]
        && [coder allowsKeyedCoding]) {
      [self setSelectedColorLabel: [coder decodeObjectForKey: @"selectedColorLabel"]];
      [self setDisplaysClearButton: [coder decodeBoolForKey: @"displaysClearButton"]];
    } else {
      [self setSelectedColorLabel: [coder decodeObject]];
      BOOL mTmpDisplaysClearButton = NO;
      [coder decodeValueOfObjCType: @encode(BOOL)
                                at: &mTmpDisplaysClearButton];
      [self setDisplaysClearButton: mTmpDisplaysClearButton];
    }
    return self;
  }
  return nil;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  if ([coder respondsToSelector:@selector(allowsKeyedCoding)]
      && [coder allowsKeyedCoding]) {
    [coder encodeObject: [self selectedColorLabel] forKey: @"selectedColorLabel"];
    [coder encodeBool: [self displaysClearButton] forKey: @"displaysClearButton"];
  } else {
    [coder encodeObject: [self selectedColorLabel]];
    [coder encodeValueOfObjCType: @encode(BOOL) 
                              at: &mDisplaysClearButton];
  }
}


#pragma mark -
#pragma mark Attributes 
- (void) setLabelType: (ColorLabelButtonType) type {
	[[self cell] setLabelType: type]; 
}

- (ColorLabelButtonType) labelType {
	return [[self cell] labelType]; 
}

- (NSControlSize) controlSize {
	return NSSmallControlSize;
}

- (void) setControlSize: (NSControlSize) newControlSize {
}

#pragma mark -
- (void) setColorLabels: (NSArray*) colors {
	[self resetColorLabels: colors]; 
	[self setNeedsDisplay: YES]; 
}

- (NSArray*) colorLabels {
	NSEnumerator*             cellIter	= [[mColorLabels cells] objectEnumerator]; 
	ColorLabelButtonCell*	cell			= nil; 
	
	NSMutableArray* colors = [NSMutableArray array]; 
	
	while (cell = [cellIter nextObject]) {
		if ([cell color]) 
			[colors addObject: [cell color]]; 
	}
	
	return colors; 
}

#pragma mark -
- (void) setSelectedColorLabel: (NSColor*) color {
  MMM_ASSIGN_COPY(mColorLabelColor, color);
	
	// we have to find the correct cell now 
	NSEnumerator*             cellIter	= [[mColorLabels cells] objectEnumerator]; 
	ColorLabelButtonCell* cell			= nil; 
	
	while (cell = [cellIter nextObject]) {
		if ([[cell color] isEqual: mColorLabelColor]) {
			[mColorLabels selectCell: cell];
      return; 
		}
	}
  
}

- (NSColor*) selectedColorLabel {
	return [[mColorLabelColor copy] autorelease];
}

#pragma mark -
- (void) setDisplaysClearButton: (BOOL) flag {
	mDisplaysClearButton = flag;
	
	[self resetColorLabels: [self colorLabels]]; 
	[self setNeedsDisplay]; 
}

- (BOOL) displaysClearButton {
	return mDisplaysClearButton; 
}

#pragma mark -
#pragma mark NSControl 

- (BOOL)isOpaque {
	return NO;
}

#pragma mark -
- (BOOL) acceptsFirstMouse: (NSEvent*) theEvent {
	return YES;
}

#pragma mark -
- (void) drawRect: (NSRect) aRect {
	[super drawRect: aRect]; 
}

#pragma mark -

- (void) mouseEntered: (NSEvent*) event {
	int						trackingTag		= [event trackingNumber]; 
	ColorLabelButtonCell*	trackedCell		= (ColorLabelButtonCell*)[mColorLabels cellWithTag: trackingTag]; 
  
	// forward the message to the correct cell 
	[trackedCell mouseEntered: event];
}

- (void) mouseExited: (NSEvent*) event {
	int						trackingTag		= [event trackingNumber]; 
	ColorLabelButtonCell*	trackedCell		= (ColorLabelButtonCell*)[mColorLabels cellWithTag: trackingTag]; 
	
	// forward the message to the correct cell 
	[trackedCell mouseExited: event]; 	
}

- (void) resetCursorRects {
	[self resetTrackingRects]; 
}

@end

#pragma mark -
@implementation ColorLabelButton (Private) 

- (void) resetColorLabels: (NSArray*) colors {
	// remove old colors 
	while ([mColorLabels numberOfColumns] > 0) 
		[mColorLabels removeColumn: 0]; 
	
	int numberOfColumns = [colors count]; 	
	if (mDisplaysClearButton)
		numberOfColumns++; 
	
	[mColorLabels renewRows: 1 columns: numberOfColumns]; 
	
	NSEnumerator*	colorIter   = [colors objectEnumerator]; 
	NSColor*      color       = nil; 
	int           columnIter	= 0; 
	
	if (mDisplaysClearButton) {
		ColorLabelButtonCell* cell = [[mColorLabels cells] objectAtIndex: 0]; 
		
		[cell setLabelType: ClearLabelType]; 
    [cell setColor: [NSColor colorWithCalibratedRed: 0.0 green: 0.0 blue: 0.0 alpha: 0.0]];
		[cell setTarget: self];
		
		// increment the iterator to start from column 1 later on, as the clear button 
		// is always displayed in the front 
		columnIter++; 
	}
	
	while (color = [colorIter nextObject]) {
		ColorLabelButtonCell* cell = [[mColorLabels cells] objectAtIndex: columnIter]; 
		
		[cell setLabelType: ColorLabelType]; 
		[cell setColor: color]; 
		[cell setTarget: self]; 
		
		columnIter++; 
	}
	
	[mColorLabels sizeToFit];	  
	[self setFrameSize: [mColorLabels frame].size]; 
	[self setNeedsDisplay: YES]; 
}

- (void) resetTrackingRects {
	// remove all tracking rects 
	while ([mTrackingRects count] > 0) 
		[self removeTrackingRect: [[mTrackingRects objectAtIndex: 0] intValue]]; 
	[mTrackingRects removeAllObjects]; 
		
	// now create the new ones 
	NSEnumerator*			cellIter	= [[mColorLabels cells] objectEnumerator]; 
	ColorLabelButtonCell*	cell		= nil; 
		
	while (cell = [cellIter nextObject]) {
		int row; 
		int col; 
    
		[mColorLabels getRow: &row column: &col ofCell: cell]; 
    
		NSRect cellFrame		= [mColorLabels cellFrameAtRow: row column: col]; 
		NSRect cellFrameView	= [mColorLabels convertRect: cellFrame toView: self]; 
    
		// add the new one 
		NSTrackingRectTag trackingRect = [self addTrackingRect: cellFrameView owner: self userData: self assumeInside: NO]; 
		
		// remember the tag	
		[cell setTag: trackingRect]; 
	}
}
@end
