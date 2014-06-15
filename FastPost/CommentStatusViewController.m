//
//  CommentStatusViewController.m
//  FastPost
//
//  Created by Sihang Huang on 3/12/14.
//  Copyright (c) 2014 Huang, Sihang. All rights reserved.
//

#import "CommentStatusViewController.h"
#import <Parse/Parse.h>
#import "CommentTableViewCell.h"
#import "Helper.h"
#import "UITextView+Utilities.h"
#define COMMENT_LABEL_WIDTH 234.0f
@interface CommentStatusViewController ()<UITableViewDataSource,UITableViewDelegate,UITextViewDelegate>{
    //cache cell height
    NSMutableDictionary *cellHeightMap;
    UISwipeGestureRecognizer *swipeGesture;
}
@property (strong, nonatomic) NSArray *dataSource;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *enterMessageContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *enterMessageContainerViewBottomSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation CommentStatusViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (!swipeGesture) {
        swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
        swipeGesture.direction = UISwipeGestureRecognizerDirectionRight;
    }
    [self.view addGestureRecognizer:swipeGesture];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void)handleSwipe:(UISwipeGestureRecognizer *)swipe{
    [self.textView resignFirstResponder];
    self.enterMessageContainerView.hidden = YES;
    [UIView animateWithDuration:1 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0 options:UIViewAnimationOptionTransitionNone animations:^{
        
        self.view.frame = CGRectMake(320, 100, 50,50);
    } completion:^(BOOL finished) {
        self.enterMessageContainerView.hidden= NO;
    }];
}

-(void)setStatusObjectId:(NSString *)statusObjectId{
    //fetch all the comments
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Comment"];
    [query whereKey:@"statusId" equalTo:statusObjectId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error && objects) {
            self.dataSource = objects;
            [self.tableView reloadData];
        }
    }];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)clearCommentTableView{
    self.dataSource = nil;
    [self.tableView reloadData];
}

-(void)sendComment{
    PFQuery *query = [[PFQuery alloc] initWithClassName:@"Comment"];
    [query whereKey:@"objectId" equalTo:self.statusObjectId];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (!error) {
            //create comment object
            PFObject *comment = [[PFObject alloc] initWithClassName:@"Comment"];
            comment[@"senderUsername"] = [PFUser currentUser].username;
            comment[@"statusId"] = self.statusObjectId;
#warning put textview content here
            comment[@"contentString"] = nil;

            //increase comment count on Status object
            object[@"commentCount"] = [NSNumber numberWithInt:[object[@"commentCount"] intValue] +1];

            [comment saveInBackground];
            [object saveInBackground];
        }
    }];
}

#pragma mark - keyboard notification 

-(void)handleKeyboardWillShow:(NSNotification *)notification{
    CGRect rect = [notification.userInfo[@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];

    CGRect convertedRect =  [self.view convertRect:rect fromView:nil];
    self.enterMessageContainerViewBottomSpaceConstraint.constant += self.view.frame.size.height - convertedRect.origin.y;
    [UIView animateWithDuration:.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}

-(void)handleKeyboardWillHide:(NSNotification *)notification{
    CGRect rect = [notification.userInfo[@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    self.enterMessageContainerViewBottomSpaceConstraint.constant = 0;
    [UIView animateWithDuration:.3 animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - UITableViewDelete

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    return self.dataSource.count;
}

//hides the liine separtors when data source has 0 objects
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    
    return view;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 100;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    CommentTableViewCell *cell = (CommentTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    PFObject *comment = self.dataSource[indexPath.row];
    cell.commentStringLabel.text = comment[@"contentString"];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(!self.dataSource || self.dataSource.count == 0){
        return 100.0f;
    }else{
        
        PFObject *comment = self.dataSource[indexPath.row];
        NSString *key =[NSString stringWithFormat:@"%lu",(unsigned long)comment.hash];
        //        NSLog(@"indexPath:%@",indexPath);
        //is cell height has been calculated, return it
        if ([cellHeightMap objectForKey:key]) {
            //            NSLog(@"return stored cell height: %f",[[cellHeightMap objectForKey:key] floatValue]);
            return [[cellHeightMap objectForKey:key] floatValue];
            
        }else{
            
            NSString *contentString = comment[@"contentString"];
            CGRect boundingRect =[contentString boundingRectWithSize:CGSizeMake(COMMENT_LABEL_WIDTH, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]} context:nil];  
            [cellHeightMap setObject:@(boundingRect.size.height+10) forKey:key];
            return boundingRect.size.height+10;
        }
    }
}

-(void)scrollTextViewToShowCursor{
    [self.textView scrollTextViewToShowCursor];
}

#pragma mark - uitextview delegate
-(BOOL)textViewShouldBeginEditing:(UITextView *)textView{
    [self performSelector:@selector(scrollTextViewToShowCursor) withObject:nil afterDelay:0.1f];
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
//    if (textView.text.length == 1 && [text isEqualToString:@""]) {
//        [self showPlaceHolderText];
//    }else{
//        [self hidePlaceHolderText];
//    }
    
    [self performSelector:@selector(scrollTextViewToShowCursor) withObject:NSStringFromRange(range) afterDelay:0.1f];
    return YES;
}

@end
