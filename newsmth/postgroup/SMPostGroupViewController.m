//
//  SMPostGroupViewController.m
//  newsmth
//
//  Created by Maxwin on 13-5-30.
//  Copyright (c) 2013年 nju. All rights reserved.
//

#import "SMPostGroupViewController.h"
#import "XPullRefreshTableView.h"
#import "XImageView.h"
#import "SMPost.h"
#import "SMAttach.h"
#import "SMPostGroup.h"
#import "SMWritePostViewController.h"
#import "P2PNavigationController.h"
#import "SMBoardViewController.h"
#import "SMUserViewController.h"

#import "SMPostGroupHeaderCell.h"
#import "SMPostGroupContentCell.h"
#import "SMPostGroupAttachCell.h"
#import "SMPostFailCell.h"
#import "PBWebViewController.h"

////////////////////////////////////////////////
@implementation SMPostGroupItem
@end

////////////////////////////////////////////////

@implementation SMPostGroupCellData
@end

////////////////////////////////////////////////
@interface SMPostGroupViewController ()<UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate,  XPullRefreshTableViewDelegate, SMWebLoaderOperationDelegate, XImageViewDelegate, SMPostGroupHeaderCellDelegate, SMPostFailCellDelegate, SMPostGroupContentCellDelegate>
@property (weak, nonatomic) IBOutlet XPullRefreshTableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *tableViewHeader;
@property (weak, nonatomic) IBOutlet UILabel *labelForTitle;

// data
@property (strong, nonatomic) NSArray *postItems;
@property (strong, nonatomic) NSArray *cellDatas;
@property (strong, nonatomic) NSArray *prepareCellDatas;

@property (strong, nonatomic) NSMutableDictionary *postHeightMap;   // cache post webview height;

@property (strong, nonatomic) SMWebLoaderOperation *pageOp; // 分页加载数据用op
@property (assign, nonatomic) BOOL isLoading;

@property (assign, nonatomic) NSInteger bid;    // board id
@property (assign, nonatomic) NSInteger tpage;  // total page
@property (assign, nonatomic) NSInteger pno;    // current page

@property (assign, nonatomic) BOOL needReloadData;

@property (strong, nonatomic) SMPost *replyPost;    // 准备回复的主题
@property (strong, nonatomic) NSString *postTitle;

@property (weak, nonatomic) IBOutlet UIView *viewForPageHint;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewForPageHintBg;
@property (weak, nonatomic) IBOutlet UILabel *labelForPageHint;

@end

@implementation SMPostGroupViewController

- (id)init
{
    self = [super initWithNibName:@"SMPostGroupViewController" bundle:nil];
    if (self) {
        _pno = 1;
        _postHeightMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    // cancel all requests
    [_pageOp cancel];
    [_postItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SMPostGroupItem *item = obj;
        [item.op cancel];
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = [NSString stringWithFormat:@"同主题：%@", _board.cnName];
    self.tableView.xdelegate = self;
    [self.tableView beginRefreshing];
    
    if (!_fromBoard) {
        self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                      target:self
                                                      action:@selector(onRightBarButtonClick)];
    }
    
    _imageViewForPageHintBg.image = [SMUtils stretchedImage:_imageViewForPageHintBg.image];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = YES;
    
    NSIndexPath *indexPath = [_tableView indexPathForSelectedRow];
    if (indexPath != nil) {
        [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)onRightBarButtonClick
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    if (!_fromBoard) {
        [actionSheet addButtonWithTitle:[NSString stringWithFormat:@"进入[%@]版", _board.cnName]];
    }
    [actionSheet addButtonWithTitle:@"取消"];
    actionSheet.destructiveButtonIndex = actionSheet.numberOfButtons - 1;
    actionSheet.delegate = self;
    [actionSheet showInView:self.view];
}

- (void)loadData:(BOOL)more
{
    if (!more) {
        _pno = 1;
    } else {
        ++_pno;
    }
    NSString *url = [NSString stringWithFormat:@"http://www.newsmth.net/bbstcon.php?board=%@&gid=%d&start=%d&pno=%d", _board.name, _gid, _gid, _pno];
    _pageOp = [[SMWebLoaderOperation alloc] init];
    _pageOp.delegate = self;
    _isLoading = YES;
    [_pageOp loadUrl:url withParser:@"bbstcon"];
}

- (void)setPostItems:(NSArray *)postItems
{
    _postItems = postItems;
    [self makeupCellDatas];
}

- (void)makeupCellDatas
{
    __block NSMutableArray *datas = [[NSMutableArray alloc] initWithCapacity:0];
    [_postItems enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        SMPostGroupItem *item = obj;
        if (item.op.data != nil) {  // post loaded
            item.post = item.op.data;
        }
        if (item.op.isFinished && item.op.data == nil) {
            item.loadFail = YES;
        } else {
            item.loadFail = NO;
        }
        
        // header
        SMPostGroupCellData *header = [[SMPostGroupCellData alloc] init];
        header.index = idx;
        header.item = item;
        header.type = SMPostGroupCellTypeHeader;
        [datas addObject:header];
        
        // content
        SMPostGroupCellData *content = [[SMPostGroupCellData alloc] init];
        content.item = item;
        if (item.loadFail) {
            content.type = SMPostGroupCellTypeFail;
        } else if (item.op.data == nil) {
            content.type = SMPostGroupCellTypeLoading;
        } else if (item.op.data) {
            content.type = SMPostGroupCellTypeContent;
        }
        [datas addObject:content];
        
        // attaches
        if (item.op.data != nil) {
            SMPost *post = item.op.data;
            [post.attaches enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                SMPostGroupCellData *data = [[SMPostGroupCellData alloc] init];
                data.item = item;
                data.type = SMPostGroupCellTypeAttach;
                data.attach = obj;
                
                [datas addObject:data];
            }];
        }
        
    }];
    self.prepareCellDatas = datas;
}

