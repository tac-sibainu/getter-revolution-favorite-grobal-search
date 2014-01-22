//
//  MasterViewController.m
//  Getter
//
//  Created by 大坪裕樹 on 2013/10/22.
//  Copyright (c) 2013年 大坪裕樹. All rights reserved.
//

#import "MasterViewController.h"
#import "DetailViewController.h"
#import "TweetViewController.h"
#import "ProfileViewController.h"
#import "QuartzCore/QuartzCore.h"
#define SEARCH_HEIGHT   (32.0f)

@interface MasterViewController()

@property (nonatomic, retain) UIImage *profileImage;
@property (nonatomic, retain) UIImage *bannerImage;
@end


#import "SBJson.h"
#import "GTMOAuthAuthentication.h"
#import "GTMOAuthViewControllerTouch.h"

@implementation MasterViewController {
    // OAuth認証オブジェクト
    GTMOAuthAuthentication *auth_;
    // 表示中ツイート情報
    NSArray *timelineStatuses_;
    NSArray *timelineStatuses2_;
    
    NSDictionary *user;
    NSDictionary *user2;
}

@synthesize profileImage;
@synthesize bannerImage;
@synthesize filteredCandyArray;

- (void)awakeFromNib
{
    [super awakeFromNib];
}

// KeyChain登録サービス名
static NSString *const kKeychainAppServiceName = @"KodawariButter";

- (void)viewDidLoad
{
    
    self.navigationController.navigationBar.barTintColor = [UIColor redColor];
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    self.navigationController.navigationBar.tintColor = [UIColor greenColor];
    // Do any additional setup after loading the view, typically from a nib.
    CGRect rc = [[UIScreen mainScreen] applicationFrame];
    // SearchBar
    m_Srch = [[UISearchBar alloc] initWithFrame:CGRectMake( 0, 0, rc.size.width, SEARCH_HEIGHT)];
    [m_Srch setTintColor:[UIColor greenColor]];
    m_Srch.barStyle = UIBarStyleBlack;
    [m_Srch setPlaceholder:@"Search Word"];
    [m_Srch setShowsCancelButton:YES];
    
    [self.view addSubview:m_Srch];
    m_Srch.delegate = self;
    
    // GTMOAuthAuthenticationインスタンス生成
    // ※自分の登録アプリの Consumer Key と Consumer Secret に書き換えてください
    NSString *consumerKey = @"2tb4YeEFfV7LtUQk3s7AQw";
    NSString *consumerSecret = @"38To4tIdT71q0lYLuxkhXeF4qJcsGQ6eH1H3xcv79U";
    auth_ = [[GTMOAuthAuthentication alloc]
             initWithSignatureMethod:kGTMOAuthSignatureMethodHMAC_SHA1
             consumerKey:consumerKey
             privateKey:consumerSecret];
    
    // 既にOAuth認証済みであればKeyChainから認証情報を読み込む
    BOOL authorized = [GTMOAuthViewControllerTouch
                       authorizeFromKeychainForName:kKeychainAppServiceName
                       authentication:auth_];
    if (authorized) {
        // 認証済みの場合はタイムライン更新
        [self asyncShowHomeTimeline];
    } else {
        // 未認証の場合は認証処理を実施
        [self asyncSignIn];
    }
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// 認証処理
- (void)asyncSignIn
{
    NSString *requestTokenURL = @"https://api.twitter.com/oauth/request_token";
    NSString *accessTokenURL = @"https://api.twitter.com/oauth/access_token";
    NSString *authorizeURL = @"https://api.twitter.com/oauth/authorize";
    
    NSString *keychainAppServiceName = @"KodawariButter";
    
    auth_.serviceProvider = @"Twitter";
    auth_.callback = @"http://www.example.com/OAuthCallback";
    
    GTMOAuthViewControllerTouch *viewController;
    viewController = [[GTMOAuthViewControllerTouch alloc]
                      initWithScope:nil
                      language:nil
                      requestTokenURL:[NSURL URLWithString:requestTokenURL]
                      authorizeTokenURL:[NSURL URLWithString:authorizeURL]
                      accessTokenURL:[NSURL URLWithString:accessTokenURL]
                      authentication:auth_
                      appServiceName:keychainAppServiceName
                      delegate:self
                      finishedSelector:@selector(authViewContoller:finishWithAuth:error:)];
    
    [[self navigationController] pushViewController:viewController animated:YES];
}

// 認証エラー表示AlertViewタグ
static const int kMyAlertViewTagAuthenticationError = 1;

// 認証処理が完了した場合の処理
- (void)authViewContoller:(GTMOAuthViewControllerTouch *)viewContoller
           finishWithAuth:(GTMOAuthAuthentication *)auth
                    error:(NSError *)error
{
    if (error != nil) {
        // 認証失敗
        NSLog(@"Authentication error: %d.", error.code);
        UIAlertView *alertView;
        alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                               message:@"Authentication failed."
                                              delegate:self
                                     cancelButtonTitle:@"Confirm"
                                     otherButtonTitles:nil];
        alertView.tag = kMyAlertViewTagAuthenticationError;
        [alertView show];
    } else {
        // 認証成功
        NSLog(@"Authentication succeeded.");
        // タイムライン表示
        [self asyncShowHomeTimeline];
    }
}

