import sys

with open("ScheduleView.swift", "r") as f:
    text = f.read()

target = """                                        .onDrag {
                                            let idString = task.id.persistentModelID.uriRepresentation().absoluteString
                                            return NSItemProvider(object: idString as NSString)
                                        }"""

replacement = """                                        .onDrag {
                                            let idString = task.createdAt.timeIntervalSince1970.description
                                            return NSItemProvider(object: idString as NSString)
                                        }"""

if target in text:
    text = text.replace(target, replacement)
    with open("ScheduleView.swift", "w") as f:
        f.write(text)
    print("Success")
else:
    print("Target not found. Let's do a more robust replace.")
    import re
    text = re.sub(r'let idString = task\.id\.persistentModelID\.uriRepresentation\(\)\.absoluteString', r'let idString = task.createdAt.timeIntervalSince1970.description', text)
    with open("ScheduleView.swift", "w") as f:
        f.write(text)
    print("Fallback success")

