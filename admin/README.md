# hg 工单系统部署指南

## 功能概述

- 用户端：在 `support.hg1.dpdns.org/admin/submit-ticket.html` 提交工单
- 管理端：在 `support.hg1.dpdns.org/admin/tickets.html` 查看和回复工单
- 数据存储：Supabase PostgreSQL
- 鉴权方式：
  - 用户端：读取跨子域 cookie `hg_user_name`，值为 `hg` 时放行提交
  - 管理端：管理员密码验证

## 鉴权机制说明

### 用户端鉴权（Cookie）

浏览器安全策略禁止跨域读取 localStorage，因此采用跨子域 cookie 方案：

1. **hg1.dpdns.org 主站登录时**，设置跨子域 cookie：
   ```javascript
   // 前端 JS 设置（需要 HTTPS）
   document.cookie = "hg_user_name=hg; domain=.hg1.dpdns.org; path=/; Secure; SameSite=Lax";
   ```
   或在服务端设置：
   ```
   Set-Cookie: hg_user_name=hg; Domain=.hg1.dpdns.org; Path=/; Secure; HttpOnly
   ```

2. **support.hg1.dpdns.org 子站**读取 cookie：
   ```javascript
   // submit-ticket.html 中的 getCookie('hg_user_name')
   // 值为 'hg' 时放行提交工单
   ```

### 管理端鉴权（密码）

管理后台 `tickets.html` 需要管理员密码登录，防止越权查看所有工单。

## 部署步骤

### 1. 配置 Supabase

1. 登录 Supabase 项目
2. 在 SQL Editor 中执行 `tickets-schema.sql`（宽松策略版）或 `tickets-schema-strict.sql`（严格策略版）
3. 记录你的项目 URL 和 anon key：
   - URL: `https://xxx.supabase.co`
   - anon key: 在 Settings → API → Project API keys 中获取

### 2. 修改配置

在 `submit-ticket.html` 和 `tickets.html` 中修改以下变量：

```javascript
// tickets.html 中
const ADMIN_PASSWORD = 'hg_admin_2024'; // 改为你的管理员密码
const SUPABASE_URL = 'https://xxx.supabase.co'; // 替换为你的 Supabase URL
const SUPABASE_KEY = 'xxx'; // 替换为你的 anon key

// submit-ticket.html 中
const SUPABASE_URL = 'https://xxx.supabase.co'; // 替换为你的 Supabase URL
const SUPABASE_KEY = 'xxx'; // 替换为你的 anon key
```

### 3. 修改 hg1.dpdns.org 主站登录逻辑

在 hg1.dpdns.org 的登录逻辑中，登录成功后添加：

```javascript
// 登录成功后设置跨子域 cookie
document.cookie = "hg_user_name=hg; domain=.hg1.dpdns.org; path=/; Secure; SameSite=Lax";
```

或服务端响应头设置：

```
Set-Cookie: hg_user_name=hg; Domain=.hg1.dpdns.org; Path=/; Secure; HttpOnly
```

### 4. 上传到 GitHub Pages

将 `admin/` 目录上传到你的 GitHub Pages 仓库的 `admin/` 文件夹下。

### 5. 验证

- 用户端：访问 `https://support.hg1.dpdns.org/admin/submit-ticket.html`
  - 先访问 `https://hg1.dpdns.org` 登录
  - 返回工单页面，应显示用户名 "hg"
  - 填写表单并提交
- 管理端：访问 `https://support.hg1.dpdns.org/admin/tickets.html`
  - 输入管理员密码登录
  - 查看工单列表
  - 点击工单查看详情并回复

## 合规性与安全

### 低风险（推荐）
- Cookie 只存用户名（`hg`），不存密码、token 等敏感信息
- 设置 `Secure` 标志，仅通过 HTTPS 传输
- 设置 `SameSite=Lax`，防止 CSRF
- 管理后台有独立密码验证

### 注意事项
- `domain=.hg1.dpdns.org` 会让所有 `*.hg1.dpdns.org` 子域都能读到 cookie
- 如果设了 `HttpOnly`，前端 JS 读不到，但浏览器会自动携带
- 不要存密码、API key 等敏感信息在 cookie 里
- 如果以后需要更严格的权限控制，可以升级到 `tickets-schema-strict.sql` + Supabase Auth

### 不合规场景（避免）
- ❌ 存密码或 token 在 cookie 里
- ❌ 不设 Secure 标志，HTTP 明文传输
- ❌ 不设 SameSite，可能被 CSRF 利用
- ❌ 管理后台不做任何验证

## 文件结构

```
D:\support\
├── admin/
│   ├── submit-ticket.html         # 用户端提交工单页面
│   ├── tickets.html               # 管理后台
│   ├── tickets-schema.sql         # 数据库表结构（宽松策略）
│   ├── tickets-schema-strict.sql  # 数据库表结构（严格策略）
│   ├── cookie-auth-notes.sql      # Cookie 鉴权说明（仅供参考）
│   ├── config.example.js          # 配置文件模板
│   └── README.md                  # 本文件
└── ... (其他帮助文档)
```

## 环境变量（可选）

如果需要区分开发/生产环境，建议通过环境变量或配置文件管理敏感信息：

```javascript
// config.js（不要提交到 GitHub）
window.HG_CONFIG = {
    ADMIN_PASSWORD: 'your_password_here',
    SUPABASE_URL: 'https://xxx.supabase.co',
    SUPABASE_KEY: 'your_anon_key_here'
};
```

然后在 HTML 中引用：
```html
<script src="config.js"></script>
```

记得在 `.gitignore` 中排除 `config.js`。