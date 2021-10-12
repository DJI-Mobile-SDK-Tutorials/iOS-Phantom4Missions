//
//  ActiveTrackViewController.m
//  P4Missions
//
//  Created by DJI on 15/3/16.
//  Copyright © 2016 DJI. All rights reserved.
//

#import "ActiveTrackViewController.h"
#import "TrackingRenderView.h"
#import "DemoUtility.h"
#import "DJIScrollView.h"

@interface ActiveTrackViewController () <DJIVideoFeedListener, TrackingRenderViewDelegate, DJIVideoPreviewerFrameControlDelegate>

@property (weak, nonatomic) IBOutlet UIView *fpvView;
@property (weak, nonatomic) IBOutlet TrackingRenderView *renderView;
@property (weak, nonatomic) IBOutlet UIButton *acceptButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *rejectButton;
@property (weak, nonatomic) IBOutlet UILabel *retreatEnabledLabel;
@property (weak, nonatomic) IBOutlet UILabel *gestureEnabledLabel;
@property (weak, nonatomic) IBOutlet UISwitch *retreatSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *gestureSwitch;

@property(nonatomic) DJIScrollView *statusView;
@property(nonatomic, assign) CGRect currentTrackingRect;

@property(nonatomic, assign) BOOL isNeedConfirm;
@property(nonatomic, assign) BOOL isTrackingMissionRunning;

@end

@implementation ActiveTrackViewController

