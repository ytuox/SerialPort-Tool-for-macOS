//
//  ViewController.m
//  SerialPort Tool
//
//  Created by abc on 20/8/12.
//  Copyright © 2020年 abc. All rights reserved.
//

#import "ViewController.h"
#import "ORSSerialPortManager.h"

@class AMPathPopUpButton;
@implementation ViewController


- (void)awakeFromNib{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
        self.availableBaudRates = @[@300, @1200, @2400, @4800, @9600, @14400, @19200, @28800, @38400, @57600, @115200, @230400];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(serialPortsWereConnected:) name:ORSSerialPortsWereConnectedNotification object:nil];
        [nc addObserver:self selector:@selector(serialPortsWereDisconnected:) name:ORSSerialPortsWereDisconnectedNotification object:nil];
        
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
        [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];
#endif
        
        _panel = [NSSavePanel savePanel];
        [_panel setMessage:@"选择存储路径"];
        [_panel setAllowsOtherFileTypes:YES];
        [_panel setAllowedFileTypes:@[@"txt"]];
        [_panel setExtensionHidden:YES];
        [_panel setCanCreateDirectories:YES];
        self.isLoopSend1 = NO;
        self.isLoopSend2 = NO;
        self.isWorkInSend = NO;
    });
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    [self.RXDataDisplayTextView setEditable:NO];
    [self.RXCounter setEditable:NO];
    [self.TXCounter setEditable:NO];
    self.isRXHexString = YES;
    self.isTXHexString = YES;
    self.TXNumber = 0;
    self.RXNumber = 0;
    // Do any additional setup after loading the view.
    self.TXDataDisplayTextView1.delegate = self;
    self.TXDataDisplayTextView2.delegate = self;
    self.tableviewFordevices.delegate = self;
}

-(void)viewDidAppear{
    [super viewDidAppear];
    
    if(self.serialPortManager.availablePorts.count>0){
        self.serialPort=self.serialPortManager.availablePorts[0];
    }
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    // Update the view, if already loaded.
}

//设置只显示收到的数据，而不添加指示/状态文字等
- (IBAction)setDisplayRxDataOnly:(NSButton *)sender {
    if(sender.intValue==1){
        self.isOnlyDisplayRxData = YES;
    }else{
        self.isOnlyDisplayRxData = NO;
    }
}

//设置循环发送数据1
- (IBAction)setSendLoop1:(NSButton *)sender {
    if(sender.intValue==1){
        [self.countOfSend setEnabled:YES];
        [self.TimeInternel setEnabled:YES];
        self.isLoopSend1 = YES;
    }else{
        // [self.countOfSend setEnabled:NO];
        // [self.TimeInternel setEnabled:NO];
        self.isLoopSend1 = NO;
    }
    [self stopTimer1];
}

//设置循环发送数据2
- (IBAction)setSendLoop2:(NSButton *)sender {
    if(sender.intValue==1){
        [self.countOfSend setEnabled:YES];
        [self.TimeInternel setEnabled:YES];
        self.isLoopSend2 = YES;
    }else{
        // [self.countOfSend setEnabled:NO];
        // [self.TimeInternel setEnabled:NO];
        self.isLoopSend2 = NO;
    }
    [self stopTimer2];
}

- (IBAction)openComPort:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.serialPort.isOpen ? [self.serialPort close] : [self.serialPort open];
    });
}

//设置接收区采用hexstring还是字符串显示方式
- (IBAction)setDisplayMode_RX:(NSMatrix *)sender {
    if (sender.selectedTag==1) {
        self.isRXHexString = YES;
        [self.stringType_RX setEnabled:NO];
    }else if(sender.selectedTag==2){
        self.isRXHexString = NO;
        [self.stringType_RX setEnabled:YES];
    }
}

//设置发送区采用hexstring还是字符串发送
- (IBAction)setDisplayMode_TX:(NSMatrix *)sender {
    if (sender.selectedTag==1) {
        self.isTXHexString = YES;
        [self.stringType_TX setEnabled:NO];
    }else{
        self.isTXHexString = NO;
        [self.stringType_TX setEnabled:YES];
    }
}


//发送数据1
- (IBAction)sendData1:(NSButton *)sender {
    //停止循环发送
    if (self.isWorkInSend) {
        [self stopTimer1];
        return;
    }
    
    self.StatusText.stringValue = @"发送数据中...";
    NSString *textStr = self.TXDataDisplayTextView1.textStorage.mutableString;
    if(textStr.length==0){
        self.StatusText.stringValue = @"发送数据长度为0";
        return;
    }
    
    if (_isLoopSend1) {
        //获取次数和间隔值
        _sendCount = [self.countOfSend.stringValue intValue];
        double timeout1 = [self.TimeInternel.stringValue doubleValue]/1000.0;
        
        if(_sendCount<=0 || timeout1 <= 0){
            self.StatusText.stringValue = @"请填入循环发送参数(时间间隔和次数)";
            return;
        }
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:timeout1 target:self selector:@selector(timeout1) userInfo:nil repeats:YES];
        self.StatusText.stringValue = @"循环发送中...";
        self.SendButton1.title = @"停止循环";
        _isWorkInSend = YES;
        
    }else{
        [self sendDataWithPort:1];
    }
}

