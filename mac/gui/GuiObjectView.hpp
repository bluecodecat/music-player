//
//  GuiObjectView.hpp
//  MusicPlayer
//
//  Created by Albert Zeyer on 23.01.14.
//  Copyright (c) 2014 Albert Zeyer. All rights reserved.
//

#import "NSFlippedView.h"
#import "CocoaGuiObject.hpp"

@protocol GuiObjectProt
- (CocoaGuiObject*)getControl; // new ref
@end

@protocol GuiObjectProt_customContent
- (void)updateContent;
@end

@interface GuiObjectView : _NSFlippedView <GuiObjectProt>
{
	// Note that we can keep all Python references only in guiObjectList because that
	// is handled in childIter: or otherwise in weakrefs.
	// Otherwise, our owner, the CocoaGuiObject.tp_traverse would not find all refs
	// and the GC would not cleanup correctly when there are cyclic refs.
	PyWeakReference* controlRef;
	
	BOOL canHaveFocus;
}

- (id)initWithControl:(CocoaGuiObject*)control;

@end
