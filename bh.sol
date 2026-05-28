// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract BaoHiemYTe {
    
    // --- QUẢN LÝ QUYỀN TRUY CẬP (ACCESS CONTROL) ---
    address public admin; 

    modifier chiCoAdmin() {
        require(msg.sender == admin, "Chi co Admin moi co quyen thuc thi");
        _;
    }

    modifier chiCoBenhVien() {
        require(danhSachBenhVien[msg.sender].daDangKy, "Chi co Benh vien hop phap moi co quyen");
        _;
    }

    modifier chongKhoaKep() {
        require(!_dangKhoa, "Loi Reentrancy: Giao dich dang duoc thuc thi");
        _dangKhoa = true;
        _;
        _dangKhoa = false;
    }

    // --- CẤU TRÚC DỮ LIỆU ---
    enum NhomDoiTuong { ChinhSach, CanNgheo, HocSinhSinhVien, TuNguyen }

    struct BenhVien {
        bool daDangKy;
        string tenBenhVien;
        uint8 capTuyen; // 1: Tuyến Trung ương, 2: Tuyến Tỉnh, 3: Tuyến Huyện/Xã
    }

    struct TheBHYT {
        bool dangHoatDong;
        string maThe;             
        string tenBenhNhan;       
        string soCCCD;            
        uint256 hanSuDung;        
        uint256 maHoGiaDinh;      
        NhomDoiTuong nhomTuoi;    
        address benhVienBanDau;   
    }

    struct HoSoChoThanhToan {
        bool tonTai;
        bool daXacNhanThanhToan;
        address benhVienKham;          
        uint256 tongVienPhiVND;         
        uint256 tienMienGiamBaoHiemVND;
        uint256 tienBenhNhanTraVND;   
        uint256 tienQuyChiTraETH;      
        uint256 tienBenhNhanTraETH;   
    }

    // --- BIẾN TRẠNG THÁI HỆ THỐNG ---
    bool private _dangKhoa;
    uint256 public luongCoSoVND;          
    uint256 public phiDuyTriHeThongVND;   
    uint256 public heSoPhatTraiTuyen;     
    uint256 public tyGiaEthSangVND;       
    uint256 public tongQuyBaoHiemETH;     

    mapping(address => BenhVien) public danhSachBenhVien;
    mapping(address => TheBHYT) public danhSachTheBHYT;
    mapping(uint256 => uint256) public soThanhVienHoGiaDinh;      
    mapping(address => uint256) public congChoQuyetToanBenhVien;    
    mapping(address => HoSoChoThanhToan) public hoSoCuaBenhNhan; 

    // --- SỰ KIỆN (EVENTS) ---
    event CoSoYTeDaDangKy(address indexed diaChiBenhVien, string tenBenhVien, uint8 capTuyen);
    event TheBHYTDaMuaThanhCong(address indexed nguoiDan, string maThe, uint256 tienDongETH);
    event HoSoYTeChoQuyetToanDaLap(address indexed benhVien, address indexed benhNhan, uint256 tongHoaDonVND);
    event GiaoDichVienPhiHoanTat(address indexed benhNhan, address indexed benhVien, uint256 tienQuyTraETH, uint256 tienDanTraETH);
    event BenhVienDaRutTienThanhCong(address indexed benhVien, uint256 soTienETH);

    // BƯỚC 1: KHỞI TẠO HỢP ĐỒNG (Admin thiết lập tham số nền tảng)
    constructor(
        uint256 _luongCoSoVND,
        uint256 _phiDuyTriHeThongVND,
        uint256 _heSoPhatTraiTuyen,
        uint256 _tyGiaEthSangVND
    ) {
        admin = msg.sender; 
        luongCoSoVND = _luongCoSoVND;
        phiDuyTriHeThongVND = _phiDuyTriHeThongVND;
        heSoPhatTraiTuyen = _heSoPhatTraiTuyen;
        tyGiaEthSangVND = _tyGiaEthSangVND;
    }

    // BƯỚC 2: BỆNH VIỆN ĐĂNG KÝ VÀO HỆ THỐNG
    function dangKyBenhVien(address _diaChiBenhVien, string memory _tenBenhVien, uint8 _capTuyen) external chiCoAdmin {
        require(_diaChiBenhVien != address(0), "Dia chi vi khong hop le");
        require(_capTuyen >= 1 && _capTuyen <= 3, "Cap tuyen phai tu 1 den 3");
        
        danhSachBenhVien[_diaChiBenhVien] = BenhVien({daDangKy: true, tenBenhVien: _tenBenhVien, capTuyen: _capTuyen});
        emit CoSoYTeDaDangKy(_diaChiBenhVien, _tenBenhVien, _capTuyen);
    }

    // BƯỚC 3: NGƯỜI DÂN MUA VÀ KÍCH HOẠT THẺ BẢO HIỂM
    function tinhPhiGiaHanVND(uint256 _maHoGiaDinh) public view returns (uint256) {
        uint256 phiGoc = (luongCoSoVND * 54) / 100; 
        uint256 soThanhVienHienTai = soThanhVienHoGiaDinh[_maHoGiaDinh];

        if (soThanhVienHienTai == 0) return phiGoc;
        if (soThanhVienHienTai == 1) return (phiGoc * 70) / 100;
        if (soThanhVienHienTai == 2) return (phiGoc * 60) / 100;
        if (soThanhVienHienTai == 3) return (phiGoc * 50) / 100;
        return (phiGoc * 40) / 100;
    }

    function baoGiaPhiBaoHiem(uint256 _maHoGiaDinh) public view returns (uint256 tongTienVND, uint256 tienYeuCauETH) {
        tongTienVND = tinhPhiGiaHanVND(_maHoGiaDinh) + phiDuyTriHeThongVND;
        require(tyGiaEthSangVND > 0, "Ty gia hien tai chua nap");
        tienYeuCauETH = (tongTienVND * 1e18) / tyGiaEthSangVND;
    }

    function muaTheBaoHiem(
        string memory _maThe,
        string memory _tenBenhNhan,
        string memory _soCCCD,
        uint256 _maHoGiaDinh,
        NhomDoiTuong _nhomDoiTuong,
        address _benhVienBanDau
    ) external payable {
        (, uint256 tienYeuCauETH) = baoGiaPhiBaoHiem(_maHoGiaDinh);
        require(msg.value >= (tienYeuCauETH * 98) / 100, "Tien nop vao quy thieu so voi bao gia");

        TheBHYT storage the = danhSachTheBHYT[msg.sender];
        bool daTungChay = the.dangHoatDong && (the.hanSuDung >= block.timestamp);
        
        the.dangHoatDong = true;
        the.maThe = _maThe;
        the.tenBenhNhan = _tenBenhNhan;
        the.soCCCD = _soCCCD;
        the.maHoGiaDinh = _maHoGiaDinh;
        the.nhomTuoi = _nhomDoiTuong;
        the.hanSuDung = (the.hanSuDung < block.timestamp) ? block.timestamp + 365 days : the.hanSuDung + 365 days;
        the.benhVienBanDau = _benhVienBanDau;

        if (!daTungChay) {
            soThanhVienHoGiaDinh[_maHoGiaDinh] += 1;
        }

        tongQuyBaoHiemETH += msg.value;
        emit TheBHYTDaMuaThanhCong(msg.sender, _maThe, msg.value);
    }

    // BƯỚC 4: BỆNH VIỆN ĐĂNG HỒ SƠ VÀ CHI PHÍ LÊN CHUỖI KHỐI
    function lapHoSoChoQuyetToan(
        address _benhNhan,
        uint256 _tongVienPhiVND,
        uint256 _khoanHopLeBaoHiemVND,
        bool _coGiayChuyenTuyenMienTru
    ) external chiCoBenhVien {
        TheBHYT memory the = danhSachTheBHYT[_benhNhan];
        require(the.dangHoatDong && the.hanSuDung >= block.timestamp, "The cua benh nhan het han hoac khong ton tai");
        require(!hoSoCuaBenhNhan[_benhNhan].tonTai || hoSoCuaBenhNhan[_benhNhan].daXacNhanThanhToan, "Benh nhan co ho so treo chua xu ly");

        uint256 tyLeBaoHiemChiTra = 80; 
        if (the.nhomTuoi == NhomDoiTuong.ChinhSach) tyLeBaoHiemChiTra = 100;
        else if (the.nhomTuoi == NhomDoiTuong.CanNgheo) tyLeBaoHiemChiTra = 95;

        // Miễn trừ nếu tổng chi phí nhỏ hơn 15% lương cơ sở
        bool duocMienPhiHoanToan = (_khoanHopLeBaoHiemVND < (luongCoSoVND * 15) / 100);
        
        if (duocMienPhiHoanToan) {
            tyLeBaoHiemChiTra = 100;
        } else if (the.benhVienBanDau != msg.sender && !_coGiayChuyenTuyenMienTru) {
            uint8 tuyenBv = danhSachBenhVien[msg.sender].capTuyen;
            if (tuyenBv == 1) tyLeBaoHiemChiTra = (tyLeBaoHiemChiTra * heSoPhatTraiTuyen) / 100; // Trái tuyến Trung ương
            else if (tuyenBv == 2) tyLeBaoHiemChiTra = (tyLeBaoHiemChiTra * (heSoPhatTraiTuyen + 10)) / 100; // Trái tuyến Tỉnh
        }

        uint256 tienMienGiamVND = (_khoanHopLeBaoHiemVND * tyLeBaoHiemChiTra) / 100;
        uint256 tienBenhNhanTraVND = _tongVienPhiVND - tienMienGiamVND;

        hoSoCuaBenhNhan[_benhNhan] = HoSoChoThanhToan({
            tonTai: true,
            daXacNhanThanhToan: false,
            benhVienKham: msg.sender,
            tongVienPhiVND: _tongVienPhiVND,
            tienMienGiamBaoHiemVND: tienMienGiamVND,
            tienBenhNhanTraVND: tienBenhNhanTraVND,
            tienQuyChiTraETH: (tienMienGiamVND * 1e18) / tyGiaEthSangVND,
            tienBenhNhanTraETH: (tienBenhNhanTraVND * 1e18) / tyGiaEthSangVND
        });

        emit HoSoYTeChoQuyetToanDaLap(msg.sender, _benhNhan, _tongVienPhiVND);
    }

    // BƯỚC 5: NGƯỜI DÂN XEM CHI TIẾT VÀ KÝ DUYỆT THANH TOÁN (XEM ĐƯỢC SỐ GIẢM)
    function xemChiTietHoSoCho(address _viBenhNhan) external view returns (
        uint256 tongVienPhiVND, 
        uint256 soTienDuocBHYTChiTraVND, 
        uint256 soTienTuChiTraVND,
        uint256 soTienDONGCHITRA_ETH
    ) {
        HoSoChoThanhToan memory hs = hoSoCuaBenhNhan[_viBenhNhan];
        require(hs.tonTai && !hs.daXacNhanThanhToan, "Khong tim thay ho so nao dang cho thanh toan");
        return (hs.tongVienPhiVND, hs.tienMienGiamBaoHiemVND, hs.tienBenhNhanTraVND, hs.tienBenhNhanTraETH);
    }

    function xacNhanVaThanhToan() external payable chongKhoaKep {
        HoSoChoThanhToan storage hs = hoSoCuaBenhNhan[msg.sender];
        require(hs.tonTai && !hs.daXacNhanThanhToan, "Ban khong co ho so treo nao can thanh toan");
        
        if (hs.tienBenhNhanTraETH > 0) {
            uint256 gioiHanThapNhat = (hs.tienBenhNhanTraETH * 98) / 100;
            require(msg.value >= gioiHanThapNhat, "Tien dong chi tra ban gui khong du");
        }
        require(tongQuyBaoHiemETH >= hs.tienQuyChiTraETH, "Quy bao hiem hien tai khong du thanh khoan");

        // Đóng hồ sơ hóa đơn
        hs.daXacNhanThanhToan = true;
        tongQuyBaoHiemETH -= hs.tienQuyChiTraETH;

        // Trộn nguồn quỹ tổng và tiền mặt của dân đưa vào cổng chờ của bệnh viện khám
        uint256 tongDoanhThuDonViNhan = hs.tienQuyChiTraETH + msg.value;
        congChoQuyetToanBenhVien[hs.benhVienKham] += tongDoanhThuDonViNhan;

        emit GiaoDichVienPhiHoanTat(msg.sender, hs.benhVienKham, hs.tienQuyChiTraETH, msg.value);
    }

    // BƯỚC 6: BỆNH VIỆN THU HỒI DOANH THU VỀ VÍ NGÂN QUỸ
    function rutTienDoanhThu() external chiCoBenhVien chongKhoaKep {
        uint256 soTienRut = congChoQuyetToanBenhVien[msg.sender];
        require(soTienRut > 0, "Tai khoan cong cho cua benh vien hien tai bang khong");

        // Xóa trạng thái trước khi gửi ETH để chống hack Reentrancy
        congChoQuyetToanBenhVien[msg.sender] = 0;

        (bool thanhCong, ) = msg.sender.call{value: soTienRut}("");
        require(thanhCong, "Rut dong tien quyet toan ve vi that bai");

        emit BenhVienDaRutTienThanhCong(msg.sender, soTienRut);
    }

    receive() external payable {
        tongQuyBaoHiemETH += msg.value;
    }
}