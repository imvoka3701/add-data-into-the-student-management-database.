# Thêm Dữ Liệu Vào Trong Cơ Sở Dữ Liệu Quản Lý Sinh Viên

> **Mục tiêu:** Sử dụng thành thạo câu lệnh `INSERT INTO` (DML) trong MySQL để thêm dữ liệu vào các bảng trong cơ sở dữ liệu `QuanLySinhVien`, nắm vững thứ tự chèn dữ liệu tuân thủ ràng buộc toàn vẹn khóa ngoại (Referential Integrity), các kỹ thuật chèn bản ghi linh hoạt (Bulk Insert, chỉ định cột, giá trị mặc định, hàm hệ thống `CURRENT_DATE`).

---

## 📑 Mục lục
1. [Tổng quan CSDL & Sơ đồ ERD](#1-tổng-quan-csdl--sơ-đồ-erd)
2. [Nguyên tắc thứ tự chèn dữ liệu (Khóa ngoại)](#2-nguyên-tắc-thứ-tự-chèn-dữ-liệu-khóa-ngoại)
3. [Các biến thể của câu lệnh INSERT INTO](#3-các-biến-thể-của-câu-lệnh-insert-into)
4. [Hướng dẫn chi tiết các bước thực hiện](#4-hướng-dẫn-chi-tiết-các-bước-thực-hiện)
5. [Dữ liệu kết quả sau khi nạp](#5-dữ-liệu-kết-quả-sau-khi-nạp)
6. [Truy vấn kiểm tra & Báo cáo học tập (JOIN)](#6-truy-vấn-kiểm-tra--báo-cáo-học-tập-join)
7. [Hướng dẫn đồng bộ Git & GitHub](#7-hướng-dẫn-đồng-bộ-git--github)

---

## 1. Tổng quan CSDL & Sơ đồ ERD

Cơ sở dữ liệu `QuanLySinhVien` gồm 4 bảng có liên kết chặt chẽ:
* **`Class` (Lớp học):** Lưu danh sách lớp (`ClassID`, `ClassName`, `StartDate`, `Status`).
* **`Student` (Sinh viên):** Lưu thông tin sinh viên và mã lớp tham gia (`StudentID`, `StudentName`, `Address`, `Phone`, `Status`, `ClassId`).
* **`Subject` (Môn học):** Lưu danh mục môn học (`SubId`, `SubName`, `Credit`, `Status`).
* **`Mark` (Điểm thi):** Lưu điểm thi từng môn của sinh viên theo lần thi (`MarkId`, `SubId`, `StudentId`, `Mark`, `ExamTimes`).

### Sơ đồ Thực thể Quan hệ (ERD Diagram)

```mermaid
erDiagram
    Class ||--o{ Student : "chứa (1-n)"
    Student ||--o{ Mark : "có kết quả (1-n)"
    Subject ||--o{ Mark : "được chấm điểm (1-n)"

    Class {
        int ClassID PK "AUTO_INCREMENT"
        varchar(60) ClassName "NOT NULL"
        datetime StartDate "NOT NULL"
        bit Status "DEFAULT 1"
    }

    Student {
        int StudentID PK "AUTO_INCREMENT"
        varchar(30) StudentName "NOT NULL"
        varchar(50) Address
        varchar(20) Phone "NULLABLE"
        bit Status "DEFAULT 1"
        int ClassId FK "Tham chiếu Class(ClassID)"
    }

    Subject {
        int SubId PK "AUTO_INCREMENT"
        varchar(30) SubName "NOT NULL"
        tinyint Credit "CHECK (Credit >= 1)"
        bit Status "DEFAULT 1"
    }

    Mark {
        int MarkId PK "AUTO_INCREMENT"
        int SubId FK "Tham chiếu Subject(SubId)"
        int StudentId FK "Tham chiếu Student(StudentID)"
        float Mark "CHECK (Mark BETWEEN 0 AND 100)"
        tinyint ExamTimes "DEFAULT 1"
    }
```

---

## 2. Nguyên tắc thứ tự chèn dữ liệu (Khóa ngoại)

Trong cơ sở dữ liệu quan hệ, **ràng buộc toàn vẹn tham chiếu (Foreign Key Constraint)** yêu cầu: *Giá trị của trường khóa ngoại trong bảng con (Child Table) bắt buộc phải tồn tại trong trường khóa chính của bảng cha (Parent Table)*.

Do đó, **thứ tự thực thi câu lệnh `INSERT` bắt buộc phải là**:

```
[Bảng độc lập / Bảng cha]         [Bảng con cấp 1]          [Bảng con cấp 2]
     1. Class       ───────────►     2. Student    ────────┐
                                                           ├────►  4. Mark
     3. Subject     ───────────────────────────────────────┘
```

> [!IMPORTANT]
> **Tuyệt đối không chèn bảng `Student` trước bảng `Class`**: Nếu cố tình chèn `Student` với `ClassId = 1` khi bảng `Class` chưa có bản ghi nào, MySQL sẽ báo lỗi vi phạm khóa ngoại:
> `Error Code: 1452. Cannot add or update a child row: a foreign key constraint fails`.
> Tương tự, bảng `Mark` phải được chèn sau cùng vì nó phụ thuộc đồng thời vào cả `Student` và `Subject`.

---

## 3. Các biến thể của câu lệnh INSERT INTO

Bài thực hành này giúp nắm vững 3 cú pháp quan trọng nhất của `INSERT INTO`:

| Cú pháp | Đặc điểm | Trường hợp sử dụng |
| :--- | :--- | :--- |
| **1. Cú pháp toàn diện (Implicit columns)** | `INSERT INTO TableName VALUES (v1, v2, ...);` | Khi đã biết rõ và cung cấp đầy đủ giá trị cho mọi cột theo đúng thứ tự khai báo. |
| **2. Cú pháp chỉ định cột (Explicit columns)** | `INSERT INTO TableName (col1, col2) VALUES (v1, v2);` | Khi bỏ qua các cột tự tăng (`AUTO_INCREMENT`), các cột cho phép `NULL`, hoặc các cột có `DEFAULT`. |
| **3. Cú pháp chèn nhiều dòng (Bulk / Multi-row)** | `INSERT INTO TableName VALUES (r1), (r2), (r3);` | Tối ưu hóa hiệu năng mạng và I/O khi cần nạp nhanh danh mục nhiều bản ghi. |

---

## 4. Hướng dẫn chi tiết các bước thực hiện

### Bước 1: Chọn CSDL cần thao tác
```sql
USE QuanLySinhVien;
```

### Bước 2: Thêm bản ghi vào bảng `Class`
Thêm 3 lớp học với thông tin ngày khai giảng và trạng thái. Lưu ý ở bản ghi thứ 3, ta sử dụng hàm `CURRENT_DATE` của MySQL để lấy ngày thực thi tự động.

```sql
INSERT INTO Class VALUES (1, 'A1', '2008-12-20', 1);
INSERT INTO Class VALUES (2, 'A2', '2008-12-22', 1);
INSERT INTO Class VALUES (3, 'B3', CURRENT_DATE, 0);
```

### Bước 3: Thêm dữ liệu vào bảng `Student`
Ở bước này, ta chỉ định rõ danh sách các cột trong câu lệnh `INSERT`:
* Bỏ qua cột `StudentID` vì cột này có thuộc tính `AUTO_INCREMENT` tự động tăng.
* Bản ghi của sinh viên `Hoa` không có số điện thoại, ta bỏ cột `Phone` khỏi danh sách trường, MySQL sẽ tự động điền `NULL`.

```sql
INSERT INTO Student (StudentName, Address, Phone, Status, ClassId) 
VALUES ('Hung', 'Ha Noi', '0912113113', 1, 1);

INSERT INTO Student (StudentName, Address, Status, ClassId) 
VALUES ('Hoa', 'Hai phong', 1, 1);

INSERT INTO Student (StudentName, Address, Phone, Status, ClassId) 
VALUES ('Manh', 'HCM', '0123123123', 0, 2);
```

### Bước 4: Thêm dữ liệu nhanh (Bulk Insert) vào bảng `Subject`
Chèn 4 môn học với số tín chỉ tương ứng chỉ bằng 1 câu lệnh SQL duy nhất:

```sql
INSERT INTO Subject VALUES 
    (1, 'CF', 5, 1),
    (2, 'C', 6, 1),
    (3, 'HDJ', 5, 1),
    (4, 'RDBMS', 10, 1);
```

### Bước 5: Thêm dữ liệu vào bảng `Mark`
Chèn kết quả thi của sinh viên cho từng môn:
* Sinh viên `Hung` (StudentID = 1) thi môn `CF` (SubId = 1) được **8 điểm** ở lần thi 1.
* Sinh viên `Hoa` (StudentID = 2) thi môn `CF` (SubId = 1) được **10 điểm** ở lần thi 2.
* Sinh viên `Hung` (StudentID = 1) thi môn `C` (SubId = 2) được **12 điểm** ở lần thi 1.

```sql
INSERT INTO Mark (SubId, StudentId, Mark, ExamTimes) 
VALUES 
    (1, 1, 8, 1),
    (1, 2, 10, 2),
    (2, 1, 12, 1);
```

---

## 5. Dữ liệu kết quả sau khi nạp

### Bảng `Class`
| ClassID | ClassName | StartDate | Status | Ghi chú |
| :---: | :---: | :---: | :---: | :--- |
| `1` | A1 | 2008-12-20 | 1 (True) | Lớp học đang hoạt động |
| `2` | A2 | 2008-12-22 | 1 (True) | Lớp học đang hoạt động |
| `3` | B3 | Ngày hiện tại | 0 (False) | Lớp chờ mở/tạm dừng |

### Bảng `Student`
| StudentID | StudentName | Address | Phone | Status | ClassId |
| :---: | :--- | :--- | :---: | :---: | :---: |
| `1` | Hung | Ha Noi | 0912113113 | 1 | 1 |
| `2` | Hoa | Hai phong | *NULL* | 1 | 1 |
| `3` | Manh | HCM | 0123123123 | 0 | 2 |

### Bảng `Subject`
| SubId | SubName | Credit | Status |
| :---: | :--- | :---: | :---: |
| `1` | CF (Computer Fundamentals) | 5 | 1 |
| `2` | C (C Programming) | 6 | 1 |
| `3` | HDJ (HTML / CSS / JS) | 5 | 1 |
| `4` | RDBMS (Relational Database) | 10 | 1 |

### Bảng `Mark`
| MarkId | SubId | StudentId | Mark | ExamTimes |
| :---: | :---: | :---: | :---: | :---: |
| `1` | 1 | 1 | 8.0 | 1 |
| `2` | 1 | 2 | 10.0 | 2 |
| `3` | 2 | 1 | 12.0 | 1 |

---

## 6. Truy vấn kiểm tra & Báo cáo học tập (JOIN)

Để kiểm tra mối quan hệ và tính toàn vẹn của dữ liệu vừa nạp, ta thực hiện câu lệnh `INNER JOIN` giữa 4 bảng:

```sql
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
```

**Kết quả trả về:**
| StudentID | StudentName | ClassName | SubName | Credit | DiemThi | LanThi |
| :---: | :--- | :---: | :--- | :---: | :---: | :---: |
| 1 | Hung | A1 | C | 6 | 12.0 | 1 |
| 1 | Hung | A1 | CF | 5 | 8.0 | 1 |
| 2 | Hoa | A1 | CF | 5 | 10.0 | 2 |

---

## 7. Hướng dẫn đồng bộ Git & GitHub

Repository đã được khởi tạo và liên kết tới remote trên GitHub:

```bash
# Di chuyển vào thư mục dự án
cd "C:\Users\ductr\.gemini\antigravity-ide\scratch\add-data-into-the-student-management-database"

# Kiểm tra trạng thái
git status

# Đẩy mã nguồn lên nhánh chính (main)
git push -u origin main
```

Mã nguồn tham khảo CodeGym: [jwbd-2023-sql-student-management-insert-into](https://github.com/codegym-vn/jwbd-2023-sql-student-management-insert-into)
