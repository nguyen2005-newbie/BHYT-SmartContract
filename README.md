# 🏥 DeInsure BHYT - Hệ Thống Quản Lý BHYT Phi Tập Trung

Dự án nghiên cứu ứng dụng Hợp đồng thông minh (Smart Contract) trên nền tảng Blockchain nhằm tối ưu hóa quy trình đối soát và quyết toán chi phí Bảo hiểm Y tế.

## 👥 Thành Viên Thực Hiện
* **Sinh viên:** Nguyễn Thanh Nguyên
* **Chuyên ngành:** Công nghệ Tài chính (Fintech)
* **Trường:** Đại học Công nghiệp Thực phẩm TP.HCM (HUIT)

## 📌 Các Tính Năng Cốt Lõi
1. **Cấp thẻ định danh điện tử (DID):** Tự động áp dụng thuật toán giảm trừ gia cảnh lũy tiến khi mua thẻ on-chain.
2. **Đối soát phân tuyến tự động:** Nhận diện và thực thi điều khoản xử phạt tài chính khi người bệnh điều trị trái tuyến Trung ương/Tỉnh hoặc miễn trừ đối với hóa đơn nhỏ (<15% lương cơ sở).
3. **Cổng chờ quyết toán (Escrow):** Khóa dòng tiền đồng chi trả của người dân và tiền quỹ gánh an toàn, cho phép bệnh viện rút tiền chủ động theo thời gian thực (Real-time).

## 🛠️ Công Nghệ Sử Dụng
* Ngôn ngữ lập trình: Solidity `^0.8.20`
* Trình biên dịch giả lập: Remix IDE (Remix VM - Cancun)
* Tiêu chuẩn an toàn: Cơ chế khóa trạng thái kép chống tấn công Reentrancy.
