package com.nara.server;

import java.io.File;
import java.io.IOException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Semaphore;

/* loaded from: /home/hatch/workspace/rea-clash-of-clans/analysis/../dump-full/classes.dex */
final class Server {
    private Server() {
    }

    static void serve(String str, int i, File file, Config config, int i2, CountDownLatch countDownLatch) throws IOException {
        Log log = new Log(file);
        final Semaphore semaphore = new Semaphore(8);
        ServerSocket serverSocket = new ServerSocket();
        serverSocket.setReuseAddress(true);
        serverSocket.bind(new InetSocketAddress(InetAddress.getByName(str), i), 8);
        if (countDownLatch != null) {
            countDownLatch.countDown();
        }
        log.write("nara coc server listening on " + str + ":" + i + " tutorial=" + Py.bool(config.tutorial));
        Builders.verifyLevels(config, log);
        final Hub hub = new Hub(log);
        Thread thread = new Thread(new Runnable() { // from class: com.nara.server.Server.1
            @Override // java.lang.Runnable
            public void run() {
                Hub.this.run();
            }
        }, "NaraHubChat");
        thread.setDaemon(true);
        thread.start();
        Thread thread2 = new Thread(new Runnable() { // from class: com.nara.server.Server.2
            @Override // java.lang.Runnable
            public void run() {
                Hub.this.clanRun();
            }
        }, "NaraHubClan");
        thread2.setDaemon(true);
        thread2.start();
        while (true) {
            Socket accept = serverSocket.accept();
            if (!semaphore.tryAcquire()) {
                try {
                    accept.close();
                } catch (IOException unused) {
                }
            } else {
                try {
                    final Session session = new Session(accept, log, config, i2, hub);
                    Thread thread3 = new Thread(new Runnable() { // from class: com.nara.server.Server.3
                        @Override // java.lang.Runnable
                        public void run() {
                            try {
                                Session.this.run();
                            } finally {
                                semaphore.release();
                            }
                        }
                    }, "NaraSession");
                    thread3.setDaemon(true);
                    thread3.start();
                } catch (IOException unused2) {
                    semaphore.release();
                    accept.close();
                }
            }
        }
    }

    public static void main(String[] strArr) throws Exception {
        Levels fromDirectory;
        int i;
        String str = "nara_coc_capture.log";
        int i2 = 0;
        String str2 = null;
        String str3 = "127.0.0.1";
        long j = 1000;
        long j2 = 1000;
        long j3 = 500;
        String str4 = "Nara";
        String str5 = null;
        String str6 = "full";
        boolean z = false;
        boolean z2 = false;
        int i3 = 9339;
        int i4 = 0;
        long j4 = 0;
        long j5 = 0;
        while (i2 < strArr.length) {
            String str7 = strArr[i2];
            if ("--host".equals(str7) && (i = i2 + 1) < strArr.length) {
                str3 = strArr[i];
            } else if ("--port".equals(str7) && (i = i2 + 1) < strArr.length) {
                i3 = Integer.parseInt(strArr[i]);
            } else if ("--log".equals(str7) && (i = i2 + 1) < strArr.length) {
                str = strArr[i];
            } else if ("--reply-version".equals(str7) && (i = i2 + 1) < strArr.length) {
                i4 = Integer.parseInt(strArr[i]);
            } else if ("--gold".equals(str7) && (i = i2 + 1) < strArr.length) {
                j = Long.parseLong(strArr[i]);
            } else if ("--elixir".equals(str7) && (i = i2 + 1) < strArr.length) {
                j2 = Long.parseLong(strArr[i]);
            } else if ("--gems".equals(str7) && (i = i2 + 1) < strArr.length) {
                j3 = Long.parseLong(strArr[i]);
            } else if ("--name".equals(str7) && (i = i2 + 1) < strArr.length) {
                str4 = strArr[i];
            } else {
                if ("--no-tutorial".equals(str7)) {
                    z = true;
                } else if ("--resources".equals(str7) && (i = i2 + 1) < strArr.length) {
                    j4 = Long.parseLong(strArr[i]);
                } else if ("--match-th".equals(str7) && (i = i2 + 1) < strArr.length) {
                    j5 = Long.parseLong(strArr[i]);
                } else if ("--level-dir".equals(str7) && (i = i2 + 1) < strArr.length) {
                    str2 = strArr[i];
                } else if ("--state".equals(str7) && (i = i2 + 1) < strArr.length) {
                    str5 = strArr[i];
                } else if ("--fresh".equals(str7)) {
                    z2 = true;
                } else if ("--stage".equals(str7) && (i = i2 + 1) < strArr.length) {
                    str6 = strArr[i];
                }
                i2++;
            }
            i2 = i;
            i2++;
        }
        if (str2 != null) {
            fromDirectory = Levels.fromDirectory(new File(str2));
        } else {
            fromDirectory = Levels.fromDirectory(new File("level"));
        }
        Levels levels = fromDirectory;
        if (str5 == null) {
            str5 = "nara_state.json";
        }
        Config config = new Config(j, j2, j3, str4, str6, !z, levels, new File(str5));
        if (!z2) {
            config.loadState();
        }
        config.matchLevel = Math.max(0L, j5);
        if (j4 > 0) {
            config.setResources(Math.min(j4, 1000000000L));
        }
        serve(str3, i3, new File(str), config, i4, null);
    }
}
