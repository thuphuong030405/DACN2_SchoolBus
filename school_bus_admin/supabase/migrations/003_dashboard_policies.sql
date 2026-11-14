-- =========================================================
-- Policy cho Web Dashboard (Ban giám hiệu). Chạy SAU 001_schema_v4 và 002_security_v4.
-- Phân quyền phải làm ở DATABASE, không chỉ ở giao diện.
-- =========================================================

-- Vai trò của người đang đăng nhập (dùng được qua supabase.rpc('my_role'))
CREATE OR REPLACE FUNCTION public.my_role() RETURNS TEXT
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
    SELECT role::text FROM public.users
    WHERE user_id = (SELECT auth.uid()) AND is_active
$$;

REVOKE ALL ON FUNCTION public.my_role() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.my_role() TO authenticated;

-- Ban giám hiệu (ADMIN, SCHOOL_MANAGER) toàn quyền trên các bảng vận hành.
-- is_school_admin() đã được tạo ở 002_security_v4.sql.
DO $$
DECLARE t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'buses','routes','route_stops','student_routes',
        'teachers','drivers','trips','attendance','absences','alerts'
    ]
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', t || '_staff_all', t);
        EXECUTE format(
            'CREATE POLICY %I ON public.%I FOR ALL TO authenticated
             USING (public.is_school_admin()) WITH CHECK (public.is_school_admin())',
            t || '_staff_all', t);
    END LOOP;
END;
$$;

-- Lịch sử GPS: Ban giám hiệu chỉ xem
DROP POLICY IF EXISTS gps_staff_select ON public.gps_locations;
CREATE POLICY gps_staff_select ON public.gps_locations
    FOR SELECT TO authenticated USING (public.is_school_admin());

-- Lưu ý: các bảng trên vẫn CHƯA cho phụ huynh, giáo viên, tài xế truy cập.
-- Viết policy cho các vai trò đó trước khi test app di động
-- (tìm .from('tên_bảng') trong code Flutter để biết app đang đọc bảng nào).
