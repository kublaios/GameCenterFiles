//
//  ViewController.h
//  JumpYouBox
//
//  Created by Kubilay Erdogan on 12/06/14.
//  Copyright (c) 2014 kublaios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import "GameCenterFiles.h"

@interface ViewController : UIViewController <GKGameCenterControllerDelegate, GameCenterFilesDelegate> {
    GameCenterFiles *gameCenterManager;
    NSString *currentLeaderBoard;
    NSString *highScore;
}

@end