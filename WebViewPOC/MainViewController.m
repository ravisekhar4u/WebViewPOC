//
//  ViewController.m
//  WebViewPOC
//
//  Created by Pitapurapu,Ravi on 6/11/15.
//  Copyright (c) 2015 Pitapurapu,Ravi. All rights reserved.
//

#import "MainViewController.h"

#import <AddressBookUI/AddressBookUI.h>

@interface MainViewController () <UIWebViewDelegate,ABPeoplePickerNavigationControllerDelegate>

@property (nonatomic, strong) IBOutlet UIWebView    *webView;
@property (nonatomic, strong) NSString              *firstName;
@property (nonatomic, strong) NSString              *lastName;
@property (nonatomic, strong) NSString              *phoneNumber;
@property (nonatomic, strong) NSString              *email;

@end

BOOL isContactLoaded = NO;

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareWebView];
}

- (void)prepareWebView
{
    self.webView.delegate = self;

//    NSString *url = @"http://www.google.com";
//    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
//    [self.webView loadRequest:request];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"]isDirectory:NO]]];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
//    if (isContactLoaded)
//    {
//        NSString *functionCall = [NSString stringWithFormat:@"fillInContactInfo(%@,%@,%@,%@)",self.firstName,self.lastName,self.phoneNumber,self.email];
//        [self.webView stringByEvaluatingJavaScriptFromString:functionCall];
//    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    BOOL returnType = NO;
    isContactLoaded = NO;
    switch (navigationType)
    {
        case UIWebViewNavigationTypeOther:
            returnType = YES;
            break;
            
        case UIWebViewNavigationTypeLinkClicked:
            returnType = NO;
            [self launchContacts];
            break;
            
        default:
            break;
    }
    
    return returnType;
}

- (void)launchContacts
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        //Background Thread
        ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
        picker.peoplePickerDelegate = self;
        dispatch_async(dispatch_get_main_queue(), ^(void){
            //Run UI Updates
                [self presentViewController:picker animated:YES completion:nil];
        });
    });
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    [peoplePicker dismissViewControllerAnimated:YES completion:nil];
}


- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController*)peoplePicker didSelectPerson:(ABRecordRef)person
{
    
    [self fetchInfoFromPerson:person];
    [self logContactInfo];
    [peoplePicker dismissViewControllerAnimated:YES completion:nil];
    if (isContactLoaded)
    {
        NSString *function = [NSString stringWithFormat:@"setTimeout(function(){\ndocument.getElementById(\"divContact\").style.display = \"block\";\nvar firstName = document.getElementById( \"fname\");\nfirstName.innerHTML =\"First Name : %@ \";\nvar lastName = document.getElementById( \"lname\");\nlastName.innerHTML = \"Last Name : %@ \";\nvar phoneNumber = document.getElementById(\"phone\");\nphoneNumber.innerHTML = \"Phone Number : %@\";\nvar emailElement = document.getElementById(\"email\");\nemailElement.innerHTML = \"Email : %@\";},1);",self.firstName,self.lastName,self.phoneNumber,self.email];
        
        [self.webView stringByEvaluatingJavaScriptFromString:function];
    }
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person
                                property:(ABPropertyID)property
                              identifier:(ABMultiValueIdentifier)identifier
{
    return NO;
}

- (void)fetchInfoFromPerson:(ABRecordRef)person
{
    [self extractFirstAndLastNamesFromRecord:person];
    [self extractEmailFromRecord:person];
    [self extractPhoneFromRecord:person];
    isContactLoaded = YES;
}

- (void)extractFirstAndLastNamesFromRecord:(ABRecordRef)person
{
    NSString* fname = (__bridge_transfer NSString*)ABRecordCopyValue(person,
                                                                     kABPersonFirstNameProperty);
    self.firstName = fname;
    
    NSString* lname = (__bridge_transfer NSString*)ABRecordCopyValue(person,
                                                                     kABPersonLastNameProperty);
    self.lastName = lname;
}

- (void)extractPhoneFromRecord:(ABRecordRef)person
{
    NSString* phone = nil;
    ABMultiValueRef phoneNumbers = ABRecordCopyValue(person,
                                                     kABPersonPhoneProperty);
    if (ABMultiValueGetCount(phoneNumbers) > 0) {
        phone = (__bridge_transfer NSString*)
        ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
    } else {
        phone = @"[None]";
    }
    
    self.phoneNumber = phone;
    CFRelease(phoneNumbers);
}

- (void)extractEmailFromRecord:(ABRecordRef)person
{
    NSString* email = nil;
    ABMultiValueRef emails = ABRecordCopyValue(person,
                                               kABPersonEmailProperty);
    if (ABMultiValueGetCount(emails) > 0)
        email = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(emails, 0);
    else
        email = @"[None]";
    
    self.email = email;
    CFRelease(emails);
}

- (void)logContactInfo
{
    NSLog(@"First Name      : %@ \n",self.firstName);
    NSLog(@"Last Name       : %@ \n",self.lastName);
    NSLog(@"Phone Number    : %@ \n",self.phoneNumber);
    NSLog(@"Email           : %@ \n",self.email);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
