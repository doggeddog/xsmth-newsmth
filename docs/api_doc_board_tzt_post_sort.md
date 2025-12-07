# 水木社区“同主题-发表时间排序”模式 API 文档

## 1. 接口概述

该接口用于获取指定版面的帖子列表。
在此模式（同主题、发表时间排序）下，服务端返回的是老版 `www` 站点的 HTML 页面，数据通过内嵌 JavaScript 脚本传输，而非标准 HTML DOM 结构。

- **URL**: `https://www.newsmth.net/bbsdoc.php`
- **HTTP 方法**: `GET`
- **编码**: GBK (注意：现有 App 代码未显式处理编码转换，依赖 WebView 或系统自动识别，自行开发时需注意)

## 2. 请求参数

| 参数名 | 类型 | 必填 | 示例值 | 描述 |
| :--- | :--- | :--- | :--- | :--- |
| `board` | string | 是 | `Apple` | 版面英文名称 |
| `ftype` | int | 是 | `6` | **关键参数**。`6` 代表“同主题、发表时间”排序模式。 |
| `page` | int | 否 | `0` | 页码。用于翻页，对应响应中的 `currentPage - 1`。 |

**请求 URL 示例**:
`https://www.newsmth.net/bbsdoc.php?board=Apple&ftype=6&page=0`

## 3. 响应解析

### 3.1 数据格式
响应体为 HTML 文档。核心数据位于文档头部的一段注释块中，包含可执行的 JavaScript 代码。

**没有使用 CSS Selector**。现有 App 代码通过正则表达式提取脚本并使用 `eval` 执行。

### 3.2 解析流程

1.  **正则提取**: 使用正则表达式从 HTML 中提取被注释的 JS 代码块。
    *   正则: `/<!--((.|\s)*?)\/\/-->/`
    *   取第一个匹配项的内容。

2.  **环境模拟 (Mock)**: 在执行提取的脚本前，需要定义 `docWriter` 函数及其原型方法，用于接收数据回调。

3.  **执行脚本**: 执行提取的代码，数据将流向 Mock 的函数中。

### 3.3 字段映射详情

提取的脚本会实例化 `docWriter` 并多次调用其 `o` 方法。

#### 3.3.1 `docWriter` 构造函数 (分页信息)

```javascript
new docWriter(board, bid, start, man, ftype, page, total, apath, showHot, normalB);
```

| 参数索引 | 参数名 | 说明 |
| :--- | :--- | :--- |
| 5 | `page` | 当前页码。解析器应保存此值用于后续翻页计算。 |
| 其他 | - | 可忽略 |

#### 3.3.2 `docWriter.prototype.o` (帖子数据)

每个帖子会生成一行 `o(...)` 调用。

```javascript
o(id, gid, author, flag, time, title, size, imported, is_tex);
```

| 参数索引 | 参数名 | 类型 | 目标字段 | 处理逻辑 |
| :--- | :--- | :--- | :--- | :--- |
| 0 | `id` | int | `pid` | 帖子 ID |
| 1 | `gid` | int | `gid` | 主题 ID (Group ID) |
| 2 | `author` | string | `author` | 作者用户名 |
| 3 | `flag` | string | `isTop` / Title | 状态标志字符串。<br>- 包含 `d` 或 `D`: **置顶帖** (`isTop = true`)<br>- 包含 `@`: **有附件** (通常在标题后追加 "📎" 符号) |
| 4 | `time` | int | `date` | 发表时间戳 (秒)。需乘以 1000 转换为毫秒。 |
| 5 | `title` | string | `title` | 帖子标题。需进行 HTML 解码 (如 `&lt;` 转 `<`)。 |
| 6 | `size` | int | - | 帖子大小 (字节)，通常忽略。 |
| 7 | `imported`| - | - | 忽略 |
| 8 | `is_tex` | - | - | 忽略 |

### 3.4 解析逻辑示例 (JavaScript)

以下代码改编自 `newsmth/jsParser/board.js` 中的 `parse_www` 函数：

```javascript
function parseResponse(html) {
    var data = {
        posts: [],
        currentPage: 0
    };

    // 1. Mock docWriter
    function docWriter(board, bid, start, man, ftype, page, total, apath, showHot, normalB) {
        data.currentPage = page;
    }

    docWriter.prototype = {
        // 解析单行帖子数据
        o: function(id, gid, author, flag, time, title, size, imported, is_tex) {
            var isTop = flag.indexOf("d") != -1 || flag.indexOf("D") != -1;
            var processedTitle = title; // 实际场景需做 HTML Decode
            
            if (flag.indexOf("@") !== -1) {
                processedTitle += "📎";
            }

            var post = {
                pid: id,
                gid: gid,
                title: processedTitle,
                author: author,
                date: time * 1000,
                isTop: isTop
            };
            data.posts.push(post);
        },
        t: function() {}, // 忽略
        f: function() {}  // 忽略
    };

    // 2. 正则提取脚本
    // 匹配 HTML 注释 <!-- ... //--> 包裹的代码块
    var match = html.match(/<!--((.|\s)*?)\/\/-->/);
    if (match) {
        var scriptContent = match[0];
        // 3. 执行脚本 (需确保当前作用域有 docWriter 定义)
        eval(scriptContent);
    }
    
    // 注意：www 模式返回的数据顺序可能需要根据 UI 需求反转
    // data.posts.reverse(); 

    return data;
}
```

## 4. 注意事项

1.  **数据排序**: 原版代码中对解析出的 `posts` 进行了 `reverse()` 操作 (`board.js` 第 81 行)，说明 API 返回的顺序可能与 App 期望的显示顺序相反（可能是旧的在前），开发时需根据实际体验调整。
2.  **HTML 解码**: `title` 字段可能包含 HTML 实体（如 `&lt;`），必须进行反转义处理。
3.  **编码问题**: `www.newsmth.net` 通常使用 GBK 编码。如果使用现代 HTTP 库（如 Python requests 或 Node.js axios），可能需要手动处理 GBK 到 UTF-8 的解码，否则中文会乱码。

