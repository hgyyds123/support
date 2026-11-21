-- ================================================
-- hg 工单系统 - Cookie 跨子域鉴权方案
-- 需要先在 hg1.dpdns.org 主站设置跨子域 cookie
-- ================================================

-- 此 SQL 文件仅用于说明，不需要在 Supabase 执行
-- 实际 cookie 设置需要在 hg1.dpdns.org 的登录逻辑中添加

-- 方案说明：
-- 1. hg1.dpdns.org 登录时设置 cookie: hg_user_name=hg; domain=.hg1.dpdns.org; path=/
-- 2. support.hg1.dpdns.org 可以直接读取这个 cookie
-- 3. 前端通过 document.cookie 读取用户名，无需密码、无需 localStorage

-- 安全注意事项：
-- - cookie 设置 domain=.hg1.dpdns.org 会让所有 *.hg1.dpdns.org 子域都能读到
-- - 建议设置 HttpOnly 标志，防止 XSS 窃取（前端 JS 读不到，但浏览器会自动携带）
-- - 如果前端需要读取，不能设 HttpOnly；此时要确保 HTTPS + SameSite 设置正确
-- - 不要存密码等敏感信息在 cookie 里，只存用户名即可

-- hg1.dpdns.org 登录时的设置示例（伪代码）：
-- document.cookie = "hg_user_name=hg; domain=.hg1.dpdns.org; path=/; Secure; SameSite=Lax";
-- 或者在服务端设置：
-- Set-Cookie: hg_user_name=hg; Domain=.hg1.dpdns.org; Path=/; Secure; HttpOnly