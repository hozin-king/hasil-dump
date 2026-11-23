package com.nara.server;

import com.facebook.internal.ServerProtocol;
import com.nara.server.Builders;
import com.nara.server.Cipher;
import com.nara.server.Py;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/* loaded from: /home/hatch/workspace/rea-clash-of-clans/analysis/../dump-full/classes.dex */
final class Session {
    private double battleStartedAt;
    private long battleTick;
    private long[] ccDrop;
    private boolean combatEndedExplicitly;
    private final Config config;
    private final Socket conn;
    private Boolean headerEncrypted;
    private final Hub hub;
    private final InputStream input;
    private Long lastNpc;
    volatile boolean live;
    private final Log log;
    private boolean loggedIn;
    private Map<String, Object> match;
    private final OutputStream output;
    private final int replyVersion;
    private final String stage;
    private final String tag;
    private final Object sendLock = new Object();
    private Cipher.RC4 recvCipher = Cipher.makeCipher();
    private final Cipher.RC4 sendCipher = Cipher.makeCipher();
    private final long accountId = 1;
    private List<long[]> placements = new ArrayList();
    private List<long[]> heroesPlaced = new ArrayList();
    private List<Long> casts = new ArrayList();
    private List<Long> buildingUids = new ArrayList();
    private List<Long> trapUids = new ArrayList();
    private List<Long> decoUids = new ArrayList();
    private List<Long> obstacleUids = new ArrayList();
    private final double started = Py.now();

    static final class Reply {
        final int id;
        final byte[] payload;

        Reply(int i, byte[] bArr) {
            this.id = i;
            this.payload = bArr;
        }
    }

    private static final class Message {
        final int id;
        final byte[] payload;
        final int version;

        Message(int i, int i2, byte[] bArr) {
            this.id = i;
            this.version = i2;
            this.payload = bArr;
        }
    }

    Session(Socket socket, Log log, Config config, int i, Hub hub) throws IOException {
        this.hub = hub;
        this.conn = socket;
        socket.setSoTimeout(120000);
        this.input = socket.getInputStream();
        this.output = socket.getOutputStream();
        this.log = log;
        this.config = config;
        this.replyVersion = i;
        InetSocketAddress inetSocketAddress = (InetSocketAddress) socket.getRemoteSocketAddress();
        if (inetSocketAddress != null) {
            this.tag = inetSocketAddress.getAddress().getHostAddress() + ":" + inetSocketAddress.getPort();
        } else {
            this.tag = "unknown:0";
        }
        this.stage = config.pickStage();
    }

    private List<Reply> dispatch(int i, byte[] bArr) {
        long j = i;
        if (j == 10101) {
            return handleLogin(bArr);
        }
        if (j == 10108) {
            return handleKeepAlive();
        }
        if (j == 14134) {
            return handleAttackNpc(bArr);
        }
        if (j == 14325) {
            return handleAvatarProfile(bArr);
        }
        if (j == 14401) {
            return handleAllianceRanking();
        }
        if (j == 14403) {
            return handleAvatarRanking();
        }
        if (j == 14404) {
            return handleAvatarRankingLocal();
        }
        if (j == 14301) {
            return handleCreateAlliance(bArr);
        }
        if (j == 14302) {
            return handleAskAllianceData(bArr);
        }
        if (j == 14305) {
            return handleAskAllianceStream(bArr);
        }
        if (j == 14308) {
            return handleLeaveAlliance();
        }
        if (j == 14303) {
            return handleJoinableAlliances();
        }
        if (j == 14324) {
            return handleSearchAlliances(bArr);
        }
        if (j == 14315) {
            return handleClanChat(bArr);
        }
        if (j == 14715) {
            return handleGlobalChat(bArr);
        }
        if (j == 14113) {
            return handleVisitHome(bArr);
        }
        if (j == 14101) {
            return handleGoHome();
        }
        if (j == 14108) {
            return handleChangeHomeName(bArr);
        }
        if (j == 14102) {
            return handleEndTurn(bArr);
        }
        return null;
    }

    private void syncSessionUids() {
        this.buildingUids = this.config.buildingUids();
        this.trapUids = this.config.trapUids();
        this.decoUids = this.config.decoUids();
        this.obstacleUids = this.config.obstacleUids();
    }

    private List<Reply> handleLogin(byte[] bArr) {
        Hub hub;
        this.log.write(this.tag + " LOGIN " + Builders.describeLogin(bArr));
        this.loggedIn = true;
        if (this.config.settleTimers(null)) {
            this.config.save();
        }
        StringBuilder sb = new StringBuilder("nara");
        for (int i = 0; i < 36; i++) {
            sb.append('0');
        }
        ArrayList arrayList = new ArrayList();
        arrayList.add(new Reply(20104, Builders.buildLoginOk(1L, sb.toString())));
        if (!"login-only".equals(this.stage)) {
            boolean equals = "empty-home".equals(this.stage);
            final byte[] maybeRaid = equals ? null : maybeRaid();
            arrayList.add(new Reply(24101, Builders.buildOwnHomeData(1L, this.config, equals)));
            syncSessionUids();
            if (maybeRaid != null && (hub = this.hub) != null) {
                hub.schedule(7.0d, new Runnable() { // from class: com.nara.server.Session.1
                    @Override // java.lang.Runnable
                    public void run() {
                        Session.this.safeRun(new Runnable() { // from class: com.nara.server.Session.1.1
                            @Override // java.lang.Runnable
                            public void run() {
                                Session.this.deliverRaidReport(maybeRaid);
                            }
                        });
                    }
                });
            }
        }
        return arrayList;
    }

    private List<Reply> handleKeepAlive() {
        return Collections.singletonList(new Reply(20108, new byte[0]));
    }