// UIAlertViewが閉じられた時
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // 認証失敗通知AlertViewが閉じられた場合
    if (alertView.tag == kMyAlertViewTagAuthenticationError) {
        // 再度認証
        [self asyncSignIn];
    }
}

// デフォルトのタイムライン処理表示
- (void)asyncShowHomeTimeline
{
    //[self fetchGetHomeTimeline];
    NSURL *url01 = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    NSString *tl01 = @"tl01";
    [self fetchGetHomeTimeline:url01 timeLine:tl01];
}

// タイムライン (home_timeline) 取得
- (void)fetchGetHomeTimeline:(NSURL *)url timeLine:(NSString *)tl
{
    // 要求を準備
    //NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    // 要求に署名情報を付加
    [auth_ authorizeRequest:request];
    
    // 非同期通信による取得開始
    if([tl  isEqual: @"tl01"]){
        GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
        [fetcher beginFetchWithDelegate:self
                      didFinishSelector:@selector(homeTimelineFetcher:finishedWithData:error:)];
    } else if([tl  isEqual: @"tl02"]){
        GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
        [fetcher beginFetchWithDelegate:self
                      didFinishSelector:@selector(homeTimelineFetcher02:finishedWithData:error:)];
    }
}

// タイムライン (home_timeline) 取得応答時
- (void)homeTimelineFetcher:(GTMHTTPFetcher *)fetcher
           finishedWithData:(NSData *)data
                      error:(NSError *)error
{
    if (error != nil) {
        // タイムライン取得時エラー
        NSLog(@"Fetching status/home_timeline error: %d", error.code);
        return;
    }
    
    // タイムライン取得成功
    // JSONデータをパース
    NSError *jsonError = nil;
    NSArray *statuses = [NSJSONSerialization JSONObjectWithData:data
                                                        options:0
                                                          error:&jsonError];
    
    // JSONデータのパースエラー
    if (statuses == nil) {
        NSLog(@"JSON Parser error: %d", jsonError.code);
        return;
    }
    
    // データを保持
    timelineStatuses_ = statuses;
    
    // テーブルを更新
    [self.tableView reloadData];
}
    
- (void)homeTimelineFetcher02:(GTMHTTPFetcher *)fetcher
finishedWithData:(NSData *)data
error:(NSError *)error
    {
        if (error != nil) {
            // タイムライン取得時エラー
            NSLog(@"Fetching status/home_timeline error: %d", error.code);
            return;
        }
        
        // タイムライン取得成功
        // JSONデータをパース
        NSError *jsonError = nil;
        NSArray *statuses = [NSJSONSerialization JSONObjectWithData:data
                                                            options:0
                                                              error:&jsonError];
        
        // JSONデータのパースエラー
        if (statuses == nil) {
            NSLog(@"JSON Parser error: %d", jsonError.code);
            return;
        }
        
        // データを保持
        timelineStatuses2_ = statuses;
    }

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [timelineStatuses_ count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    // 対象インデックスのステータス情報を取り出す
    NSDictionary *status = [timelineStatuses_ objectAtIndex:indexPath.row];
    
    // ツイート本文を表示
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [UIFont fontWithName:@"Geeza Pro" size:9];
   // cell.contentView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    cell.textLabel.text = [status objectForKey:@"text"];
    
    // ユーザ情報から screen_name を取り出して表示
    //NSDictionary *user = [status objectForKey:@"user"];
    user = [status objectForKey:@"user"];
    cell.detailTextLabel.text = [user objectForKey:@"screen_name"];
    NSURL *url = [NSURL URLWithString:[user objectForKey:@"profile_image_url"]];
    NSData *Tweetdata = [NSData dataWithContentsOfURL:url];
    
    UIImage *img = [UIImage imageWithData:Tweetdata];  // 切り取り前UIImage
    
    float widthPer = 0.8;  // リサイズ後幅の倍率
    float heightPer = 0.8;  // リサイズ後高さの倍率
    CGSize sz = CGSizeMake(img.size.width*widthPer,
                           img.size.height*heightPer);
    UIGraphicsBeginImageContext(sz);
    [img drawInRect:CGRectMake(0, 0, sz.width, sz.height)];
    img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    cell.imageView.layer.masksToBounds = YES;
    cell.imageView.layer.cornerRadius = 5.0f;
    
    cell.imageView.image = img;


    NSLog(@"%@ - %@", [status objectForKey:@"text"], [[status objectForKey:@"user"] objectForKey:@"screen_name"]);
    // UIButtonインスタンスを生成する
	UIButton *sampleButton = [ UIButton buttonWithType:UIButtonTypeRoundedRect ];
    UIImage *favo = [UIImage imageNamed:@"getter_favo.png"];
    
    sampleButton.tag = (NSInteger)[status objectForKey:@"id_str"]; // senderで渡すため
    
	// ボタンの位置とサイズを指定する
	sampleButton.frame = CGRectMake(280, 10, 30, 40 );
	// ボタンのラベル文字列を指定する
	//[ sampleButton setTitle:@"★" forState:UIControlStateNormal ];
    [sampleButton setBackgroundImage:favo forState:UIControlStateNormal];
	// ボタンがタップされたときの動作を定義する
	[ sampleButton addTarget:self action:@selector(fetchPostFavorite:) forControlEvents:UIControlEventTouchUpInside ];
	// ボタンを画面に表示する
	[ cell addSubview:sampleButton ];
    
    return cell;
}



