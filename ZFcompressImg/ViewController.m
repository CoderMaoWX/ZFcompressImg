//
//  ViewController.m
//  ZFcompressImg
//
//  Created by Luke on 2019/3/24.
//  Copyright © 2019 Luke. All rights reserved.
//

#import "ViewController.h"

//自定义Log
#ifdef DEBUG
    #define ZFLog(fmt, ...) fprintf(stderr,"%s: %s [Line %d]\t%s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String],__PRETTY_FUNCTION__, __LINE__, [[NSString stringWithFormat:fmt, ##__VA_ARGS__] UTF8String]);
#else
    #define ZFLog(...)
#endif

@interface ViewController ()<NSTextFieldDelegate>
@property (weak) IBOutlet NSTextField *filePathField;
@property (weak) IBOutlet NSProgressIndicator *progressIndictor;
@property (weak) IBOutlet NSTextField *tipLabel;
@property (weak) IBOutlet NSImageView *tipImageView;
@property (weak) IBOutlet NSButtonCell *chooseButton;
@property (weak) IBOutlet NSButtonCell *startButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:nil]; 
    
    NSImage *image = [NSImage imageNamed:@"background"];
    CALayer *layer = [CALayer layer];
    layer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    layer.contents = (__bridge id _Nullable)[self imageToCGImageRef:image];
    layer.opacity = 0.05;
    [self.view.layer addSublayer:layer];
    
    self.tipLabel.hidden = YES;
    self.tipLabel.textColor = [NSColor redColor];
    self.tipLabel.stringValue = @"请选择文件夹来进行压缩！";
    self.progressIndictor.hidden = YES;
    self.filePathField.delegate = self;
}

- (void)controlTextDidChange:(NSNotification *)obj {
    self.tipLabel.stringValue = @"";
    self.tipImageView.hidden = YES;
}

/**
 * 选择路径
 */
- (IBAction)chooseAction:(NSButton *)sender {
    self.tipImageView.hidden = YES;
    self.tipLabel.hidden = YES;
    self.tipLabel.stringValue = @"";
    self.filePathField.stringValue = @"";
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setAllowsMultipleSelection:false];  //是否允许多选file
    [panel setCanChooseDirectories:YES];
    
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *filePath = [panel URL];
            
            BOOL isDirectory = NO;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            BOOL isExists = [fileManager fileExistsAtPath:filePath.path isDirectory:&isDirectory];
            if (!isExists) {
                self.tipLabel.stringValue = [NSString stringWithFormat:@"选择的文件(夹): \"%@\"不存在！", filePath.path];
                self.tipLabel.hidden = NO;
                return;
            }
            if (!isDirectory && ![filePath.path hasSuffix:@"png"]) {
                self.tipLabel.stringValue = [NSString stringWithFormat:@"选择的文件: \"%@\"仅支持png图片！", filePath.path];
                self.tipLabel.hidden = NO;
                return;
            }
            self.filePathField.stringValue = filePath.path;
            self.tipLabel.stringValue = @"";
            self.tipImageView.hidden = YES;
        } else {
            ZFLog(@"已取消路径选择");
        }
    }];
}

/**
 * 开始压缩
 */
- (IBAction)startDispose:(id)sender {
    self.tipLabel.hidden = NO;
    self.tipImageView.hidden = YES;
    
    NSString *filePath = self.filePathField.stringValue;
    if ([filePath containsString:@" "]) {
        self.tipLabel.stringValue = @"请检查文件(夹)路径中不能带空格";
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existsFile = [fileManager fileExistsAtPath:filePath];
    if (filePath.length == 0 || ![filePath containsString:@"/"] || !existsFile) {
        self.tipLabel.stringValue = @"请选择正确的路径！";
        return;
    }
    self.progressIndictor.hidden = NO;
    [self.progressIndictor startAnimation:nil];
    self.filePathField.enabled = NO;
    self.chooseButton.enabled = NO;
    self.startButton.enabled = NO;
    self.tipLabel.stringValue = @"正在压缩中。。。";
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString *shellPathPng = [[NSBundle mainBundle] pathForResource:@"PNGCompress" ofType:@""];
        
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/bin/sh";
        task.arguments = @[shellPathPng, filePath];
        task.currentDirectoryPath = [[NSBundle mainBundle] resourcePath];
        
        NSPipe *outputPipe = [NSPipe pipe];
        [task setStandardOutput:outputPipe];
        [task setStandardError:outputPipe];
        
        NSError *error = nil;
        if (@available(macOS 10.13, *)) {
            [task launchAndReturnError:&error];
        } else {
            [task launch];
        }
        [task waitUntilExit];
        
        NSFileHandle *readHandle = [outputPipe fileHandleForReading];
        NSData *outputData = [readHandle readDataToEndOfFile];
        NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        ZFLog(@"脚本输出-Debug : \n%@",outputString);
        
        int status = [task terminationStatus];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == 0 || !error) {
                self.tipImageView.image = [NSImage imageNamed:@"success"];
                self.tipLabel.stringValue = @"恭喜,所有图片压缩完成！！！";
            } else {
                self.tipImageView.image = [NSImage imageNamed:@"fail"];
                self.tipLabel.stringValue = @"糟糕,图片压缩遇到未知错误！！！";
            }
            self.progressIndictor.hidden = YES;
            self.tipImageView.hidden = NO;
            self.filePathField.enabled = YES;
            self.chooseButton.enabled = YES;
            self.startButton.enabled = YES;
        });
    });
}

//NSImage 转换为 CGImageRef
- (CGImageRef)imageToCGImageRef:(NSImage*)image {
    NSData * imageData = [image TIFFRepresentation];
    CGImageRef imageRef = nil;
    if(imageData){
        CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)imageData, NULL);
        imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    }
    return imageRef;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}


@end
