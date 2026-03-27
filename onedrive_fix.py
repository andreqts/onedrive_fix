import os
import sys
import time
import unicodedata
from datetime import datetime

# CONFIGURE HERE: OneDrive local folder path
ONEDRIVE_PATH = r"C:\Users\andre\OneDrive"

# Report path
REPORT = "onedrive_diagnosis.txt"

# Prohibited characters by OneDrive/Windows
INVALID_CHARS = set('<>:"/\\|?*')

def has_invalid_chars(name):
    return any(c in INVALID_CHARS for c in name)

def has_invisible_chars(name):
    return any(ord(c) < 32 for c in name)

def is_path_too_long(path):
    return len(path) > 250  # safety margin

def has_invalid_timestamp(path):
    try:
        ts = os.path.getmtime(path)
        dt = datetime.fromtimestamp(ts)
        return dt.year < 1980 or dt.year > 2100
    except:
        return True

def check_file(path, report):
    problems = []

    name = os.path.basename(path)

    if has_invalid_chars(name):
        problems.append("Invalid characters in name")

    if has_invisible_chars(name):
        problems.append("Invisible characters in name")

    if is_path_too_long(path):
        problems.append("Path too long (>250 chars)")

    if has_invalid_timestamp(path):
        problems.append("Invalid timestamp")

    # ADS (Alternate Data Streams)
    if ":" in name and not path.startswith("\\\\?\\"):
        problems.append("Alternate Data Stream detected")

    if problems:
        report.write(f"[ISSUE] {path}\n")
        for p in problems:
            report.write(f"  - {p}\n")
        report.write("\n")

def main():
    if not os.path.exists(ONEDRIVE_PATH):
        print("OneDrive path not found.")
        sys.exit(1)

    with open(REPORT, "w", encoding="utf-8") as report:
        report.write("=== OneDrive Diagnosis ===\n")
        report.write(f"Date: {datetime.now()}\n\n")

        for root, dirs, files in os.walk(ONEDRIVE_PATH):
            for f in files:
                full = os.path.join(root, f)
                check_file(full, report)

    print(f"Diagnosis completed. View the file: {REPORT}")

if __name__ == "__main__":
    main()