    private List<Reply> handleChangeHomeName(byte[] bArr) {
        try {
            String readString = new Cipher.Reader(bArr).readString();
            if (readString == null) {
                return Collections.emptyList();
            }
            String trim = readString.trim();
            int cpLen = Py.cpLen(trim);
            if (cpLen <= 0 || cpLen > 16) {
                return Collections.emptyList();
            }
            synchronized (this.config) {
                this.config.name = trim;
                this.config.advance(11L);
                this.config.save();
            }
            this.log.write(this.tag + " RENAME name=" + this.config.name);
            return Collections.singletonList(new Reply(24111, Builders.buildChangeNameCommand(this.config.name)));
        } catch (Py.StructError unused) {
            return Collections.emptyList();
        }
    }

    private List<Reply> handleAttackNpc(byte[] bArr) {
        if (bArr.length < 4) {
            return Collections.emptyList();
        }
        long readIntBE = Cipher.readIntBE(bArr, 0);
        if (17000000 > readIntBE || readIntBE >= 17000050) {
            this.log.write(this.tag + " NPC rejected ref=" + readIntBE);
            return Collections.emptyList();
        }
        long j = readIntBE - 17000000;
        this.log.write(this.tag + " NPC attack ref=" + readIntBE);
        this.config.settleTimers(null);
        this.config.advance(Builders.tutorialBeforeAttack(j));
        this.config.save();
        this.lastNpc = Long.valueOf(j);
        this.match = null;
        this.placements = new ArrayList();
        this.heroesPlaced = new ArrayList();
        this.casts = new ArrayList();
        this.ccDrop = null;
        this.battleTick = 0L;
        this.battleStartedAt = Py.now();
        this.combatEndedExplicitly = false;
        Config config = this.config;
        return Collections.singletonList(new Reply(24133, Builders.buildNpcData(readIntBE, config, 1L, config.missions())));
    }

    private List<Reply> handleAvatarProfile(byte[] bArr) {
        return Collections.singletonList(new Reply(24334, Builders.buildAvatarProfile(bArr.length >= 8 ? new Cipher.Reader(bArr).readLong() : 1L, this.config)));
    }

    private static long resolveUid(List<Long> list, long j) {
        int fmod = (int) Py.fmod(j, 1000000L);
        if (fmod < 0 || fmod >= list.size()) {
            return -1L;
        }
        return list.get(fmod).longValue();
    }

    private long resolveBuildingIndex(long j) {
        return resolveUid(this.buildingUids, j) > 0 ? Config.findByUid(this.config.buildings, r0) : j - 500000000;
    }

    private boolean moveTarget(long j, long j2, long j3) {
        long fdiv = Py.fdiv(j, 1000000L);
        if (fdiv == 506) {
            return this.config.moveDeco(resolveUid(this.decoUids, j), j2, j3);
        }
        if (fdiv == 504) {
            return this.config.moveTrap(resolveUid(this.trapUids, j), j2, j3);
        }
        return this.config.moveBuilding(resolveBuildingIndex(j), j2, j3);
    }

