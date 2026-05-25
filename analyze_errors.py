import re
from collections import Counter

with open('analyze_output.txt', 'r', encoding='utf-8') as f:
    lines = f.readlines()

errors = []
for line in lines:
    if 'error - ' in line:
        parts = line.strip().split(' - ')
        if len(parts) >= 3:
            errors.append(parts[-1])

print("Error counts:")
for k, v in Counter(errors).items():
    print(f"{k}: {v}")
