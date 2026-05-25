from pathlib import Path
s = Path('lib/main.dart').read_text(encoding='utf-8')
stack = []
pairs = {'(':')','{':'}','[':']'}
closers = {v:k for k,v in pairs.items()}
line=1
col=0
for i,ch in enumerate(s):
    col+=1
    if ch=='\n':
        line+=1
        col=0
        continue
    if ch in pairs:
        stack.append((ch,line,col))
    elif ch in closers:
        if not stack:
            print(f"Unmatched closer '{ch}' at {line}:{col}")
            break
        last, lline, lcol = stack.pop()
        if closers[ch] != last:
            print(f"Mismatched closer '{ch}' at {line}:{col}, expected '{pairs[last]}' for opener at {lline}:{lcol}")
            break
else:
    if stack:
        last, lline, lcol = stack[-1]
        print(f"Unclosed opener '{last}' at {lline}:{lcol}")
    else:
        print('All balanced')
