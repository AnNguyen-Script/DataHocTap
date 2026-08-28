# GitVault - Nền Tảng Lưu Trữ Dữ Liệu Thực Tế Trên GitHub (Public & Open Source)

**GitVault** là một ứng dụng web hiện đại biến **GitHub Repository** thành một dịch vụ lưu trữ đám mây (Cloud Drive) và cơ sở dữ liệu (JSON Database / Mini CMS) thực tế với giao diện người dùng trực quan, bảo mật và hoàn toàn miễn phí.

---

## 🌟 Tính Năng Nổi Bật

1. **Cloud Drive Đích Thực:**
   * Tải lên bất kỳ định dạng tệp tin nào (Hình ảnh, Video, Âm thanh, PDF, Tài liệu, Mã nguồn).
   * Hỗ trợ kéo & thả (Drag & Drop) nhiều tệp tin cùng lúc.
   * Tạo cây thư mục, đổi tên, chỉnh sửa tệp trực tiếp trong trình duyệt và commit tự động vào GitHub.

2. **Cơ Sở Dữ Liệu JSON (Data Vault / Mini CMS):**
   * Lưu trữ các bảng dữ liệu dạng JSON (ví dụ: `data/records.json`, `data/posts.json`).
   * Giao diện thêm, sửa, xóa, tìm kiếm bản ghi tức thì không cần can thiệp trực tiếp vào mã nguồn JSON.
   * Hỗ trợ phân loại danh mục, gán nhãn (tags) và xuất file dữ liệu.

3. **Xem Trước Trực Quan & Trình Soạn Thảo Đa Năng:**
   * Xem trước ảnh, phát video/audio, hiển thị tài liệu PDF.
   * Trình biên soạn Markdown với chế độ xem trước (Live Preview).
   * Trình soạn thảo văn bản và mã nguồn có syntax highlight.

4. **Trình Tạo Link CDN & Public Embed Tốc Độ Cao:**
   * Tự động tạo liên kết phân phối nội dung toàn cầu qua **jsDelivr CDN**, **Raw GitHub**, **Statically**.
   * Cung cấp sẵn mã nhúng thẻ HTML `<img>` và cú pháp Markdown `![]()`.

5. **Hoạt Động Công Khai & Bảo Mật Tuyệt Đối:**
   * Khách truy cập công khai có thể duyệt file và xem dữ liệu (Read-Only) mà không cần đăng nhập.
   * Chủ sở hữu quản trị bằng **GitHub Fine-grained Personal Access Token (PAT)** được lưu cục bộ trong trình duyệt (`localStorage`), không thông qua máy chủ trung gian.

---

## 🚀 Hướng Dẫn Cài Đặt & Sử Dụng Từng Bước

### Bước 1: Tạo GitHub Repository để chứa dữ liệu
1. Đăng nhập vào GitHub và truy cập: [https://github.com/new](https://github.com/new)
2. Đặt tên cho kho dữ liệu (Ví dụ: `my-data-vault` hoặc `my-cloud-storage`).
3. Chọn **Public** (nếu muốn ai cũng xem được tệp qua CDN) hoặc **Private** (nếu chỉ muốn mình bạn xem).
4. Tích chọn **Add a README file** để GitHub tạo nhánh `main` mặc định.
5. Bấm **Create repository**.

---

### Bước 2: Tạo GitHub Personal Access Token (PAT)
Token giúp website có quyền ghi (Upload / Sửa / Xóa) dữ liệu vào Repository của bạn:

1. Vào [GitHub Token Settings](https://github.com/settings/tokens?type=beta) (Hoặc: *Avatar góc phải > Settings > Developer Settings > Personal access tokens > Fine-grained tokens*).
2. Bấm **Generate new token**.
3. Điền các thông tin:
   * **Token name:** `GitVault Web App`
   * **Expiration:** Chọn thời hạn (ví dụ: 90 days hoặc Custom).
   * **Repository access:** Chọn **Only select repositories** > Chọn repo bạn vừa tạo ở Bước 1.
   * **Permissions > Repository permissions:** Tìm mục **Contents** và đổi sang **Read and write**.
4. Kéo xuống dưới cùng và bấm **Generate token**.
5. Sao chép chuỗi mã Token vừa tạo (bắt đầu bằng `github_pat_...`).

---

### Bước 3: Kết Nối Trên Website
1. Mở trang web GitVault.
2. Bấm vào nút **Cấu hình Repo** (hoặc biểu tượng bánh răng ⚙️ ở góc trên bên phải).
3. Nhập:
   * **Username (Owner):** Tên tài khoản GitHub của bạn (ví dụ: `nguyenan`).
   * **Tên Repository:** Tên repo ở Bước 1 (ví dụ: `my-data-vault`).
   * **Nhánh (Branch):** `main`.
   * **Personal Access Token:** Dán mã Token vừa tạo ở Bước 2.
4. Bấm **Kiểm tra kết nối** > Sau khi hiện thông báo thành công, bấm **Lưu & Kết nối**.

---

### Bước 4: Xuất Bản Website Công Khai Lên GitHub Pages (100% Miễn Phí)
Để đưa website này lên mạng Internet công khai cho mọi người cùng truy cập:

1. Đẩy toàn bộ mã nguồn của thư mục này (`index.html`, `styles.css`, thư mục `js/`, ...) lên một GitHub Repository của bạn.
2. Mở Repository đó trên GitHub > Vào tab **Settings**.
3. Ở menu bên trái, chọn mục **Pages**.
4. Tại phần **Build and deployment > Source**, chọn **Deploy from a branch**.
5. Tại mục **Branch**, chọn nhánh `main` và thư mục `/(root)`, sau đó bấm **Save**.
6. Sau khoảng 1-2 phút, GitHub Pages sẽ kích hoạt và cung cấp cho bạn một đường dẫn công khai có dạng:
   ```
   https://<username>.github.io/<ten-repo>/
   ```
7. Bạn có thể chia sẻ đường link này cho bất kỳ ai!

---

## 🛠️ Cấu Trúc Mã Nguồn

```text
├── index.html            # Giao diện chính chuẩn SEO & Semantic HTML5
├── styles.css            # Hệ thống Design System Dark Theme & Glassmorphism
├── js/
│   ├── github-api.js     # Module kết nối GitHub REST API v3 (CRUD, Auth, CDN)
│   ├── storage-manager.js# Quản lý Base64 UTF-8, định dạng dung lượng & phân loại file
│   └── app.js            # Controller chính điều khiển sự kiện, drag-drop, modal, database
└── README.md             # Tài liệu hướng dẫn sử dụng & triển khai
```

---

## 🔒 Cam Kết Bảo Mật
* **Không lưu trữ trên Server thứ 3:** Mã nguồn hoạt động 100% Client-side.
* **Token được mã hóa cục bộ:** Token GitHub của bạn chỉ lưu trong trình duyệt của bạn và gửi thẳng tới máy chủ chính thức `api.github.com` qua giao thức HTTPS.
