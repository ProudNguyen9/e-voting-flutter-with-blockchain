# Prompt Google Stitch cho giao diện E-Voting hiện đại

Dùng prompt dưới đây để tạo giao diện app voting hiện đại:

```text
Thiết kế một web app E-Voting hiện đại, chuyên nghiệp, tối giản và đáng tin cậy, dành cho hệ thống bỏ phiếu điện tử kết hợp blockchain + backend xác thực.

Mục tiêu:
- Giao diện hiện đại, sạch, high-tech nhưng dễ dùng
- Phù hợp cho sinh viên, tổ chức, trường học, doanh nghiệp
- Ưu tiên UX rõ ràng, thao tác nhanh, dễ hiểu
- Responsive desktop + tablet + mobile
- Phong cách giống dashboard SaaS cao cấp

Tone thiết kế:
- Hiện đại, minh bạch, bảo mật, đáng tin cậy
- Kết hợp cảm giác civic-tech + fintech + gov-tech
- Tối giản, ít rối, khoảng trắng tốt
- Có hiệu ứng hover nhẹ, shadow mềm, glassmorphism nhẹ vừa phải

Màu sắc:
- Primary: xanh dương đậm / indigo / cobalt
- Secondary: tím nhẹ hoặc cyan
- Background: trắng, xám rất nhạt, dark navy cho một số section nổi bật
- Success: xanh lá hiện đại
- Warning: vàng cam nhẹ
- Danger: đỏ vừa phải
- Cần cả Light Mode và Dark Mode

Typography:
- Font hiện đại, dễ đọc
- Heading mạnh mẽ, body text rõ ràng
- Ưu tiên cảm giác công nghệ và chuyên nghiệp

Hãy tạo full UI/UX cho các màn hình sau:

1. Landing page
- Hero section lớn với headline về bỏ phiếu điện tử an toàn và minh bạch
- Mô tả ngắn: xác thực người dùng, PIN xác minh, blockchain, hoàn gas
- CTA chính: “Bắt đầu bỏ phiếu”
- CTA phụ: “Xem cách hoạt động”
- Các feature cards: bảo mật, minh bạch, ẩn danh, blockchain verification, gas refund
- Section mô tả quy trình 4 bước:
  1) Tạo tài khoản
  2) Đăng ký tham gia cuộc bầu cử
  3) Admin duyệt và gửi PIN
  4) Xác thực PIN và bỏ phiếu
- Section FAQ
- Footer chuyên nghiệp

2. Trang đăng ký tài khoản user
- Form gồm: họ tên, email, mật khẩu, xác nhận mật khẩu, địa chỉ ví MetaMask
- Có panel minh họa bảo mật tài khoản
- Hiển thị trạng thái: đăng ký xong có thể đăng nhập ngay
- UI đẹp, rõ, có validation trực quan

3. Trang đăng nhập user
- Form email + mật khẩu
- Nút đăng nhập hiện đại
- Nút kết nối MetaMask phụ trợ
- Có khối thông tin giải thích: đăng nhập tài khoản xong mới đăng ký bầu cử

4. Trang đăng nhập admin
- Giao diện riêng biệt hơn, cảm giác secure admin portal
- Form username + password
- Có icon/shield/security visual

5. Dashboard user
- Header có avatar, tên user, địa chỉ ví rút gọn
- Sidebar hoặc top navigation hiện đại
- Các card thống kê:
  - Số cuộc bầu cử đang mở
  - Số cuộc đã đăng ký
  - Trạng thái duyệt
  - Trạng thái hoàn gas
- Danh sách cuộc bầu cử dạng card hiện đại
- Mỗi election card có:
  - Tiêu đề
  - Mô tả ngắn
  - Thời gian bắt đầu / kết thúc
  - Trạng thái: sắp diễn ra / đang mở / đã kết thúc
  - Nút “Đăng ký tham gia”
  - Nếu đã đăng ký thì hiện badge “Chờ admin duyệt” hoặc “Đã được duyệt”

6. Trang chi tiết cuộc bầu cử
- Thông tin cuộc bầu cử rõ ràng
- Danh sách ứng cử viên dạng card đẹp
- Mỗi candidate card có avatar, tên, mô tả ngắn, slogan
- Hiển thị tiến trình tham gia:
  - Chưa đăng ký
  - Đã đăng ký chờ duyệt
  - Đã duyệt và có PIN
  - Đã bỏ phiếu
- Nếu chưa duyệt thì hiện banner chờ admin phê duyệt
- Nếu đã duyệt thì hiện khu vực nhập PIN

7. Màn hình xác thực PIN
- Form nhập mã PIN 6 số
- Thiết kế cực rõ ràng, cảm giác an toàn
- Có visual trạng thái thành công / thất bại
- Sau khi xác thực thành công, mở quyền bỏ phiếu

8. Màn hình bỏ phiếu
- Danh sách ứng cử viên card/grid đẹp, hiện đại
- Chọn 1 ứng cử viên với trạng thái selected rõ ràng
- Có panel xác nhận lựa chọn trước khi gửi vote
- Hiển thị lưu ý: vote sẽ được ghi lên blockchain và ẩn danh
- Nút “Xác nhận bỏ phiếu” nổi bật
- Sau khi vote thành công hiển thị transaction hash, trạng thái gas tracking, trạng thái hoàn gas

9. Trang kết quả bỏ phiếu
- Biểu đồ hiện đại: bar chart / donut chart
- Số phiếu theo từng ứng cử viên
- Có badge xác minh blockchain
- Có audit trail / transaction proof / thời gian cập nhật

10. Admin dashboard
- Giao diện dashboard hiện đại, chuyên nghiệp, nhiều card dữ liệu
- Các phần chính:
  - Danh sách đăng ký bầu cử chờ duyệt
  - Quản lý cuộc bầu cử
  - Tạo cuộc bầu cử mới
  - Theo dõi người đã vote
  - Theo dõi gas refund
- Bảng pending registrations hiện đại, có nút duyệt từng user
- Khi admin duyệt thì UI hiển thị flow: tạo PIN, đăng ký blockchain, gửi email
- Form tạo election đẹp, rõ ràng, dùng date-time picker hiện đại

11. Gas refund tracking page
- Danh sách giao dịch vote
- Cột: user, election, tx hash, gas used, total cost, refund status
- Badge: pending / refunded
- Nút refund cho admin
- Có filter theo election và trạng thái

12. Notification / status system
- Toast notifications đẹp cho:
  - đăng ký thành công
  - đăng nhập thành công
  - đăng ký bầu cử thành công
  - chờ admin duyệt
  - admin duyệt thành công
  - PIN đúng / sai
  - bỏ phiếu thành công
  - hoàn gas thành công

Yêu cầu component:
- Modern navbar
- Sidebar dashboard
- Cards bo góc lớn
- Buttons gradient nhẹ
- Tables hiện đại
- Status badges đẹp
- Step progress / timeline
- Modal xác nhận hành động
- Empty states đẹp
- Loading skeletons
- Search / filter / sort cho dashboard

UX requirements:
- Rất rõ các trạng thái nghiệp vụ:
  - user đăng ký tài khoản xong là dùng được ngay
  - chỉ khi đăng ký tham gia cuộc bầu cử mới cần admin duyệt
  - sau khi admin duyệt thì user nhận PIN
  - PIN chỉ để xác thực trước khi bỏ phiếu
- Mỗi trạng thái cần có badge màu riêng và message dễ hiểu
- Nên có stepper hoặc timeline cho flow bỏ phiếu

Hãy tạo giao diện hoàn chỉnh với:
- layout system rõ ràng
- spacing đẹp
- component consistency cao
- icon gợi ý phù hợp
- mock data thực tế
- ưu tiên thiết kế có thể triển khai bằng HTML/CSS/JS hoặc React
- style đủ hiện đại để nhìn giống một sản phẩm thật, không phải giao diện demo đơn giản
```

