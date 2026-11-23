package com.nara.server;

import android.content.Context;
import android.content.res.AssetManager;
import com.nara.server.Levels;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

/* loaded from: /home/hatch/workspace/rea-clash-of-clans/analysis/../dump-full/classes.dex */
public final class AndroidServer {
    private static final CountDownLatch READY = new CountDownLatch(1);
    private static boolean started;

    private AndroidServer() {
    }

    public static void start(final Context context) {
        if (context == null) {
            return;
        }
        if (context.getApplicationContext() != null) {
            context = context.getApplicationContext();
        }
        synchronized (AndroidServer.class) {
            if (!started) {
                started = true;
                Thread thread = new Thread(new Runnable() { // from class: com.nara.server.AndroidServer.1
                    @Override // java.lang.Runnable
                    public void run() {
                        try {
                            final AssetManager assets = context.getAssets();
                            Levels fromSource = Levels.fromSource(new Levels.Source() { // from class: com.nara.server.AndroidServer.1.1
                                @Override // com.nara.server.Levels.Source
                                public List<String> list() {
                                    try {
                                        String[] list = assets.list("level");
                                        if (list == null) {
                                            return Collections.emptyList();
                                        }
                                        ArrayList arrayList = new ArrayList(Arrays.asList(list));
                                        Collections.sort(arrayList);
                                        return arrayList;
                                    } catch (IOException unused) {
                                        return Collections.emptyList();
                                    }
                                }

                                @Override // com.nara.server.Levels.Source
                                public byte[] readLevel(String str) {
                                    if (!Levels.LEVEL_NAME.matcher(str).matches()) {
                                        return null;
                                    }
                                    try {
                                        return Levels.readBounded(assets.open("level/" + str), 900000L);
                                    } catch (IOException unused) {
                                        return null;
                                    }
                                }

                                @Override // com.nara.server.Levels.Source
                                public byte[] readFingerprint() {
                                    try {
                                        return Levels.readBounded(assets.open("fingerprint.json"), 1800000L);
                                    } catch (IOException unused) {
                                        return null;
                                    }
                                }
                            });
                            File filesDir = context.getFilesDir();
                            File file = new File(filesDir, "nara_state.json");
                            File resolveLogFile = AndroidServer.resolveLogFile(context, filesDir);
                            Config config = new Config(1000L, 1000L, 500L, "Nara", "full", true, fromSource, file);
                            config.loadState();
                            android.util.Log.i("NaraServer", "Starting embedded server state=" + file.getAbsolutePath() + " log=" + resolveLogFile.getAbsolutePath());
                            Server.serve("127.0.0.1", 9339, resolveLogFile, config, 0, AndroidServer.READY);
                        } finally {
                            try {
                            } finally {
                            }
                        }
                    }
                }, "NaraServerAccept");
                thread.setDaemon(true);
                thread.start();
            }
        }
        try {
            READY.await(3L, TimeUnit.SECONDS);
        } catch (InterruptedException unused) {
            Thread.currentThread().interrupt();
        }
    }

    static File resolveLogFile(Context context, File file) {
        File file2 = new File(file, "nara_server.log");
        try {
            File externalFilesDir = context.getExternalFilesDir(null);
            if (externalFilesDir != null && (externalFilesDir.isDirectory() || externalFilesDir.mkdirs())) {
                File file3 = new File(externalFilesDir, "nara_server.log");
                new FileOutputStream(file3, true).close();
                return file3;
            }
        } catch (Throwable unused) {
        }
        return file2;
    }
}