//------------------------------------------------------------------------------
- (void)fetchPostFavorite:(NSString *)sender
{
    NSLog( @"タップされたよ！" );
    
    UIButton *sampleButton = (UIButton *)sender;
    UIImage *favo = [UIImage imageNamed:@"getter_favoed2.png"];
        [sampleButton setBackgroundImage:favo forState:UIControlStateNormal];
    NSLog(@"ID---- %@",sampleButton.tag);
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/favorites/create.json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

    // idパラメータをURI符号化してbodyにセット
    NSString *body = [NSString stringWithFormat:@"id=%@", sampleButton.tag];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    // 要求に署名情報を付加
    [auth_ authorizeRequest:request];
    
    
    NSLog(@"body---- %@",body);
    
    
    // 接続開始
    GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
    [fetcher beginFetchWithDelegate:self
didFinishSelector:@selector(tweetFavoriteFetcher:finishedWithData:error:)];
    
}

// favoriteに対する動作
- (void)tweetFavoriteFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error
{
    if (error != nil) {
        // favorite取得エラー
        NSLog(@"Fetching statuses/favorites/create error: %d", error.code);
        return;
    }
    NSLog( @"お気に入りに登録したよ , %d",error.code );
    
    // タイムライン更新
    //[self fetchGetHomeTimeline];
    //NSURL *url01 = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    //NSString *tl01 = @"tl01";
    //[self fetchGetHomeTimeline:url01 timeLine:tl01];
}
//------------------------------------------------------------------------------

//------------------ツイート検索--------------------------------------

#pragma mark - 検索
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [m_Srch resignFirstResponder];
    
    NSLog(@"検索 : %@", m_Srch.text);
    NSString *hashTag = [NSString stringWithFormat:@"%@", m_Srch.text];
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json"];
    NSString *encode = [GTMOAuthAuthentication encodedOAuthParameterForString:hashTag];
    
    GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithURLString:[NSString stringWithFormat:@"%@?q=%@", url, encode]];
    [fetcher setAuthorizer:auth_];
    [fetcher beginFetchWithDelegate:self didFinishSelector:@selector(searchDidComplete:finishedWithData:error:)];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [m_Srch resignFirstResponder];
    
    // タイムライン更新
    //[self fetchGetHomeTimeline];
    NSURL *url01 = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    NSString *tl01 = @"tl01";
    [self fetchGetHomeTimeline:url01 timeLine:tl01];
}

- (void)searchDidComplete:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error
{
    if( error != nil )
    {
        NSLog(@"error : %d", error.code);
    } else
    {
        NSLog(@"success");
        

        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        SBJsonParser *parser = [[SBJsonParser alloc] init];
        
        NSDictionary *req = [parser objectWithString:str];
        NSLog(@"%@", req);

        timelineStatuses_ = [req objectForKey:@"statuses"];
        NSLog(@"%@",timelineStatuses_);
        
        NSLog(@"Count = %d", [timelineStatuses_ count]);
        for( int i = 0; i < [timelineStatuses_ count]; i++ )
        {
            NSDictionary *dict = [timelineStatuses_ objectAtIndex:i];
            NSDictionary *usr = [dict objectForKey:@"user"];
            NSLog(@"%@ : %@", [usr objectForKey:@"screen_name"], [dict objectForKey:@"text"]);
        }
        
        // テーブルを更新
        [self.tableView reloadData];
    }
}


//------------------------------------------------------------------------------

// 指定位置の行で使用する高さの要求
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // 対象インデックスのステータス情報を取り出す
    NSDictionary *status = [timelineStatuses_ objectAtIndex:indexPath.row];
    
    // ツイート本文をもとにセルの高さを決定
    NSString *content = [status objectForKey:@"text"];
    CGSize labelSize = [content sizeWithFont:[UIFont systemFontOfSize:12]
                           constrainedToSize:CGSizeMake(300, 1000)
                               lineBreakMode:UILineBreakModeWordWrap];
    return labelSize.height + 25;
}

