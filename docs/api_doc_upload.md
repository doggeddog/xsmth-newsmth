# 水木社区“附件上传”模式 API 文档

## 1. 接口概述

该接口用于在发帖前上传图片或其他附件，以及删除已上传的附件。
返回 HTML 页面，通过内嵌 JS 解析。

- **URL**: `https://www.newsmth.net/bbsupload.php`
- **HTTP 方法**: `POST` (上传) / `GET` (删除)
- **编码**: GBK

## 2. 上传附件

- **URL**: `https://www.newsmth.net/bbsupload.php?act=add`
- **HTTP 方法**: `POST` (Multipart Form Data)
- **参数**:
    - `attachfile0`: (File) 文件内容。
    - `counter`: `1` (可能代表文件数量或索引)。
    - `MAX_FILE_SIZE`: `5242880` (5MB 限制)。

## 3. 删除附件

- **URL**: `https://www.newsmth.net/bbsupload.php?act=delete&attachname={key}`
- **HTTP 方法**: `GET`
- **参数**:
    - `act`: `delete`
    - `attachname`: 附件唯一标识 key (从上传列表中获取)。

## 4. 响应解析

HTML 响应通过 DOM 操作解析（WebView 环境）。

### 4.1 状态判断
- **成功 (上传)**: 页面包含文本 `上传成功`。
- **成功 (删除)**: 页面包含正则匹配 `提示：删除.*成功`。
- **失败**: 提取 `<font color='red'>(.*)<\/font>` 中的错误信息。

### 4.2 附件列表提取 (针对上传后)
从响应的 `<ol>` 列表中提取当前已上传的所有附件。

- **HTML 结构**:
  ```html
  <ol>
    <li>
      文件名
      <a href="javascript:deletesubmit('KEY')">删除</a>
    </li>
  </ol>
  ```
- **字段提取**:
    - `name`: `li` 的首个文本节点。
    - `key`: 从删除链接的 JS 参数中提取。

### 4.3 解析逻辑示例 (JavaScript)

```javascript
function parseUpload(html) {
    var data = { act: 0, message: '', items: [] };
    
    // 1. 提取消息
    var match = html.match(/<font color='red'>(.*)<\/font>/);
    if (match) {
        data.message = match[1];
        if (data.message.indexOf('上传成功') != -1) data.act = 1;
        else if (data.message.match(/提示：删除.*成功/)) data.act = 2;
    }
    
    // 2. 提取列表 (依赖 DOM)
    var listMatch = html.match(/<ol(.|\s)*?<\/ol>/);
    if (listMatch) {
        var div = document.createElement('div');
        div.innerHTML = listMatch[0];
        var lis = div.querySelectorAll('li');
        // 遍历提取 name 和 key...
    }
    return data;
}
```

