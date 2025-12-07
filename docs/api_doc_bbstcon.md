# 水木社区“同主题帖子列表”模式 API 文档

## 1. 接口概述

该接口用于获取“同主题阅读”模式下的帖子列表。
返回 HTML，内嵌 JS 数据。

- **URL**: `https://www.newsmth.net/bbstcon.php`
- **HTTP 方法**: `GET`
- **编码**: GBK

## 2. 请求参数

| 参数名 | 必填 | 示例值 | 描述 |
| :--- | :--- | :--- | :--- |
| `board` | 是 | `Apple` | 版面名称 |
| `gid` | 是 | `12345` | 主题 ID |
| `start` | 否 | `12345` | 起始 PID (用于定位) |
| `pno` | 否 | `1` | 页码 |

**URL 示例**:
`https://www.newsmth.net/bbstcon.php?board=Apple&gid=12345&start=12345&pno=1`

## 3. 响应解析

HTML 响应中内嵌 JS 脚本。

### 3.1 提取数据脚本
正则: `/<!--\s*var o\s*=\s*new\s+tconWriter((.|\s)*?)\/\/-->/`

### 3.2 Mock 环境与字段映射

#### 3.2.1 `tconWriter` (元数据)
```javascript
function tconWriter(board, bid, gid, start, tpage, pno, serial, prevgid, nextgid, title)
```
- `bid`: Board ID
- `tpage`: 总页数 (Total Pages)
- `title`: 主题标题

#### 3.2.2 `tconWriter.prototype.o` (列表数据)
```javascript
tconWriter.prototype.o = function(arr)
```
- `arr`: 二维数组 `[[pid, author], [pid, author], ...]`
- 映射:
    - `pid`: `arr[i][0]`
    - `author`: `arr[i][1]`

### 3.3 解析逻辑示例

```javascript
function parseTopicPosts(html) {
    var data = { posts: [] };
    
    function tconWriter(board, bid, gid, start, tpage, pno, serial, prevgid, nextgid, title) {
        data.tpage = tpage;
        data.title = title;
    }
    tconWriter.prototype.o = function(arr) {
        arr.forEach(item => {
            data.posts.push({ pid: item[0], author: item[1] });
        });
    };
    
    // Extract & Eval
    var match = html.match(/<!--\s*var o\s*=\s*new\s+tconWriter((.|\s)*?)\/\/-->/);
    if (match) eval(match[0]);
    
    return data;
}
```

