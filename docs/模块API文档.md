# xsmth-newsmth 模块API文档

## 核心接口说明

本文档详细介绍了项目中各个主要模块的API接口，便于开发者理解和使用。

## 1. 网络层接口

### 1.1 SMHttpRequest

**主要接口**：
```objc
// 创建请求实例
+ (instancetype)requestWithURL:(NSString *)url;

// 发送GET请求
- (void)startWithCompletionHandler:(SMHttpRequestCompletionHandler)handler;

// 发送POST请求
- (void)postWithParams:(NSDictionary *)params 
     completionHandler:(SMHttpRequestCompletionHandler)handler;

// 取消请求
- (void)cancel;
```

**使用示例**：
```objc
SMHttpRequest *request = [SMHttpRequest requestWithURL:@"https://www.newsmth.net/nForum/"];
[request startWithCompletionHandler:^(NSData *data, NSError *error) {
    if (error) {
        // 处理错误
        return;
    }
    // 处理返回数据
}];
```

### 1.2 SMNetwork (Swift)

**主要接口**：
```swift
// 获取主页内容
static func fetchMainPage(completion: @escaping (Error?, SMMainPage?) -> Void)

// 登录
static func login(username: String, password: String, completion: @escaping (Error?, Bool) -> Void)

// 获取帖子列表
static func fetchPostList(boardID: String, page: Int, completion: @escaping (Error?, SMPostGroup?) -> Void)

// 获取帖子详情
static func fetchPostContent(boardID: String, postID: String, completion: @escaping (Error?, SMPost?) -> Void)
```

### 1.3 SMWebParser

**主要接口**：
```objc
// 解析HTML转为JSON
+ (id)parseHTML:(NSString *)html withScript:(NSString *)script;

// 获取解析脚本
+ (NSString *)parserForType:(SMWebParserType)type;

// 更新解析脚本
+ (void)updateParsers;
```

**使用示例**：
```objc
NSString *html = /* HTML 内容 */;
NSString *script = [SMWebParser parserForType:SMWebParserTypeMainPage];
id json = [SMWebParser parseHTML:html withScript:script];
// 处理JSON数据
```

## 2. 数据模型接口

### 2.1 SMBaseData

所有数据模型的基类，提供基础的JSON数据转换功能。

**主要接口**：
```objc
// 从JSON创建模型对象
+ (instancetype)fromJSON:(NSDictionary *)json;

// 将模型对象转为JSON
- (NSDictionary *)toJSON;

// 从字符串解析
+ (instancetype)fromJSONString:(NSString *)jsonString;
```

### 2.2 SMBoard

版块信息模型。

**属性**：
```objc
@property (nonatomic, copy) NSString *boardID;     // 版块ID
@property (nonatomic, copy) NSString *title;       // 版块标题
@property (nonatomic, copy) NSString *category;    // 版块分类
@property (nonatomic, assign) BOOL isDirectory;    // 是否为目录
@property (nonatomic, assign) NSInteger unread;    // 未读数量
```

### 2.3 SMPost

帖子信息模型。

**属性**：
```objc
@property (nonatomic, copy) NSString *postID;      // 帖子ID
@property (nonatomic, copy) NSString *title;       // 帖子标题
@property (nonatomic, copy) NSString *author;      // 作者
@property (nonatomic, copy) NSString *content;     // 内容
@property (nonatomic, copy) NSString *time;        // 发布时间
@property (nonatomic, strong) NSArray *attachments; // 附件列表
@property (nonatomic, assign) BOOL isTop;          // 是否置顶
```

## 3. 视图控制器接口

### 3.1 SMViewController

所有视图控制器的基类，提供通用功能。

**主要接口**：
```objc
// 显示加载指示器
- (void)showLoading;

// 隐藏加载指示器
- (void)hideLoading;

// 显示错误信息
- (void)showError:(NSError *)error;

// 显示消息
- (void)showNotice:(NSString *)notice;

// 需要登录检查
- (BOOL)needLogin;
```

### 3.2 SMBoardViewController

版块视图控制器，显示帖子列表。

**主要接口**：
```objc
// 使用版块ID初始化
- (instancetype)initWithBoardID:(NSString *)boardID;

// 刷新数据
- (void)refreshData;

// 加载更多
- (void)loadMore;

// 设置视图类型（列表/时间线）
- (void)setViewType:(SMBoardViewType)type;
```

### 3.3 SMPostGroupViewController

帖子组视图控制器，显示帖子及其回复。

**主要接口**：
```objc
// 使用版块ID和帖子ID初始化
- (instancetype)initWithBoardID:(NSString *)boardID postID:(NSString *)postID;

// 刷新数据
- (void)refreshData;

// 跳转到指定页
- (void)gotoPage:(NSInteger)page;

// 回复帖子
- (void)replyPost;
```

## 4. 账户管理接口

### 4.1 SMAccountManager

管理用户账户，处理登录状态。

**主要接口**：
```objc
// 单例访问
+ (instancetype)sharedInstance;

// 检查登录状态
- (BOOL)isLogin;

// 执行登录
- (void)loginWithUsername:(NSString *)username 
                 password:(NSString *)password 
                  success:(void (^)(void))success 
                  failure:(void (^)(NSError *error))failure;

// 退出登录
- (void)logout;

// 获取当前登录用户
- (SMUser *)currentUser;
```

