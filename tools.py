from pathlib import Path

INPUT_FILE = r"ios\Runner.xcodeproj\project.pbxproj"
OUTPUT_FILE = "pbx_extract.txt"


def extract_section(content: str, begin: str, end: str):
    start = content.find(begin)
    if start == -1:
        print(f"Không tìm thấy: {begin}")
        return ""

    finish = content.find(end, start)
    if finish == -1:
        print(f"Không tìm thấy: {end}")
        return ""

    finish += len(end)
    return content[start:finish]


with open(INPUT_FILE, "r", encoding="utf-8") as f:
    text = f.read()

sections = [
    (
        "PBXBuildFile -> PBXResourcesBuildPhase",
        "/* Begin PBXBuildFile section */",
        "/* End PBXResourcesBuildPhase section */",
    ),
    (
        "PBXFileReference -> PBXShellScriptBuildPhase",
        "/* Begin PBXFileReference section */",
        "/* End PBXShellScriptBuildPhase section */",
    ),
    (
        "PBXResourcesBuildPhase",
        "/* Begin PBXResourcesBuildPhase section */",
        "/* End PBXResourcesBuildPhase section */",
    ),
]

result = []

for title, begin, end in sections:
    data = extract_section(text, begin, end)

    result.append("=" * 100)
    result.append(title)
    result.append("=" * 100)

    if data:
        result.append(data)
    else:
        result.append("Không tìm thấy đoạn này.")

    result.append("\n\n")

with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    f.write("\n".join(result))

print(f"Đã xuất ra: {Path(OUTPUT_FILE).resolve()}")