//发送数据2
- (IBAction)sendData2:(NSButton *)sender {
    
    //停止循环发送
    if (self.isWorkInSend) {
        [self stopTimer2];
        return;
    }
    
    self.StatusText.stringValue = @"发送数据中...";
    NSString *textStr = self.TXDataDisplayTextView2.textStorage.mutableString;
    if(textStr.length == 0){
        self.StatusText.stringValue = @"发送数据长度为0";
        return;
    }
    
    if (_isLoopSend2) {
        //获取次数和间隔值
        _sendCount = [self.countOfSend.stringValue intValue];
        double timeout2 = [self.TimeInternel.stringValue doubleValue]/1000.0;
        
        if(_sendCount<=0 || timeout2 <= 0){
            self.StatusText.stringValue = @"请填入循环发送参数(时间间隔和次数)";
            return;
        }
        
        _timer = [NSTimer scheduledTimerWithTimeInterval:timeout2 target:self selector:@selector(timeout2) userInfo:nil repeats:YES];
        self.StatusText.stringValue = @"循环发送中...";
        self.SendButton2.title = @"停止循环";
        _isWorkInSend = YES;
        
    }else{
        [self sendDataWithPort:2];
    }
}

-(void)stopTimer1{
    [_timer invalidate];
    _timer = nil;
    if (_isLoopSend1) {
        self.SendButton1.title = @"循环发送";
    }else{
        self.SendButton1.title = @"手动发送";
    }
    self.isWorkInSend = NO;
}

-(void)timeout1{
    if (0 ==_sendCount) {
        [self stopTimer1];
        return;
    }
    [self sendDataWithPort:1];
    _sendCount --;
}

// 循环2时间
-(void)stopTimer2{
    [_timer invalidate];
    _timer = nil;
    if (_isLoopSend2) {
        self.SendButton2.title = @"循环发送";
    }else{
        self.SendButton2.title = @"手动发送";
    }
    self.isWorkInSend = NO;
}

-(void)timeout2{
    if (0 ==_sendCount) {
        [self stopTimer2];
        return;
    }
    [self sendDataWithPort:2];
    _sendCount --;
}

// 写数据
-(void)sendDataWithPort:(int)data{
    if (!self.serialPort.isOpen) {
        self.StatusText.stringValue = @"串口未打开，不能发送数据";
        return;
    }
    NSData *sendData;
    NSString *textStr;
    if (data == 1){
        textStr = self.TXDataDisplayTextView1.textStorage.mutableString;
    }
    else{
        textStr = self.TXDataDisplayTextView2.textStorage.mutableString;
    }
    if (self.isTXHexString) {
        textStr = [textStr stringByReplacingOccurrencesOfString:@"," withString:@""];
        textStr = [textStr stringByReplacingOccurrencesOfString:@" " withString:@""];
        textStr = [textStr stringByReplacingOccurrencesOfString:@"0x" withString:@""];
        textStr = [textStr stringByReplacingOccurrencesOfString:@"\\x" withString:@""];
        if (textStr.length%2!=0) {
            self.StatusText.stringValue = @"发送16进制数据长度错误！";
            return;
        }
        
        NSString* number=@"^[a-f|A-F|0-9]+$";
        NSPredicate *numberPre = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",number];
        if(![numberPre evaluateWithObject:textStr]){
            self.StatusText.stringValue = @"包含非[0-9A-Fa-f]字符！";
            return;
        }
        
        self.TXNumber += textStr.length/2;
        sendData = [ORSSerialPortManager convertHexStrToData:textStr];
        if([self.serialPort sendData:sendData]){
            self.StatusText.stringValue = @"发送HEX数据成功";
            self.TXCounter.stringValue = [NSString stringWithFormat:@"%ld",self.TXNumber];
        }else{
            self.StatusText.stringValue = @"发送HEX数据失败";
            return;
        }
    }else{
        
        const char* cstr;
        NSString *tmp;
        cstr = [textStr cStringUsingEncoding:NSUTF8StringEncoding];
        tmp = @"发送UTF8编码数据成功";
        if(cstr!=NULL){
            self.TXNumber += strlen(cstr);
            sendData = [NSData dataWithBytes:cstr length:strlen(cstr)];
            if([self.serialPort sendData:sendData]){
                self.TXCounter.stringValue = [NSString stringWithFormat:@"%ld",self.TXNumber];
                self.StatusText.stringValue = tmp;
            }else{
                self.StatusText.stringValue = @"发送数据失败";
                return;
            }
        }else{
            self.StatusText.stringValue=@"字符串按选定编码转为字节流失败";
            return;
        }
    }
    NSString *sendStr;
    if(self.isOnlyDisplayRxData){
        sendStr = [NSString stringWithFormat:@"[%@]%@\n",[self get2DateTime],[ORSSerialPortManager convertDataToHexStr:sendData]];
    }else{
        sendStr = [NSString stringWithFormat:@"%@\n",[ORSSerialPortManager convertDataToHexStr:sendData]];
    }
    //显示文字为橙色，大小为13
    NSInteger startPorint = self.RXDataDisplayTextView.textStorage.length;
    NSInteger length = sendStr.length;
    [self.RXDataDisplayTextView.textStorage.mutableString appendString:sendStr];
    [self.RXDataDisplayTextView.textStorage addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Andale Mono" size:13] range:NSMakeRange(startPorint, length)];
    [self.RXDataDisplayTextView.textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor orangeColor] range:NSMakeRange(startPorint, length)];
    
    [self.RXDataDisplayTextView scrollRangeToVisible:NSMakeRange(self.RXDataDisplayTextView.string.length, 1)];
    return;
}

