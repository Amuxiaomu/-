//
//  ViewController.m
//  二维码
//
//  Created by Amuxiaomu on 16/8/5.
//  Copyright © 2016年 Amuxiaomu. All rights reserved.
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>

@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate>

@property (weak, nonatomic) IBOutlet UILabel *infoLabel;

// 捕捉会话
@property (nonatomic, strong)AVCaptureSession * captureSession;
// 展示layer
@property (nonatomic, strong)AVCaptureVideoPreviewLayer * videoPreviewLayer;

@property (nonatomic, strong) UIView * viewPreview;

@property (nonatomic, strong)UIView * boxView;

@property (nonatomic, strong) CALayer * scanLayer;

@property (nonatomic, strong)IBOutlet UIImageView * imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addSubview:self.videoPreview];
    
    self.captureSession = nil;
}

- (UIView *)videoPreview{
    if (_viewPreview == nil) {
        _viewPreview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 375, 375)];
    }
    return  _viewPreview;
}
- (IBAction)actionStart:(UIButton *)sender {
    [self startReading];
    
}
- (IBAction)actionStop:(UIButton *)sender {
    [self stopRunning];
}

- (BOOL)startReading{
    NSError * error;
    //
    AVCaptureDevice * captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 用captureDevice 创建输入流
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input) {
        NSLog(@"%@",[error localizedDescription]);
        return NO;
    }
    
    // 创建媒体数据输出流
    AVCaptureMetadataOutput * captureMetadataOutput = [[AVCaptureMetadataOutput alloc]init];
    // 实例化捕捉对象
    _captureSession = [[AVCaptureSession alloc] init];
    
    // 将输入流添加到会话
    [_captureSession addInput:input];
    // 将媒体输出流添加到会话
    [_captureSession addOutput:captureMetadataOutput];
    
    // 创建串行队列
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    
    //设置代理
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    
    // 设置输出媒体数据类型QRCode
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    // 实例化预览图层填充方式
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];

    // 设置预览图层填充方式
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    // 设置图层的frame
    [_videoPreviewLayer setFrame:self.viewPreview.layer.bounds];
    
    // 将图层添加到预览view 的图层上
    [_viewPreview.layer addSublayer:_videoPreviewLayer];
    
    // 设置扫描范围
    captureMetadataOutput.rectOfInterest = CGRectMake(0.2f, 0.2f, 0.8f, 0.8);
    
    // 扫描框
    _boxView = [[UIView alloc] initWithFrame:CGRectMake(_viewPreview.bounds.size.width * 0.2f, _viewPreview.bounds.size.height * 0.2f, _viewPreview.bounds.size.width - _viewPreview.bounds.size.width * 0.4f, _viewPreview.bounds.size.height - _viewPreview.bounds.size.height * 0.4f)];
    
    _boxView.layer.borderColor = [UIColor greenColor].CGColor;
    _boxView.layer.borderWidth = 1.0f;
    [_viewPreview addSubview:_boxView];
    
    // 扫描线
    _scanLayer = [[CALayer alloc] init];
    _scanLayer.frame = CGRectMake(0, 0, _boxView.bounds.size.width, 1);
    _scanLayer.backgroundColor = [UIColor blueColor].CGColor;
    
    [_boxView.layer addSublayer:_scanLayer];
    
//    NSTimer * timer = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(moveScanLayer) userInfo:nil repeats:YES];
//    
//    [timer fire];
    
    // 开始扫描
    [_captureSession startRunning];
    
    return YES;
}
- (void)moveScanLayer{
    NSLog(@"扫描线 上下移动中");
}
- (void)stopRunning{
    [_captureSession stopRunning];
    _captureSession = nil;
    [_scanLayer removeFromSuperlayer];
    [_videoPreviewLayer removeFromSuperlayer];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    //判断是否有数据
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        
        
        //[self stopRunning];
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        //判断回传的数据类型
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            //对获取信息进行处理
            //NSLog(@"%@",metadataObj.stringValue);
            self.infoLabel.text = [NSString stringWithFormat:@"内容:%@",metadataObj.stringValue];
        }
    }
}

