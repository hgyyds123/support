-- ================================================
-- hg 工单系统 Supabase 数据库表结构
-- 执行方式：在 Supabase 项目的 SQL Editor 中运行
-- ================================================

-- 1. 工单表
CREATE TABLE IF NOT EXISTS tickets (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'other' CHECK (category IN ('account', 'safe_2fa', 'talkroom', 'internet', 'community', 'other')),
    description TEXT NOT NULL,
    contact TEXT NOT NULL,
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high')),
    attachment TEXT,
    user_name TEXT,
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'replied', 'closed')),
    reply TEXT,
    replied_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. 索引（加速查询）
CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status);
CREATE INDEX IF NOT EXISTS idx_tickets_category ON tickets(category);
CREATE INDEX IF NOT EXISTS idx_tickets_created_at ON tickets(created_at DESC);

-- 3. 自动更新时间戳的触发器
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_ticket_updated_at
    BEFORE UPDATE ON tickets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- 4. Row Level Security (RLS) 策略
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;

-- 策略 1：任何人可以提交工单（INSERT）
CREATE POLICY "anyone_can_insert_tickets" ON tickets
    FOR INSERT
    WITH CHECK (true);

-- 策略 2：任何人可以读取工单（因为管理后台用密码鉴权，不依赖数据库角色）
-- 生产环境建议改为只允许管理员读取
CREATE POLICY "anyone_can_read_tickets" ON tickets
    FOR SELECT
    USING (true);

-- 策略 3：允许更新工单（回复、改状态）
CREATE POLICY "anyone_can_update_tickets" ON tickets
    FOR UPDATE
    USING (true);

-- 5. 可选：创建管理员角色（更严格的鉴权方案）
-- 如果以后需要更严格的权限控制，可以启用以下代码
-- 创建一个管理员用户，然后在策略中使用 auth.jwt() 验证

-- 6. 注释
COMMENT ON TABLE tickets IS 'hg 支持工单系统';
COMMENT ON COLUMN tickets.status IS '工单状态: open=待处理, replied=已回复, closed=已关闭';
COMMENT ON COLUMN tickets.priority IS '优先级: low=低, normal=普通, high=紧急';