- (IBAction)clearTXDataDisplayTextView1:(id)sender {
    self.StatusText.stringValue = @"已清空发送区";
    [self.TXDataDisplayTextView1 setString:@""];
}

- (IBAction)clearTXDataDisplayTextView2:(id)sender {
    self.StatusText.stringValue = @"已清空发送区";
    [self.TXDataDisplayTextView2 setString:@""];
}

- (IBAction)clearRXDataDisplayTextView:(id)sender {
    self.StatusText.stringValue = @"已清空接收区";
    [self.RXDataDisplayTextView setString:@""];
}

- (IBAction)clearCounter:(id)sender {
    self.RXNumber = 0;
    self.TXNumber = 0;
    self.TXCounter.stringValue=@"";
    self.RXCounter.stringValue = @"";
}

#pragma mark - ORSSerialPortDelegate Methods

- (void)serialPortWasOpened:(ORSSerialPort *)serialPort
{
    self.OpenOrClose.title = @"关闭串口";
    self.StatusText.stringValue = @"串口已打开";
}

- (void)serialPortWasClosed:(ORSSerialPort *)serialPort
{
    self.OpenOrClose.title = @"打开串口";
    self.StatusText.stringValue = @"串口已关闭";
}

// 接收数据
- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
{
    if(serialPort!=self.serialPort){//不是同一个对象，直接返回
        return;
    }
//    NSLog(@"收到数据: %@",data);
    self.StatusText.stringValue = @"收到一次数据...";
    self.RXNumber += data.length;
    self.RXCounter.stringValue = [NSString stringWithFormat:@"%ld",self.RXNumber];
    
    NSString *string;
    if (self.isRXHexString) {
        // NSData转成HEX
        string = [ORSSerialPortManager convertDataToHexStr:data];
        string = [NSString stringWithFormat:@"%@\n",string];
    }else{
        // NSData转成ASCII
        string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    if ([string length] == 0){
        return;
    }

    if(self.isOnlyDisplayRxData){
        string = [NSString stringWithFormat:@"[%@]%@",[self get2DateTime],string];
    }else{
        string = [NSString stringWithFormat:@"%@",string];
    }
    
    //显示文字为深灰色，大小为14
    NSInteger startPorint = self.RXDataDisplayTextView.textStorage.length;
    NSInteger length = string.length;
    [self.RXDataDisplayTextView.textStorage.mutableString appendString:string];
    [self.RXDataDisplayTextView.textStorage addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"Andale Mono" size:13] range:NSMakeRange(startPorint, length)];
    [self.RXDataDisplayTextView.textStorage addAttribute:NSForegroundColorAttributeName value:[NSColor redColor] range:NSMakeRange(startPorint, length)];
    [self.RXDataDisplayTextView scrollRangeToVisible:NSMakeRange(self.RXDataDisplayTextView.string.length, 1)];
    
    [self.RXDataDisplayTextView setNeedsDisplay:YES];
    self.StatusText.stringValue = @"数据接收完毕";
}

- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort;
{
    // After a serial port is removed from the system, it is invalid and we must discard any references to it
    self.serialPort = nil;
    self.OpenOrClose.title = @"打开串口";
}

//各种错误，比如打开，关闭，发送数据等发生错误
- (void)serialPort:(ORSSerialPort *)serialPort didEncounterError:(NSError *)error
{
    NSLog(@"Serial port %@ encountered an error: %@", serialPort, error);
    self.StatusText.stringValue = [NSString stringWithFormat:@"错误:%@",error.userInfo[@"NSLocalizedDescription"]];
    
}

