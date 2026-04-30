# 发表/编辑文章 API

本文档详细描述了在水木社区 (NewSMTH) nForum 接口下发表新帖、回复帖子以及编辑帖子的 API 细节。

## 1. 接口基本信息

此接口用于在指定版面发表文章或编辑已有文章。接口通过 HTTP POST 请求，返回 JSON 格式的数据。

| 属性 | 说明 |
| :--- | :--- |
| **协议** | HTTPS |
| **主机** | `www.newsmth.net` |
| **路径 (发表/回复)** | `/nForum/article/{boardName}/ajax_post.json` |
| **路径 (编辑)** | `/nForum/article/{boardName}/ajax_edit/{pid}.json` |
| **方法** | `POST` |
| **鉴权** | Cookie (必须包含登录状态的 Cookie，如 `main[UTMPUSERID]`) |

### URL 参数说明
*   `{boardName}`: 版面的英文 ID (例如 `Talking`, `AutoWorld`).
*   `{pid}`: (仅编辑时) 被编辑帖子的 ID.

## 2. 请求头 (Headers)

必须包含以下 Header 以模拟 Ajax 请求并确保服务端正确处理：

```http
Content-Type: application/x-www-form-urlencoded; charset=UTF-8
X-Requested-With: XMLHttpRequest
User-Agent: Mozilla/5.0 ... (建议使用浏览器或 App 的 UA)
Cookie: ... (包含登录 Cookie)
```

## 3. 请求参数 (Body)

请求体为 `application/x-www-form-urlencoded` 格式。

| 参数名 | 类型 | 必填 | 说明 |
| :--- | :--- | :--- | :--- |
| `subject` | string | 是 | **标题**。需进行 URL 编码。 |
| `content` | string | 是 | **内容**。需进行 URL 编码。 |
| `id` | int | 是 | **关联 ID**。<br>- **发表新主题**: 传 `0`。<br>- **回复帖子**: 传被回复帖子的 ID。<br>- **编辑帖子**: 传被编辑帖子的 ID。 |

> **注意**: 
> 1. 无需发送 `ticket`, `randstr` 等验证码字段（除非账号被特殊风控，App 端通常依赖 Cookie 信任）。
> 2. 只有在**回复**时，`id` 参数才真正起到关联父贴的作用；发表新主题时通常忽略该值但建议传 `0`。

## 4. 响应数据 (JSON)

接口返回 JSON 格式数据。

### 成功响应示例

```json
{
    "ajax_st": 1,
    "ajax_code": "0005",
    "ajax_msg": "操作成功",
    "list": [
        {
            "text": "主题:[测试][Test] App模拟",
            "url": "/article/Test/11"
        },
        {
            "text": "水木社区",
            "url": "/mainpage"
        }
    ]
}
```

### 失败响应示例

```json
{
    "ajax_st": 0,
    "ajax_code": "0101", 
    "ajax_msg": "未登录"
}
```

## 5. 结果判断逻辑

解析 JSON 响应中的 `ajax_code` 字段来判断操作是否成功。

| ajax_code | 含义 | 说明 |
| :--- | :--- | :--- |
| **"0005"** | **操作成功** | 标准成功状态码（包含跳转链接等信息）。 |
| **"0406"** | **发表成功** | 旧版或特定场景下的成功码（App 源码中包含此判断）。 |
| **"0306"** | **编辑成功** | 编辑操作的成功码（App 源码中包含此判断）。 |
| 其他 | 失败 | 通常 `ajax_msg` 会包含具体的错误信息（如“需要验证码”、“版面只读”等）。 |

> **重要提示**: App 源代码 (`SMWritePostViewController.m`) 目前仅判断了 `0406` 和 `0306`，遗漏了 `0005`。重写时请务必包含 `0005`。

## 6. 示例代码 (curl)

以下是模拟 App 真实请求的 curl 命令（包含 User-Agent 和签名）：

```bash
curl --compressed 'https://www.newsmth.net/nForum/article/Test/ajax_post.json' \
  -X POST \
  -H 'Host: www.newsmth.net' \
  -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
  -H 'Accept: */*' \
  -H 'Cookie: YOUR_LOGIN_COOKIES_HERE' \
  -H 'Connection: keep-alive' \
  -H 'User-Agent: newsmth/4.4.1 (me.maxwin.newsmth; build:4.4.1.1; iOS 26.3.0) Alamofire/5.6.2' \
  -H 'Accept-Language: zh-Hans-CN;q=1.0, en-CN;q=0.9' \
  -H 'Accept-Encoding: br;q=1.0, gzip;q=0.9, deflate;q=0.8' \
  -H 'x-requested-with: XMLHttpRequest' \
  --data-raw 'content=efg1&id=0&subject=test6'
```

