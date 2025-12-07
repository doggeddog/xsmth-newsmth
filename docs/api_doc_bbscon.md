# 水木社区“帖子内容”模式 (Legacy) API 文档

## 1. 接口概述

该接口用于获取单个帖子的详细内容。这是旧版 Legacy 接口，通常用于获取一些 nForum 接口无法完整提供的数据（如复杂的附件布局或旧版格式）。
**注意**：App 中主要使用 nForum 接口获取帖子，此接口可能用于备用或特定场景（如从 Web 跳转）。

- **URL**: `https://www.newsmth.net/bbscon.php`
- **HTTP 方法**: `GET`
- **编码**: GBK

## 2. 请求参数

| 参数名 | 必填 | 示例值 | 描述 |
| :--- | :--- | :--- | :--- |
| `bid` | 是 | `133` | 版面 ID (Board ID) |
| `id` | 是 | `1936479557` | 帖子 ID (Pid) |

**URL 示例**:
`https://www.newsmth.net/bbscon.php?bid=133&id=1936479557`

## 3. 响应解析

HTML 响应中内嵌 JS 脚本，通过 `eval` 执行。

### 3.1 提取数据脚本
正则: `/<!--((.|\s)*?)\/\/-->/`

### 3.2 Mock 环境与字段映射

#### 3.2.1 `conWriter` (元数据)
```javascript
function conWriter(ftype, board, bid, id, gid, reid, favtxt, num, istex, title)
```
- `id`: pid
- `bid`: bid
- `gid`: gid
- `board`: board name
- `title`: 标题 (需 HTML Decode)

#### 3.2.2 `prints` (正文内容)
该函数接收一段包含 Header 的原始文本，客户端需自行解析。
```javascript
function prints(content)
```
解析逻辑（正则）：
1.  **Nick/Author**: `/^发信人: (.+)\((.*)\), /`
2.  **Date**: 匹配 "发信站" 行中的日期格式。
3.  **Content**: 匹配 Header 之后的内容。
    - 需去除末尾的 "来源: 水木社区..." 尾巴。
    - 需处理自定义标签（如 `[b]`, `[img]` 等）。

#### 3.2.3 `attach` (附件)
```javascript
function attach(name, len, pos)
```
- `name`: 附件文件名
- `len`: 大小
- `pos`: 位置信息

### 3.3 解析逻辑示例

```javascript
function parsePost(html) {
    // 1. Mock Functions: conWriter, prints, attach
    // 2. Extract JS from <!-- ... //-->
    // 3. Eval
    // 4. prints() function must parse the raw content string using Regex to separate headers and body.
}
```