    private boolean applyCommand(int i, List<Object> list, long j) {
        long j2 = i;
        if (j2 == 519) {
            long lv = Py.lv(list.get(0)) - Data.MISSIONS[0];
            return 0 <= lv && lv < ((long) Data.MISSIONS.length) && this.config.advance(lv + 1);
        }
        if (j2 == 518) {
            long lv2 = Py.lv(list.get(0));
            long lv3 = Py.lv(list.get(1));
            Builders.Command command = (Builders.Command) list.get(2);
            long lv4 = Py.lv(list.get(3));
            long resourceCode = Builders.resourceCode(lv2);
            if (resourceCode < 0 || lv3 <= 0 || !this.config.trySpend(3L, Builders.resourceGemCost(resourceCode, lv3))) {
                return false;
            }
            this.config.gain(resourceCode, lv3);
            if (command == null) {
                return true;
            }
            applyCommand(command.id, command.values, lv4);
            return true;
        }
        if (j2 == 508) {
            return this.config.train(resolveBuildingIndex(Py.lv(list.get(0))), Py.lv(list.get(2)), Py.lv(list.get(3)));
        }
        if (j2 == 509) {
            return this.config.cancelTraining(resolveBuildingIndex(Py.lv(list.get(0))), Py.lv(list.get(2)), Py.lv(list.get(3)));
        }
        if (j2 == 513) {
            return this.config.speedUpTraining(resolveBuildingIndex(Py.lv(list.get(0))));
        }
        if (j2 == 506) {
            return this.config.collect(resolveBuildingIndex(Py.lv(list.get(0))));
        }
        if (j2 == 507) {
            return this.config.clearObstacle(resolveUid(this.obstacleUids, Py.lv(list.get(0))));
        }
        if (j2 == 514) {
            return this.config.speedUpClearing(resolveUid(this.obstacleUids, Py.lv(list.get(0))));
        }
        if (j2 == 520) {
            return this.config.unlockBuilding(resolveBuildingIndex(Py.lv(list.get(0)))) != null;
        }
        if (j2 == 521) {
            long lv5 = Py.lv(list.get(0));
            Builders.Command command2 = (Builders.Command) list.get(1);
            boolean freeWorker = this.config.freeWorker();
            return command2 != null ? applyCommand(command2.id, command2.values, lv5) || freeWorker : freeWorker;
        }
        if (j2 == 516) {
            return this.config.upgradeUnit(resolveBuildingIndex(Py.lv(list.get(0))), Py.lv(list.get(2))) != null;
        }
        if (j2 == 515) {
            return this.config.cancelUpgradeUnit(resolveBuildingIndex(Py.lv(list.get(0))));
        }
        if (j2 == 517) {
            return this.config.speedUpUpgradeUnit(resolveBuildingIndex(Py.lv(list.get(0))));
        }
        if (j2 == 527) {
            return this.config.upgradeHero(resolveBuildingIndex(Py.lv(list.get(0)))) != null;
        }
        if (j2 == 528) {
            return this.config.speedUpHero(resolveBuildingIndex(Py.lv(list.get(0))));
        }
        if (j2 == 531) {
            return this.config.cancelHeroUpgrade(resolveBuildingIndex(Py.lv(list.get(0))));
        }
        if (j2 == 529) {
            return this.config.toggleHeroSleep(resolveBuildingIndex(Py.lv(list.get(0))), Boolean.TRUE.equals(list.get(1)));
        }
        if (j2 == 530) {
            return this.config.speedUpHeroHealth(resolveBuildingIndex(Py.lv(list.get(0))));
        }
        if (j2 == 512) {
            Long addDeco = this.config.addDeco(Py.lv(list.get(0)), Py.lv(list.get(1)), Py.lv(list.get(2)));
            if (addDeco == null) {
                return false;
            }
            this.decoUids.add(addDeco);
            return true;
        }
        if (j2 == 510) {
            Long addTrap = this.config.addTrap(Py.lv(list.get(0)), Py.lv(list.get(1)), Py.lv(list.get(2)));
            if (addTrap == null) {
                return false;
            }
            this.trapUids.add(addTrap);
            return true;
        }
        if (j2 == 522) {
            return this.config.buyShield(Py.lv(list.get(0)));
        }
        if (j2 == 523) {
            return this.config.claimAchievement(Py.lv(list.get(0)));
        }
        if (j2 == 500) {
            long[] addBuilding = this.config.addBuilding(Py.lv(list.get(0)), Py.lv(list.get(1)), Py.lv(list.get(2)));
            if (addBuilding == null) {
                return false;
            }
            this.buildingUids.add(Long.valueOf(addBuilding[0]));
            return true;
        }
        if (j2 == 533) {
            int lv6 = (int) Py.lv(list.get(0));
            boolean z = false;
            for (int i2 = 0; i2 < lv6; i2++) {
                int i3 = i2 * 3;
                z = moveTarget(Py.lv(list.get(i3 + 3)), Py.lv(list.get(i3 + 1)), Py.lv(list.get(i3 + 2))) || z;
            }
            return z;
        }
        if (j2 == 501) {
            return moveTarget(Py.lv(list.get(2)), Py.lv(list.get(0)), Py.lv(list.get(1)));
        }
        if (j2 == 502) {
            return this.config.upgradeBuilding(resolveBuildingIndex(Py.lv(list.get(0)))) != null;
        }
        if (j2 == 504) {
            return this.config.speedUpConstruction(resolveBuildingIndex(Py.lv(list.get(0))));
        }
        if (j2 == 505) {
            return this.config.cancelConstruction(resolveBuildingIndex(Py.lv(list.get(0))));
        }
        if (j2 == 503) {
            long lv7 = Py.lv(list.get(0));
            long fdiv = Py.fdiv(lv7, 1000000L);
            if (fdiv == 506) {
                return this.config.sellObjectByUid(fdiv, resolveUid(this.decoUids, lv7));
            }
            if (fdiv == 504) {
                return this.config.sellObjectByUid(fdiv, resolveUid(this.trapUids, lv7));
            }
            return this.config.sellObjectByUid(fdiv, resolveUid(this.buildingUids, lv7));
        }
        if (j2 == 524) {
            return this.config.toggleAttackMode(resolveBuildingIndex(Py.lv(list.get(0))));
        }
        if (j2 == 525) {
            return this.config.loadAmmo(resolveBuildingIndex(Py.lv(list.get(0))));
        }
        if (j2 == 526) {
            return this.config.boostBuilding(resolveBuildingIndex(Py.lv(list.get(0))));
        }
        return false;
    }

    private static int countSubstring(String str, String str2) {
        int i = 0;
        int i2 = 0;
        while (true) {
            int indexOf = str.indexOf(str2, i);
            if (indexOf < 0) {
                return i2;
            }
            i2++;
            i = indexOf + str2.length();
        }
    }

    private List<Reply> startMatch() {
        if (this.lastNpc != null || (this.match != null && !this.placements.isEmpty())) {
            return Collections.emptyList();
        }
        this.config.settleTimers(null);
        long j = Data.ATTACK_COST[((int) Math.min(this.config.townHallLevel(), Data.ATTACK_COST.length)) - 1];
        boolean z = this.match != null;
        this.config.spend(0L, j);
        this.match = Builders.generateEnemy(this.config, Builders.RANDOM);
        this.placements = new ArrayList();
        this.heroesPlaced = new ArrayList();
        this.casts = new ArrayList();
        this.ccDrop = null;
        this.battleTick = 0L;
        this.battleStartedAt = Py.now();
        this.combatEndedExplicitly = false;
        String str = (String) this.match.get("json");
        this.log.write(String.format(Locale.US, "%s MATCH tag=%s next=%s th=%d name=%s gold=%d elixir=%d cost=%d bytes=%d buildings=%d", this.tag, "Nara-raid-v7", Py.bool(z), Long.valueOf(Py.lv(this.match.get("level"))), this.match.get("name"), Long.valueOf(Py.lv(this.match.get("gold"))), Long.valueOf(Py.lv(this.match.get("elixir"))), Long.valueOf(j), Integer.valueOf(str.length()), Integer.valueOf(countSubstring(str, "\"lvl\""))));
        this.config.save();
        return Collections.singletonList(new Reply(24107, Builders.buildEnemyHome(this.match, this.config, 1L)));
    }

    /* JADX WARN: Code restructure failed: missing block: B:33:0x009d, code lost:
    
        if (r2 == false) goto L36;
     */
    /* JADX WARN: Code restructure failed: missing block: B:34:0x00a0, code lost:
    
        r2 = false;
     */
    /* JADX WARN: Code restructure failed: missing block: B:41:0x00c8, code lost:
    
        if (r2 == false) goto L36;
     */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    private java.util.List<com.nara.server.Session.Reply> handleEndTurn(byte[] r22) {
        /*
            Method dump skipped, instructions count: 637
            To view this dump add '--comments-level debug' option
        */
        throw new UnsupportedOperationException("Method not decompiled: com.nara.server.Session.handleEndTurn(byte[]):java.util.List");
    }

