-- ====================================================================
-- BÀI THỰC HÀNH: THÊM DỮ LIỆU VÀO TRONG CSDL QUẢN LÝ SINH VIÊN
-- Cơ sở dữ liệu: QuanLySinhVien
-- Tác giả: CodeGym / Database Management Practicum
-- Mục tiêu: Luyện tập sử dụng câu lệnh DML INSERT INTO với các biến thể:
--   1. Chèn đầy đủ tất cả các cột theo thứ tự mặc định
--   2. Chèn chỉ định rõ danh sách các cột (bỏ qua cột NULL hoặc có DEFAULT)
--   3. Chèn nhiều bản ghi đồng thời (Bulk / Multi-row INSERT)
--   4. Sử dụng hàm hệ thống của MySQL (CURRENT_DATE / NOW())
-- ====================================================================

-- Bước 0: Tạo cơ sở dữ liệu và cấu trúc các bảng nếu chưa có
DROP DATABASE IF EXISTS QuanLySinhVien;
CREATE DATABASE QuanLySinhVien CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Bước 1: Sử dụng câu lệnh USE QuanLySinhVien để kích hoạt CSDL
USE QuanLySinhVien;

-- -----------------------------------------------------
-- 1. Tạo bảng Class (Lớp học)
-- -----------------------------------------------------
CREATE TABLE Class (
    ClassID   INT AUTO_INCREMENT NOT NULL,
    ClassName VARCHAR(60) NOT NULL,
    StartDate DATETIME NOT NULL,
    Status    BIT DEFAULT 1,
    CONSTRAINT PK_Class PRIMARY KEY (ClassID)
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- 2. Tạo bảng Student (Sinh viên)
-- -----------------------------------------------------
CREATE TABLE Student (
    StudentID   INT AUTO_INCREMENT NOT NULL,
    StudentName VARCHAR(30) NOT NULL,
    Address     VARCHAR(50),
    Phone       VARCHAR(20),
    Status      BIT DEFAULT 1,
    ClassId     INT NOT NULL,
    CONSTRAINT PK_Student PRIMARY KEY (StudentID),
    CONSTRAINT FK_Student_Class FOREIGN KEY (ClassId) 
        REFERENCES Class(ClassID) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- 3. Tạo bảng Subject (Môn học)
-- -----------------------------------------------------
CREATE TABLE Subject (
    SubId   INT AUTO_INCREMENT NOT NULL,
    SubName VARCHAR(30) NOT NULL,
    Credit  TINYINT NOT NULL DEFAULT 1 CHECK (Credit >= 1),
    Status  BIT DEFAULT 1,
    CONSTRAINT PK_Subject PRIMARY KEY (SubId)
) ENGINE = InnoDB;

-- -----------------------------------------------------
-- 4. Tạo bảng Mark (Điểm thi)
-- -----------------------------------------------------
CREATE TABLE Mark (
    MarkId    INT AUTO_INCREMENT NOT NULL,
    SubId     INT NOT NULL,
    StudentId INT NOT NULL,
    Mark      FLOAT DEFAULT 0 CHECK (Mark BETWEEN 0 AND 100),
    ExamTimes TINYINT DEFAULT 1,
    CONSTRAINT PK_Mark PRIMARY KEY (MarkId),
    CONSTRAINT FK_Mark_Subject FOREIGN KEY (SubId) 
        REFERENCES Subject(SubId) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT FK_Mark_Student FOREIGN KEY (StudentId) 
        REFERENCES Student(StudentID) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
) ENGINE = InnoDB;


-- ====================================================================
-- THỰC HIỆN THÊM DỮ LIỆU (DML INSERT STATEMENTS)
-- LƯU Ý QUAN TRỌNG VỀ THỨ TỰ THÊM DỮ LIỆU:
-- 1. Bảng độc lập (Class, Subject) phải được thêm trước.
-- 2. Bảng Student phụ thuộc vào Class nên phải thêm sau Class.
-- 3. Bảng Mark phụ thuộc vào cả Subject và Student nên phải thêm cuối cùng.
-- ====================================================================

-- Bước 2: Thêm lần lượt các bản ghi vào trong bảng Class
-- Cách 1: Chèn giá trị cho toàn bộ các cột theo thứ tự định nghĩa
INSERT INTO Class VALUES (1, 'A1', '2008-12-20', 1);
INSERT INTO Class VALUES (2, 'A2', '2008-12-22', 1);
-- Sử dụng hàm CURRENT_DATE của MySQL để lấy ngày hiện tại tự động
INSERT INTO Class VALUES (3, 'B3', CURRENT_DATE, 0);

-- Bước 3: Thêm dữ liệu vào trong bảng Student
-- Cách 2: Chỉ định rõ danh sách các cột cần thêm (bỏ qua StudentID vì tự tăng AUTO_INCREMENT)
-- Bản ghi 1: Có đầy đủ số điện thoại
INSERT INTO Student (StudentName, Address, Phone, Status, ClassId) 
VALUES ('Hung', 'Ha Noi', '0912113113', 1, 1);

-- Bản ghi 2: Không có Phone (cột Phone sẽ tự động nhận giá trị NULL)
INSERT INTO Student (StudentName, Address, Status, ClassId) 
VALUES ('Hoa', 'Hai phong', 1, 1);

-- Bản ghi 3: Sinh viên thuộc lớp 2 (A2), trạng thái nghỉ/chờ duyệt (Status = 0)
INSERT INTO Student (StudentName, Address, Phone, Status, ClassId) 
VALUES ('Manh', 'HCM', '0123123123', 0, 2);

-- Bước 4: Thêm dữ liệu nhanh (Bulk Insert / Multi-row) vào bảng Subject
-- Chèn nhiều dòng trong một lệnh INSERT duy nhất giúp tối ưu hiệu năng
INSERT INTO Subject VALUES 
    (1, 'CF', 5, 1),
    (2, 'C', 6, 1),
    (3, 'HDJ', 5, 1),
    (4, 'RDBMS', 10, 1);

-- Bước 5: Thêm dữ liệu vào bảng Mark
-- Chỉ định các cột ngoại khóa và giá trị điểm, lần thi
INSERT INTO Mark (SubId, StudentId, Mark, ExamTimes) 
VALUES 
    (1, 1, 8, 1),
    (1, 2, 10, 2),
    (2, 1, 12, 1);


-- ====================================================================
-- TRUY VẤN KIỂM TRA DỮ LIỆU ĐÃ NẠP
-- ====================================================================

-- Kiểm tra danh sách lớp học
SELECT 
    ClassID, 
    ClassName, 
    DATE_FORMAT(StartDate, '%d/%m/%Y') AS NgayBatDau, 
    IF(Status = 1, 'Hoạt động', 'Ngừng hoạt động') AS TrangThai 
FROM Class;

-- Kiểm tra danh sách sinh viên
SELECT 
    StudentID, 
    StudentName, 
    Address, 
    IFNULL(Phone, 'Chưa có SĐT') AS DienThoai, 
    IF(Status = 1, 'Đang học', 'Nghỉ học') AS TrangThai, 
    ClassId 
FROM Student;

-- Kiểm tra danh mục môn học
SELECT 
    SubId, 
    SubName, 
    Credit AS SoTinChi, 
    IF(Status = 1, 'Đang mở', 'Đóng') AS TrangThai 
FROM Subject;

-- Kiểm tra bảng điểm thi
SELECT 
    MarkId, 
    SubId, 
    StudentId, 
    Mark AS DiemThi, 
    ExamTimes AS LanThi 
FROM Mark;

-- Báo cáo tổng hợp kết quả học tập (JOIN 4 bảng)
SELECT 
    s.StudentID,
    s.StudentName,
    c.ClassName,
    sub.SubName,
    sub.Credit,
    m.Mark AS DiemThi,
    m.ExamTimes AS LanThi
FROM Mark m
INNER JOIN Student s ON m.StudentId = s.StudentID
INNER JOIN Class c ON s.ClassId = c.ClassID
INNER JOIN Subject sub ON m.SubId = sub.SubId
ORDER BY s.StudentID ASC, sub.SubName ASC;
