package com.nara.server;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/* loaded from: /home/hatch/workspace/rea-clash-of-clans/analysis/../dump-full/classes.dex */
final class Log {
    private static final long MAX_LOG_BYTES = 2097152;
    private final SimpleDateFormat fmt;
    private final Object lock;
    private final boolean mirrorStdout;
    private final File path;

    Log(File file) {
        this(file, true);
    }

    Log(File file, boolean z) {
        this.lock = new Object();
        this.fmt = new SimpleDateFormat("HH:mm:ss", Locale.US);
        this.path = file;
        this.mirrorStdout = z;
    }

    void write(String str) {
        boolean z;
        FileOutputStream fileOutputStream;
        synchronized (this.lock) {
            String str2 = "[" + this.fmt.format(new Date()) + "] " + str;
            if (this.mirrorStdout) {
                System.out.println(str2);
                System.out.flush();
            }
            File file = this.path;
            if (file != null) {
                try {
                    File parentFile = file.getParentFile();
                    if (parentFile != null && !parentFile.exists()) {
                        parentFile.mkdirs();
                    }
                    try {
                        if (this.path.isFile() && this.path.length() > MAX_LOG_BYTES) {
                            z = false;
                            fileOutputStream = new FileOutputStream(this.path, z);
                            fileOutputStream.write((str2 + "\n").getBytes(Py.UTF8));
                            fileOutputStream.close();
                        }
                        fileOutputStream.write((str2 + "\n").getBytes(Py.UTF8));
                        fileOutputStream.close();
                    } catch (Throwable th) {
                        fileOutputStream.close();
                        throw th;
                    }
                    z = true;
                    fileOutputStream = new FileOutputStream(this.path, z);
                } catch (IOException unused) {
                }
            }
        }
    }
}