    private List<Reply> handleVisitHome(byte[] bArr) {
        if (bArr.length < 8) {
            return Collections.emptyList();
        }
        if (this.config.settleTimers(null)) {
            this.config.save();
        }
        long readLong = new Cipher.Reader(bArr).readLong();
        this.log.write(this.tag + " VISIT target=" + readLong);
        return Collections.singletonList(new Reply(24113, Builders.buildVisitedHome(readLong, this.config, 1L)));
    }

    /* JADX WARN: Type inference failed for: r1v28 */
    /* JADX WARN: Type inference failed for: r1v29, types: [java.lang.Long, long[]] */
    /* JADX WARN: Type inference failed for: r1v34 */
    private List<Reply> handleGoHome() {
        ArrayList arrayList;
        long j;
        ?? r1;
        this.log.write(this.tag + " GOHOME");
        this.config.settleTimers(null);
        ArrayList arrayList2 = new ArrayList(this.casts);
        if (!this.casts.isEmpty() && (this.lastNpc != null || this.match != null)) {
            LinkedHashMap linkedHashMap = new LinkedHashMap();
            for (Long l : this.casts) {
                linkedHashMap.put(l, Long.valueOf((linkedHashMap.containsKey(l) ? ((Long) linkedHashMap.get(l)).longValue() : 0L) + 1));
            }
            this.config.consumeSpells(linkedHashMap);
        }
        this.casts = new ArrayList();
        long fdiv = Py.fdiv(this.battleTick, 60L);
        long max = (long) Math.max(0.0d, Py.now() - this.battleStartedAt);
        if (!this.combatEndedExplicitly) {
            fdiv = Math.max(fdiv, max);
        }
        long j2 = fdiv;
        boolean z = (this.placements.isEmpty() && this.heroesPlaced.isEmpty() && this.ccDrop == null && arrayList2.isEmpty()) ? false : true;
        Long l2 = this.lastNpc;
        if (l2 != null) {
            long longValue = l2.longValue();
            if (z) {
                LinkedHashMap linkedHashMap2 = new LinkedHashMap();
                for (long[] jArr : this.placements) {
                    linkedHashMap2.put(Long.valueOf(jArr[0]), Long.valueOf((linkedHashMap2.containsKey(Long.valueOf(jArr[0])) ? ((Long) linkedHashMap2.get(Long.valueOf(jArr[0]))).longValue() : 0L) + 1));
                }
                long j3 = longValue + 17000000;
                String npcJson = Builders.npcJson(longValue, this.config);
                List<long[]> castleSlots = this.ccDrop != null ? this.config.castleSlots() : Collections.emptyList();
                arrayList = arrayList2;
                Builders.BattleOutcome simulateBattle = Builders.simulateBattle(npcJson, this.placements, this.heroesPlaced, arrayList2, this.ccDrop, castleSlots, this.config.unitLevels, this.config.spellLevels, this.config.heroLevels, j2);
                LinkedHashMap linkedHashMap3 = new LinkedHashMap();
                for (long[] jArr2 : this.config.grants(longValue)) {
                    linkedHashMap3.put(Long.valueOf(jArr2[0]), Long.valueOf(jArr2[1]));
                }
                this.config.consume(linkedHashMap2, linkedHashMap3);
                if (this.ccDrop != null && !castleSlots.isEmpty()) {
                    this.config.castleUnits.clear();
                }
                for (Map.Entry<Long, Double> entry : simulateBattle.heroDamageFraction.entrySet()) {
                    this.config.recordHeroBattleResult(entry.getKey().longValue(), entry.getValue().doubleValue());
                }
                this.config.award(j3, simulateBattle.stars);
                this.config.awardLoot(j3, simulateBattle.destruction);
                this.config.addXp(Builders.destructionXp(npcJson, simulateBattle.destruction));
                j = 0;
                if (simulateBattle.stars > 0) {
                    this.config.advance(Builders.tutorialAfterAttack(longValue));
                }
                this.log.write(String.format(Locale.US, "%s NPC result ref=%d placed=%d destruction=%.2f stars=%d", this.tag, Long.valueOf(j3), Integer.valueOf(this.placements.size()), Double.valueOf(simulateBattle.destruction), Long.valueOf(simulateBattle.stars)));
                r1 = 0;
            } else {
                arrayList = arrayList2;
                j = 0;
                r1 = 0;
            }
            this.lastNpc = r1;
            this.placements = new ArrayList();
            this.heroesPlaced = new ArrayList();
            this.ccDrop = r1;
        } else {
            arrayList = arrayList2;
            j = 0;
        }
        if (this.match != null) {
            if (z) {
                LinkedHashMap linkedHashMap4 = new LinkedHashMap();
                for (long[] jArr3 : this.placements) {
                    linkedHashMap4.put(Long.valueOf(jArr3[0]), Long.valueOf((linkedHashMap4.containsKey(Long.valueOf(jArr3[0])) ? ((Long) linkedHashMap4.get(Long.valueOf(jArr3[0]))).longValue() : j) + 1));
                }
                String str = (String) this.match.get("json");
                List<long[]> castleSlots2 = this.ccDrop != null ? this.config.castleSlots() : Collections.emptyList();
                Builders.BattleOutcome simulateBattle2 = Builders.simulateBattle(str, this.placements, this.heroesPlaced, arrayList, this.ccDrop, castleSlots2, this.config.unitLevels, this.config.spellLevels, this.config.heroLevels, j2);
                this.config.consume(linkedHashMap4, Collections.emptyMap());
                if (this.ccDrop != null && !castleSlots2.isEmpty()) {
                    this.config.castleUnits.clear();
                }
                for (Map.Entry<Long, Double> entry2 : simulateBattle2.heroDamageFraction.entrySet()) {
                    this.config.recordHeroBattleResult(entry2.getKey().longValue(), entry2.getValue().doubleValue());
                }
                Config config = this.config;
                double lv = Py.lv(this.match.get("gold"));
                double d = simulateBattle2.destruction;
                Double.isNaN(lv);
                config.gain(j, (long) (lv * d));
                Config config2 = this.config;
                double lv2 = Py.lv(this.match.get("elixir"));
                double d2 = simulateBattle2.destruction;
                Double.isNaN(lv2);
                config2.gain(1L, (long) (lv2 * d2));
                this.config.addXp(Builders.destructionXp(str, simulateBattle2.destruction));
                this.log.write(String.format(Locale.US, "%s MATCH result placed=%d destruction=%.2f stars=%d trophies=%+d total=%d", this.tag, Integer.valueOf(this.placements.size()), Double.valueOf(simulateBattle2.destruction), Long.valueOf(simulateBattle2.stars), Long.valueOf(this.config.recordBattle(simulateBattle2.stars)), Long.valueOf(this.config.trophies)));
            }
            this.match = null;
            this.placements = new ArrayList();
            this.heroesPlaced = new ArrayList();
            this.ccDrop = null;
        }
        this.config.save();
        byte[] buildOwnHomeData = Builders.buildOwnHomeData(1L, this.config, false);
        syncSessionUids();
        return Collections.singletonList(new Reply(24101, buildOwnHomeData));
    }

