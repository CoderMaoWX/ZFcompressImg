//
//  AppDelegate.m
//  ZFcompressImg
//
//  Created by Luke on 2019/3/24.
//  Copyright © 2019 Luke. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

/**
 * 设置关闭窗口之后点击Dock中的图标可以再次打开窗口
 */
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    if (!flag) {
        [NSApp activateIgnoringOtherApps:NO];
        //显示当前App的第一个窗口
        [[NSApplication sharedApplication].windows.firstObject makeKeyAndOrderFront:self];
        //[self.window makeKeyAndOrderFront:self];//主窗口显示自己方法一
        //[self.window orderFront:nil];           //主窗口显示自己方法二
    }
    return YES;
}

@end
