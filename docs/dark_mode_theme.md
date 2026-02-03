# 暗色模式主题配色方案

本文档记录了 `xsmth-newsmth` 项目中暗色模式（Night Mode）的配色方案。
相关代码主要位于 `newsmth/Common/SMTheme.m` 文件中。

## 配色详情

当 `[SMConfig enableDayMode]` 返回 `false` 时，应用将使用以下配色：

| 颜色用途 | 属性名 | 色值 (RGB/Hex) | 说明 |
| :--- | :--- | :--- | :--- |
| **主要文字** | `colorForPrimary` | `(173, 173, 174)` / `#ADADAE` | 正文主要文字颜色 |
| **次要文字** | `colorForSecondary` | `(154, 154, 154)` / `#9A9A9A` | 辅助信息文字颜色 |
| **引用文字** | `colorForQuote` | `(88, 88, 89)` / `#585859` | 引用内容的文字颜色 |
| **控件着色** | `colorForTintColor` | `(135, 135, 135)` / `#878787` | 按钮、链接等控件颜色 |
| **高亮背景** | `colorForHighlightBackground` | `[UIColor darkGrayColor]` | 选中或高亮状态的背景色 |

### 背景色特殊处理

背景色和导航栏颜色根据机型（是否为 iPhone X 系列）有不同的处理，以适配 OLED 屏幕的纯黑显示特性。

| 颜色用途 | 属性名 | iPhone X 系列 | 其他机型 |
| :--- | :--- | :--- | :--- |
| **导航栏背景** | `colorForBarTintColor` | `[UIColor blackColor]` (纯黑) | `(38, 38, 39)` / `#262627` |
| **页面背景** | `colorForBackground` | `[UIColor blackColor]` (纯黑) | `(40, 40, 41)` / `#282829` |

## 代码参考

```objective-c
// newsmth/Common/SMTheme.m

+ (UIColor *)colorForPrimary
{
    return [SMConfig enableDayMode] ? SMRGB(0x32, 0x32, 0x32) : SMRGB(0xad, 0xad, 0xae);
}

+ (UIColor *)colorForSecondary
{
    return [SMConfig enableDayMode] ? SMRGB(0x65, 0x65, 0x65) : SMRGB(0x9a, 0x9a, 0x9a);
}

+ (UIColor *)colorForQuote
{
    return [SMConfig enableDayMode] ? SMRGB(0x87, 0x87, 0x87) : SMRGB(0x58, 0x58, 0x59);
}

+ (UIColor *)colorForBarTintColor
{
    return [SMConfig enableDayMode] ? SMRGB(0xff, 0xff, 0xff) : (IS_IPHONE_X ? [UIColor blackColor] : SMRGB(0x26, 0x26, 0x27));
}

+ (UIColor *)colorForTintColor
{
    return [SMConfig enableDayMode] ? SMRGB(0x1c, 0x0, 0xce) : SMRGB(0x87, 0x87, 0x87);
}

+ (UIColor *)colorForBackground
{
    return [SMConfig enableDayMode] ? SMRGB(0xfc, 0xfc, 0xfc) : (IS_IPHONE_X ? [UIColor blackColor] : SMRGB(0x28, 0x28, 0x29));
}

+ (UIColor *)colorForHighlightBackground
{
    return [SMConfig enableDayMode] ? SMRGB(0xe0, 0xe0, 0xe0) : [UIColor darkGrayColor];
}
```

