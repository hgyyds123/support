-- ================================================
-- hg 工单系统 - 更严格的 RLS 策略（推荐生产环境使用）
-- 在 tickets-schema.sql 之后执行
-- ================================================

-- 删除原有的宽松策略
DROP POLICY IF EXISTS "anyone_can_insert_tickets" ON tickets;
DROP POLICY IF EXISTS "anyone_can_read_tickets" ON tickets;
DROP POLICY "anyone_can_update_tickets" ON tickets;

-- 策略 1：已登录用户可以提交工单（需要 Supabase Auth）
-- 这要求前端先通过 Supabase Auth 登录，获取 JWT
CREATE POLICY "authenticated_can_insert" ON tickets
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- 策略 2：管理员可以读取所有工单
-- 创建一个 profiles 表来存储用户角色
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    username TEXT UNIQUE,
    role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- 用户可以读取自己的 profile
CREATE POLICY "users_read_own_profile" ON profiles
    FOR SELECT
    USING (auth.uid() = id);

-- 用户可以更新自己的 profile
CREATE POLICY "users_update_own_profile" ON profiles
    FOR UPDATE
    USING (auth.uid() = id);

-- 管理员可以读取所有 profile
CREATE POLICY "admins_read_all_profiles" ON profiles
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- 工单读取策略：管理员可以读取所有，用户可以读取自己的
CREATE POLICY "admin_read_all_tickets" ON tickets
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

CREATE POLICY "user_read_own_tickets" ON tickets
    FOR SELECT
    USING (user_name = (
        SELECT username FROM profiles WHERE id = auth.uid()
    ));

-- 工单更新策略：只有管理员可以回复和改状态
CREATE POLICY "admin_update_tickets" ON tickets
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- 将第一个注册用户设为管理员（可选）
-- INSERT INTO profiles (id, username, role)
-- SELECT id, raw_user_meta_data->>'username', 'admin'
-- FROM auth.users
-- LIMIT 1;

COMMENT ON TABLE profiles IS '用户资料与角色权限';
COMMENT ON COLUMN profiles.role IS '角色: user=普通用户, admin=管理员';