- (IBAction)actionGetQRCode:(UIButton *)sender {
    
    //self.imageView.bounds.size.width;
    //self.imageView.bounds.size.height
    
//    self.imageView.image = [self generateQRCode:@"这是个二维码" width:self.imageView.bounds.size.width height:self.imageView.bounds.size.height];
    [self test];
    [self test2];
    
    [self.view setNeedsDisplay];
}


//生成二维码
- (UIImage *)generateQRCode:(NSString *)str width:(CGFloat)width height:(CGFloat)height {
    
    // 生成二维码图片
    CIImage *qrcodeImage;
//    qrcodeImage = [[CIImage alloc] init];
    NSData *data = [str dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:false];
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    
    [filter setDefaults];
    
    [filter setValue:data forKey:@"inputMessage"];
    //[filter setValue:@"H" forKey:@"inputCorrectionLevel"];
    qrcodeImage = [filter outputImage];
    
    // 消除模糊
    CGFloat scaleX = width / qrcodeImage.extent.size.width; // extent 返回图片的frame
    CGFloat scaleY = height / qrcodeImage.extent.size.height;
    CIImage *transformedImage = [qrcodeImage imageByApplyingTransform:CGAffineTransformScale(CGAffineTransformIdentity, scaleX, scaleY)];
    
    return [UIImage imageWithCIImage:transformedImage];
}


- (void)test{
    // 1. 实例化二维码滤镜
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 2. 恢复滤镜的默认属性
    [filter setDefaults];
    NSString *str = @"www.qq.com";
    // 3. 将字符串转换成NSData
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    // 4. 通过KVO设置滤镜inputMessage数据
    [filter setValue:data forKey:@"inputMessage"];
    // 5. 获得滤镜输出的图像
    CIImage *outputImage = [filter outputImage];
    
    
    CIImage *transformedImage = [outputImage imageByApplyingTransform:CGAffineTransformScale(CGAffineTransformIdentity, 100, 100)];
    // 6. 将CIImage转换成UIImage，并放大显示
    self.imageView.image = [UIImage imageWithCIImage:transformedImage scale:20.0 orientation:UIImageOrientationUp];
}
#pragma mark
#pragma mark - 修改
- (void)test2{
    // 1. 实例化二维码滤镜
    CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // 2. 恢复滤镜的默认属性
    [filter setDefaults];
    NSString *str = @"www.qq.com";
    // 3. 将字符串转换成NSData
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    // 4. 通过KVO设置滤镜inputMessage数据
    [filter setValue:data forKey:@"inputMessage"];
    // 5. 获得滤镜输出的图像
    CIImage *outputImage = [filter outputImage];
    // 6. 将CIImage转换成UIImage，并放大显示
    self.imageView.image = [UIImage imageWithCIImage:outputImage scale:20.0 orientation:UIImageOrientationUp];
}

// 此方法利用了位图的原理,不好解释, 不过使用的时候,可以自建一个工具类使用
+ (UIImage *)createNonInterpolatedUIImageFormCIImage:(CIImage *)image withSize:(CGFloat)size
{
    CGRect extent = CGRectIntegral(image.extent);
    CGFloat scale = MIN(size/CGRectGetWidth(extent), size/CGRectGetHeight(extent));
    
    // 1.创建bitmap;
    size_t width = CGRectGetWidth(extent) * scale;
    size_t height = CGRectGetHeight(extent) * scale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 0, cs, (CGBitmapInfo)kCGImageAlphaNone);
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef bitmapImage = [context createCGImage:image fromRect:extent];
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, scale, scale);
    CGContextDrawImage(bitmapRef, extent, bitmapImage);
    
    // 2.保存bitmap到图片
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    return [UIImage imageWithCGImage:scaledImage];
}
@end
