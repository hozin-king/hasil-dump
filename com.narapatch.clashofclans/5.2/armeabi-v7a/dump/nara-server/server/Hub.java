package com.nara.server;

import com.nara.server.Py;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;

/* loaded from: /home/hatch/workspace/rea-clash-of-clans/analysis/../dump-full/classes.dex */
final class Hub {
    private final Log log;
    private final Set<Session> sessions = new LinkedHashSet();
    private final Object lock = new Object();
    private final Py.Random rng = new Py.Random();
    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(2, new ThreadFactory() { // from class: com.nara.server.Hub.1
        @Override // java.util.concurrent.ThreadFactory
        public Thread newThread(Runnable runnable) {
            Thread thread = new Thread(runnable, "NaraHubTimer");
            thread.setDaemon(true);
            return thread;
        }
    });

    Hub(Log log) {
        this.log = log;
    }

    void attach(Session session) {
        synchronized (this.lock) {
            this.sessions.add(session);
        }
    }

    void detach(Session session) {
        synchronized (this.lock) {
            this.sessions.remove(session);
        }
    }

    List<Session> audience() {
        ArrayList arrayList;
        synchronized (this.lock) {
            arrayList = new ArrayList();
            for (Session session : this.sessions) {
                if (session.live) {
                    arrayList.add(session);
                }
            }
        }
        return arrayList;
    }

    void schedule(double d, Runnable runnable) {
        this.scheduler.schedule(runnable, Math.max(0L, (long) (d * 1000.0d)), TimeUnit.MILLISECONDS);
    }

    void say(Map<String, Object> map, String str) {
        byte[] buildBotChatLine = Builders.buildBotChatLine(Py.cpSlice(str, 200), map);
        Iterator<Session> it = audience().iterator();
        while (it.hasNext()) {
            it.next().push(24715, buildBotChatLine);
        }
    }

    private Object[] pickMessage() {
        Map map = (Map) this.rng.choice(Builders.roster());
        return (!Py.truthy(map.get("promo")) || this.rng.random() >= 0.35d) ? new Object[]{map, this.rng.choice(Data.CHAT_LINES)} : new Object[]{map, this.rng.choice(Data.PROMO_LINES)};
    }

    void later(double d, final Map<String, Object> map, final String str) {
        schedule(d, new Runnable() { // from class: com.nara.server.Hub.2
            @Override // java.lang.Runnable
            public void run() {
                try {
                    Hub.this.say(map, str);
                } catch (Throwable unused) {
                }
            }
        });
    }

    void greet() {
        double[] dArr = {this.rng.uniform(2.0d, 4.0d), this.rng.uniform(5.0d, 9.0d)};
        for (int i = 0; i < 2; i++) {
            double d = dArr[i];
            Object[] pickMessage = pickMessage();
            later(d, (Map) pickMessage[0], (String) pickMessage[1]);
        }
    }

    void playerSaid(String str) {
        if (this.rng.random() < 0.4d) {
            later(this.rng.uniform(2.0d, 6.0d), (Map) this.rng.choice(Builders.roster()), this.rng.choice(Data.REPLY_LINES));
        }
    }

    void clanRun() {
        while (true) {
            try {
                Thread.sleep((long) (this.rng.uniform(20.0d, 55.0d) * 1000.0d));
                Iterator<Session> it = audience().iterator();
                while (it.hasNext()) {
                    it.next().safeClanEvent(this.rng);
                }
            } catch (InterruptedException unused) {
                Thread.currentThread().interrupt();
                return;
            } catch (Throwable unused2) {
            }
        }
    }

    void clanPlayerSaid(final Session session) {
        if (this.rng.random() < 0.5d) {
            schedule(this.rng.uniform(2.0d, 6.0d), new Runnable() { // from class: com.nara.server.Hub.3
                @Override // java.lang.Runnable
                public void run() {
                    session.safeClanSay(Hub.this.rng);
                }
            });
        }
    }

    void run() {
        while (true) {
            try {
                Thread.sleep((long) (this.rng.uniform(6.0d, 18.0d) * 1000.0d));
                if (!audience().isEmpty()) {
                    Object[] pickMessage = pickMessage();
                    say((Map) pickMessage[0], (String) pickMessage[1]);
                }
            } catch (InterruptedException unused) {
                Thread.currentThread().interrupt();
                return;
            } catch (Throwable unused2) {
            }
        }
    }
}
