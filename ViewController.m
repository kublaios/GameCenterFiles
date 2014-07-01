//
//  ViewController.m
//  JumpYouBox
//
//  Created by Kubilay Erdogan on 12/06/14.
//  Copyright (c) 2014 kublaios. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

BOOL isGameCenterAvailable = true;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // check and set the highScore
    highScore = [defaults objectForKey:@"highScore"];
    if (highScore == nil) {
        highScore = @"0";
        [defaults setObject:highScore forKey:@"highScore"];
        [defaults synchronize];
    }
    
    // game center stuff
    currentLeaderBoard = @"HighScores";
    [[GameCenterFiles sharedInstance] authenticateLocalUser];

    // game center manager for submitting and displaying scores
    gameCenterManager = [[GameCenterFiles alloc] init];
    gameCenterManager.delegate = self;
    
}

// when a new score needs to be submitted
- (void)sendScore:(id)sender {
    // get score
    int score = 10;
    // score check
    if (score > highScore.intValue) {
        highScore = [NSString stringWithFormat:@"%i", score];
        // submit the score to the game center
        [gameCenterManager reportScore:highScore.intValue forCategory:currentLeaderBoard];
        NSLog(@"Submitted high score is %@", highScore);
        // sync the score
        [defaults setObject:highScore forKey:@"highScore"];
        [defaults synchronize];
    }
}

// when user taps on show high scores
- (void)open:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        GKGameCenterViewController *leaderboardViewController = [[GKGameCenterViewController alloc] init];
        if (leaderboardViewController) {
            leaderboardViewController.leaderboardIdentifier = currentLeaderBoard;
            leaderboardViewController.viewState = GKGameCenterViewControllerStateLeaderboards;
            leaderboardViewController.gameCenterDelegate = self;
            [self presentViewController:leaderboardViewController animated:YES completion:nil];
        }
    });
}

- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController {
    [gameCenterViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end