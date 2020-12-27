//
//  ViewController.h
//  SerialPort Tool
//
//  Created by abc on 20/8/12.
//  Copyright © 2020年 abc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ORSSerialPort.h"

@class ORSSerialPortManager;

@interface ViewController : NSViewController <ORSSerialPortDelegate, NSUserNotificationCenterDelegate,NSTextViewDelegate,NSTableViewDelegate>
@property (weak) IBOutlet NSArrayController *DeviceArray;

@property (weak) IBOutlet NSButton *OpenOrClose;

@property (weak) IBOutlet NSTextField *StatusText;

@property (weak) IBOutlet NSTextField *RXCounter;
@property (nonatomic, assign) long RXNumber;

@property (weak) IBOutlet NSTextField *TXCounter;
@property (nonatomic, assign) long TXNumber;

@property (unsafe_unretained) IBOutlet NSTextView *RXDataDisplayTextView;


@property (unsafe_unretained) IBOutlet NSTextView *TXDataDisplayTextView1;

@property (unsafe_unretained) IBOutlet NSTextView *TXDataDisplayTextView2;

@property (weak) IBOutlet NSMatrix *stringType_RX;
@property (weak) IBOutlet NSMatrix *stringType_TX;

@property (weak) IBOutlet NSTextField *TimeInternel;
@property (weak) IBOutlet NSTextField *countOfSend;
@property (weak) IBOutlet NSButton *SendButton1;
@property (weak) IBOutlet NSButton *SendButton2;
@property (nonatomic, assign) BOOL isRXHexString;

@property (nonatomic, assign) BOOL isTXHexString;

@property (nonatomic, strong) ORSSerialPortManager *serialPortManager;
@property (nonatomic, strong) ORSSerialPort *serialPort;//ORSSerialPort
@property (nonatomic, strong) NSArray *availableBaudRates;
@property (weak) IBOutlet NSTableView *tableviewFordevices;

@property (nonatomic,strong) NSSavePanel*  panel;
@property (nonatomic, assign) BOOL isLoopSend1;
@property (nonatomic, assign) BOOL isLoopSend2;
@property (nonatomic, assign) BOOL isWorkInSend;
@property (nonatomic, assign) BOOL isOnlyDisplayRxData;
@property (assign,nonatomic) int sendCount;
@property (assign,nonatomic) NSTimer *timer;
@end

