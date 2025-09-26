import re

# ==== Cấu hình chuyển numpy sang cupy ====
USE_GPU = True
NP_MODULE = "cupy" if USE_GPU else "numpy"

# ==== Đọc file .byby ====
with open("main.byby", "r", encoding="utf-8") as f:
    code_byby = f.read()

# ==== Chuyển import .byby sang Python ====
def convert_imports(line):
    if 'import "numpy.byby"' in line:
        return f"import {NP_MODULE} as np"
    elif 'import "cv2.byby"' in line:
        return "import cv2"
    elif 'import "os.byby"' in line:
        return "import os"
    elif 'import "glob.byby"' in line:
        return "import glob"
    elif 'import "hashlib.byby"' in line:
        return "import hashlib"
    elif 'import "random.byby"' in line:
        return "import random"
    return line

# ==== Chuyển cú pháp cơ bản ====
def convert_syntax(line):
    line = line.rstrip()
    # function name and params -> def name(params):
    match = re.match(r'function (\w+) and (.+)', line)
    if match:
        func_name = match.group(1)
        params = match.group(2).replace(" and ", ", ")
        return f"def {func_name}({params}):"
    # biến is biểu thức -> biến = biểu thức
    line = re.sub(r'(\w+) is (.+)', r'\1 = \2', line)
    # gọi hàm dạng func and params -> func(params)
    line = re.sub(r'(\w+) and (.+)', r'\1(\2)', line)
    # giữ indent
    indent_level = len(line) - len(line.lstrip())
    line = ' ' * indent_level + line.lstrip()
    return line

# ==== Chuyển toàn bộ code ====
python_lines = []
for l in code_byby.splitlines():
    l = convert_imports(l)
    if l.strip() == "":
        python_lines.append("")
        continue
    python_lines.append(convert_syntax(l))

python_code = "\n".join(python_lines)

# ==== Xuất ra file .py (tuỳ chọn) ====
with open("main.py", "w", encoding="utf-8") as f:
    f.write(python_code)

print("Đã chuyển main.byby -> main.py xong!")

# ==== Exec code trực tiếp vào globals() ====
try:
    exec(python_code)
except Exception as e:
    print("Lỗi khi exec:", e)
