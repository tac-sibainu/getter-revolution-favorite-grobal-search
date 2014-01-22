//
//  MasterViewController.h
//  Getter
//
//  Created by 大坪裕樹 on 2013/10/22.
//  Copyright (c) 2013年 大坪裕樹. All rights reserved.
//

#import <UIKit/UIKit.h>
@interface MasterViewController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate>{
    UISearchBar     *m_Srch;
}

@property (strong,nonatomic) NSArray *candyArray;
@property (strong,nonatomic) NSMutableArray *filteredCandyArray;
@property IBOutlet UISearchBar *candySearchBar;

@end