    private List<Reply> handleCreateAlliance(byte[] bArr) {
        Cipher.Reader reader = new Cipher.Reader(bArr);
        try {
            String readString = reader.readString();
            String readString2 = reader.readString();
            long readInt = reader.readInt();
            long readInt2 = reader.readInt();
            long readInt3 = reader.readInt();
            if (this.config.allianceBlock() != null) {
                return clanSnapshotReplies();
            }
            if (readString == null || readString2 == null || !this.config.createAlliance(readString, readString2, readInt, readInt2, readInt3)) {
                return Collections.singletonList(new Reply(24332, new Cipher.Writer().writeInt(1L).toBytes()));
            }
            this.config.save();
            this.log.write(this.tag + " CLAN created name=" + this.config.alliance.get("name"));
            return clanSnapshotReplies();
        } catch (Py.StructError unused) {
            return Collections.emptyList();
        }
    }

    void safeRun(Runnable runnable) {
        try {
            runnable.run();
        } catch (Throwable th) {
            StringWriter stringWriter = new StringWriter();
            th.printStackTrace(new PrintWriter(stringWriter));
            this.log.write(this.tag + " FATAL " + stringWriter.toString().replace("\r", "").replace("\n", " | "));
        }
    }

    void safeClanEvent(final Py.Random random) {
        safeRun(new Runnable() { // from class: com.nara.server.Session.2
            @Override // java.lang.Runnable
            public void run() {
                Session.this.clanEvent(random);
            }
        });
    }

    void safeClanSay(final Py.Random random) {
        safeRun(new Runnable() { // from class: com.nara.server.Session.3
            @Override // java.lang.Runnable
            public void run() {
                Session.this.clanSay(random);
            }
        });
    }

    private byte[] maybeRaid() {
        long[] battleStats = this.config.battleStats();
        if ((this.config.tutorial && battleStats[1] + battleStats[2] == 0) || Builders.RANDOM.random() >= 0.3d) {
            return null;
        }
        ArrayList arrayList = new ArrayList();
        for (Map<String, Object> map : Builders.roster()) {
            if (Py.lv(map.get("id")) != 50) {
                arrayList.add(map);
            }
        }
        Map map2 = (Map) Builders.RANDOM.choice(arrayList);
        long[] applyRaid = this.config.applyRaid(Builders.RANDOM);
        this.config.save();
        this.log.write(String.format(Locale.US, "%s RAID attacker=%s gold=-%d elixir=-%d trophies=-%d", this.tag, map2.get("name"), Long.valueOf(applyRaid[0]), Long.valueOf(applyRaid[1]), Long.valueOf(applyRaid[2])));
        return Builders.buildAttackReport(Builders.RANDOM.randint(Data.RAID_AGE_RANGE[0], Data.RAID_AGE_RANGE[1]), (String) map2.get("name"));
    }

    /* JADX INFO: Access modifiers changed from: private */
    public void deliverRaidReport(byte[] bArr) {
        push(24106, bArr);
    }

    private void pushEntry(Map<String, Object> map) {
        Map<String, Object> allianceBlock = this.config.allianceBlock();
        if (allianceBlock == null || map == null) {
            return;
        }
        push(24312, Builders.buildStreamEntryMessage(this.config, allianceBlock, map));
    }

    private List<Reply> clanSnapshotReplies() {
        ArrayList arrayList = new ArrayList(3);
        arrayList.add(new Reply(24303, Builders.buildJoinOk(this.config)));
        arrayList.add(new Reply(24301, Builders.buildAllianceData(this.config)));
        arrayList.add(new Reply(24311, Builders.buildStreamMessage(this.config)));
        return arrayList;
    }

    private List<Reply> handleAskAllianceData(byte[] bArr) {
        long readLong = bArr.length >= 8 ? new Cipher.Reader(bArr).readLong() : 0L;
        Map<String, Object> allianceBlock = this.config.allianceBlock();
        if (allianceBlock != null && (readLong == 0 || readLong == Py.lv(allianceBlock.get("id")))) {
            ArrayList arrayList = new ArrayList(2);
            arrayList.add(new Reply(24301, Builders.buildAllianceData(this.config)));
            arrayList.add(new Reply(24311, Builders.buildStreamMessage(this.config)));
            return arrayList;
        }
        Map<String, Object> dummyClan = Builders.dummyClan(readLong);
        if (dummyClan != null) {
            return Collections.singletonList(new Reply(24301, Builders.buildDummyAllianceData(dummyClan)));
        }
        return Collections.emptyList();
    }

