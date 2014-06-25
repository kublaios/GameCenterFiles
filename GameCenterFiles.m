//
//  GameCenterFiles.m
//  JumpYouBox
//
//  Created by Kubilay Erdogan on 25/06/14.
//  Copyright (c) 2014 kublaios. All rights reserved.
//

#import "GameCenterFiles.h"

@implementation GameCenterFiles

@synthesize earnedAchievementCache;
@synthesize gameCenterAvailable;
@synthesize presentingViewController;
@synthesize match;
@synthesize delegate;

#pragma mark Initialization

static GameCenterFiles *sharedHelper = nil;

+ (GameCenterFiles *) sharedInstance {
    if (!sharedHelper) {
        sharedHelper = [[GameCenterFiles alloc] init];
    }
    return sharedHelper;
}

- (BOOL)isGameCenterAvailable {
    
    Class gcClass = (NSClassFromString(@"GKLocalPlayer"));
	NSString *reqSysVer = @"4.1";
	NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
	BOOL osVersionSupported = ([currSysVer compare:reqSysVer
                                           options:NSNumericSearch] != NSOrderedAscending);
	
	return (gcClass && osVersionSupported);
}

- (id)init {
    if ((self = [super init])) {
        gameCenterAvailable = [self isGameCenterAvailable];
        if (gameCenterAvailable) {
            NSNotificationCenter *nc =
            [NSNotificationCenter defaultCenter];
            [nc addObserver:self
                   selector:@selector(authenticationChanged)
                       name:GKPlayerAuthenticationDidChangeNotificationName
                     object:nil];
        }
    }
    return self;
}

#pragma mark Internal functions

- (void)authenticationChanged {
    
    if ([GKLocalPlayer localPlayer].isAuthenticated && !userAuthenticated)
    {
        NSLog(@"Authentication changed: player authenticated.");
        userAuthenticated = TRUE;
    } else if (![GKLocalPlayer localPlayer].isAuthenticated && userAuthenticated)
    {
        NSLog(@"Authentication changed: player not authenticated");
        userAuthenticated = FALSE;
    }
    
}

#pragma mark User functions

- (void) submitAchievement: (NSString*) identifier percentComplete: (double) percent
{
    GKAchievement *achievement = [[GKAchievement alloc] initWithIdentifier: identifier];
    if (achievement)
    {
        achievement.percentComplete = percent;
        [achievement reportAchievementWithCompletionHandler:^(NSError *error)
         {
             if (error != nil)
             {
                 // Retain the achievement object and try again later (not shown).
             }
         }];
    }
}

- (void) resetAchievements
{
	self.earnedAchievementCache= NULL;
	[GKAchievement resetAchievementsWithCompletionHandler: ^(NSError *error)
     {
         if (error != nil)
         {
             // Retain the achievement object and try again later (not shown).
         }
     }];
    
}

- (void) reportScore: (int64_t) score forCategory: (NSString*) category
{
	GKScore *scoreReporter = [[GKScore alloc] initWithCategory:category] ;
	scoreReporter.value = score;
	[scoreReporter reportScoreWithCompletionHandler: ^(NSError *error)
     { if (error != nil)
     {
         // handle the reporting error
     }
         
         // [self callDelegateOnMainThread: @selector(scoreReported:) withArg: NULL error: error];
	 }];
}

#define SYSTEM_VERSION_LESS_THAN(v) ([[[UIDevice currentDevice] systemVersion] \
compare:v options:NSNumericSearch] == NSOrderedAscending)

- (void)authenticateLocalUser {
    
    if (!gameCenterAvailable) return;
    
    
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    if (SYSTEM_VERSION_LESS_THAN(@"6.0"))
    {
        // ios 5.x and below
        [localPlayer authenticateWithCompletionHandler:^(NSError *error)
         {
             [self checkLocalPlayer];
         }];
    }
    else
    {
        // ios 6.0 and above
        [localPlayer setAuthenticateHandler:(^(UIViewController* viewcontroller, NSError *error) {
            if (!error && viewcontroller)
            {
                [viewcontroller presentViewController:viewcontroller animated:YES completion:nil];
            }
            else
            {
                [self checkLocalPlayer];
            }
        })];
    }
}



- (void)checkLocalPlayer
{
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    
    if (localPlayer.isAuthenticated)
    {
        /* Perform additional tasks for the authenticated player here */
    }
    else
    {
        /* Perform additional tasks for the non-authenticated player here */
    }
}



- (void)findMatchWithMinPlayers:(int)minPlayers maxPlayers:(int)maxPlayers viewController:(UIViewController *)viewController delegate:(id<GameCenterFilesDelegate>)theDelegate {
    
    if (!gameCenterAvailable) return;
    
    matchStarted = NO;
    self.match = nil;
    self.presentingViewController = viewController;
    delegate = theDelegate;
    [presentingViewController dismissViewControllerAnimated:NO completion:nil];
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init] ;
    request.minPlayers = minPlayers;
    request.maxPlayers = maxPlayers;
    
    GKMatchmakerViewController *mmvc = [[GKMatchmakerViewController alloc] initWithMatchRequest:request] ;
    mmvc.matchmakerDelegate = self;
    
    [presentingViewController presentModalViewController:mmvc animated:YES];
    
}

#pragma mark GKMatchmakerViewControllerDelegate

// The user has cancelled matchmaking
- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController {
    //  [presentingViewController dismissModalViewControllerAnimated:YES completion:nil];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

// Matchmaking has failed with an error
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFailWithError:(NSError *)error {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"Error finding match: %@", error.localizedDescription);
}

// A peer-to-peer match has been found, the game should start
- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController didFindMatch:(GKMatch *)theMatch {
    [presentingViewController dismissViewControllerAnimated:YES completion:nil];
    self.match = theMatch;
    match.delegate = self;
    if (!matchStarted && match.expectedPlayerCount == 0) {
        NSLog(@"Ready to start match!");
    }
}

#pragma mark GKMatchDelegate

// The match received data sent from the player.
- (void)match:(GKMatch *)theMatch didReceiveData:(NSData *)data fromPlayer:(NSString *)playerID {
    
    if (match != theMatch) return;
    
    [delegate match:theMatch didReceiveData:data fromPlayer:playerID];
}

// The player state changed (eg. connected or disconnected)
- (void)match:(GKMatch *)theMatch player:(NSString *)playerID didChangeState:(GKPlayerConnectionState)state {
    
    if (match != theMatch) return;
    
    switch (state) {
        case GKPlayerStateConnected:
            // handle a new player connection.
            NSLog(@"Player connected!");
            
            if (!matchStarted && theMatch.expectedPlayerCount == 0) {
                NSLog(@"Ready to start match!");
            }
            
            break;
        case GKPlayerStateDisconnected:
            // a player just disconnected.
            NSLog(@"Player disconnected!");
            matchStarted = NO;
            [delegate matchEnded];
            break;
    }
    
}

// The match was unable to connect with the player due to an error.
- (void)match:(GKMatch *)theMatch connectionWithPlayerFailed:(NSString *)playerID withError:(NSError *)error {
    
    if (match != theMatch) return;
    
    NSLog(@"Failed to connect to player with error: %@", error.localizedDescription);
    matchStarted = NO;
    [delegate matchEnded];
}

// The match was unable to be established with any players due to an error.
- (void)match:(GKMatch *)theMatch didFailWithError:(NSError *)error {
    
    if (match != theMatch) return;
    
    NSLog(@"Match failed with error: %@", error.localizedDescription);
    matchStarted = NO;
    [delegate matchEnded];
}

@end