#pragma mark - NSUserNotificationCenterDelegate

#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 3.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [center removeDeliveredNotification:notification];
    });
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

#endif

#pragma mark - Notifications

- (void)serialPortsWereConnected:(NSNotification *)notification
{
    NSArray *connectedPorts = [notification userInfo][ORSConnectedSerialPortsKey];
    NSLog(@"Ports were connected: %@", connectedPorts);
    [self postUserNotificationForConnectedPorts:connectedPorts];
}

- (void)serialPortsWereDisconnected:(NSNotification *)notification
{
    NSArray *disconnectedPorts = [notification userInfo][ORSDisconnectedSerialPortsKey];
    NSLog(@"Ports were disconnected: %@", disconnectedPorts);
    [self postUserNotificationForDisconnectedPorts:disconnectedPorts];
    
}

- (void)postUserNotificationForConnectedPorts:(NSArray *)connectedPorts
{
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
    if (!NSClassFromString(@"NSUserNotificationCenter")) return;
    
    NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
    for (ORSSerialPort *port in connectedPorts)
    {
        NSUserNotification *userNote = [[NSUserNotification alloc] init];
        userNote.title = NSLocalizedString(@"侦测到串口线连接", @"侦测到串口线连接");
        NSString *informativeTextFormat = NSLocalizedString(@"串口设备 %@ 已经连接到你的 Mac电脑.", @"Serial port connected user notification informative text");
        userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
        userNote.soundName = nil;
        [unc deliverNotification:userNote];
    }
#endif
}

- (void)postUserNotificationForDisconnectedPorts:(NSArray *)disconnectedPorts
{
#if (MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_7)
    if (!NSClassFromString(@"NSUserNotificationCenter")) return;
    
    NSUserNotificationCenter *unc = [NSUserNotificationCenter defaultUserNotificationCenter];
    for (ORSSerialPort *port in disconnectedPorts)
    {
        NSUserNotification *userNote = [[NSUserNotification alloc] init];
        userNote.title = NSLocalizedString(@"侦测到串口线断开", @"侦测到串口线断开");
        NSString *informativeTextFormat = NSLocalizedString(@"串口设备 %@ 已从你的 Mac电脑断开物理连接.", @"Serial port disconnected user notification informative text");
        userNote.informativeText = [NSString stringWithFormat:informativeTextFormat, port.name];
        userNote.soundName = nil;
        [unc deliverNotification:userNote];
    }
#endif
}

-(void)tableViewSelectionDidChange:(NSNotification*)notification{
    self.serialPort = [self getCurrentORSSerialPort];
    self.serialPort.delegate = self;
    self.serialPort.allowsNonStandardBaudRates = YES;//允许非标准的波特率
}

-(ORSSerialPort *)getCurrentORSSerialPort {
    if([[self.DeviceArray selectedObjects] count]> 0){
        return [[self.DeviceArray selectedObjects] objectAtIndex:0];
    } else {
        return nil;
    }
}


#pragma mark - Properties

- (void)setSerialPort:(ORSSerialPort *)port
{
    if (port != _serialPort)
    {
//        [_serialPort close];
        _serialPort.delegate = nil;
        _serialPort = port;
        _serialPort.delegate = self;
        self.OpenOrClose.title = self.serialPort.isOpen ? @"关闭串口" : @"打开串口";
        NSString *tmp=[NSString stringWithFormat:@"%@%@",_serialPort.name,(self.serialPort.isOpen ? @"串口已打开" : @"串口已关闭")];
        self.StatusText.stringValue = tmp;
    }
}


// 保存日志文件
- (IBAction)SaveLog:(id)sender {
    
    [_panel setNameFieldStringValue:[NSString stringWithFormat:@"%@-%@.txt",_serialPort.name,[self getDateTime]]];
    
    [_panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            NSString *path = [[self->_panel URL] path];
    
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.RXDataDisplayTextView.textStorage.mutableString writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
            });
        }
    }];
}

- (NSString *)getDateTime
{
    char dateTime[15];
    time_t t;
    struct tm tm;
    t = time( NULL );
    memcpy(&tm, localtime(&t), sizeof(struct tm));
    sprintf(dateTime, "%04d%02d%02d%02d%02d%02d",
            tm.tm_year+1900, tm.tm_mon+1, tm.tm_mday,
            tm.tm_hour, tm.tm_min,tm.tm_sec);
    return [[NSString alloc] initWithCString:dateTime encoding:NSASCIIStringEncoding];
}

- (NSString *)get2DateTime
{
    NSString* date;
    NSDateFormatter * formatter = [[NSDateFormatter alloc ] init];
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss:SSS"];
    date = [formatter stringFromDate:[NSDate date]];
    NSString * timeNow = [[NSString alloc] initWithFormat:@"%@", date];
    return timeNow;
}
@end