- (void)setCellDatas:(NSArray *)cellDatas
{
    _prepareCellDatas = nil;
    _cellDatas = cellDatas;
    [self.tableView reloadData];
}

- (void)setPrepareCellDatas:(NSArray *)prepareCellDatas
{
    if (_tableView.isDragging) {
        _prepareCellDatas = prepareCellDatas;
    } else {
        self.cellDatas = prepareCellDatas;
    }
}


- (void)makeupTableViewHeader:(NSString *)text
{
    _labelForTitle.text = text;
    self.title = text;
    CGFloat delta = [_labelForTitle.text sizeWithFont:_labelForTitle.font constrainedToSize:CGSizeMake(_labelForTitle.frame.size.width, CGFLOAT_MAX) lineBreakMode:_labelForTitle.lineBreakMode].height - _labelForTitle.frame.size.height;
    CGRect frame = _tableViewHeader.frame;
    frame.size.height += delta;
    _tableViewHeader.frame = frame;
    _tableView.tableHeaderView = _tableViewHeader;
}

#pragma mark - UITableViewDataSource/Delegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (_prepareCellDatas != nil) {
        self.cellDatas = _prepareCellDatas;
    }
    if (!decelerate) {
        [self hidePageHint];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self hidePageHint];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSString *text = [NSString stringWithFormat:@"%d/%d页", _pno, _tpage];
    _labelForPageHint.text = text;
    
    CGSize size = [text sizeWithFont:_labelForPageHint.font];
    
    CGRect frame = _viewForPageHint.frame;
    frame.size = size;
    frame.size.width += 10.0f;
    frame.size.height += 6.0f;
    frame.origin.x = self.view.frame.size.width - frame.size.width - 10.0f;
    frame.origin.y = self.view.frame.size.height - frame.size.height - 10.0f;
    _viewForPageHint.frame = frame;
    
    [UIView animateWithDuration:0.5f animations:^{
        _viewForPageHint.alpha = 1.0f;
    }];
}

