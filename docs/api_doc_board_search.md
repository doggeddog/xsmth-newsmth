# 水木社区“版面搜索”模式 API 文档

## 1. 接口概述

该接口用于在指定版面内搜索帖子。
返回数据为 HTML 页面，核心数据封装在内嵌的 JavaScript 脚本中。

- **URL**: `https://www.newsmth.net/bbsbfind.php`
- **HTTP 方法**: `GET`
- **编码**: GBK

## 2. 请求参数

| 参数名 | 必填 | 示例值 | 描述 |
| :--- | :--- | :--- | :--- |
| `q` | 是 | `1` | 查询模式标记，固定为 1 |
| `board` | 是 | `Apple` | 版面英文名称 |
| `title` | 否 | `iPhone` | 标题包含关键字 1 |
| `title2` | 否 | | 标题包含关键字 2 |
| `title3` | 否 | | 标题**不**包含关键字 |
| `userid` | 否 | | 作者用户名 |
| `dt` | 否 | | 搜索时间范围 (格式未知，App 暂未完整实现) |
| `ag` | 否 | `on` | **有附件**。传 `on` 代表只搜有附件的；不传代表不限。 |
| `og` | 否 | `on` | **不含原文**。传 `on` 代表结果不含原文（即可能是只含回复？或不含引用？App UI 描述为“不含原文”）。<br>注：App 逻辑是：开关开启（“包含回复”？）传空；开关关闭传 `on`。需根据实际测试确认服务端行为。 |

**请求 URL 示例**:
`https://www.newsmth.net/bbsbfind.php?q=1&board=Apple&title=iPhone&ag=on`

## 3. 响应解析

### 3.1 数据格式
响应体为 HTML。核心数据位于 `<script>` 标签中。

**没有使用 CSS Selector**。通过正则表达式提取脚本并使用 `eval` 执行。

### 3.2 解析流程

1.  **正则提取**:
    *   正则: `/<script>\s*(var ta =(.|\s)*?)<\/script>/`
    *   取第一个捕获组（即 `var ta = ...` 开始的内容）。

2.  **环境模拟 (Mock)**: 定义 `tabWriter` 类及其原型方法 `r` 和 `t`。

3.  **执行脚本**: 执行提取的代码。

### 3.3 字段映射详情

提取的脚本会实例化 `tabWriter` 并多次调用 `r` 方法。

#### 3.3.1 `tabWriter` 构造函数
```javascript
function tabWriter() {}
```
无参数，无操作。

#### 3.3.2 `tabWriter.prototype.r` (搜索结果行)

```javascript
r(idx, space, userLink, dateStr, postTitle);
```

| 参数索引 | 参数名 | 原始数据示例 | 目标字段 | 处理逻辑 |
| :--- | :--- | :--- | :--- | :--- |
| 0 | `idx` | `1` | - | 忽略 |
| 1 | `space` | `&nbsp;` | - | 忽略 |
| 2 | `userLink` | `<a href="...">user</a>` | `author` | 去除 HTML 标签: `userLink.replace(/<.*?>/g, '')` |
| 3 | `dateStr` | `Aug 12` | `date` | 日期字符串 (通常只有月日)。<br>现有解析逻辑强制将其拼接在当前年份和当前时间上，**存在跨年数据日期错误的风险**。 |
| 4 | `postTitle` | `<a href="...&id=123">Title</a>` | `title`<br>`gid` | **Title**: 去除 HTML 标签并解码。<br>**GID**: 从 href 中提取 `id` 参数: `postTitle.match(/<.*?&id=(\d+)">/i)[1]` |

### 3.4 解析逻辑示例 (JavaScript)

```javascript
function parseSearchResponse(html) {
    var data = { posts: [] };

    function decode(str) {
        // 实现 HTML 实体解码 (&lt; -> < 等)
        return str.replace(/&lt;/ig, '<').replace(/&gt;/ig, '>').replace(/&quot;/ig, '"').replace(/&amp;/ig, '&');
    }

    // 1. Mock tabWriter
    function tabWriter() {}
    
    tabWriter.prototype.r = function(idx, space, userLink, dateStr, postTitle) {
        var author = userLink.replace(/<.*?>/g, '');
        
        // 日期解析 Hack: 拼接到当前年份。注意：这可能导致旧帖子显示为今年。
        // 假设 dateStr 为 "Dec 07"
        // new Date().toString() -> "Sun Dec 07 2025 ..."
        // 替换逻辑将当前日期的 "Mon Day" 部分替换为 dateStr
        var nowStr = new Date().toString();
        // Regex: (Week) Month Day Year (Time...)
        // Replace with: (Week) {dateStr} Year (Time...)
        var dateTimeStr = nowStr.replace(/(\w+) \w+ \d+ (.*)/, '$1 ' + decode(dateStr) + ' $2');
        var date = Date.parse(dateTimeStr);

        var title = decode(postTitle.replace(/<.*?>/g, ''));
        var gidMatch = postTitle.match(/<.*?&id=(\d+)">/i);
        var gid = gidMatch ? gidMatch[1] : 0;

        data.posts.push({
            gid: gid,
            title: title,
            author: author,
            date: date
        });
    };
    
    tabWriter.prototype.t = function() {}; // 忽略表头/表尾

    // 2. 提取脚本
    var match = html.match(/<script>\s*(var ta =(.|\s)*?)<\/script>/);
    if (match) {
        var script = match[1];
        // 3. 执行
        eval(script);
    }

    // 反转顺序
    data.posts.reverse();
    
    return data;
}
```

## 4. 已知问题

1.  **日期解析不准确**: 由于 API 返回的日期字符串仅包含月和日（如 "Aug 12"），现有解析逻辑默认假设为当前年份。当搜索结果包含往年数据时，解析出的年份将是错误的（显示为今年）。
2.  **不支持翻页**: 现有 App 代码未实现搜索结果的翻页加载（未处理 `page` 参数，UI 也未启用 LoadMore），搜索结果可能被截断。

