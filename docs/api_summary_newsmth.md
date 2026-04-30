# 水木社区 (NewSMTH) API 汇总

本文档汇总了 App 中使用的主要网络接口，分为新版 nForum 接口和旧版 Legacy 接口。

## 1. Legacy 接口 (bbs*.php)

旧版接口通常返回 HTML 页面，客户端通过正则表达式提取内嵌的 JavaScript 数据或直接解析 HTML 结构。这些接口主要用于一些 nForum 尚未覆盖或实现不全的功能。

| 接口文件 | 功能 | URL 模式 | 解析方式 | 详细文档 |
| :--- | :--- | :--- | :--- | :--- |
| `bbsdoc.php` | 帖子列表 (同主题模式) | `/bbsdoc.php?board={board}&ftype=6` | JS eval | [查看文档](./api_doc_board_tzt_post_sort.md) |
| `bbsbfind.php` | 版面搜索 | `/bbsbfind.php?q=1&board={board}...` | JS eval | [查看文档](./api_doc_board_search.md) |
| `bbsfav.php` | 添加收藏 | `/bbsfav.php?bname={board}&select=0` | 忽略响应 | [查看文档](./api_doc_board_favor.md) |
| `bbsupload.php` | 附件上传/删除 | `/bbsupload.php?act={act}` | JS eval/DOM | [查看文档](./api_doc_upload.md) |
| `bbscon.php` | 帖子内容 | `/bbscon.php?bid={bid}&id={pid}` | JS eval | [查看文档](./api_doc_bbscon.md) |
| `bbstcon.php` | 同主题帖子内容 | `/bbstcon.php?board={board}&gid={gid}...` | JS eval | [查看文档](./api_doc_bbstcon.md) |
| `bbsfwd.php` | 转发/转寄 | `/bbsfwd.php?do` | 字符串匹配 | [查看文档](./api_doc_forward.md) |

### 1.1 附件上传 (`bbsupload.php`)
[详细文档](./api_doc_upload.md)

### 1.2 帖子内容 (`bbscon.php`)
[详细文档](./api_doc_bbscon.md)

## 2. nForum 接口

新版接口，通常支持 Ajax 调用并返回 JSON 数据 (部分返回 HTML)。

### 2.1 帖子相关
- **发表帖子**: `/nForum/article/{boardName}/ajax_post.json` (POST) [查看文档](./api_doc_post_article.md)
- **编辑帖子**: `/nForum/article/{boardName}/ajax_edit/{pid}.json` (POST) [查看文档](./api_doc_post_article.md)
- **删除帖子**: `/nForum/article/{boardName}/ajax_delete/{pid}.json`
- **帖子内容**: `/nForum/article/{boardName}/{postID}` (HTML, 通常用于 WebView 加载)

### 2.2 版面相关
- **版面文章**: `/nForum/board/{boardName}?ajax&p={page}` (JSON/HTML)
    - 这是“普通模式”和“同主题-回复时间排序”模式使用的接口。

### 2.3 用户相关
- **登录**: `/nForum/user/login`
- **回复/提及**: `/nForum/refer/{refer}?ajax&p={page}` (`refer` = `reply` or `at`)

### 2.4 其他
- **首页**: `/nForum/mainpage?ajax`

## 3. 注意事项
- **编码**: 所有 Legacy 接口 (`bbs*.php`) 均使用 **GBK** 编码。URL 参数需进行 GBK 编码，返回内容需进行 GBK 解码。
- **Cookie**: 所有接口依赖 Cookie 进行身份验证。
- **JS 解析**: Legacy 接口的返回值解析高度依赖页面内的 JS 结构，服务端页面改版极易导致解析失效。