    private List<Reply> handleAskAllianceStream(byte[] bArr) {
        if (bArr.length >= 8) {
            return handleJoinAlliance(bArr);
        }
        if (this.config.allianceBlock() == null) {
            return Collections.emptyList();
        }
        return Collections.singletonList(new Reply(24311, Builders.buildStreamMessage(this.config)));
    }

    private List<Reply> handleJoinAlliance(byte[] bArr) {
        long readLong = new Cipher.Reader(bArr).readLong();
        Map<String, Object> allianceBlock = this.config.allianceBlock();
        if (allianceBlock == null) {
            Map<String, Object> dummyClan = Builders.dummyClan(readLong);
            if (dummyClan == null || !this.config.joinDummyAlliance(dummyClan, Builders.RANDOM)) {
                return Collections.emptyList();
            }
            this.config.save();
            this.log.write(this.tag + " CLAN joined name=" + dummyClan.get("name"));
        } else if (Py.lv(allianceBlock.get("id")) != readLong) {
            return Collections.emptyList();
        }
        return clanSnapshotReplies();
    }

    private List<Reply> handleJoinableAlliances() {
        return Collections.singletonList(new Reply(24304, Builders.buildJoinableList()));
    }

    private List<Reply> handleSearchAlliances(byte[] bArr) {
        String str = "";
        try {
            String readString = new Cipher.Reader(bArr).readString();
            if (readString != null) {
                str = readString;
            }
        } catch (Py.StructError unused) {
        }
        return Collections.singletonList(new Reply(24310, Builders.buildSearchResult(Py.cpSlice(str, 16))));
    }

    private List<Reply> handleLeaveAlliance() {
        Map<String, Object> allianceBlock = this.config.allianceBlock();
        if (allianceBlock == null || !this.config.leaveAlliance()) {
            return Collections.emptyList();
        }
        this.config.save();
        return Collections.singletonList(new Reply(24305, new Cipher.Writer().writeLong(Py.lv(allianceBlock.get("id"))).writeInt(0L).writeInt(0L).toBytes()));
    }

    private List<Reply> handleClanChat(byte[] bArr) {
        try {
            String readString = new Cipher.Reader(bArr).readString();
            if (readString == null || this.config.allianceBlock() == null) {
                return Collections.emptyList();
            }
            String strip = Py.strip(Py.cpSlice(Py.printable(readString), 200));
            if (strip.isEmpty()) {
                return Collections.emptyList();
            }
            Map<String, Object> appendEntry = this.config.appendEntry(Py.map(ServerProtocol.DIALOG_PARAM_TYPE, 2L, "sender", 1L, "text", strip), 0.0d);
            this.config.save();
            Hub hub = this.hub;
            if (hub != null) {
                hub.clanPlayerSaid(this);
            }
            return Collections.singletonList(new Reply(24312, Builders.buildStreamEntryMessage(this.config, this.config.allianceBlock(), appendEntry)));
        } catch (Py.StructError unused) {
            return Collections.emptyList();
        }
    }

    private List<Reply> handleAllianceRanking() {
        return Collections.singletonList(new Reply(24401, Builders.buildAllianceRanking(this.config)));
    }

    private void handleTroopRequest(String str) {
        long j;
        if (this.config.allianceBlock() == null) {
            return;
        }
        long[] castleInfo = this.config.castleInfo();
        long j2 = castleInfo[0];
        long j3 = castleInfo[1];
        long j4 = castleInfo[2];
        if (j3 <= 0) {
            return;
        }
        Map<String, Object> appendEntry = this.config.appendEntry(Py.map(ServerProtocol.DIALOG_PARAM_TYPE, 1L, "sender", 1L, "castle", Py.list(Long.valueOf(j2), Long.valueOf(j3), Long.valueOf(j4)), "donors", new ArrayList(), "message", Py.strip(Py.cpSlice(Py.printable(str), 100))), 0.0d);
        pushEntry(appendEntry);
        if (this.hub != null) {
            final long lv = Py.lv(appendEntry.get("id"));
            j = j3;
            this.hub.schedule(Builders.RANDOM.uniform(1.0d, 5.0d), new Runnable() { // from class: com.nara.server.Session.4
                @Override // java.lang.Runnable
                public void run() {
                    Session.this.safeRun(new Runnable() { // from class: com.nara.server.Session.4.1
                        @Override // java.lang.Runnable
                        public void run() {
                            Session.this.fulfillRequest(lv);
                        }
                    });
                }
            });
        } else {
            j = j3;
        }
        this.log.write(String.format(Locale.US, "%s CLAN troop request castle=%d/%d", this.tag, Long.valueOf(j4), Long.valueOf(j)));
    }

    /* JADX INFO: Access modifiers changed from: private */
    /* JADX WARN: Removed duplicated region for block: B:26:0x007a  */
    /* JADX WARN: Removed duplicated region for block: B:30:0x00a5  */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    public void fulfillRequest(long r24) {
        /*
            Method dump skipped, instructions count: 387
            To view this dump add '--comments-level debug' option
        */
        throw new UnsupportedOperationException("Method not decompiled: com.nara.server.Session.fulfillRequest(long):void");
    }

    /* JADX INFO: Access modifiers changed from: private */
    public void clanSay(Py.Random random) {
        Map<String, Object> allianceBlock = this.config.allianceBlock();
        if (allianceBlock == null) {
            return;
        }
        List<Object> asList = Py.asList(allianceBlock.get("members"));
        if (asList.isEmpty()) {
            return;
        }
        pushEntry(this.config.appendEntry(Py.map(ServerProtocol.DIALOG_PARAM_TYPE, 2L, "sender", random.choice(asList), "text", random.choice(Data.CLAN_CHAT_LINES)), 0.0d));
    }