//セルを選択したときにscreen_nameを特定する。
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //特定した人のタイムラインだけを「NSDictionary *title」にいれる。
    NSDictionary *title = [timelineStatuses_ objectAtIndex:indexPath.row];
    //titleの中身を表示
    NSLog (@"start-----------------------------------------------------------------");
    NSLog(@"%@",title);
    NSLog (@"end-------------------------------------------------------------------");
    //titleから「user」の構造だけをぬきとる。
    user2 = [title objectForKey:@"user"];
    //プロフィール画像用。
    NSURL *url = [NSURL URLWithString:[user2 objectForKey:@"profile_image_url"]];
    NSData *Tweetdata = [NSData dataWithContentsOfURL:url];
    profileImage = [UIImage imageWithData:Tweetdata];
    
    NSURL *url2 = [NSURL URLWithString:[user2 objectForKey:@"profile_banner_url"]];
    NSData *Tweetdata2 = [NSData dataWithContentsOfURL:url2];
    bannerImage = [UIImage imageWithData:Tweetdata2];
    
    NSString *scname = [user2 objectForKey:@"screen_name"];
    NSString *str_cid = [NSString stringWithFormat:@"https://api.twitter.com/1.1/statuses/user_timeline.json?screen_name=%@",scname];
    NSURL *url02 = [NSURL URLWithString:[str_cid stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
    NSString *tl02 = @"tl02";
    [self fetchGetHomeTimeline:url02 timeLine:tl02];
    
}

// ツイート投稿要求
- (void)fetchPostTweet:(NSString *)text
{
    // 要求を準備
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSLog(@"Post tweet is %@",text);
    // statusパラメータをURI符号化してbodyにセット
    NSString *encodedText = [GTMOAuthAuthentication encodedOAuthParameterForString:text];
    NSString *body = [NSString stringWithFormat:@"status=%@", encodedText];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSLog(@"request --- %@",request);
    
    // 要求に署名情報を付加
    [auth_ authorizeRequest:request];
    
    // 接続開始
    GTMHTTPFetcher *fetcher = [GTMHTTPFetcher fetcherWithRequest:request];
    [fetcher beginFetchWithDelegate:self
                  didFinishSelector:@selector(postTweetFetcher:finishedWithData:error:)];
                NSLog(@"%@",fetcher);
}

// ツイート投稿要求に対する応答
- (void)postTweetFetcher:(GTMHTTPFetcher *)fetcher finishedWithData:(NSData *)data error:(NSError *)error
{
    if (error != nil) {
        // ツイート投稿取得エラー
        NSLog(@"Fetching statuses/update error: %d", error.code);
        return;
    }
                    NSLog(@"%@",fetcher);
    // タイムライン更新
    //[self fetchGetHomeTimeline];
    NSURL *url01 = [NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/home_timeline.json"];
    NSString *tl01 = @"tl01";
    [self fetchGetHomeTimeline:url01 timeLine:tl01];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showTweetView"]) {
        [segue.destinationViewController setDelegate:self];
    }else if ([[segue identifier] isEqualToString:@"reply"]) {
        [segue.destinationViewController setDelegate:self];
        
        TweetViewController *tweetViewController = (TweetViewController*)[segue destinationViewController];
        tweetViewController.username = [user2 objectForKey:@"screen_name"];

    }else if ([[segue identifier] isEqualToString:@"showProfileView"]) {
        
        ProfileViewController *profileViewController = (ProfileViewController*)[segue destinationViewController];
        
        profileViewController.username = [user2 objectForKey:@"screen_name"];
        profileViewController.name = [user2 objectForKey:@"name"];
        [profileViewController setProf:self.profileImage];
        profileViewController.tweets = [user2 objectForKey:@"statuses_count"];
        profileViewController.following = [user2 objectForKey:@"friends_count"];
        profileViewController.followers = [user2 objectForKey:@"followers_count"];
        [profileViewController setBann:self.bannerImage];
        
        profileViewController.timeline =  timelineStatuses2_;
    }
}

// TweetViewでCancelが押された
- (void)tweetViewControllerDidCancel:(TweetViewController *)viewController
{
    // TweetViewを閉じる
    [viewController dismissModalViewControllerAnimated:YES];
}

// TweetViewでDoneが押された
-(void)tweetViewControllerDidFinish:(TweetViewController *)viewController
                            content:(NSString *)content
{
    // ツイートを投稿する
    if ([content length] > 0) {
        [self fetchPostTweet:content];
        
    }
    
    // TweetViewを閉じる
    [viewController dismissModalViewControllerAnimated:YES];
    
}




/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/



@end
