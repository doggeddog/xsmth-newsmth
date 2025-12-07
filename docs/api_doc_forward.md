# 水木社区“转发/转寄”模式 API 文档

## 1. 接口概述

该接口用于将帖子转寄给其他用户或转发到其他版面。
返回 HTML。

- **URL**:
    - 转寄给用户: `https://www.newsmth.net/bbsfwd.php?do`
    - 转发到版面: `https://www.newsmth.net/bbstfwd.php?do` (通常)
- **HTTP 方法**: `POST`
- **编码**: GBK

## 2. 请求参数

**Method**: `POST` (Form Urlencoded)

| 参数名 | 必填 | 示例值 | 描述 |
| :--- | :--- | :--- | :--- |
| `board` | 是 | `Apple` | 当前版面 |
| `id` | 是 | `12345` | 帖子 ID |
| `target` | 是 | `user_id` | 目标用户名 (转寄) 或 版面名 (转发) |
| `threads`| 否 | `on` | 是否同时转发同主题所有帖子 (`on` 为是，空为否) |
| `noansi` | 否 | `on` | 是否去除 ANSI 颜色码 |

## 3. 响应解析

### 3.1 成功判定
检查 HTML 内容是否包含字符串 `操作成功`。

### 3.2 失败判定
如果未成功，提取 `<table class="error">` 标签内的内容作为错误提示。

### 3.3 解析逻辑示例

```javascript
function parseResult(html) {
    if (html.indexOf('操作成功') != -1) {
        return { success: true };
    }
    
    var match = html.match(/<table class="error">(.|\s)*?<\/table>/);
    if (match) {
        var msg = match[0].replace(/<.+?>/g, '').trim(); // 去除 HTML 标签
        return { success: false, message: msg };
    }
    
    return { success: false, message: '未知错误' };
}
```