    /* JADX INFO: Access modifiers changed from: private */
    public void clanEvent(Py.Random random) {
        Map<String, Object> allianceBlock = this.config.allianceBlock();
        if (allianceBlock == null) {
            return;
        }
        List<Object> asList = Py.asList(allianceBlock.get("members"));
        double random2 = random.random();
        if (random2 < 0.55d) {
            clanSay(random);
            return;
        }
        if (random2 < 0.8d) {
            ArrayList arrayList = new ArrayList();
            Iterator<Map<String, Object>> it = Builders.roster().iterator();
            while (it.hasNext()) {
                Long l = (Long) it.next().get("id");
                if (l.longValue() != 50 && !asList.contains(l)) {
                    arrayList.add(l);
                }
            }
            if (asList.size() >= 30 || arrayList.isEmpty()) {
                return;
            }
            long longValue = ((Long) random.choice(arrayList)).longValue();
            this.config.changeMembers(Long.valueOf(longValue), null);
            byte[] buildMemberMessage = Builders.buildMemberMessage(this.config, longValue);
            if (buildMemberMessage != null) {
                push(24308, buildMemberMessage);
            }
            pushEntry(this.config.appendEntry(Py.map(ServerProtocol.DIALOG_PARAM_TYPE, 4L, "sender", Long.valueOf(longValue), "event", 3L, "target", Long.valueOf(longValue)), 0.0d));
        } else {
            Object obj = allianceBlock.get("leader");
            ArrayList arrayList2 = new ArrayList();
            Iterator<Object> it2 = asList.iterator();
            while (it2.hasNext()) {
                long lv = Py.lv(it2.next());
                if (lv != 50 && (obj == null || lv != Py.lv(obj))) {
                    arrayList2.add(Long.valueOf(lv));
                }
            }
            if (asList.size() <= 3 || arrayList2.isEmpty()) {
                return;
            }
            long longValue2 = ((Long) random.choice(arrayList2)).longValue();
            this.config.changeMembers(null, Long.valueOf(longValue2));
            push(24309, new Cipher.Writer().writeLong(longValue2).toBytes());
            pushEntry(this.config.appendEntry(Py.map(ServerProtocol.DIALOG_PARAM_TYPE, 4L, "sender", Long.valueOf(longValue2), "event", 4L, "target", Long.valueOf(longValue2)), 0.0d));
        }
        this.config.save();
    }

    private List<Reply> handleGlobalChat(byte[] bArr) {
        try {
            String readString = new Cipher.Reader(bArr).readString();
            if (readString == null) {
                return Collections.emptyList();
            }
            String strip = Py.strip(Py.cpSlice(Py.printable(readString), 200));
            if (strip.isEmpty()) {
                return Collections.emptyList();
            }
            Hub hub = this.hub;
            if (hub != null) {
                hub.playerSaid(strip);
            }
            return Collections.singletonList(new Reply(24715, Builders.buildChatLine(strip, this.config)));
        } catch (Py.StructError unused) {
            return Collections.emptyList();
        }
    }

    private List<Reply> handleAvatarRanking() {
        return Collections.singletonList(new Reply(24403, Builders.buildAvatarRanking(this.config)));
    }

    private List<Reply> handleAvatarRankingLocal() {
        return Collections.singletonList(new Reply(24404, Builders.buildAvatarRanking(this.config)));
    }

    void sendMessage(int i, byte[] bArr, boolean z) throws IOException {
        synchronized (this.sendLock) {
            byte[] process = this.sendCipher.process(bArr);
            byte[] packHeader = Cipher.packHeader(i, bArr.length, this.replyVersion);
            if (Boolean.TRUE.equals(this.headerEncrypted)) {
                packHeader = this.sendCipher.process(packHeader);
            }
            byte[] bArr2 = new byte[packHeader.length + process.length];
            System.arraycopy(packHeader, 0, bArr2, 0, packHeader.length);
            System.arraycopy(process, 0, bArr2, packHeader.length, process.length);
            this.output.write(bArr2);
            this.output.flush();
        }
        if (z) {
            this.log.write(String.format(Locale.US, "%s PUSH id=%d len=%d", this.tag, Integer.valueOf(i), Integer.valueOf(bArr.length)));
            return;
        }
        this.log.write(String.format(Locale.US, "%s SEND id=%d len=%d", this.tag, Integer.valueOf(i), Integer.valueOf(bArr.length)));
        this.log.write(this.tag + " SENDDATA " + Cipher.hexdump(bArr, 2048));
    }

    void push(int i, byte[] bArr) {
        if (this.live) {
            try {
                sendMessage(i, bArr, true);
            } catch (IOException unused) {
                this.live = false;
            } catch (RuntimeException unused2) {
                this.live = false;
            }
        }
    }

    private Message readMessage() throws IOException {
        int i;
        int i2;
        int i3;
        byte[] bArr;
        int read;
        byte[] recvExact = Cipher.recvExact(this.input, 7);
        if (recvExact == null) {
            return null;
        }
        Boolean bool = this.headerEncrypted;
        if (bool == null) {
            int[] unpackHeader = Cipher.unpackHeader(recvExact);
            i = unpackHeader[0];
            i2 = unpackHeader[1];
            i3 = unpackHeader[2];
            if (Cipher.plausible(i, i2)) {
                this.headerEncrypted = Boolean.FALSE;
            } else {
                Cipher.RC4 rc4 = new Cipher.RC4(this.recvCipher);
                int[] unpackHeader2 = Cipher.unpackHeader(rc4.process(recvExact));
                int i4 = unpackHeader2[0];
                int i5 = unpackHeader2[1];
                int i6 = unpackHeader2[2];
                if (Cipher.plausible(i4, i5)) {
                    this.headerEncrypted = Boolean.TRUE;
                    this.recvCipher = rc4;
                    i3 = i6;
                    i = i4;
                    i2 = i5;
                } else {
                    this.log.write(this.tag + " RAW unrecognised header=" + Py.hex(recvExact, recvExact.length));
                    int min = Math.min(4096, Math.max(0, this.input.available()));
                    if (min > 0 && (read = this.input.read((bArr = new byte[min]))) > 0) {
                        byte[] bArr2 = new byte[read];
                        System.arraycopy(bArr, 0, bArr2, 0, read);
                        this.log.write(this.tag + " RAW rest=" + Cipher.hexdump(bArr2));
                    }
                    return null;
                }
            }
            this.log.write(this.tag + " header_encrypted=" + Py.bool(this.headerEncrypted.booleanValue()));
        } else if (bool.booleanValue()) {
            int[] unpackHeader3 = Cipher.unpackHeader(this.recvCipher.process(recvExact));
            i = unpackHeader3[0];
            i2 = unpackHeader3[1];
            i3 = unpackHeader3[2];
        } else {
            int[] unpackHeader4 = Cipher.unpackHeader(recvExact);
            i = unpackHeader4[0];
            i2 = unpackHeader4[1];
            i3 = unpackHeader4[2];
        }
        byte[] recvExact2 = i2 > 0 ? Cipher.recvExact(this.input, i2) : new byte[0];
        if (recvExact2 == null) {
            return null;
        }
        return new Message(i, i3, i2 > 0 ? this.recvCipher.process(recvExact2) : new byte[0]);
    }