**使用示例**：
```objc
SMAccountManager *manager = [SMAccountManager sharedInstance];
if (![manager isLogin]) {
    [manager loginWithUsername:@"username" 
                     password:@"password" 
                      success:^{
                          // 登录成功处理
                      } 
                      failure:^(NSError *error) {
                          // 登录失败处理
                      }];
}
```

## 5. 工具类接口

### 5.1 SMUtils

提供各种工具方法。

**主要接口**：
```objc
// 解析时间字符串
+ (NSDate *)parseTimeString:(NSString *)timeString;

// 格式化时间为友好显示
+ (NSString *)friendlyTimeFromDate:(NSDate *)date;

// URL编码
+ (NSString *)urlEncodeString:(NSString *)string;

// 判断iPad
+ (BOOL)isPad;

// 获取设备信息
+ (NSString *)deviceInfo;
```

### 5.2 SMDBManager

数据库管理类，处理本地存储。

**主要接口**：
```objc
// 单例访问
+ (instancetype)sharedInstance;

// 保存对象
- (BOOL)saveObject:(id)object forKey:(NSString *)key;

// 读取对象
- (id)objectForKey:(NSString *)key;

// 删除对象
- (BOOL)removeObjectForKey:(NSString *)key;

// 清空数据库
- (BOOL)clearAll;
```

### 5.3 XImageViewCache

图片缓存管理类。

**主要接口**：
```objc
// 单例访问
+ (instancetype)sharedInstance;

// 获取图片（优先从缓存获取）
- (void)imageWithURL:(NSString *)url completion:(void (^)(UIImage *image))completion;

// 预加载图片
- (void)preloadImages:(NSArray *)urls;

// 清空缓存
- (void)clearCache;
```

## 6. 数据操作接口

### 6.1 数据获取流程

1. 使用SMHttpRequest或SMNetwork获取HTML内容
2. 使用SMWebParser解析HTML为JSON
3. 使用对应的SMData模型类转换为模型对象
4. 将模型对象绑定到UI

**示例代码**：
```objc
// 获取主页数据
[SMNetwork fetchMainPageWithCompletion:^(NSError *error, SMMainPage *mainPage) {
    if (error) {
        [self showError:error];
        return;
    }
    
    // 更新UI
    [self updateUIWithMainPage:mainPage];
}];

// 获取帖子列表
[SMNetwork fetchPostListWithBoardID:boardID page:1 completion:^(NSError *error, SMPostGroup *postGroup) {
    if (error) {
        [self showError:error];
        return;
    }
    
    // 更新UI
    [self updateUIWithPostGroup:postGroup];
}];
```

## 7. 自定义控件接口

### 7.1 XPullRefreshTableView

支持下拉刷新的表格视图。

**主要接口**：
```objc
// 设置下拉刷新回调
- (void)setPullRefreshHandler:(void (^)(void))handler;

// 开始刷新
- (void)startRefresh;

// 结束刷新
- (void)finishRefresh;

// 设置上拉加载更多回调
- (void)setLoadMoreHandler:(void (^)(void))handler;

// 结束加载更多
- (void)finishLoadMore;
```

### 7.2 XImageView

支持异步加载和缓存的图片视图。

**主要接口**：
```objc
// 设置图片URL
- (void)setImageWithURL:(NSString *)url;

// 设置图片URL和占位图
- (void)setImageWithURL:(NSString *)url placeholderImage:(UIImage *)placeholder;

// 设置加载完成回调
- (void)setImageWithURL:(NSString *)url completed:(void (^)(UIImage *image))completedBlock;

// 取消加载
- (void)cancelCurrentImageLoad;
```

## 8. 通知与事件

项目中使用的主要通知：

```objc
// 主题变更
NOTIFYCATION_THEME_CHANGED

// 摇一摇
NOTIFYCATION_SHAKE

// IAP购买成功
NOTIFYCATION_IAP_PRO

// 用户登录状态变更
kSMNotificationUserLogin
kSMNotificationUserLogout
```

**监听示例**：
```objc
[[NSNotificationCenter defaultCenter] addObserver:self 
                                         selector:@selector(handleThemeChanged:) 
                                             name:NOTIFYCATION_THEME_CHANGED 
                                           object:nil];
```

## 9. 配置与常量

项目中主要的配置项：

```objc
// 字体大小设置
USERDEFAULTS_LIST_FONT_SIZE
USERDEFAULTS_POST_FONT_SIZE

// 功能开关设置
USERDEFAULTS_CONFIG_HIDE_TOP_POST
USERDEFAULTS_CONFIG_SHOW_QMD
USERDEFAULTS_CONFIG_OPTIMIZE_POST_CONTENT
USERDEFAULTS_CONFIG_USER_CLICKABLE
USERDEFAULTS_CONFIG_ENABLE_DAY_MODE
USERDEFUALTS_CONFIG_ENABLE_SHAKE_SWITCH_DAY_MODE
```

## 10. 错误处理

错误处理统一使用NSError，错误域为SM_ERROR_DOMAIN。

错误码定义：
```objc
typedef enum {
    SMNetworkErrorCodeParseFail = -1,
    SMNetworkErrorCodeRequestFail = 1,
} SMNetworkErrorCode;
```

**错误处理示例**：
```objc
if (error) {
    if (error.code == SMNetworkErrorCodeParseFail) {
        // 处理解析错误
    } else if (error.code == SMNetworkErrorCodeRequestFail) {
        // 处理请求错误
    } else {
        // 处理其他错误
    }
}
``` 