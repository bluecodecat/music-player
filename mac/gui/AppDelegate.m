//
//  AppDelegate.m
//  MusicPlayer
//
//  Created by Albert Zeyer on 17.01.14.
//  Copyright (c) 2014 Albert Zeyer. All rights reserved.
//

#include <Python.h>
#include <dlfcn.h>
#import "PyObjCBridge.h"
#include "PythonHelpers.h"
#import "AppDelegate.h"


static void handleFatalError(const char* msg) {
	typedef void Handler(const char* msg);
	Handler* handler = (Handler*) dlsym(RTLD_DEFAULT, "handleFatalError");
	if(handler)
		handler(msg);
	else
		printf("Error^2: Error handler not found. This is probably not executed within the orig exec.\n");
	_exit(1);
}

NSWindow* getWindow(const char* name) {
	NSWindow* res = NULL;

	PyGILState_STATE gstate = PyGILState_Ensure();
	PyObject* w = handleModuleCommand("guiCocoa", "getWindow", "(s)", name);
	if(!w) goto final;
	res = PyObjCObj_GetNativeObj(w);
	
final:
	Py_XDECREF(w);
	PyGILState_Release(gstate);
	
	return res;
}


@implementation AppDelegate

- (void)setupMainWindow
{
	handleModuleCommand_noReturn("guiCocoa", "setupMainWindow", NULL);
}

- (void)setupSearchWindow
{
	handleModuleCommand_noReturn("guiCocoa", "setupSearchWindow", NULL);
}

- (void)setupSongEditWindow
{
	handleModuleCommand_noReturn("guiCocoa", "setupSongEditWindow", NULL);
}

NSMenu* dockMenu;

- (void)setDockMenu:(NSMenu*)m
{
	dockMenu = m;
}

- (void)updateControlMenu
{
	if(!dockMenu) return;

	PyGILState_STATE gstate = PyGILState_Ensure();
	PyObject* mod = getModule("State"); // borrowed
	PyObject* state = NULL;
	PyObject* songTitle = NULL;
	PyObject* playingState = NULL;
	
	if(!mod) goto final;
	state = attrChain(mod, "state");
	if(!state || PyObject_IsTrue(state) <= 0) goto final;
	
	songTitle = attrChain(mod, "state.curSong.userString");
	if(!songTitle) goto final;
	playingState = attrChain(mod, "state.player.playing");
	if(!playingState) goto final;
		
	{
		NSMenuItem* songEntry = [dockMenu itemAtIndex:0];
		NSMenuItem* playPauseEntry = [dockMenu itemAtIndex:1];

		[songEntry setTitle:convertToStr(songTitle)];
		[playPauseEntry setTitle:((PyObject_IsTrue(playingState) > 0) ? @"Pause" : @"Play")];
	}
	
final:
	if(PyErr_Occurred())
		PyErr_Print();

	Py_XDECREF(state);
	Py_XDECREF(songTitle);
	Py_XDECREF(playingState);
	PyGILState_Release(gstate);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	printf("My app delegate: finish launching\n");
	
	PyGILState_STATE gstate = PyGILState_Ensure();
	
	const char* fatalErrorMsg = NULL;
	PyObject* mod = getModule("guiCocoa"); // borrowed
	PyObject* callback = NULL;
	PyObject* ret = NULL;
	if(!mod) {
		fatalErrorMsg = "Startup error. Did not loaded guiCocoa correctly.";
		goto final;
	}
	callback = PyObject_GetAttrString(mod, "setupAfterAppFinishedLaunching");
	if(!callback) {
		fatalErrorMsg = "Startup error. setupAfterAppFinishedLaunching not found.";
		goto final;
	}
	ret = PyObject_CallFunction(callback, NULL);
	
final:
	if(PyErr_Occurred()) {
		PyErr_Print();
		if(!fatalErrorMsg)
			fatalErrorMsg = "Startup error. Unknown Python exception occured.";
	}
	
	if(fatalErrorMsg)
		handleFatalError(fatalErrorMsg);
	
	Py_XDECREF(ret);
	Py_XDECREF(callback);
	PyGILState_Release(gstate);
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSNotification *)aNotification
{
	printf("My app delegate: should terminate\n");
	handleModuleCommand_noReturn("guiCocoa", "handleApplicationQuit", NULL);
	return NSTerminateNow;
}

- (BOOL)applicationOpenUntitledFile:(NSApplication *)sender
{
	if(!getWindow("mainWindow"))
		[self setupMainWindow];
	else
		[NSApp activateIgnoringOtherApps:YES];
	return YES;
}

// for NSUserNotificationCenterDelegate, >= MacOSX 10.8
- (BOOL)userNotificationCenter:(id)center shouldPresentNotification:(id)notification
{
	return YES;
}

- (void)openMainWindow:(id)sender
{
	[self setupMainWindow];
}

- (void)openSearchWindow:(id)sender
{
	[self setupSearchWindow];
}

- (void)openSongEditWindow:(id)sender
{
	[self setupSongEditWindow];
}

- (void)about:(id)sender
{
	PyGILState_STATE gstate = PyGILState_Ensure();
	
	PyObject* mod = getModule("gui"); // borrowed
	PyObject* callback = NULL;
	PyObject* ret = NULL;
	if(!mod) {
		printf("Warning: Did not find gui module.\n");
		goto final;
	}
	callback = PyObject_GetAttrString(mod, "about");
	if(!callback) {
		printf("Warning: gui.about not found.\n");
		goto final;
	}
	ret = PyObject_CallFunction(callback, NULL);
	
final:
	if(PyErr_Occurred())
		PyErr_Print();
	
	Py_XDECREF(ret);
	Py_XDECREF(callback);
	PyGILState_Release(gstate);
}

- (void)playPause:(id)sender
{
	handleModuleCommand_noReturn("State", "state.playPause", NULL);
}

- (void)nextSong:(id)sender
{
	handleModuleCommand_noReturn("State", "state.nextSong", NULL);
}

- (void)resetPlayer:(id)sender
{
	handleModuleCommand_noReturn("State", "state.player.resetPlaying", NULL);
}

- (void)dealloc
{
	printf("My app delegate dealloc\n");
}

@end