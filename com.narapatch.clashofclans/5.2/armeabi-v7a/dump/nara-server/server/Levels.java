package com.nara.server;

import com.facebook.internal.Utility;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.regex.Pattern;

/* loaded from: /home/hatch/workspace/rea-clash-of-clans/analysis/../dump-full/classes.dex */
final class Levels {
    static final Pattern LEVEL_NAME = Pattern.compile("^[a-z0-9_]+\\.json$");
    private final Source source;

    interface Source {
        List<String> list();

        byte[] readFingerprint();

        byte[] readLevel(String str);
    }

    private Levels(Source source) {
        this.source = source;
    }

    static Levels fromSource(Source source) {
        return new Levels(source);
    }

    static Levels fromDirectory(File file) {
        if (file == null || !file.isDirectory()) {
            return null;
        }
        try {
            final File canonicalFile = file.getCanonicalFile();
            return new Levels(new Source() { // from class: com.nara.server.Levels.1
                @Override // com.nara.server.Levels.Source
                public List<String> list() {
                    String[] list = canonicalFile.list();
                    if (list == null) {
                        return Collections.emptyList();
                    }
                    ArrayList arrayList = new ArrayList(Arrays.asList(list));
                    Collections.sort(arrayList);
                    return arrayList;
                }

                @Override // com.nara.server.Levels.Source
                public byte[] readLevel(String str) {
                    if (!Levels.LEVEL_NAME.matcher(str).matches()) {
                        return null;
                    }
                    try {
                        File canonicalFile2 = new File(canonicalFile, str).getCanonicalFile();
                        if (canonicalFile.equals(canonicalFile2.getParentFile()) && canonicalFile2.isFile() && canonicalFile2.length() <= 900000) {
                            return Config.readAll(canonicalFile2);
                        }
                        return null;
                    } catch (IOException unused) {
                    }
                    return null;
                }

                @Override // com.nara.server.Levels.Source
                public byte[] readFingerprint() {
                    File parentFile = canonicalFile.getParentFile();
                    if (parentFile == null) {
                        return null;
                    }
                    File file2 = new File(parentFile, "fingerprint.json");
                    if (!file2.isFile()) {
                        return null;
                    }
                    try {
                        return Config.readAll(file2);
                    } catch (IOException unused) {
                        return null;
                    }
                }
            });
        } catch (IOException unused) {
            return null;
        }
    }

    static byte[] readBounded(InputStream inputStream, long j) throws IOException {
        try {
            ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
            byte[] bArr = new byte[Utility.DEFAULT_STREAM_BUFFER_SIZE];
            long j2 = 0;
            while (true) {
                int read = inputStream.read(bArr);
                if (read < 0) {
                    return byteArrayOutputStream.toByteArray();
                }
                j2 += read;
                if (j < 0 || j2 <= j) {
                    byteArrayOutputStream.write(bArr, 0, read);
                } else {
                    inputStream.close();
                    return null;
                }
            }
        } finally {
            inputStream.close();
        }
    }

    List<String> list() {
        return this.source.list();
    }

    byte[] readLevel(String str) {
        if (LEVEL_NAME.matcher(str).matches()) {
            return this.source.readLevel(str);
        }
        return null;
    }

    byte[] readFingerprint() {
        return this.source.readFingerprint();
    }
}
