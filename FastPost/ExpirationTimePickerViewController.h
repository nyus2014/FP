//
//  ExpirationTimePickerViewController.h
//  FastPost
//
//  Created by Huang, Jason on 12/11/13.
//  Copyright (c) 2013 Huang, Jason. All rights reserved.
//
typedef enum{
    PickerTypeRevive,
    PickerTypeFilter
}PickerType;

#import <UIKit/UIKit.h>
@class ExpirationTimePickerViewController;
@protocol ExpirationTimePickerViewControllerDelegate <NSObject>
-(void)revivePickerViewExpirationTimeSetToMins:(NSInteger)min andSecs:(NSInteger)sec andPickerView:(UIPickerView *)pickerView;
-(void)filterPickerViewExpirationTimeSetToLessThanMins:(int)min andPickerView:(UIPickerView *)pickerView;
@end


@interface ExpirationTimePickerViewController : UIViewController
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil type:(PickerType)type;
@property (nonatomic) PickerType type;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) UIToolbar *blurToolBar;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (nonatomic, assign) id<ExpirationTimePickerViewControllerDelegate>delegate;
- (IBAction)doneButtonTapped:(id)sender;

@end