- (void)hidePageHint
{
    [UIView animateWithDuration:0.5f animations:^{
        _viewForPageHint.alpha = 0.0f;
    }];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _cellDatas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SMPostGroupCellData *data = _cellDatas[indexPath.row];
    
    if (_pno != _tpage && indexPath.row == _cellDatas.count - 1) {    // last row
        [self loadData:YES];
    }
    
    UITableViewCell *cell;
    switch (data.type) {
        case SMPostGroupCellTypeHeader:
            cell = [self cellForTitle:data];
            break;
        case SMPostGroupCellTypeFail:
            cell = [self cellForFail:data];
            break;
        case SMPostGroupCellTypeLoading:
            cell = [self cellForLoading:data];
            break;
        case SMPostGroupCellTypeContent:
            cell = [self cellForContent:data];
            break;
        case SMPostGroupCellTypeAttach:
            cell = [self cellForAttach:data];
            break;
        default:
            break;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SMPostGroupCellData *data = _cellDatas[indexPath.row];

    id v = [_postHeightMap objectForKey:@(data.item.post.pid)];
    switch (data.type) {
        case SMPostGroupCellTypeHeader:
            return [SMPostGroupHeaderCell cellHeight];
        case SMPostGroupCellTypeFail:
            return 44.0f;
        case SMPostGroupCellTypeLoading:
            return 44.0f;
        case SMPostGroupCellTypeContent:
            if (v != nil) {
                return [v floatValue];
            }
            return 100.0f;
//            return [SMPostGroupContentCell cellHeight:data.item.post];
        case SMPostGroupCellTypeAttach:
            return [SMPostGroupAttachCell cellHeight:[self getAttachUrl:data]];
        default:
            break;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SMPostGroupCellData *data = _cellDatas[indexPath.row];
    if (data.type == SMPostGroupCellTypeAttach) {
        NSString *attachUrl = [self getAttachOriginalUrl:data];
        PBWebViewController *webView = [[PBWebViewController alloc] init];
        webView.URL = [NSURL URLWithString:attachUrl];
        [self.navigationController pushViewController:webView animated:YES];
    }
}

#pragma create cell
- (UITableViewCell *)cellForTitle:(SMPostGroupCellData *)data
{
    NSString *cellid = @"title_cell";
    SMPostGroupHeaderCell *cell = (SMPostGroupHeaderCell *)[self.tableView dequeueReusableCellWithIdentifier:cellid];
    if (cell == nil) {
        cell = [[SMPostGroupHeaderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellid];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.delegate = self;
    }
//    cell.item = data.item;
    return cell;
}

- (UITableViewCell *)cellForLoading:(SMPostGroupCellData *)data
{
    NSString *cellid = @"loading_cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellid];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellid];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    cell.textLabel.text = @"Loading...";
    return cell;
}

- (UITableViewCell *)cellForFail:(SMPostGroupCellData *)data
{
    NSString *cellid = @"fail_cell";
    SMPostFailCell *cell = (SMPostFailCell *)[self.tableView dequeueReusableCellWithIdentifier:cellid];
    if (cell == nil) {
        cell = [[SMPostFailCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellid];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
//    cell.cellData = data;
    cell.delegate = self;
    return cell;
}

- (UITableViewCell *)cellForContent:(SMPostGroupCellData *)data
{
    NSString *cellid = @"content_cell";
    SMPostGroupContentCell *cell = (SMPostGroupContentCell *)[self.tableView dequeueReusableCellWithIdentifier:cellid];
    if (cell == nil) {
        cell = [[SMPostGroupContentCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellid];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.delegate = self;
    }
    cell.post = data.item.post;
    return cell;
}

- (UITableViewCell *)cellForAttach:(SMPostGroupCellData *)data
{
    NSString *cellid = @"attach_cell";
    SMPostGroupAttachCell *cell = (SMPostGroupAttachCell *)[self.tableView dequeueReusableCellWithIdentifier:cellid];
    if (cell == nil) {
        cell = [[SMPostGroupAttachCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellid];
    }
    cell.imageViewForAttach.delegate = self;
    cell.url = [self getAttachUrl:data];
    return cell;
}

- (NSString *)getAttachUrl:(SMPostGroupCellData *)data
{
    return [NSString stringWithFormat:@"http://att.newsmth.net/nForum/att/%@/%d/%d/large", _board.name, data.item.post.pid, data.attach.pos];
}

- (NSString *)getAttachOriginalUrl:(SMPostGroupCellData *)data
{
    return [NSString stringWithFormat:@"http://att.newsmth.net/nForum/att/%@/%d/%d", _board.name, data.item.post.pid, data.attach.pos];
}

#pragma mark - XPullRefreshTableViewDelegate
- (void)tableViewDoRefresh:(XPullRefreshTableView *)tableView
{
    [self loadData:NO];
    [SMUtils trackEventWithCategory:@"postgroup" action:@"refresh" label:_board.name];
}

- (void)tableViewDoRetry:(XPullRefreshTableView *)tableView
{
    [self loadData:YES];
    [SMUtils trackEventWithCategory:@"postgroup" action:@"retry" label:_board.name];
}

#pragma mark - XImageViewDelegate
- (void)xImageViewDidLoad:(XImageView *)imageView
{
    [_tableView reloadData];
}

#pragma mark - SMWebLoaderOperationDelegate
- (void)webLoaderOperationFinished:(SMWebLoaderOperation *)opt
{
    if (opt == _pageOp) {
        // add post to postOps
        SMPostGroup *postGroup = opt.data;
        _tpage = postGroup.tpage;
        
        if (_pno != _tpage) {
            [_tableView setLoadMoreShow];
        } else {
            [_tableView setLoadMoreHide];
        }
        
        NSMutableArray *tmp;
        if (_pno == 1) {    // first page
            [self.tableView endRefreshing:YES];
            tmp = [[NSMutableArray alloc] initWithCapacity:0];
            _bid = postGroup.bid;
            
            _postTitle = postGroup.title;
            [self makeupTableViewHeader:postGroup.title];
        } else {
            tmp = [_postItems mutableCopy];
        }
        [postGroup.posts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            SMPost *post = obj;
            NSString *url = [NSString stringWithFormat:@"http://www.newsmth.net/bbscon.php?bid=%d&id=%d", _bid, post.pid];
            
            SMWebLoaderOperation *op = [[SMWebLoaderOperation alloc] init];
            op.delegate = self;
            [op loadUrl:url withParser:@"bbscon"];
            
            SMPostGroupItem *item = [[SMPostGroupItem alloc] init];
            item.op = op;
            item.post = post;
            [tmp addObject:item];
        }];
        self.postItems = tmp;
    } else {
        [self makeupCellDatas];
    }
}

- (void)webLoaderOperationFail:(SMWebLoaderOperation *)opt error:(SMMessage *)error
{
    XLog_e(@"%@", error);
    if (opt == _pageOp) {
        if (_pno == 1) {
            [self.tableView endRefreshing:NO];
        } else {
            [self.tableView setLoadMoreFail];
        }
        [self toast:error.message];
    } else {
        [self makeupCellDatas];
    }
}

#pragma mark - SMPostGroupHeaderCellDelegate
- (void)postAfterLogin
{
    [self postGroupHeaderCellOnReply:_replyPost];
//    [self performSelector:@selector(postGroupHeaderCellOnReply:) withObject:_replyPost afterDelay:TOAST_DURTAION + 0.2f];
}

- (void)postGroupHeaderCellOnReply:(SMPost *)post
{
    if (![SMAccountManager instance].isLogin) {
        _replyPost = post;
        [self performSelectorAfterLogin:@selector(postAfterLogin)];
        return ;
    }
    SMWritePostViewController *writeViewController = [[SMWritePostViewController alloc] init];
    writeViewController.post = post;
    writeViewController.postTitle = _postTitle;
    writeViewController.title = [NSString stringWithFormat:@"回复-%@", _postTitle];
    P2PNavigationController *nvc = [[P2PNavigationController alloc] initWithRootViewController:writeViewController];
    [self.navigationController presentModalViewController:nvc animated:YES];
    
    [SMUtils trackEventWithCategory:@"postgroup" action:@"reply" label:_board.name];
}

- (void)postGroupHeaderCellOnUsernameClick:(NSString *)username
{
    SMUserViewController *vc = [[SMUserViewController alloc] init];
    vc.username = username;
    [self.navigationController pushViewController:vc animated:YES];   
}

#pragma mark - SMPostFailCellDelegate
- (void)postFailCellOnRetry:(SMPostFailCell *)cell
{
//    SMPostGroupCellData *data = cell.cellData;
//    SMPostGroupItem *item = data.item;
//    SMPost *post = item.post;
////    NSString *url = [NSString stringWithFormat:@"http://www.newsmth.net/bbscon.php?bid=%d&id=%d", _bid, post.pid];
//    
//    // use m.newsmth to retry
//    // http://m.newsmth.net/article/AdvancedEdu/single/31071/0
//    NSString *url = [NSString stringWithFormat:@"http://m.newsmth.net/article/%@/single/%d/0", _board.name, post.pid];
////    XLog_d(@"%@", url);
//
//    [item.op cancel];
//    
//    SMWebLoaderOperation *op = [[SMWebLoaderOperation alloc] init];
//    op.delegate = self;
//    item.op = op;
//    
//    [op loadUrl:url withParser:@"bbscon"];
//    
//    [self.tableView reloadData];
//    
//    [SMUtils trackEventWithCategory:@"postgroup" action:@"retry_cell" label:_board.name];
}

#pragma mark - SMPostGroupContentCellDelegate
- (void)postGroupContentCell:(SMPostGroupContentCell *)cell heightChanged:(CGFloat)height
{
    int pid = cell.post.pid;
    [_postHeightMap setObject:@(height) forKey:@(pid)];
    [_tableView beginUpdates];
    [_tableView endUpdates];
}

- (void)postGroupContentCell:(SMPostGroupContentCell *)cell shouldLoadUrl:(NSURL *)url
{
    PBWebViewController *webView = [[PBWebViewController alloc] init];
    webView.URL = url;
    [self.navigationController pushViewController:webView animated:YES];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.destructiveButtonIndex) {
        SMBoardViewController *vc = [[SMBoardViewController alloc] init];
        vc.board = _board;
        [self.navigationController pushViewController:vc animated:YES];
        
        [SMUtils trackEventWithCategory:@"postgroup" action:@"enter_board" label:_board.name];
    }
}

@end