---

curl 'https://www.newsmth.net/nForum/article/Test/ajax_post.json' \
  -H 'accept: */*' \
  -H 'accept-language: zh-CN,zh;q=0.9' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/x-www-form-urlencoded; charset=UTF-8' \
  -b 'Hm_lvt_3663c777a66d280fdb290b6b9808aff0=1771570978; HMACCOUNT=013FC8277CA918F2; main[XWJOKE]=hoho; main[UTMPUSERID]=ismthapp; main[UTMPKEY]=4973036; main[UTMPNUM]=3454; NFORUM=s0hfl6u4qthnv1dj3dbor479s4; \
  -H 'origin: https://www.newsmth.net' \
  -H 'pragma: no-cache' \
  -H 'priority: u=1, i' \
  -H 'referer: https://www.newsmth.net/nForum/' \
  -H 'sec-ch-ua: "Not(A:Brand";v="8", "Chromium";v="144", "Google Chrome";v="144"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-origin' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36' \
  -H 'x-requested-with: XMLHttpRequest' \
  --data-raw 'content=efg1&id=964737&subject=test17'



 curl 'https://m.newsmth.net/article/Test/post/964737' \
  -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
  -H 'accept-language: zh-CN,zh;q=0.9' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/x-www-form-urlencoded' \
  -b 'main[XWJOKE]=hoho; main[UTMPUSERID]=ismthapp; main[UTMPKEY]=48344774; main[UTMPNUM]=4315; Hm_lvt_bbac0322e6ee13093f98d5c4b5a10912=1771573983; HMACCOUNT=013FC8277CA918F2; nforum-left=00100; NFORUM=h694c7durma4akoqbd34uc4df2; Hm_lpvt_bbac0322e6ee13093f98d5c4b5a10912=1771590367' \
  -H 'origin: https://m.newsmth.net' \
  -H 'pragma: no-cache' \
  -H 'priority: u=0, i' \
  -H 'referer: https://m.newsmth.net/article/Test/post/964737' \
  -H 'sec-ch-ua: "Not(A:Brand";v="8", "Chromium";v="144", "Google Chrome";v="144"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: document' \
  -H 'sec-fetch-mode: navigate' \
  -H 'sec-fetch-site: same-origin' \
  -H 'sec-fetch-user: ?1' \
  -H 'upgrade-insecure-requests: 1' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36' \
  --data-raw 'subject=Re%3A+test&content=11'


  curl 'https://www.newsmth.net/nForum/board/Test/ajax_topads.json' \
  -H 'accept: application/json, text/javascript, */*; q=0.01' \
  -H 'accept-language: zh-CN,zh;q=0.9,en;q=0.8,zh-TW;q=0.7' \
  -H 'cache-control: no-cache' \
  -b 'HMACCOUNT=82BA97D4D9CDD034; HMACCOUNT=82BA97D4D9CDD034; Hm_lvt_9c7f4d9b7c00cb5aba2c637c64a41567=1769962450; Hm_lpvt_9c7f4d9b7c00cb5aba2c637c64a41567=1769962500; left-index=00000000000; nforum-left=00100; __gads=ID=e9a3bcfdd08097a1:T=1753198607:RT=1770833591:S=ALNI_Mb5vjUEEtPiccuxv-v8c7LSTeITGQ; __gpi=UID=0000116c1c3f95b4:T=1753198607:RT=1770833591:S=ALNI_MaGKOh41wbLpJKbqsL5qrKaT-2aNg; __eoi=ID=697793911fc83f44:T=1768915170:RT=1770833591:S=AA-AfjbtFr3_ON46VNBOm4Lz6lh7; Hm_lvt_bbac0322e6ee13093f98d5c4b5a10912=1771209766; Hm_lvt_3663c777a66d280fdb290b6b9808aff0=1771223172; WWWPARAMS=0; Hm_lpvt_bbac0322e6ee13093f98d5c4b5a10912=1771589945; main[XWJOKE]=hoho; main[UTMPUSERID]=ismthapp; main[UTMPKEY]=4973036; main[UTMPNUM]=3454; NFORUM=s0hfl6u4qthnv1dj3dbor479s4; Hm_lpvt_3663c777a66d280fdb290b6b9808aff0=1771674963' \
  -H 'pragma: no-cache' \
  -H 'priority: u=1, i' \
  -H 'referer: https://www.newsmth.net/nForum/' \
  -H 'sec-ch-ua: "Not(A:Brand";v="8", "Chromium";v="144", "Google Chrome";v="144"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-origin' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/144.0.0.0 Safari/537.36' \
  -H 'x-requested-with: XMLHttpRequest'