## Prompt ngắn gọn hơn

```text
Thiết kế UI/UX hiện đại cho web app E-Voting sử dụng blockchain và backend xác thực. App có các màn hình: landing page, đăng ký user, đăng nhập user, đăng nhập admin, user dashboard, election list, election detail, chờ admin duyệt, nhập PIN, bỏ phiếu, kết quả bầu cử, admin dashboard, gas refund tracking. Phong cách hiện đại, tối giản, tin cậy, high-tech, giống SaaS dashboard cao cấp. Màu chủ đạo xanh dương/indigo, có light và dark mode, responsive, card đẹp, bảng đẹp, badge trạng thái rõ ràng, stepper flow rõ ràng. Nhấn mạnh đúng nghiệp vụ: user đăng ký tài khoản xong dùng ngay, nhưng đăng ký tham gia bầu cử thì phải chờ admin duyệt và gửi PIN. Sau khi xác thực PIN mới được bỏ phiếu. Hãy tạo giao diện chuyên nghiệp như sản phẩm thực tế.
```

## Prompt nếu muốn thiên về frontend code

```text
Generate a modern, premium, responsive E-Voting web application UI with a clean SaaS dashboard style. Include pages for landing, user auth, admin auth, user dashboard, election registration, admin approval workflow, PIN verification, voting page, results page, and gas refund tracking. Use a trustworthy civic-tech + fintech aesthetic with blue/indigo palette, smooth cards, status badges, tables, charts, timeline steps, modals, and strong visual hierarchy. Important workflow: account registration is auto-approved, but election participation requires admin approval before a PIN is sent. After PIN verification, the user can vote. Design it like a real production-ready product.
```
