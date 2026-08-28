# EduVault - Không Gian Lưu Trữ & Quản Lý Dữ Liệu Học Tập (Public Study Hub)

**EduVault** là nền tảng lưu trữ và chia sẻ tài liệu học tập (Giáo trình, Slide bài giảng, Đề thi, Sổ tay ghi chú Markdown, Mã nguồn bài tập) hoạt động trực tiếp trên **GitHub Repository** với giao diện tối giản, chuyên nghiệp và miễn phí 100%.

---

## 🌟 4 Phân Hệ Trọng Tâm Dành Cho Học Tập

1. **📚 Kho Tài Liệu Môn Học (Study Drive):**
   * Phân loại theo thư mục môn học (`LapTrinhWeb`, `ToanCaoCap`, `TiengAnh`,...).
   * Kéo & thả tài liệu (PDF, Slide PPTX, Video học, Mindmap, Mã nguồn ZIP).
   * Trình đọc PDF, xem trước hình ảnh sơ đồ và code editor tích hợp sẵn.

2. **📝 Sổ Tay Ghi Chú Lý Thuyết (Markdown Notes):**
   * Soạn thảo và đọc tóm tắt công thức, định lý, lý thuyết bằng Markdown.
   * Chế độ chia đôi màn hình (Side-by-side Live Preview).
   * Tự động lưu và đồng bộ thành các tệp `.md` trong thư mục `notes/` của GitHub.

3. **🎯 Ngân Hàng Đề Thi & Bài Tập Ôn Luyện (Exam Bank):**
   * Quản lý đề thi giữa kỳ, cuối kỳ, đề kiểm tra các năm kèm link đáp án chi tiết.
   * Đánh dấu độ khó (Dễ, Trung bình, Khó) và trạng thái ôn tập (*Đang ôn*, *Cần ôn lại*, *Đã hoàn thành*).
   * Xuất file dữ liệu đề thi dạng JSON dự phòng.

4. **⚡ Trình Tạo Link CDN jsDelivr Toàn Cầu:**
   * Tự động tạo link tải tài liệu tốc độ cao để gửi cho bạn bè trong nhóm lớp mà không lo bị chặn hoặc quá tải dung lượng.

---

## 🚀 Hướng Dẫn Cập Nhật Website Lên GitHub Pages

Vì bạn đã cấu hình kho lưu trữ **`AnNguyen-Script/DataHocTap`**, để cập nhật phiên bản mới này lên trang web công khai:

1. Mở trang kho lưu trữ của bạn: [https://github.com/AnNguyen-Script/DataHocTap](https://github.com/AnNguyen-Script/DataHocTap)
2. Bấm nút **Add file** (góc phải) > Chọn **Upload files**.
3. Kéo toàn bộ các tệp:
   * [index.html](file:///c:/Users/PC/Documents/WED%20An%20Nguyen/index.html)
   * [styles.css](file:///c:/Users/PC/Documents/WED%20An%20Nguyen/styles.css)
   * [README.md](file:///c:/Users/PC/Documents/WED%20An%20Nguyen/README.md)
   * Thư mục `js/` (chứa [app.js](file:///c:/Users/PC/Documents/WED%20An%20Nguyen/js/app.js), [github-api.js](file:///c:/Users/PC/Documents/WED%20An%20Nguyen/js/github-api.js), [storage-manager.js](file:///c:/Users/PC/Documents/WED%20An%20Nguyen/js/storage-manager.js))
4. Bấm **Commit changes**.
5. Sau 30-60 giây, website tại **`https://annguyen-script.github.io/DataHocTap/`** sẽ tự động cập nhật sang giao diện EduVault mới!

---

## 🔒 Hướng Dẫn Lấy Token (PAT) Để Tải Lên Tài Liệu

1. Truy cập: [https://github.com/settings/tokens?type=beta](https://github.com/settings/tokens?type=beta)
2. Bấm **Generate new token**.
3. Chọn Repository: **Only select repositories** > Chọn **`DataHocTap`**.
4. Tại mục **Permissions > Repository permissions**, chọn **Contents** -> **Read and write**.
5. Bấm **Generate token** và dán mã token vào mục **Cấu hình Repo** trên website EduVault.
