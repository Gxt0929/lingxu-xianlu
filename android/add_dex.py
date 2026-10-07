# Append classes.dex into an existing APK zip without re-compressing other entries.
import sys, zipfile, shutil

src, dex, out = sys.argv[1], sys.argv[2], sys.argv[3]
shutil.copyfile(src, out)
with zipfile.ZipFile(out, 'a', zipfile.ZIP_DEFLATED) as z:
    z.write(dex, 'classes.dex')
print('classes.dex added ->', out)