#pragma mark - Inherited Methods

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[DJIVideoPreviewer instance] setView:self.fpvView];
    [[DJISDKManager videoFeeder].primaryVideoFeed addListener:self withQueue:nil];
    [[DJIVideoPreviewer instance] start];
    [DJIVideoPreviewer instance].frameControlHandler = self;

    [[self missionOperator] setRecommendedConfigurationWithCompletion:^(NSError * _Nullable error) {
        if(error){
            ShowResult(@"Set Recommended recommended camera and gimbal configuration: %@", error.localizedDescription);
        }
    }];
    
    DJICamera* camera = [DemoUtility fetchCamera];
    if (camera.displayName == DJICameraDisplayNameMavic2ZoomCamera ||
        camera.displayName == DJICameraDisplayNameMavic2ProCamera) {
        [[self missionOperator] enableAutoSensingWithCompletion:^(NSError * _Nullable error) {
            if (error) {
                ShowResult(@"Start Auto Sensing Failed:%@", error.localizedDescription);
            }
        }];
    }
    
    [self updateButtons];
    [self updateGestureEnabled];
    [self updateRetreatEnabled];
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[DJIVideoPreviewer instance] unSetView];
    [[DJISDKManager videoFeeder].primaryVideoFeed removeListener:self];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"ActiveTrack Mission";
    
    self.renderView.delegate = self;
    
    [self.retreatEnabledLabel setTextColor:[UIColor whiteColor]];
    [self.gestureEnabledLabel setTextColor:[UIColor whiteColor]];
    
    self.statusView = [DJIScrollView viewWithViewController:self];
    self.statusView.fontSize = 18;

    weakSelf(target);
    [[self missionOperator] addListenerToEvents:self withQueue:dispatch_get_main_queue() andBlock:^(DJIActiveTrackMissionEvent * _Nonnull event) {
        weakReturn(target);
        [target didUpdateEvent:event];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(DJIActiveTrackMissionOperator *) missionOperator {
    return [DJISDKManager missionControl].activeTrackMissionOperator;
}

-(void)updateRetreatEnabled {
    weakSelf(target);
    [[self missionOperator] getRetreatEnabledWithCompletion:^(BOOL boolean, NSError * _Nullable error) {
        weakReturn(target);
        if (!error) {
            target.retreatSwitch.on = boolean;
        }else{
            ShowResult(@"Get RetreatEnabled failed");
        }
    }];
}

-(void)updateGestureEnabled {
    
    self.gestureSwitch.on = [[self missionOperator] isGestureModeEnabled];
}

- (BOOL)isTrackingState:(DJIActiveTrackMissionState)state {
    switch (state) {
        case DJIActiveTrackMissionStateFindingTrackedTarget:
        case DJIActiveTrackMissionStateAircraftFollowing:
        case DJIActiveTrackMissionStateOnlyCameraFollowing:
        case DJIActiveTrackMissionStateCannotConfirm:
        case DJIActiveTrackMissionStateWaitingForConfirmation:
        case DJIActiveTrackMissionStatePerformingQuickShot:
            return YES;
            
        default:
            break;
    }
    return NO;
}

- (BOOL)isTrackingMissionRunning {
    return [self isTrackingState:[self missionOperator].currentState];
}

-(void)updateButtons {
    
    self.stopButton.hidden = ![self isTrackingMissionRunning];

    if ([self missionOperator].currentState != DJIActiveTrackMissionStateWaitingForConfirmation) {
        self.acceptButton.hidden = YES;
    }else{
        self.acceptButton.hidden = NO;
    }

    if (([self missionOperator].currentState == DJIActiveTrackMissionStateAircraftFollowing ||
           [self missionOperator].currentState == DJIActiveTrackMissionStateFindingTrackedTarget) && [self missionOperator].trackingMode == DJIActiveTrackModeTrace) {
        self.rejectButton.hidden = NO;
    }else
    {
        self.rejectButton.hidden = YES;
    }
    
}

-(void)didUpdateEvent:(DJIActiveTrackMissionEvent *)event {

    DJIActiveTrackMissionState prevState = event.previousState;
    DJIActiveTrackMissionState curState = event.currentState;
    if ([self isTrackingState:prevState] &&
        ![self isTrackingState:curState]) {
        if (event.error) {
            ShowResult(@"Mission Interrupted: %@", event.error.description);
        }
    }
    
    if (event.trackingState) {
        DJIActiveTrackTrackingState *state = event.trackingState;
        CGRect rect = [DemoUtility rectFromStreamSpace:state.targetRect withView:self.renderView];
        self.currentTrackingRect = rect;
        if (event.trackingState.state == DJIActiveTrackTargetStateWaitingForConfirmation) {
            self.isNeedConfirm = YES;
            self.renderView.text = @"?";
        }
        else {
            self.isNeedConfirm = NO;
            self.renderView.text = nil;
        }
        UIColor *color = nil;
        switch (state.state) {
            case DJIActiveTrackTargetStateWaitingForConfirmation:
                color = [[UIColor orangeColor] colorWithAlphaComponent:0.5];
                break;
            case DJIActiveTrackTargetStateCannotConfirm:
                color = [[UIColor redColor] colorWithAlphaComponent:0.5];
                break;
            case DJIActiveTrackTargetStateTrackingWithHighConfidence:
                color = [[UIColor greenColor] colorWithAlphaComponent:0.5];
                break;
            case DJIActiveTrackTargetStateTrackingWithLowConfidence:
                color = [[UIColor yellowColor]colorWithAlphaComponent:0.5];
                break;
            case DJIActiveTrackTargetStateUnknown:
                color = [[UIColor grayColor] colorWithAlphaComponent:0.5];
                break;
            default:
                break;
        }
        [self.renderView updateRect:rect fillColor:color];
    }
    else {
        self.renderView.isDottedLine = NO;
        self.renderView.text = nil;
        self.isNeedConfirm = NO;
        [self.renderView updateRect:CGRectNull fillColor:nil];
    }
    
    NSMutableString* logString = [[NSMutableString alloc] init];
    [logString appendFormat:@"From State:%@\n", [DemoUtility stringFromActiveTrackState:prevState]];
    [logString appendFormat:@"To State:%@\n", [DemoUtility stringFromActiveTrackState:curState]];
    [logString appendFormat:@"Tracking State:%@\n", event.trackingState ? [DemoUtility stringFromTargetState:event.trackingState.state] : nil];
    [logString appendFormat:@"Cannot Confirm Reason:%@\n", event.trackingState ? [DemoUtility stringFromCannotConfirmReason:event.trackingState.cannotConfirmReason] : nil];
    [logString appendFormat:@"Error:%@\n", event.error.localizedDescription];
    [logString appendFormat:@"PersistentError:%@", [self missionOperator].persistentError.localizedDescription];
    [logString appendFormat:@"QuickMoive Progress:%tu", event.trackingState.progress];
    
    [self.statusView writeStatus:logString];
    [self updateButtons];
    
}

#pragma mark TrackingRenderView Delegate Methods

-(void) renderViewDidTouchAtPoint:(CGPoint)point
{
    if (self.isTrackingMissionRunning && !self.isNeedConfirm) {
        return;
    }
    
    if (self.isNeedConfirm) {
        CGRect largeRect = CGRectInset(self.currentTrackingRect, -10, -10);
        if (CGRectContainsPoint(largeRect, point)) {
            [[self missionOperator] acceptConfirmationWithCompletion:^(NSError * _Nullable error) {
                ShowResult(@"Confirm Tracking:%@", error.localizedDescription);
            }];
        }
        else
        {
            [[self missionOperator] stopMissionWithCompletion:^(NSError * _Nullable error) {
                ShowResult(@"Cancel Tracking:%@", error.localizedDescription);
            }];
        }
    }
    else
    {
        weakSelf(target);
        point = [DemoUtility pointToStreamSpace:point withView:self.renderView];
        DJIActiveTrackMission* mission = [[DJIActiveTrackMission alloc] init];
        mission.targetRect = CGRectMake(point.x, point.y, 0, 0);
        mission.mode = DJIActiveTrackModeTrace;
        [[self missionOperator] startMission:mission withCompletion:^(NSError * _Nullable error) {
            if (error) {
                ShowResult(@"Start Mission Error:%@", error.localizedDescription);
                if (error) {
                    weakReturn(target);
                    target.renderView.isDottedLine = NO;
                    [target.renderView updateRect:CGRectNull fillColor:nil];
                }
            }
            else
            {
                ShowResult(@"Start Mission Success");
            }

        }];
        
    }
}

-(void) renderViewDidMoveToPoint:(CGPoint)endPoint fromPoint:(CGPoint)startPoint isFinished:(BOOL)finished
{

    self.renderView.isDottedLine = YES;
    self.renderView.text = nil;
    CGRect rect = [DemoUtility rectWithPoint:startPoint andPoint:endPoint];
    [self.renderView updateRect:rect fillColor:[[UIColor greenColor] colorWithAlphaComponent:0.5]];
    if (finished) {
        CGRect rect = [DemoUtility rectWithPoint:startPoint andPoint:endPoint];
        [self startMissionWithRect:rect];
    }
}

#pragma mark IBAction Methods

- (IBAction) onStopButtonClicked:(id)sender
{
    [[self missionOperator] stopMissionWithCompletion:^(NSError * _Nullable error) {
        if (error) {
            ShowResult(@"Stop Mission Failed: %@", error.description);
        }
    }];
    
}

- (IBAction)onAcceptButtonClicked:(id)sender {
    
    [[self missionOperator] acceptConfirmationWithCompletion:^(NSError * _Nullable error) {
        if (error) {
            ShowResult(@"Accept Confirmation Failed: %@", error.description);
        }
    }];
}

- (IBAction)onRejectButtonClicked:(id)sender {
    
    DJICamera* camera = [DemoUtility fetchCamera];
    if (camera.displayName == DJICameraDisplayNameMavic2ZoomCamera ||
        camera.displayName == DJICameraDisplayNameMavic2ProCamera) {
        [[self missionOperator] rejectConfirmationWithCompletion:^(NSError *_Nullable error) {
          if (error) {
              ShowResult(@"Reject Confirmation Failed: %@", error.description);
          }
        }];
        return;
    }
   
    [[self missionOperator] stopAircraftFollowingWithCompletion:^(NSError * _Nullable error) {
            ShowResult(@"Stop Aircraft Following Failed: %@", error.description);
    }];
    
}

- (IBAction)onGestureEnabledSwitchValueChanged:(UISwitch*)sender {
  
    weakSelf(target);
    [[self missionOperator] setGestureModeEnabled:sender.isOn withCompletion:^(NSError * _Nullable error) {
        weakReturn(target);
        if (error != nil) {
            NSLog(@"Set Gesture Mode Enabled failed.");
        }else{
            NSLog(@"Set Gesture Mode Enabled success.");
            [target updateGestureEnabled];
        }
    }];
    
}

- (IBAction) onRetreatEnabledSwitchValueChanged:(UISwitch*)sender
{
    weakSelf(target);
    [[self missionOperator] setRetreatEnabled:sender.isOn withCompletion:^(NSError * _Nullable error) {
        weakReturn(target);
        if (error != nil) {
            NSLog(@"Set Retreat Enabled failed.");
        }else{
            NSLog(@"Set Retreat Enabled success.");
            [target updateRetreatEnabled];
        }
    }];
    
}

- (IBAction)onSetRecommendedConfigurationClicked:(id)sender {
    
    [[self missionOperator] setRecommendedConfigurationWithCompletion:^(NSError * _Nullable error) {
        if (error) {
            ShowResult(@"Set Recommended Camera and Gimbal Configuration Failed: %@", error.localizedDescription);
        }else{
            ShowResult(@"Set Recommended Camera and Gimbal Configuration Success.");
        }
        
    }];
}

- (IBAction)showStatusButtonAction:(id)sender {
    [self.statusView setHidden:NO];
    [self.statusView show];
}

#pragma mark Custom Methods
-(void) startMissionWithRect:(CGRect)rect
{
    CGRect normalizedRect = [DemoUtility rectToStreamSpace:rect withView:self.renderView];
    DJIActiveTrackMission* trackMission = [[DJIActiveTrackMission alloc] init];
    trackMission.targetRect = normalizedRect;
    trackMission.mode = DJIActiveTrackModeTrace;
    
    weakSelf(target);
    [[self missionOperator] startMission:trackMission withCompletion:^(NSError * _Nullable error) {
        if (error) {
            weakReturn(target);
            target.renderView.isDottedLine = NO;
            [target.renderView updateRect:CGRectNull fillColor:nil];
            ShowResult(@"Start Mission Error:%@", error.localizedDescription);
        }
        else
        {
            ShowResult(@"Start Mission Success");
        }

    }];

}

#pragma mark - DJIVideoFeedListener

-(void)videoFeed:(DJIVideoFeed *)videoFeed didUpdateVideoData:(NSData *)videoData {
    [[DJIVideoPreviewer instance] push:(uint8_t *)videoData.bytes length:(int)videoData.length];
}

- (BOOL)isNeedFitFrameWidth {
    NSString* displayName = [DemoUtility fetchCamera].displayName;
    if ([displayName isEqualToString:DJICameraDisplayNameMavic2ZoomCamera] ||
        [displayName isEqualToString:DJICameraDisplayNameMavic2ProCamera]) {
        return YES;
    }
    
    return NO;
}

- (BOOL)parseDecodingAssistInfoWithBuffer:(uint8_t *)buffer length:(int)length assistInfo:(DJIDecodingAssistInfo *)assistInfo {
    return [[DJISDKManager videoFeeder].primaryVideoFeed parseDecodingAssistInfoWithBuffer:buffer length:length assistInfo:(void *)assistInfo];
}

- (void)syncDecoderStatus:(BOOL)isNormal {
    [[DJISDKManager videoFeeder].primaryVideoFeed syncDecoderStatus:isNormal];
}

- (void)decodingDidSucceedWithTimestamp:(uint32_t)timestamp {
    [[DJISDKManager videoFeeder].primaryVideoFeed decodingDidSucceedWithTimestamp:(NSUInteger)timestamp];
}

- (void)decodingDidFail {
    [[DJISDKManager videoFeeder].primaryVideoFeed decodingDidFail];
}

@end