    void run() {
        Log log;
        String format;
        this.log.write(this.tag + " CONNECT stage=" + this.stage);
        Hub hub = this.hub;
        if (hub != null) {
            hub.attach(this);
        }
        while (true) {
            try {
                try {
                    try {
                        try {
                            Message readMessage = readMessage();
                            if (readMessage == null) {
                                break;
                            }
                            this.log.write(String.format(Locale.US, "%s RECV id=%d ver=%d len=%d", this.tag, Integer.valueOf(readMessage.id), Integer.valueOf(readMessage.version), Integer.valueOf(readMessage.payload.length)));
                            this.log.write(this.tag + " DATA " + Cipher.hexdump(readMessage.payload));
                            List<Reply> dispatch = dispatch(readMessage.id, readMessage.payload);
                            if (dispatch != null) {
                                for (Reply reply : dispatch) {
                                    sendMessage(reply.id, reply.payload, false);
                                }
                                if (readMessage.id == 10101 && this.hub != null && !this.live) {
                                    this.live = true;
                                    this.hub.greet();
                                }
                            }
                        } catch (Throwable th) {
                            this.live = false;
                            if (this.loggedIn) {
                                this.config.settleTimers(null);
                                this.config.save();
                            }
                            Hub hub2 = this.hub;
                            if (hub2 != null) {
                                hub2.detach(this);
                            }
                            try {
                                this.conn.close();
                            } catch (IOException unused) {
                            }
                            this.log.write(String.format(Locale.US, "%s DISCONNECT stage=%s after=%.2fs", this.tag, this.stage, Double.valueOf(Py.now() - this.started)));
                            throw th;
                        }
                    } catch (IOException e) {
                        this.log.write(this.tag + " ERROR " + e.getMessage());
                        this.live = false;
                        if (this.loggedIn) {
                            this.config.settleTimers(null);
                            this.config.save();
                        }
                        Hub hub3 = this.hub;
                        if (hub3 != null) {
                            hub3.detach(this);
                        }
                        try {
                            this.conn.close();
                        } catch (IOException unused2) {
                        }
                        log = this.log;
                        format = String.format(Locale.US, "%s DISCONNECT stage=%s after=%.2fs", this.tag, this.stage, Double.valueOf(Py.now() - this.started));
                    }
                } catch (Throwable th2) {
                    StringWriter stringWriter = new StringWriter();
                    th2.printStackTrace(new PrintWriter(stringWriter));
                    this.log.write(this.tag + " FATAL " + stringWriter.toString().replace("\r", "").replace("\n", " | "));
                    this.live = false;
                    if (this.loggedIn) {
                        this.config.settleTimers(null);
                        this.config.save();
                    }
                    Hub hub4 = this.hub;
                    if (hub4 != null) {
                        hub4.detach(this);
                    }
                    try {
                        this.conn.close();
                    } catch (IOException unused3) {
                    }
                    log = this.log;
                    format = String.format(Locale.US, "%s DISCONNECT stage=%s after=%.2fs", this.tag, this.stage, Double.valueOf(Py.now() - this.started));
                }
            } catch (Py.StructError e2) {
                this.log.write(this.tag + " ERROR " + e2.getMessage());
                this.live = false;
                if (this.loggedIn) {
                    this.config.settleTimers(null);
                    this.config.save();
                }
                Hub hub5 = this.hub;
                if (hub5 != null) {
                    hub5.detach(this);
                }
                try {
                    this.conn.close();
                } catch (IOException unused4) {
                }
                log = this.log;
                format = String.format(Locale.US, "%s DISCONNECT stage=%s after=%.2fs", this.tag, this.stage, Double.valueOf(Py.now() - this.started));
            } catch (Py.ValueError e3) {
                this.log.write(this.tag + " ERROR " + e3.getMessage());
                this.live = false;
                if (this.loggedIn) {
                    this.config.settleTimers(null);
                    this.config.save();
                }
                Hub hub6 = this.hub;
                if (hub6 != null) {
                    hub6.detach(this);
                }
                try {
                    this.conn.close();
                } catch (IOException unused5) {
                }
                log = this.log;
                format = String.format(Locale.US, "%s DISCONNECT stage=%s after=%.2fs", this.tag, this.stage, Double.valueOf(Py.now() - this.started));
            }
        }
        this.live = false;
        if (this.loggedIn) {
            this.config.settleTimers(null);
            this.config.save();
        }
        Hub hub7 = this.hub;
        if (hub7 != null) {
            hub7.detach(this);
        }
        try {
            this.conn.close();
        } catch (IOException unused6) {
        }
        log = this.log;
        format = String.format(Locale.US, "%s DISCONNECT stage=%s after=%.2fs", this.tag, this.stage, Double.valueOf(Py.now() - this.started));
        log.write(format);
    }
}
