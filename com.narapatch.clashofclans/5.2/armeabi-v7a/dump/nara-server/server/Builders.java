package com.nara.server;

import com.facebook.internal.ServerProtocol;
import com.nara.server.Cipher;
import com.nara.server.Py;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;

/* loaded from: /home/hatch/workspace/rea-clash-of-clans/analysis/../dump-full/classes.dex */
final class Builders {
    static final Py.Random RANDOM = new Py.Random();
    private static final List<Map<String, Object>> ROSTER_CACHE = new ArrayList();
    private static final List<Map<String, Object>> DUMMY_CLAN_CACHE = new ArrayList();
    private static final long[][] PRODUCER_2 = {new long[]{1}, new long[]{200, 400, 600, 800, 1000, 1300, 1600, 1900, 2200, 2500, 3000}, new long[]{500, 1000, 1500, 2500, 10000, 20000, 30000, 50000, 75000, 100000, 150000}};
    private static final long[][] PRODUCER_4 = {new long[]{0}, new long[]{200, 400, 600, 800, 1000, 1300, 1600, 1900, 2200, 2500, 3000}, new long[]{500, 1000, 1500, 2500, 10000, 20000, 30000, 50000, 75000, 100000, 150000}};
    private static final long[][] PRODUCER_23 = {new long[]{2}, new long[]{20, 30, 45, 60, 80, 100}, new long[]{120, 240, 450, 720, 1120, 1600}};
    private static final String[] DUMMY_CLAN_NAMES = {"Nara Revive", "Indo Warriors", "Dragon Slayers", "Night Owls", "Golden Hawks", "Storm Riders", "Iron Legion", "Phoenix Rising"};
    private static final long[] DUMMY_CLAN_BADGES = {0, 3, 7, 11, 15, 19, 23, 27};

    static int commandSize(int i) {
        if (i == 519 || i == 520) {
            return 2;
        }
        if (i == 536) {
            return 3;
        }
        if (i == 541 || i == 544) {
            return 1;
        }
        if (i == 700) {
            return 3;
        }
        if (i == 538 || i == 539) {
            return 2;
        }
        switch (i) {
            case 500:
            case 501:
            case 510:
                return 4;
            case 502:
            case 503:
            case 504:
            case 505:
            case 506:
            case 507:
                return 2;
            case 508:
            case 509:
                return 5;
            default:
                switch (i) {
                    case 512:
                    case 516:
                        return 4;
                    case 513:
                    case 514:
                    case 515:
                    case 517:
                        return 2;
                    default:
                        switch (i) {
                            case 522:
                            case 523:
                            case 524:
                            case 525:
                            case 526:
                            case 527:
                            case 528:
                                return 2;
                            default:
                                switch (i) {
                                    case 530:
                                    case 531:
                                        return 2;
                                    case 532:
                                        return 4;
                                    default:
                                        switch (i) {
                                            case 600:
                                            case 601:
                                            case 604:
                                            case 605:
                                                return 4;
                                            case 602:
                                            case 603:
                                                return 1;
                                            default:
                                                return -1;
                                        }
                                }
                        }
                }
        }
    }

    private static double defenseRange(int i, boolean z) {
        if (i == 8) {
            return 9.0d;
        }
        if (i == 9 || i == 12 || i == 27) {
            return 10.0d;
        }
        if (i == 11 || i == 19) {
            return 7.0d;
        }
        if (i == 13) {
            return 11.0d;
        }
        if (i == 21) {
            return z ? 11.0d : 14.0d;
        }
        return 0.0d;
    }

    static long resourceCode(long j) {
        if (j == 3000001) {
            return 0L;
        }
        if (j == 3000002) {
            return 1L;
        }
        return j == 3000003 ? 2L : -1L;
    }

    private static double unitRange(int i) {
        if (i == 1 || i == 6 || i == 15) {
            return 3.2d;
        }
        if (i == 7) {
            return 5.0d;
        }
        return (i == 8 || i == 10) ? 2.8d : 1.0d;
    }

    private static double unitSpeed(int i) {
        if (i == 2 || i == 10 || i == 11) {
            return 3.0d;
        }
        return (i == 0 || i == 1 || i == 4 || i == 6 || i == 15 || i == 16) ? 2.2d : 1.6d;
    }

    private Builders() {
    }

    static final class Command {
        final int id;
        final List<Object> values;

        Command(int i, List<Object> list) {
            this.id = i;
            this.values = list;
        }
    }

    static final class ParsedCommand {
        final Command command;
        final int nextPos;

        ParsedCommand(Command command, int i) {
            this.command = command;
            this.nextPos = i;
        }
    }

    static final class AvatarOptions {
        List<Long> achievements;
        Map<String, Object> allianceOverride;
        long[] balance;
        long[] experience;
        boolean hasAllianceOverride;
        Map<Long, Long> heroes;
        List<long[]>[] loot;
        List<long[]> progress;
        List<long[]> spellLevels;
        List<long[]> stars;
        long[] stats;
        Long townHall;
        List<long[]> unitLevels;
        List<long[]> units;

        AvatarOptions() {
        }
    }

    static long[][] producer(long j) {
        if (j == 2) {
            return PRODUCER_2;
        }
        if (j == 4) {
            return PRODUCER_4;
        }
        if (j == 23) {
            return PRODUCER_23;
        }
        return null;
    }

    static long tutorialBeforeAttack(long j) {
        if (j == 0) {
            return 2L;
        }
        if (j == 1) {
            return 9L;
        }
        return Data.MISSIONS.length;
    }

    static long tutorialAfterAttack(long j) {
        if (j == 0) {
            return 3L;
        }
        if (j == 1) {
            return 10L;
        }
        return Data.MISSIONS.length;
    }

    static boolean isDefenseId(long j) {
        for (long j2 : Data.DEFENSE_IDS) {
            if (j2 == j) {
                return true;
            }
        }
        return false;
    }

    static boolean isProducerId(long j) {
        for (long j2 : Data.PRODUCER_IDS) {
            if (j2 == j) {
                return true;
            }
        }
        return false;
    }

    static long buildingDataByName(String str) {
        if ("town_hall".equals(str)) {
            return 1000001L;
        }
        if ("elixir_pump".equals(str)) {
            return 1000002L;
        }
        if ("elixir_storage".equals(str)) {
            return 1000003L;
        }
        if ("gold_mine".equals(str)) {
            return 1000004L;
        }
        if ("gold_storage".equals(str)) {
            return 1000005L;
        }
        if ("barrack".equals(str)) {
            return 1000006L;
        }
        if ("cannon".equals(str)) {
            return 1000008L;
        }
        if ("troop_housing".equals(str)) {
            return 1000000L;
        }
        return "worker".equals(str) ? 1000015L : 0L;
    }

    static long sectionBase(String str) {
        if ("buildings".equals(str)) {
            return 1000000L;
        }
        if ("obstacles".equals(str)) {
            return 8000000L;
        }
        if ("traps".equals(str)) {
            return 12000000L;
        }
        return "decos".equals(str) ? 18000000L : 0L;
    }

    static long speedCost(long j) {
        if (j <= 0) {
            return 0L;
        }
        long j2 = Data.SPEED_POINTS[0];
        long j3 = Data.SPEED_POINTS[1];
        long j4 = Data.SPEED_POINTS[2];
        long j5 = Data.SPEED_POINTS[3];
        if (j < 60) {
            return Math.max(1L, Py.fdiv(j * j2, 60L));
        }
        if (j <= 3600) {
            return j2 + Py.fdiv((j - 60) * (j3 - j2), 3540L);
        }
        if (j <= 86400) {
            return j3 + Py.fdiv((j - 3600) * (j4 - j3), 82800L);
        }
        return j4 + Py.fdiv((j - 86400) * (j5 - j4), 518400L);
    }

    static long resourceGemCost(long j) {
        return resourceGemCost(0L, j);
    }

    static long resourceGemCost(long j, long j2) {
        if (j2 <= 0) {
            return 0L;
        }
        long[][] jArr = j == 2 ? Data.DARK_GEM_POINTS : Data.RESOURCE_GEM_POINTS;
        long[] jArr2 = jArr[0];
        long j3 = jArr2[0];
        if (j2 <= j3) {
            return Math.max(1L, Py.fdiv(jArr2[1] * j2, j3));
        }
        int i = 0;
        while (i < jArr.length - 1) {
            long[] jArr3 = jArr[i];
            long j4 = jArr3[0];
            long j5 = jArr3[1];
            i++;
            long[] jArr4 = jArr[i];
            long j6 = jArr4[0];
            long j7 = jArr4[1];
            if (j2 <= j6) {
                return j5 + Py.fdiv((j2 - j4) * (j7 - j5), j6 - j4);
            }
        }
        long[] jArr5 = jArr[jArr.length - 1];
        return Py.fdiv(jArr5[1] * j2, jArr5[0]);
    }

    static final class BattleOutcome {
        final double destruction;
        final Map<Long, Double> heroDamageFraction;
        final long stars;

        BattleOutcome(double d, long j, Map<Long, Double> map) {
            this.destruction = d;
            this.stars = j;
            this.heroDamageFraction = map;
        }
    }

    private static final class SimBuilding {
        final double cx;
        final double cy;
        final double dps;
        double freezeLeft;
        double hp;
        final long index;
        final boolean isDefense;
        final boolean isResource;
        final boolean isTownHall;
        final double maxHp;
        final double range;
        final boolean targetAir;
        final boolean targetGround;

        SimBuilding(long j, double d, double d2, double d3, double d4, boolean z, boolean z2, double d5, boolean z3, boolean z4, boolean z5) {
            this.index = j;
            this.cx = d;
            this.cy = d2;
            this.hp = d3;
            this.maxHp = d3;
            this.dps = d4;
            this.targetAir = z;
            this.targetGround = z2;
            this.range = d5;
            this.isDefense = z3;
            this.isResource = z4;
            this.isTownHall = z5;
        }
    }

    private static final class SimAttacker {
        final double attackRange;
        final double deploySec;
        final double dps;
        final boolean flying;
        final long heroRef;
        double hp;
        final boolean isHealer;
        final double maxHp;
        final long prefKind;
        final double prefMod;
        double readyAt;
        final double speed;
        SimBuilding target;
        double x;
        double y;

        SimAttacker(long j, double d, double d2, double d3, double d4, double d5, double d6, double d7, boolean z, boolean z2, long j2, double d8) {
            this.heroRef = j;
            this.deploySec = d;
            this.x = d2;
            this.y = d3;
            this.hp = d4;
            this.maxHp = d4;
            this.dps = d5;
            this.speed = d6;
            this.attackRange = d7;
            this.flying = z;
            this.isHealer = z2;
            this.prefKind = j2;
            this.prefMod = d8;
            this.readyAt = d;
        }
    }

    private static double toTileCoord(long j, double d) {
        if (j == 0) {
            return d;
        }
        long abs = Math.abs(j);
        double d2 = j;
        if (abs <= 100) {
            return d2;
        }
        Double.isNaN(d2);
        return d2 / 512.0d;
    }

    private static SimBuilding pickTarget(SimAttacker simAttacker, List<SimBuilding> list) {
        SimBuilding simBuilding = null;
        double d = Double.MAX_VALUE;
        SimBuilding simBuilding2 = null;
        double d2 = Double.MAX_VALUE;
        for (SimBuilding simBuilding3 : list) {
            if (simBuilding3.hp > 0.0d) {
                double hypot = Math.hypot(simBuilding3.cx - simAttacker.x, simBuilding3.cy - simAttacker.y);
                if (hypot < d2) {
                    simBuilding2 = simBuilding3;
                    d2 = hypot;
                }
                if ((simAttacker.prefKind == 1 && simBuilding3.isDefense) || (simAttacker.prefKind == 2 && simBuilding3.isResource)) {
                    if (hypot < d) {
                        simBuilding = simBuilding3;
                        d = hypot;
                    }
                }
            }
        }
        return simBuilding != null ? simBuilding : simBuilding2;
    }

    static double estimateDestruction(String str, List<long[]> list, long j) {
        return simulateBattle(str, list, Collections.emptyList(), Collections.emptyList(), null, Collections.emptyList(), Collections.emptyMap(), Collections.emptyMap(), Collections.emptyMap(), j).destruction;
    }

    static BattleOutcome simulateBattle(String str, List<long[]> list, List<long[]> list2, List<Long> list3, long[] jArr, List<long[]> list4, Map<Long, Long> map, Map<Long, Long> map2, Map<Long, Long> map3, long j) {
        double d;
        double d2;
        double d3;
        double d4;
        double d5;
        double d6;
        double d7;
        boolean z;
        double d8;
        double d9;
        Iterator it;
        double d10;
        Iterator it2;
        double d11;
        double d12;
        Iterator it3;
        Iterator<Long> it4;
        double d13;
        ArrayList arrayList;
        double d14;
        double d15;
        char c;
        long j2;
        double d16;
        double d17;
        double d18;
        long j3;
        boolean z2;
        Map<String, Object> asMap = Py.asMap(Py.loads(str));
        ArrayList arrayList2 = new ArrayList();
        Iterator<Object> it5 = Py.asList(asMap.get("buildings")).iterator();
        long j4 = 0;
        long j5 = 0;
        while (it5.hasNext()) {
            Map<String, Object> asMap2 = Py.asMap(it5.next());
            long lvl = Config.lvl(asMap2);
            long data = Config.data(asMap2) - 1000000;
            if (lvl >= j4 && data != 10 && j4 <= data && data < Data.BUILDING_HP.length) {
                double levelValue = Config.levelValue(Data.BUILDING_HP, data, lvl);
                if (levelValue > 0.0d) {
                    Iterator<Object> it6 = it5;
                    int i = (int) data;
                    double d19 = Data.BUILDING_W[i];
                    double d20 = Data.BUILDING_H[i];
                    long j6 = j5;
                    ArrayList arrayList3 = arrayList2;
                    double d21 = Py.getLong(asMap2, "x", 22L);
                    Double.isNaN(d19);
                    Double.isNaN(d21);
                    double d22 = d21 + (d19 * 0.5d);
                    double d23 = Py.getLong(asMap2, "y", 22L);
                    Double.isNaN(d20);
                    Double.isNaN(d23);
                    double d24 = d23 + (d20 * 0.5d);
                    double levelValue2 = Config.levelValue(Data.BUILDING_DPS, data, lvl);
                    boolean z3 = Data.BUILDING_ALT_MODE[i] && Py.truthy(asMap2.get("attack_mode"));
                    boolean z4 = z3 ? Data.BUILDING_ALT_AIR[i] : Data.BUILDING_TARGET_AIR[i];
                    boolean z5 = z3 ? Data.BUILDING_ALT_GROUND[i] : Data.BUILDING_TARGET_GROUND[i];
                    if (data == 21 || data == 27) {
                        Object obj = asMap2.get("ammo");
                        if (Py.isInt(obj) && Py.lv(obj) == 0) {
                            d18 = 0.0d;
                            boolean z6 = !isDefenseId(Config.data(asMap2)) && d18 > 0.0d;
                            if (!isProducerId(Config.data(asMap2)) || data == 1 || data == 3 || data == 5 || data == 24) {
                                j3 = 1;
                                z2 = true;
                            } else {
                                j3 = 1;
                                z2 = false;
                            }
                            arrayList3.add(new SimBuilding(data, d22, d24, levelValue, d18, z4, z5, defenseRange(i, z3), z6, z2, data != j3 || data == 17));
                            j5 = j6 + ((long) levelValue);
                            arrayList2 = arrayList3;
                            it5 = it6;
                            j4 = 0;
                        }
                    }
                    d18 = levelValue2;
                    if (isDefenseId(Config.data(asMap2))) {
                    }
                    if (isProducerId(Config.data(asMap2))) {
                    }
                    j3 = 1;
                    z2 = true;
                    arrayList3.add(new SimBuilding(data, d22, d24, levelValue, d18, z4, z5, defenseRange(i, z3), z6, z2, data != j3 || data == 17));
                    j5 = j6 + ((long) levelValue);
                    arrayList2 = arrayList3;
                    it5 = it6;
                    j4 = 0;
                }
            }
            arrayList2 = arrayList2;
            it5 = it5;
            j5 = j5;
            j4 = 0;
        }
        ArrayList<SimBuilding> arrayList4 = arrayList2;
        long j7 = j5;
        if (j7 <= j4) {
            return new BattleOutcome(0.0d, 0L, Collections.emptyMap());
        }
        ArrayList<SimAttacker> arrayList5 = new ArrayList();
        long j8 = 4000016;
        long j9 = 4000000;
        char c2 = 2;
        int i2 = 4;
        double d25 = 14.0d;
        if (list != null) {
            for (long[] jArr2 : list) {
                long j10 = jArr2[0];
                if (j9 <= j10 && j10 <= j8) {
                    int i3 = (int) (j10 - j9);
                    long longValue = (map == null || !map.containsKey(Long.valueOf(j10))) ? 0L : map.get(Long.valueOf(j10)).longValue();
                    double d26 = jArr2[1];
                    double tileCoord = jArr2.length >= 4 ? toTileCoord(jArr2[2], d25) : d25;
                    double tileCoord2 = jArr2.length >= 4 ? toTileCoord(jArr2[3], d25) : d25;
                    long j11 = i3;
                    double levelValue3 = Config.levelValue(Data.UNIT_LEVEL_HP, j11, longValue);
                    double levelValue4 = Config.levelValue(Data.UNIT_LEVEL_DPS, j11, longValue);
                    arrayList5.add(new SimAttacker(-1L, d26, tileCoord, tileCoord2, levelValue3, Math.abs(levelValue4), unitSpeed(i3), unitRange(i3), Data.UNIT_FLYING[i3], levelValue4 < 0.0d, Data.UNIT_PREF_KIND[i3], Data.UNIT_PREF_MOD[i3]));
                    j8 = 4000016;
                    j9 = 4000000;
                    d25 = 14.0d;
                }
            }
        }
        if (list2 != null) {
            Iterator<long[]> it7 = list2.iterator();
            while (it7.hasNext()) {
                long[] next = it7.next();
                long j12 = next[0];
                int i4 = (int) (j12 - 28000000);
                if (i4 >= 0 && i4 < Data.HERO_HP.length) {
                    if (map3 == null || !map3.containsKey(Long.valueOf(j12))) {
                        c = 1;
                        j2 = 0;
                    } else {
                        j2 = map3.get(Long.valueOf(j12)).longValue();
                        c = 1;
                    }
                    double d27 = next[c];
                    if (next.length >= i2) {
                        long j13 = next[c2];
                        d16 = 14.0d;
                        d17 = toTileCoord(j13, 14.0d);
                    } else {
                        d16 = 14.0d;
                        d17 = 14.0d;
                    }
                    Iterator<long[]> it8 = it7;
                    long j14 = i4;
                    arrayList5.add(new SimAttacker(j12, d27, d17, next.length >= 4 ? toTileCoord(next[3], d16) : 14.0d, Config.levelValue(Data.HERO_HP, j14, j2), Config.levelValue(Data.HERO_DPS, j14, j2), 2.0d, i4 == 1 ? 5.0d : 1.0d, false, false, 0L, 1.0d));
                    it7 = it8;
                    c2 = 2;
                    i2 = 4;
                }
            }
        }
        if (jArr != null && list4 != null && !list4.isEmpty()) {
            double d28 = jArr[0];
            if (jArr.length >= 3) {
                d14 = 14.0d;
                d15 = toTileCoord(jArr[1], 14.0d);
            } else {
                d14 = 14.0d;
                d15 = 14.0d;
            }
            if (jArr.length >= 3) {
                d14 = toTileCoord(jArr[2], d14);
            }
            Iterator<long[]> it9 = list4.iterator();
            while (it9.hasNext()) {
                long[] next2 = it9.next();
                long j15 = next2[0];
                if (4000000 <= j15 && j15 <= 4000016) {
                    int i5 = (int) (j15 - 4000000);
                    long j16 = next2[1];
                    long j17 = next2[2];
                    double d29 = d15;
                    long j18 = i5;
                    double levelValue5 = Config.levelValue(Data.UNIT_LEVEL_HP, j18, j16);
                    double levelValue6 = Config.levelValue(Data.UNIT_LEVEL_DPS, j18, j16);
                    long j19 = 0;
                    while (j19 < j17) {
                        Double.isNaN(d28);
                        arrayList5.add(new SimAttacker(-1L, d28 + 1.0d, d29, d14, levelValue5, Math.abs(levelValue6), unitSpeed(i5), unitRange(i5), Data.UNIT_FLYING[i5], levelValue6 < 0.0d, Data.UNIT_PREF_KIND[i5], Data.UNIT_PREF_MOD[i5]));
                        j19++;
                        it9 = it9;
                        d28 = d28;
                    }
                    d15 = d29;
                }
            }
        }
        if (list3 == null || list3.isEmpty()) {
            d = 0.0d;
            d2 = 0.0d;
            d3 = 0.0d;
            d4 = 1.0d;
        } else {
            ArrayList<SimBuilding> arrayList6 = new ArrayList();
            for (SimBuilding simBuilding : arrayList4) {
                if (simBuilding.isDefense) {
                    arrayList6.add(simBuilding);
                }
            }
            Collections.sort(arrayList6, new Comparator<SimBuilding>() { // from class: com.nara.server.Builders.1
                @Override // java.util.Comparator
                public int compare(SimBuilding simBuilding2, SimBuilding simBuilding3) {
                    return Double.compare(simBuilding3.dps, simBuilding2.dps);
                }
            });
            Iterator<Long> it10 = list3.iterator();
            double d30 = 0.0d;
            d2 = 0.0d;
            d3 = 0.0d;
            d4 = 1.0d;
            while (it10.hasNext()) {
                Long next3 = it10.next();
                if (Config.isSpell(next3.longValue())) {
                    int longValue2 = (int) (next3.longValue() - 26000000);
                    long longValue3 = (map2 == null || !map2.containsKey(next3)) ? 0L : map2.get(next3).longValue();
                    if (longValue2 == 0 || longValue2 == 4) {
                        it4 = it10;
                        d13 = d30;
                        long j20 = longValue2;
                        double levelValue7 = Config.levelValue(Data.SPELL_DAMAGE, j20, longValue3) * Config.levelValue(Data.SPELL_HITS, j20, longValue3);
                        Iterator it11 = (arrayList6.isEmpty() ? arrayList4 : arrayList6).iterator();
                        while (it11.hasNext()) {
                            SimBuilding simBuilding2 = (SimBuilding) it11.next();
                            arrayList = arrayList6;
                            Iterator it12 = it11;
                            if (simBuilding2.hp > 0.0d) {
                                double d31 = simBuilding2.hp;
                                Double.isNaN(levelValue7);
                                simBuilding2.hp = Math.max(0.0d, d31 - levelValue7);
                                break;
                            }
                            arrayList6 = arrayList;
                            it11 = it12;
                        }
                    } else {
                        if (longValue2 == 1) {
                            double levelValue8 = Config.levelValue(Data.SPELL_HITS, 1L, longValue3) * Math.abs(Config.levelValue(Data.SPELL_DAMAGE, 1L, longValue3));
                            Double.isNaN(levelValue8);
                            d30 += levelValue8;
                            arrayList = arrayList6;
                            it4 = it10;
                            d2 = 18.0d;
                        } else if (longValue2 == 2) {
                            double levelValue9 = Config.levelValue(Data.SPELL_BOOST_PERCENT, 2L, longValue3);
                            Double.isNaN(levelValue9);
                            arrayList = arrayList6;
                            it4 = it10;
                            d4 = Math.max(d4, levelValue9 / 100.0d);
                            d3 = 18.0d;
                        } else if (longValue2 == 5) {
                            it4 = it10;
                            d13 = d30;
                            double levelValue10 = Config.levelValue(Data.SPELL_FREEZE_MS, 5L, longValue3);
                            Double.isNaN(levelValue10);
                            double d32 = levelValue10 / 1000.0d;
                            int i6 = 0;
                            for (SimBuilding simBuilding3 : arrayList6) {
                                if (simBuilding3.hp > 0.0d && i6 < 4) {
                                    simBuilding3.freezeLeft = Math.max(simBuilding3.freezeLeft, d32);
                                    i6++;
                                }
                            }
                        } else {
                            it4 = it10;
                            d13 = d30;
                        }
                        it10 = it4;
                        arrayList6 = arrayList;
                    }
                    arrayList = arrayList6;
                    d30 = d13;
                    it10 = it4;
                    arrayList6 = arrayList;
                }
            }
            d = d30;
        }
        double max = Math.max(0L, Math.min(j, 180L));
        double d33 = 0.0d;
        while (d33 <= max) {
            Iterator it13 = arrayList4.iterator();
            while (true) {
                if (!it13.hasNext()) {
                    d5 = max;
                    d6 = d4;
                    d7 = 0.0d;
                    z = false;
                    break;
                }
                d5 = max;
                d6 = d4;
                d7 = 0.0d;
                if (((SimBuilding) it13.next()).hp > 0.0d) {
                    z = true;
                    break;
                }
                d4 = d6;
                max = d5;
            }
            if (!z) {
                break;
            }
            double min = (d33 > d2 || d <= d7) ? d7 : Math.min(d, 60.0d);
            double max2 = Math.max(d7, d - min);
            double d34 = d33 <= d3 ? d6 : 1.0d;
            Iterator it14 = arrayList5.iterator();
            boolean z7 = false;
            while (it14.hasNext()) {
                double d35 = max2;
                SimAttacker simAttacker = (SimAttacker) it14.next();
                double d36 = d2;
                if (simAttacker.hp <= 0.0d) {
                    max2 = d35;
                    d2 = d36;
                } else {
                    if (d33 < simAttacker.deploySec) {
                        d8 = min;
                        d10 = d33;
                        d9 = d3;
                        it = it14;
                    } else {
                        if (simAttacker.isHealer) {
                            Iterator it15 = arrayList5.iterator();
                            SimAttacker simAttacker2 = null;
                            while (it15.hasNext()) {
                                SimAttacker simAttacker3 = (SimAttacker) it15.next();
                                if (simAttacker3.flying) {
                                    it2 = it15;
                                    d11 = min;
                                    d12 = d3;
                                } else {
                                    d12 = d3;
                                    if (simAttacker3.hp > 0.0d) {
                                        it3 = it14;
                                        if (simAttacker3.hp >= simAttacker3.maxHp || d33 < simAttacker3.deploySec) {
                                            it2 = it15;
                                            d11 = min;
                                        } else {
                                            if (simAttacker2 != null) {
                                                it2 = it15;
                                                d11 = min;
                                                if (simAttacker3.hp / simAttacker3.maxHp >= simAttacker2.hp / simAttacker2.maxHp) {
                                                }
                                            } else {
                                                it2 = it15;
                                                d11 = min;
                                            }
                                            simAttacker2 = simAttacker3;
                                        }
                                        it14 = it3;
                                        it15 = it2;
                                        d3 = d12;
                                        min = d11;
                                    } else {
                                        it2 = it15;
                                        d11 = min;
                                    }
                                }
                                it3 = it14;
                                it14 = it3;
                                it15 = it2;
                                d3 = d12;
                                min = d11;
                            }
                            d8 = min;
                            d9 = d3;
                            it = it14;
                            if (simAttacker2 != null) {
                                simAttacker2.hp = Math.min(simAttacker2.maxHp, simAttacker2.hp + (simAttacker.dps * 0.5d * d34));
                            }
                        } else {
                            d8 = min;
                            d9 = d3;
                            it = it14;
                            if (simAttacker.target == null || simAttacker.target.hp <= 0.0d) {
                                simAttacker.target = pickTarget(simAttacker, arrayList4);
                                if (simAttacker.target != null) {
                                    simAttacker.readyAt = Math.max(0.0d, (Math.hypot(simAttacker.target.cx - simAttacker.x, simAttacker.target.cy - simAttacker.y) - simAttacker.attackRange) / Math.max(0.5d, simAttacker.speed)) + d33;
                                }
                            }
                            if (d33 >= simAttacker.readyAt) {
                                double d37 = simAttacker.target.cx - simAttacker.x;
                                double d38 = simAttacker.target.cy - simAttacker.y;
                                double hypot = Math.hypot(d37, d38);
                                double d39 = simAttacker.attackRange + 1.0d;
                                if (hypot <= d39 || hypot <= 0.0d) {
                                    d10 = d33;
                                } else {
                                    d10 = d33;
                                    simAttacker.x = simAttacker.target.cx - ((d37 / hypot) * d39);
                                    simAttacker.y = simAttacker.target.cy - ((d38 / hypot) * d39);
                                }
                                double d40 = simAttacker.dps * 0.5d * d34;
                                if (simAttacker.prefKind == 2 && simAttacker.target.isResource) {
                                    d40 *= simAttacker.prefMod;
                                }
                                simAttacker.target.hp = Math.max(0.0d, simAttacker.target.hp - d40);
                                max2 = d35;
                                d2 = d36;
                                it14 = it;
                                d3 = d9;
                                min = d8;
                                d33 = d10;
                                z7 = true;
                            }
                        }
                        d10 = d33;
                    }
                    max2 = d35;
                    d2 = d36;
                    it14 = it;
                    d3 = d9;
                    min = d8;
                    d33 = d10;
                    z7 = true;
                }
            }
            double d41 = max2;
            double d42 = min;
            double d43 = d33;
            double d44 = d2;
            double d45 = d3;
            double d46 = 0.0d;
            if (!z7) {
                break;
            }
            if (d42 > 0.0d) {
                Iterator it16 = arrayList5.iterator();
                while (true) {
                    if (!it16.hasNext()) {
                        break;
                    }
                    SimAttacker simAttacker4 = (SimAttacker) it16.next();
                    if (simAttacker4.hp > d46 && simAttacker4.hp < simAttacker4.maxHp && d43 >= simAttacker4.deploySec) {
                        simAttacker4.hp = Math.min(simAttacker4.maxHp, simAttacker4.hp + d42);
                        break;
                    }
                    d46 = 0.0d;
                }
            }
            for (SimBuilding simBuilding4 : arrayList4) {
                double d47 = 0.0d;
                if (simBuilding4.hp > 0.0d && simBuilding4.dps > 0.0d) {
                    if (simBuilding4.freezeLeft > 0.0d) {
                        simBuilding4.freezeLeft = Math.max(0.0d, simBuilding4.freezeLeft - 0.5d);
                    } else {
                        double d48 = Double.MAX_VALUE;
                        SimAttacker simAttacker5 = null;
                        for (SimAttacker simAttacker6 : arrayList5) {
                            if (simAttacker6.hp > d47 && d43 >= simAttacker6.deploySec && ((!simAttacker6.flying || simBuilding4.targetAir) && (simAttacker6.flying || simBuilding4.targetGround))) {
                                double hypot2 = Math.hypot(simAttacker6.x - simBuilding4.cx, simAttacker6.y - simBuilding4.cy);
                                if (hypot2 <= simBuilding4.range + 1.0d && hypot2 < d48) {
                                    d48 = hypot2;
                                    simAttacker5 = simAttacker6;
                                }
                            }
                            d47 = 0.0d;
                        }
                        if (simAttacker5 != null) {
                            simAttacker5.hp = Math.max(0.0d, simAttacker5.hp - (simBuilding4.dps * 0.5d));
                        }
                    }
                }
            }
            d33 = d43 + 0.5d;
            d4 = d6;
            d = d41;
            d2 = d44;
            max = d5;
            d3 = d45;
        }
        boolean z8 = false;
        double d49 = 0.0d;
        for (SimBuilding simBuilding5 : arrayList4) {
            d49 += simBuilding5.maxHp - simBuilding5.hp;
            if (simBuilding5.isTownHall && simBuilding5.hp <= 0.0d) {
                z8 = true;
            }
        }
        double d50 = j7;
        Double.isNaN(d50);
        double max3 = Math.max(0.0d, Math.min(1.0d, d49 / d50));
        long stars = stars(max3, z8);
        LinkedHashMap linkedHashMap = new LinkedHashMap();
        for (SimAttacker simAttacker7 : arrayList5) {
            if (simAttacker7.heroRef > 0) {
                linkedHashMap.put(Long.valueOf(simAttacker7.heroRef), Double.valueOf(Math.max(0.0d, Math.min(1.0d, (simAttacker7.maxHp - Math.max(0.0d, simAttacker7.hp)) / simAttacker7.maxHp))));
            }
        }
        return new BattleOutcome(max3, stars, linkedHashMap);
    }

    static long stars(double d) {
        long j = 0;
        for (double d2 : Data.STAR_STEPS) {
            if (d >= d2) {
                j++;
            }
        }
        return j;
    }

    static long stars(double d, boolean z) {
        long j = d >= 0.5d ? 1L : 0L;
        if (z) {
            j++;
        }
        if (d >= 0.999d) {
            j = 3;
        }
        return Math.min(3L, j);
    }

    static long destructionXp(String str, double d) {
        Iterator<Object> it = Py.asList(Py.asMap(Py.loads(str)).get("buildings")).iterator();
        long j = 0;
        while (it.hasNext()) {
            Map<String, Object> asMap = Py.asMap(it.next());
            j += Config.levelValue(Data.DESTRUCTION_XP, Config.data(asMap) - 1000000, Config.lvl(asMap));
        }
        double d2 = j;
        Double.isNaN(d2);
        return (long) (d2 * d);
    }

    static long pickLevel(long j, double d) {
        if (d >= 0.8d) {
            j = d < 0.9d ? j - 1 : j + 1;
        }
        return Math.max(1L, Math.min(j, Data.ATTACK_COST.length));
    }

    static boolean homeInBounds(Map<String, Object> map) {
        String[] strArr = {"buildings", "obstacles", "traps", "decos"};
        long[][] jArr = {Data.BUILDING_W, Data.OBSTACLE_W, Data.TRAP_W, Data.DECO_W};
        long[][] jArr2 = {Data.BUILDING_H, Data.OBSTACLE_H, Data.TRAP_H, Data.DECO_H};
        int i = 0;
        for (int i2 = 4; i < i2; i2 = 4) {
            Object obj = map.get(strArr[i]);
            if (obj instanceof List) {
                long sectionBase = sectionBase(strArr[i]);
                Iterator<Object> it = Py.asList(obj).iterator();
                while (it.hasNext()) {
                    Map<String, Object> asMap = Py.asMap(it.next());
                    long data = Config.data(asMap) - sectionBase;
                    if (0 > data || data >= jArr[i].length) {
                        return false;
                    }
                    long lv = Py.lv(asMap.get("x"));
                    long lv2 = Py.lv(asMap.get("y"));
                    if (lv < 0 || lv2 < 0) {
                        return false;
                    }
                    int i3 = (int) data;
                    if (lv + jArr[i][i3] > 50 || lv2 + jArr2[i][i3] > 50) {
                        return false;
                    }
                }
            }
            i++;
        }
        return true;
    }

    static Map<String, Object> transformHome(Map<String, Object> map, long j) {
        Map<String, Object> map2;
        long j2;
        long j3;
        String[] strArr;
        Map<String, Object> map3 = map;
        int i = 4;
        String[] strArr2 = {"buildings", "obstacles", "traps", "decos"};
        long[][] jArr = {Data.BUILDING_W, Data.OBSTACLE_W, Data.TRAP_W, Data.DECO_W};
        long[][] jArr2 = {Data.BUILDING_H, Data.OBSTACLE_H, Data.TRAP_H, Data.DECO_H};
        long j4 = j & 7;
        if (j4 == 0) {
            return map3;
        }
        long j5 = 50;
        long j6 = 0;
        long j7 = 0;
        long j8 = 50;
        int i2 = 0;
        while (true) {
            String str = "x";
            if (i2 >= i) {
                break;
            }
            Object obj = map3.get(strArr2[i2]);
            if (obj instanceof List) {
                long sectionBase = sectionBase(strArr2[i2]);
                Iterator<Object> it = Py.asList(obj).iterator();
                j3 = j4;
                long j9 = j6;
                long j10 = j7;
                while (it.hasNext()) {
                    Map<String, Object> asMap = Py.asMap(it.next());
                    String[] strArr3 = strArr2;
                    int data = (int) (Config.data(asMap) - sectionBase);
                    long lv = Py.lv(asMap.get(str));
                    String str2 = str;
                    long lv2 = Py.lv(asMap.get("y"));
                    j5 = Math.min(j5, lv);
                    j8 = Math.min(j8, lv2);
                    j9 = Math.max(j9, lv + jArr[i2][data]);
                    j10 = Math.max(j10, lv2 + jArr2[i2][data]);
                    strArr2 = strArr3;
                    it = it;
                    str = str2;
                }
                strArr = strArr2;
                j7 = j10;
                j6 = j9;
            } else {
                strArr = strArr2;
                j3 = j4;
            }
            i2++;
            i = 4;
            map3 = map;
            j4 = j3;
            strArr2 = strArr;
        }
        String[] strArr4 = strArr2;
        long j11 = j4;
        Object obj2 = "x";
        if (j5 > j6 || j8 > j7) {
            return map;
        }
        if ((j11 & 4) == 0 || j6 - j5 == j7 - j8) {
            map2 = map;
            j2 = j11;
        } else {
            j2 = j11 & 3;
            if (j2 == 0) {
                return map;
            }
            map2 = map;
        }
        LinkedHashMap linkedHashMap = new LinkedHashMap(map2);
        int i3 = 0;
        while (i3 < 4) {
            ArrayList arrayList = new ArrayList();
            Object obj3 = map2.get(strArr4[i3]);
            if (obj3 instanceof List) {
                long sectionBase2 = sectionBase(strArr4[i3]);
                Iterator<Object> it2 = Py.asList(obj3).iterator();
                while (it2.hasNext()) {
                    Map<String, Object> asMap2 = Py.asMap(it2.next());
                    long j12 = j5;
                    ArrayList arrayList2 = arrayList;
                    int data2 = (int) (Config.data(asMap2) - sectionBase2);
                    long j13 = jArr[i3][data2];
                    long j14 = jArr2[i3][data2];
                    Object obj4 = obj2;
                    long lv3 = Py.lv(asMap2.get(obj4));
                    long lv4 = Py.lv(asMap2.get("y"));
                    if ((j2 & 4) != 0) {
                        long j15 = j8 + (lv3 - j12);
                        lv3 = j12 + (lv4 - j8);
                        lv4 = j15;
                        j13 = j14;
                        j14 = j13;
                    }
                    if ((j2 & 1) != 0) {
                        lv3 = ((j12 + j6) - lv3) - j13;
                    }
                    if ((j2 & 2) != 0) {
                        lv4 = ((j8 + j7) - lv4) - j14;
                    }
                    LinkedHashMap linkedHashMap2 = new LinkedHashMap(asMap2);
                    linkedHashMap2.put(obj4, Long.valueOf(lv3));
                    linkedHashMap2.put("y", Long.valueOf(lv4));
                    arrayList2.add(linkedHashMap2);
                    obj2 = obj4;
                    arrayList = arrayList2;
                    j5 = j12;
                }
            }
            linkedHashMap.put(strArr4[i3], arrayList);
            i3++;
            obj2 = obj2;
            j5 = j5;
        }
        return !homeInBounds(linkedHashMap) ? map2 : linkedHashMap;
    }

    static List<Object> filterKeep(Object obj, Py.Random random, double d) {
        ArrayList arrayList = new ArrayList();
        if (obj instanceof List) {
            for (Object obj2 : Py.asList(obj)) {
                if (random.random() < d) {
                    arrayList.add(obj2);
                }
            }
        }
        return arrayList;
    }

    static Map<String, Object> varyHome(Map<String, Object> map, Py.Random random) {
        LinkedHashMap linkedHashMap = new LinkedHashMap(map);
        double uniform = random.uniform(0.4d, 1.0d);
        double uniform2 = random.uniform(0.5d, 1.0d);
        double uniform3 = random.uniform(0.7d, 1.0d);
        double uniform4 = random.uniform(0.9d, 1.0d);
        linkedHashMap.put("obstacles", filterKeep(map.get("obstacles"), random, uniform));
        linkedHashMap.put("decos", filterKeep(map.get("decos"), random, uniform2));
        linkedHashMap.put("traps", filterKeep(map.get("traps"), random, uniform3));
        long choice = random.choice(new long[]{0, 0, 1, 2, 3});
        ArrayList arrayList = new ArrayList();
        Object obj = map.get("buildings");
        long j = 1000010;
        if (obj instanceof List) {
            Iterator<Object> it = Py.asList(obj).iterator();
            while (it.hasNext()) {
                LinkedHashMap linkedHashMap2 = new LinkedHashMap(Py.asMap(it.next()));
                long data = Config.data(linkedHashMap2);
                if (data == j) {
                    if (random.random() < uniform4) {
                        linkedHashMap2.put("lvl", Long.valueOf(Math.max(0L, Config.lvl(linkedHashMap2) - choice)));
                    }
                } else if (isDefenseId(data) || isProducerId(data)) {
                    linkedHashMap2.put("lvl", Long.valueOf(Math.max(0L, Config.lvl(linkedHashMap2) - random.choice(new long[]{0, 0, 1, 2}))));
                }
                arrayList.add(linkedHashMap2);
                j = 1000010;
            }
        }
        LinkedHashMap linkedHashMap3 = new LinkedHashMap();
        for (int i = 0; i < arrayList.size(); i++) {
            long data2 = Config.data((Map) arrayList.get(i));
            if (data2 != 1000010 && data2 != 1000001) {
                int i2 = (int) (data2 - 1000000);
                String str = Data.BUILDING_W[i2] + "," + Data.BUILDING_H[i2];
                List list = (List) linkedHashMap3.get(str);
                if (list == null) {
                    list = new ArrayList();
                    linkedHashMap3.put(str, list);
                }
                list.add(Integer.valueOf(i));
            }
        }
        double uniform5 = random.uniform(0.4d, 1.0d);
        for (List<Integer> list2 : linkedHashMap3.values()) {
            ArrayList arrayList2 = new ArrayList();
            for (Integer num : list2) {
                if (random.random() < uniform5) {
                    arrayList2.add(num);
                }
            }
            if (arrayList2.size() >= 2) {
                ArrayList arrayList3 = new ArrayList(arrayList2.size());
                Iterator it2 = arrayList2.iterator();
                while (it2.hasNext()) {
                    Map map2 = (Map) arrayList.get(((Integer) it2.next()).intValue());
                    arrayList3.add(new long[]{Py.lv(map2.get("x")), Py.lv(map2.get("y"))});
                }
                random.shuffle(arrayList3);
                for (int i3 = 0; i3 < arrayList2.size(); i3++) {
                    Map map3 = (Map) arrayList.get(((Integer) arrayList2.get(i3)).intValue());
                    map3.put("x", Long.valueOf(((long[]) arrayList3.get(i3))[0]));
                    map3.put("y", Long.valueOf(((long[]) arrayList3.get(i3))[1]));
                }
            }
        }
        ArrayList arrayList4 = new ArrayList(arrayList.size());
        arrayList4.addAll(arrayList);
        linkedHashMap.put("buildings", arrayList4);
        return linkedHashMap;
    }

    static Map<String, Object> generateEnemy(Config config, Py.Random random) {
        long j;
        long max = Math.max(1L, Math.min(config.matchLevel > 0 ? config.matchLevel : pickLevel(config.townHallLevel(), random.random()), Data.ATTACK_COST.length));
        String loadLevel = loadLevel(config, "townhall" + max + ".json");
        if (loadLevel == null) {
            loadLevel = npcJson(Math.min((4 * max) + 2, 49L), config);
        }
        Map<String, Object> varyHome = varyHome(transformHome(Py.asMap(Py.loads(loadLevel)), random.randrange(8L)), random);
        Iterator<Object> it = Py.asList(varyHome.get("buildings")).iterator();
        long j2 = 0;
        long j3 = 0;
        while (it.hasNext()) {
            Map<String, Object> asMap = Py.asMap(it.next());
            long data = Config.data(asMap) - 1000000;
            long lvl = Config.lvl(asMap);
            j2 += Config.levelValue(Data.STORE_GOLD, data, lvl);
            j3 += Config.levelValue(Data.STORE_ELIXIR, data, lvl);
        }
        TreeMap treeMap = new TreeMap();
        Iterator<Object> it2 = Py.asList(varyHome.get("buildings")).iterator();
        while (it2.hasNext()) {
            long data2 = Config.data(Py.asMap(it2.next()));
            if (Config.altar(data2)) {
                j = j3;
                treeMap.put(Long.valueOf(Config.altarHero(data2)), Long.valueOf(Math.min(max * 2, 20L)));
            } else {
                j = j3;
            }
            j3 = j;
        }
        long j4 = j3;
        double d = j2;
        double uniform = random.uniform(0.3d, 0.7d);
        Double.isNaN(d);
        double d2 = j4;
        double uniform2 = random.uniform(0.3d, 0.7d);
        Double.isNaN(d2);
        return Py.map("json", Py.dumps(varyHome), "heroes", treeMap, "level", Long.valueOf(max), "name", random.choice(Data.ENEMY_NAMES) + " " + random.randrange(10L, 100L), "id", Long.valueOf(random.randrange(100000L) + 300000), "gold", Long.valueOf((long) (d * uniform)), "elixir", Long.valueOf((long) (d2 * uniform2)), "gold_cap", Long.valueOf(j2), "elixir_cap", Long.valueOf(j4), "score", Long.valueOf(Math.max(0L, config.trophies + random.randint(-50L, 50L))));
    }

    static Map<String, Object> completeBuilding(Map<String, Object> map) {
        long data = Config.data(map);
        if (data == 1000020) {
            if (!map.containsKey("storage_type")) {
                map.put("storage_type", 1L);
            }
            if (!map.containsKey("units")) {
                map.put("units", new ArrayList());
            }
            if (!map.containsKey("unit_prod")) {
                map.put("unit_prod", Py.map("unit_type", 1L));
            }
        } else if ((data == 1000006 || data == 1000026) && !map.containsKey("unit_prod")) {
            map.put("unit_prod", Py.map("unit_type", 0L));
        }
        return map;
    }

    static Map<String, Object> cleanIntMap(Object obj) {
        if (!(obj instanceof Map)) {
            return null;
        }
        Map<String, Object> asMap = Py.asMap(obj);
        LinkedHashMap linkedHashMap = new LinkedHashMap();
        for (Map.Entry<String, Object> entry : asMap.entrySet()) {
            if (!Py.isInt(entry.getValue())) {
                return null;
            }
            linkedHashMap.put(entry.getKey(), Long.valueOf(Py.lv(entry.getValue())));
        }
        return linkedHashMap;
    }

    static Map<String, Object> cleanExtras(Map<String, Object> map) {
        LinkedHashMap linkedHashMap = new LinkedHashMap();
        String[] strArr = {"res_time", "storage_type", "ammo", "const_t", "boost_t", "clear_t"};
        for (int i = 0; i < 6; i++) {
            String str = strArr[i];
            Object obj = map.get(str);
            if (Py.isInt(obj)) {
                linkedHashMap.put(str, Long.valueOf(Py.lv(obj)));
            }
        }
        String[] strArr2 = {"attack_mode", "locked"};
        for (int i2 = 0; i2 < 2; i2++) {
            String str2 = strArr2[i2];
            Object obj2 = map.get(str2);
            if (obj2 instanceof Boolean) {
                linkedHashMap.put(str2, obj2);
            }
        }
        if (map.get("units") instanceof List) {
            linkedHashMap.put("units", new ArrayList());
        }
        String[] strArr3 = {"unit_prod", "unit_upg", "hero_upg"};
        for (int i3 = 0; i3 < 3; i3++) {
            String str3 = strArr3[i3];
            Map<String, Object> cleanIntMap = cleanIntMap(map.get(str3));
            if (cleanIntMap != null) {
                linkedHashMap.put(str3, cleanIntMap);
            }
        }
        return linkedHashMap;
    }

    static List<Map<String, Object>> cleanSection(Object obj, long j, long j2, String str) {
        long j3;
        long j4;
        ArrayList arrayList = new ArrayList();
        if (!(obj instanceof List)) {
            return arrayList;
        }
        Iterator<Object> it = Py.asList(obj).iterator();
        while (it.hasNext()) {
            Object next = it.next();
            if (next instanceof Map) {
                Map<String, Object> asMap = Py.asMap(next);
                Object obj2 = asMap.get("data");
                Object obj3 = asMap.get("x");
                Object obj4 = asMap.get("y");
                if (Py.isInt(obj2) && Py.isInt(obj3) && Py.isInt(obj4)) {
                    long lv = Py.lv(obj2);
                    long lv2 = Py.lv(obj3);
                    long lv3 = Py.lv(obj4);
                    ArrayList arrayList2 = arrayList;
                    Iterator<Object> it2 = it;
                    long j5 = lv - j;
                    if (0 <= j5 && j5 < j2 && 0 <= lv2 && lv2 < 50 && 0 <= lv3 && lv3 < 50) {
                        LinkedHashMap linkedHashMap = new LinkedHashMap();
                        linkedHashMap.put("data", Long.valueOf(lv));
                        if ("building".equals(str)) {
                            Map<String, Object> cleanExtras = cleanExtras(asMap);
                            boolean z = Py.isInt(cleanExtras.get("const_t")) && Py.lv(cleanExtras.get("const_t")) > 0;
                            Object obj5 = asMap.get("lvl");
                            if (Py.isInt(obj5)) {
                                j4 = Py.lv(obj5);
                                j3 = lv3;
                            } else {
                                j3 = lv3;
                                j4 = 0;
                            }
                            linkedHashMap.put("lvl", Long.valueOf(Math.max(z ? -1L : 0L, Math.min(j4, Data.BUILDING_LEVELS[(int) j5] - 1))));
                            linkedHashMap.putAll(cleanExtras);
                        } else {
                            j3 = lv3;
                            if ("trap".equals(str)) {
                                linkedHashMap.put("lvl", 0L);
                            } else if ("obstacle".equals(str)) {
                                Object obj6 = asMap.get("clear_t");
                                if (Py.isInt(obj6) && Py.lv(obj6) > 0) {
                                    linkedHashMap.put("clear_t", Long.valueOf(Py.lv(obj6)));
                                }
                            }
                        }
                        linkedHashMap.put("x", Long.valueOf(lv2));
                        linkedHashMap.put("y", Long.valueOf(j3));
                        arrayList2.add(linkedHashMap);
                    }
                    it = it2;
                    arrayList = arrayList2;
                }
            }
        }
        return arrayList;
    }

    static Map<String, Object> cleanLevel(Map<String, Object> map) {
        boolean z;
        Object obj = map.get("respawnVars");
        Map<String, Object> asMap = obj instanceof Map ? Py.asMap(obj) : Collections.emptyMap();
        Object obj2 = asMap.get("secondsFromLastRespawn");
        Object obj3 = asMap.get("respawnSeed");
        Object obj4 = asMap.get("obstacleClearCounter");
        LinkedHashMap linkedHashMap = new LinkedHashMap();
        linkedHashMap.put("buildings", cleanSection(map.get("buildings"), 1000000L, Data.BUILDING_LEVELS.length, "building"));
        linkedHashMap.put("obstacles", cleanSection(map.get("obstacles"), 8000000L, 28L, "obstacle"));
        linkedHashMap.put("traps", cleanSection(map.get("traps"), 12000000L, 7L, "trap"));
        linkedHashMap.put("decos", cleanSection(map.get("decos"), 18000000L, 37L, "deco"));
        Object[] objArr = new Object[6];
        objArr[0] = "secondsFromLastRespawn";
        if (!Py.isInt(obj2)) {
            obj2 = 0L;
        }
        objArr[1] = obj2;
        objArr[2] = "respawnSeed";
        if (!Py.isInt(obj3)) {
            obj3 = 0L;
        }
        objArr[3] = obj3;
        objArr[4] = "obstacleClearCounter";
        if (!Py.isInt(obj4)) {
            obj4 = 0L;
        }
        objArr[5] = obj4;
        linkedHashMap.put("respawnVars", Py.map(objArr));
        linkedHashMap.put("cooldowns", new ArrayList());
        String[] strArr = {"newShopBuildings", "newShopTraps", "newShopDecos"};
        for (int i = 0; i < 3; i++) {
            String str = strArr[i];
            Object obj5 = map.get(str);
            if (obj5 instanceof List) {
                Iterator<Object> it = Py.asList(obj5).iterator();
                while (true) {
                    if (!it.hasNext()) {
                        z = true;
                        break;
                    }
                    if (!Py.isInt(it.next())) {
                        z = false;
                        break;
                    }
                }
                if (z) {
                    linkedHashMap.put(str, obj5);
                }
            }
        }
        return linkedHashMap;
    }

    static String loadLevel(Config config, String str) {
        byte[] readLevel;
        if (config.levelDir != null && Levels.LEVEL_NAME.matcher(str).matches() && (readLevel = config.levelDir.readLevel(str)) != null && readLevel.length <= 900000) {
            try {
                Object loads = Py.loads(new String(readLevel, Py.UTF8));
                if (!(loads instanceof Map)) {
                    return null;
                }
                Map<String, Object> asMap = Py.asMap(loads);
                if (!(asMap.get("buildings") instanceof List)) {
                    return null;
                }
                Map<String, Object> cleanLevel = cleanLevel(asMap);
                if (Py.asList(cleanLevel.get("buildings")).isEmpty()) {
                    return null;
                }
                return Py.dumps(cleanLevel);
            } catch (Py.ValueError unused) {
            }
        }
        return null;
    }

    static void verifyLevels(Config config, Log log) {
        byte[] readLevel;
        String str;
        if (config.levelDir == null) {
            return;
        }
        LinkedHashMap linkedHashMap = new LinkedHashMap();
        byte[] readFingerprint = config.levelDir.readFingerprint();
        if (readFingerprint != null) {
            try {
                Object loads = Py.loads(new String(readFingerprint, Py.UTF8));
                if (loads instanceof Map) {
                    Object obj = Py.asMap(loads).get("files");
                    if (obj instanceof List) {
                        for (Object obj2 : Py.asList(obj)) {
                            if (obj2 instanceof Map) {
                                Map<String, Object> asMap = Py.asMap(obj2);
                                Object obj3 = asMap.get("file");
                                Object obj4 = asMap.get("sha");
                                if ((obj3 instanceof String) && (obj4 instanceof String)) {
                                    linkedHashMap.put((String) obj3, (String) obj4);
                                }
                            }
                        }
                    }
                }
            } catch (Py.ValueError unused) {
            }
        }
        try {
            MessageDigest messageDigest = MessageDigest.getInstance("SHA-1");
            ArrayList<String> arrayList = new ArrayList(config.levelDir.list());
            Collections.sort(arrayList);
            long j = 0;
            for (String str2 : arrayList) {
                if (Levels.LEVEL_NAME.matcher(str2).matches() && (readLevel = config.levelDir.readLevel(str2)) != null) {
                    j++;
                    messageDigest.reset();
                    byte[] digest = messageDigest.digest(readLevel);
                    String hex = Py.hex(digest, digest.length);
                    String str3 = (String) linkedHashMap.get("level/" + str2);
                    if (str3 == null) {
                        str = "unlisted";
                    } else {
                        str = str3.equals(hex) ? "ok" : "MISMATCH";
                    }
                    log.write("level " + str2 + " sha1=" + hex + " " + str);
                }
            }
            log.write("level files found: " + j);
        } catch (NoSuchAlgorithmException unused2) {
        }
    }

    static String layoutJson(List<Map<String, Object>> list) {
        LinkedHashMap linkedHashMap = new LinkedHashMap();
        linkedHashMap.put("buildings", list);
        linkedHashMap.put("obstacles", new ArrayList());
        linkedHashMap.put("traps", new ArrayList());
        linkedHashMap.put("decos", new ArrayList());
        linkedHashMap.put("respawnVars", Py.map("secondsFromLastRespawn", 0L, "respawnSeed", 0L, "obstacleClearCounter", 0L));
        return Py.dumps(linkedHashMap);
    }

    static Map<String, Object> homeEntry(String str, long j, long j2) {
        return Py.map("data", Long.valueOf(buildingDataByName(str)), "lvl", 0L, "x", Long.valueOf(j), "y", Long.valueOf(j2));
    }

    static Map<String, Object> baseHome(Config config) {
        String loadLevel = loadLevel(config, "starting_home.json");
        if (loadLevel != null) {
            return Py.asMap(Py.loads(loadLevel));
        }
        ArrayList arrayList = new ArrayList();
        if (config.tutorial) {
            arrayList.add(homeEntry("town_hall", 21L, 21L));
            arrayList.add(homeEntry("gold_mine", 26L, 21L));
            arrayList.add(homeEntry("troop_housing", 27L, 25L));
            arrayList.add(homeEntry("worker", 15L, 18L));
        } else {
            arrayList.add(homeEntry("town_hall", 21L, 21L));
            arrayList.add(homeEntry("gold_mine", 26L, 21L));
            arrayList.add(homeEntry("elixir_pump", 17L, 21L));
            arrayList.add(homeEntry("gold_storage", 21L, 25L));
            arrayList.add(homeEntry("elixir_storage", 24L, 25L));
            arrayList.add(homeEntry("barrack", 17L, 25L));
            arrayList.add(homeEntry("troop_housing", 27L, 25L));
            arrayList.add(homeEntry("cannon", 21L, 17L));
            arrayList.add(homeEntry("worker", 15L, 18L));
            arrayList.add(homeEntry("worker", 31L, 18L));
        }
        return Py.asMap(Py.loads(layoutJson(arrayList)));
    }

    static String homeJson(Config config, boolean z) {
        if (z) {
            return layoutJson(Collections.emptyList());
        }
        Map<String, Object> baseHome = baseHome(config);
        baseHome.put("buildings", config.villageBuildings(baseHome.get("buildings")));
        baseHome.put("obstacles", config.villageObstacles(baseHome.containsKey("obstacles") ? baseHome.get("obstacles") : Collections.emptyList()));
        baseHome.put("decos", config.villageDecos(baseHome.containsKey("decos") ? baseHome.get("decos") : Collections.emptyList()));
        baseHome.put("traps", config.villageTraps(baseHome.containsKey("traps") ? baseHome.get("traps") : Collections.emptyList()));
        return Py.dumps(baseHome);
    }

    static byte[] buildLoginOk(long j, String str) {
        String valueOf = String.valueOf((long) Py.now());
        Cipher.Writer writer = new Cipher.Writer();
        writer.writeLong(j).writeLong(j);
        writer.writeString(str).writeString("").writeString("");
        writer.writeInt(5L).writeInt(2L).writeInt(1L);
        writer.writeString("prod");
        writer.writeInt(1L).writeInt(0L).writeInt(0L);
        writer.writeString("");
        writer.writeString(valueOf).writeString(valueOf);
        writer.writeInt(0L);
        writer.writeString("");
        return writer.toBytes();
    }

    static Cipher.Writer writeAvatar(Cipher.Writer writer, long j, String str, Config config, List<Long> list, AvatarOptions avatarOptions) {
        List<long[]> arrayList;
        Map<String, Object> allianceBlock;
        List<long[]> emptyList;
        int i;
        long[] jArr;
        boolean z = j == 1;
        long longValue = avatarOptions.townHall != null ? avatarOptions.townHall.longValue() : z ? config.townHallLevel() - 1 : 0L;
        List<long[]> spellSlots = z ? config.spellSlots() : Collections.emptyList();
        if (z) {
            arrayList = config.heroStateSlots();
        } else {
            arrayList = new ArrayList<>();
            if (avatarOptions.heroes != null) {
                Iterator it = new TreeMap(avatarOptions.heroes).keySet().iterator();
                while (it.hasNext()) {
                    arrayList.add(new long[]{((Long) it.next()).longValue(), 3});
                }
            }
        }
        if (avatarOptions.hasAllianceOverride) {
            allianceBlock = avatarOptions.allianceOverride;
        } else {
            allianceBlock = z ? config.allianceBlock() : null;
        }
        List<long[]> unitLevelSlots = avatarOptions.unitLevels != null ? avatarOptions.unitLevels : z ? config.unitLevelSlots() : Collections.emptyList();
        List<long[]> spellLevelSlots = avatarOptions.spellLevels != null ? avatarOptions.spellLevels : z ? config.spellLevelSlots() : Collections.emptyList();
        List<long[]> heroHealthSlots = z ? config.heroHealthSlots() : Collections.emptyList();
        long[] battleStats = avatarOptions.stats != null ? avatarOptions.stats : z ? config.battleStats() : new long[]{0, 0, 0, 0, 0};
        long j2 = longValue;
        long j3 = battleStats[0];
        long j4 = battleStats[1];
        boolean z2 = z;
        long j5 = battleStats[2];
        List<long[]> list2 = arrayList;
        List<long[]> list3 = spellLevelSlots;
        long j6 = battleStats[3];
        long j7 = battleStats[4];
        if (z2) {
            emptyList = config.heroLevelAll();
        } else if (avatarOptions.heroes != null) {
            emptyList = Config.pairs(new TreeMap(avatarOptions.heroes));
        } else {
            emptyList = Collections.emptyList();
        }
        long[] balance = avatarOptions.balance != null ? avatarOptions.balance : config.balance();
        long j8 = balance[0];
        long j9 = balance[1];
        long j10 = balance[2];
        List<long[]> list4 = unitLevelSlots;
        List<long[]> list5 = emptyList;
        long j11 = balance[3];
        long j12 = balance[4];
        long j13 = balance[5];
        long j14 = balance[6];
        long[] experience = avatarOptions.experience != null ? avatarOptions.experience : config.experience();
        writer.writeInt(0L);
        writer.writeLong(j).writeLong(j);
        if (allianceBlock != null) {
            writer.writeFlags(true);
            writer.writeLong(Py.lv(allianceBlock.get("id"))).writeString((String) allianceBlock.get("name")).writeInt(Py.lv(allianceBlock.get("badge"))).writeInt(Py.lv(allianceBlock.get("role")));
            writer.writeFlags(false, false);
            i = 3;
        } else {
            i = 3;
            writer.writeFlags(false, false, false);
        }
        writer.writeInt(leagueFor(j3));
        if (z2) {
            jArr = config.castleInfo();
        } else {
            jArr = new long[i];
            // fill-array-data instruction
            jArr[0] = 0;
            jArr[1] = 0;
            jArr[2] = 0;
        }
        long[] jArr2 = experience;
        writer.writeInt(jArr[0]).writeInt(jArr[1]).writeInt(jArr[2]);
        writer.writeInt(j2);
        writer.writeString(str).writeString("");
        writer.writeInt(jArr2[0]).writeInt(jArr2[1]);
        writer.writeInt(j11).writeInt(j11);
        writer.writeInt(0L).writeInt(0L).writeInt(j3);
        writer.writeInt(j4).writeInt(j5).writeInt(j6).writeInt(j7);
        writer.writeBool(true);
        writer.writeInt(0L);
        ArrayList arrayList2 = new ArrayList();
        arrayList2.add(new long[]{3000001, j12});
        arrayList2.add(new long[]{3000002, j13});
        if (j14 > 0) {
            arrayList2.add(new long[]{3000003, j14});
        }
        writer.writeSlots(arrayList2);
        ArrayList arrayList3 = new ArrayList();
        arrayList3.add(new long[]{3000000, j11});
        arrayList3.add(new long[]{3000001, j8});
        arrayList3.add(new long[]{3000002, j9});
        if (j10 > 0) {
            arrayList3.add(new long[]{3000003, j10});
        }
        writer.writeSlots(arrayList3);
        writer.writeSlots(avatarOptions.units != null ? avatarOptions.units : Collections.emptyList());
        writer.writeSlots(spellSlots);
        writer.writeSlots(list4);
        writer.writeSlots(list3);
        writer.writeSlots(list5);
        writer.writeSlots(heroHealthSlots);
        writer.writeSlots(list2);
        List<long[]> castleSlots = z2 ? config.castleSlots() : Collections.emptyList();
        writer.writeInt(castleSlots.size());
        for (long[] jArr3 : castleSlots) {
            writer.writeInt(jArr3[0]).writeInt(jArr3[1]).writeInt(jArr3[2]);
        }
        writer.writeRefs(list);
        writer.writeRefs(avatarOptions.achievements != null ? avatarOptions.achievements : Collections.emptyList());
        writer.writeSlots(avatarOptions.progress != null ? avatarOptions.progress : Collections.emptyList());
        writer.writeSlots(avatarOptions.stars != null ? avatarOptions.stars : Collections.emptyList());
        List<long[]>[] listArr = avatarOptions.loot;
        writer.writeSlots(listArr != null ? listArr[0] : Collections.emptyList());
        writer.writeSlots(listArr != null ? listArr[1] : Collections.emptyList());
        return writer;
    }

    static byte[] buildOwnHomeData(long j, Config config, boolean z) {
        Cipher.Writer writer = new Cipher.Writer();
        writer.writeInt(0L);
        writer.writeInt(0L).writeLong(j).writeString(homeJson(config, z));
        writer.writeInt(config.shieldSeconds()).writeInt(0L).writeInt(0L);
        AvatarOptions avatarOptions = new AvatarOptions();
        avatarOptions.units = config.army();
        avatarOptions.stars = config.starSlots();
        avatarOptions.loot = config.lootSlots();
        avatarOptions.achievements = config.achievementRefs();
        writeAvatar(writer, j, config.name, config, config.missions(), avatarOptions);
        return writer.toBytes();
    }

    static String npcFile(long j) {
        if (j == 0) {
            return "tutorial_npc.json";
        }
        if (j == 1) {
            return "tutorial_npc2.json";
        }
        return "npc" + (j - 1) + ".json";
    }

    static String npcJson(long j, Config config) {
        String loadLevel = loadLevel(config, npcFile(j));
        if (loadLevel != null) {
            return loadLevel;
        }
        ArrayList arrayList = new ArrayList();
        for (long j2 : Data.NPC_GRID) {
            for (long j3 : Data.NPC_GRID) {
                if (j2 != 25 || j3 != 25) {
                    arrayList.add(new long[]{j2, j3});
                }
            }
        }
        Collections.sort(arrayList, new Comparator<long[]>() { // from class: com.nara.server.Builders.2
            @Override // java.util.Comparator
            public int compare(long[] jArr, long[] jArr2) {
                return ((Math.abs(jArr[0] - 25) + Math.abs(jArr[1] - 25)) > (Math.abs(jArr2[0] - 25) + Math.abs(jArr2[1] - 25)) ? 1 : ((Math.abs(jArr[0] - 25) + Math.abs(jArr[1] - 25)) == (Math.abs(jArr2[0] - 25) + Math.abs(jArr2[1] - 25)) ? 0 : -1));
            }
        });
        ArrayList arrayList2 = new ArrayList();
        arrayList2.add("gold_storage");
        arrayList2.add("elixir_storage");
        arrayList2.add("cannon");
        arrayList2.add("gold_mine");
        arrayList2.add("elixir_pump");
        long min = Math.min(Py.fdiv(j, 8L) + 1, 4L);
        for (int i = 0; i < min; i++) {
            arrayList2.add("cannon");
        }
        arrayList2.add("gold_storage");
        arrayList2.add("elixir_storage");
        arrayList2.add("cannon");
        ArrayList arrayList3 = new ArrayList();
        arrayList3.add(homeEntry("town_hall", 24L, 24L));
        int min2 = Math.min(arrayList2.size(), arrayList.size());
        for (int i2 = 0; i2 < min2; i2++) {
            long[] jArr = (long[]) arrayList.get(i2);
            arrayList3.add(homeEntry((String) arrayList2.get(i2), jArr[0] - 1, jArr[1] - 1));
        }
        return layoutJson(arrayList3);
    }

    static byte[] buildNpcData(long j, Config config, long j2, List<Long> list) {
        long j3 = j - 17000000;
        Cipher.Writer writer = new Cipher.Writer();
        writer.writeInt(0L);
        writer.writeString(npcJson(j3, config));
        AvatarOptions avatarOptions = new AvatarOptions();
        avatarOptions.units = config.attackUnits(j3);
        avatarOptions.stars = config.starSlots();
        avatarOptions.loot = config.lootSlots();
        avatarOptions.achievements = config.achievementRefs();
        writeAvatar(writer, j2, config.name, config, list, avatarOptions);
        writer.writeInt(0L);
        writer.writeInt(j);
        return writer.toBytes();
    }

    static long leagueFor(long j) {
        long j2 = 0;
        for (int i = 0; i < Data.LEAGUE_FLOORS.length; i++) {
            if (j >= Data.LEAGUE_FLOORS[i]) {
                j2 = i;
            }
        }
        return Math.min(j2, 16L);
    }

    static Map<String, Object> clanBlock(Map<String, Object> map) {
        if (map == null) {
            return null;
        }
        return Py.map("id", map.get("id"), "name", map.get("name"), "badge", map.get("badge"), "role", 1L);
    }

    static synchronized List<Map<String, Object>> roster() {
        Class<Builders> cls;
        List<Map<String, Object>> list;
        ArrayList arrayList;
        Map map;
        Class<Builders> cls2 = Builders.class;
        synchronized (cls2) {
            try {
                list = ROSTER_CACHE;
                if (list.isEmpty()) {
                    Py.Random random = new Py.Random(5029L);
                    ArrayList arrayList2 = new ArrayList(DUMMY_CLAN_NAMES.length);
                    int i = 0;
                    while (true) {
                        String[] strArr = DUMMY_CLAN_NAMES;
                        if (i >= strArr.length) {
                            break;
                        }
                        arrayList2.add(Py.map("id", Long.valueOf(i + 700100), "name", strArr[i], "badge", Long.valueOf(DUMMY_CLAN_BADGES[i] + 13000000)));
                        i++;
                    }
                    long j = 10;
                    ROSTER_CACHE.add(Py.map("id", 50L, "name", "Nara Archieve", "trophies", 5029L, "level", 100L, "th", 10L, "aw", 1840L, "al", 211L, "dw", 964L, "dl", 57L, "clan", null, "promo", Boolean.TRUE));
                    ArrayList arrayList3 = new ArrayList();
                    for (String str : Data.ROSTER_NAMES) {
                        arrayList3.add(str);
                    }
                    for (String str2 : Data.ROSTER_TAGS) {
                        for (int i2 = 0; i2 < Data.ROSTER_NAMES.length; i2 += 2) {
                            arrayList3.add(Data.ROSTER_NAMES[i2] + " " + str2);
                        }
                    }
                    int min = (int) Math.min(180L, arrayList3.size());
                    long j2 = 4960;
                    int i3 = 0;
                    while (i3 < min) {
                        int i4 = i3;
                        long max = Math.max(250L, j2 - random.randint(8L, 44L));
                        long j3 = max > 2600 ? j : max > 2000 ? 9L : max > 1500 ? 8L : max > 1100 ? 7L : max > 700 ? 6L : 5L;
                        ArrayList arrayList4 = arrayList2;
                        long min2 = Math.min(99L, Py.fdiv(max, 55L) + 25 + random.randint(0L, 6L));
                        long fdiv = Py.fdiv(max, 3L) + 80 + random.randint(0L, 60L);
                        long randint = random.randint(10L, 120L);
                        long randint2 = random.randint(5L, 80L);
                        if (random.random() < 0.6d) {
                            arrayList = arrayList4;
                            map = (Map) arrayList.get((int) random.randrange(arrayList4.size()));
                        } else {
                            arrayList = arrayList4;
                            map = null;
                        }
                        List<Map<String, Object>> list2 = ROSTER_CACHE;
                        Py.Random random2 = random;
                        int i5 = min;
                        Object[] objArr = new Object[22];
                        objArr[0] = "id";
                        cls = cls2;
                        try {
                            objArr[1] = Long.valueOf(i4 + 100);
                            objArr[2] = "name";
                            objArr[3] = arrayList3.get(i4);
                            objArr[4] = "trophies";
                            objArr[5] = Long.valueOf(max);
                            objArr[6] = "level";
                            objArr[7] = Long.valueOf(min2);
                            objArr[8] = "th";
                            objArr[9] = Long.valueOf(j3);
                            objArr[10] = "aw";
                            objArr[11] = Long.valueOf(fdiv);
                            objArr[12] = "al";
                            objArr[13] = Long.valueOf(randint);
                            objArr[14] = "dw";
                            objArr[15] = Long.valueOf(Py.fdiv(fdiv, 2L));
                            objArr[16] = "dl";
                            objArr[17] = Long.valueOf(randint2);
                            objArr[18] = "clan";
                            objArr[19] = map;
                            objArr[20] = "promo";
                            objArr[21] = Boolean.valueOf(i4 < 6);
                            list2.add(Py.map(objArr));
                            i3 = i4 + 1;
                            arrayList2 = arrayList;
                            random = random2;
                            min = i5;
                            cls2 = cls;
                            j2 = max;
                            j = 10;
                        } catch (Throwable th) {
                            th = th;
                            throw th;
                        }
                    }
                    cls = cls2;
                    List<Map<String, Object>> list3 = ROSTER_CACHE;
                    return list3;
                }
            } catch (Throwable th2) {
                th = th2;
                cls = cls2;
            }
        }
        return list;
    }

    static Map<String, Object> rosterEntry(long j) {
        for (Map<String, Object> map : roster()) {
            if (Py.lv(map.get("id")) == j) {
                return map;
            }
        }
        return null;
    }

    static AvatarOptions rosterAvatarOptions(Map<String, Object> map) {
        AvatarOptions avatarOptions = new AvatarOptions();
        long lv = Py.lv(map.get("level"));
        long lv2 = Py.lv(map.get("th"));
        long lv3 = Py.lv(map.get("id"));
        avatarOptions.experience = new long[]{lv, 0};
        avatarOptions.townHall = Long.valueOf(lv2 - 1);
        avatarOptions.stats = new long[]{Py.lv(map.get("trophies")), Py.lv(map.get("aw")), Py.lv(map.get("al")), Py.lv(map.get("dw")), Py.lv(map.get("dl"))};
        avatarOptions.hasAllianceOverride = true;
        Object obj = map.get("clan");
        avatarOptions.allianceOverride = obj != null ? clanBlock((Map) obj) : null;
        if (lv2 >= 7) {
            long min = lv3 != 50 ? Math.min(39L, (lv2 * 3) + (lv % 7)) : 39L;
            TreeMap treeMap = new TreeMap();
            treeMap.put(28000000L, Long.valueOf(min));
            treeMap.put(28000001L, Long.valueOf(min));
            avatarOptions.heroes = treeMap;
        }
        if (lv3 == 50) {
            ArrayList arrayList = new ArrayList();
            for (int i = 0; i < Data.UNIT_MAX_LEVELS.length; i++) {
                if (Data.UNIT_MAX_LEVELS[i] > 0) {
                    arrayList.add(new long[]{i + 4000000, Data.UNIT_MAX_LEVELS[i]});
                }
            }
            avatarOptions.unitLevels = arrayList;
            ArrayList arrayList2 = new ArrayList();
            for (int i2 = 0; i2 < Data.SPELL_MAX_LEVELS.length; i2++) {
                if (Data.SPELL_MAX_LEVELS[i2] > 0) {
                    arrayList2.add(new long[]{i2 + 26000000, Data.SPELL_MAX_LEVELS[i2]});
                }
            }
            avatarOptions.spellLevels = arrayList2;
            ArrayList arrayList3 = new ArrayList();
            for (int i3 = 0; i3 < Data.ACHIEVEMENT_GEMS.length; i3++) {
                arrayList3.add(Long.valueOf(i3 + 23000000));
            }
            avatarOptions.achievements = arrayList3;
            ArrayList arrayList4 = new ArrayList();
            for (int i4 = 0; i4 < Data.ACHIEVEMENT_TARGETS.length; i4++) {
                arrayList4.add(new long[]{i4 + 23000000, Data.ACHIEVEMENT_TARGETS[i4]});
            }
            avatarOptions.progress = arrayList4;
        }
        return avatarOptions;
    }

    static List<Map<String, Object>> rankingRows(Config config) {
        ArrayList arrayList = new ArrayList();
        Iterator<Map<String, Object>> it = roster().iterator();
        while (it.hasNext()) {
            arrayList.add(new LinkedHashMap(it.next()));
        }
        long[] battleStats = config.battleStats();
        int i = 0;
        long j = battleStats[0];
        Map<String, Object> map = Py.map("id", 1L, "name", config.name, "trophies", Long.valueOf(j), "level", Long.valueOf(config.experience()[0]), "th", Long.valueOf(config.townHallLevel()), "aw", Long.valueOf(battleStats[1]), "al", Long.valueOf(battleStats[2]), "dw", Long.valueOf(battleStats[3]), "dl", Long.valueOf(battleStats[4]), "clan", null);
        Map<String, Object> allianceBlock = config.allianceBlock();
        if (allianceBlock != null) {
            map.put("clan", Py.map("id", allianceBlock.get("id"), "name", allianceBlock.get("name"), "badge", allianceBlock.get("badge")));
        }
        Iterator it2 = arrayList.iterator();
        while (it2.hasNext()) {
            if (Py.lv(((Map) it2.next()).get("trophies")) > j) {
                i++;
            }
        }
        arrayList.add(i, map);
        return arrayList;
    }

    static void writeRankingEntry(Cipher.Writer writer, long j, Map<String, Object> map) {
        long lv = Py.lv(map.get("id"));
        long lv2 = Py.lv(map.get("trophies"));
        writer.writeLong(lv).writeString((String) map.get("name"));
        writer.writeInt(j).writeInt(lv2).writeInt(j);
        writer.writeInt(Py.lv(map.get("level"))).writeInt(Py.lv(map.get("aw"))).writeInt(Py.lv(map.get("al"))).writeInt(Py.lv(map.get("dw"))).writeInt(Py.lv(map.get("dl")));
        writer.writeInt(leagueFor(lv2));
        writer.writeString("");
        writer.writeLong(lv);
        Object obj = map.get("clan");
        boolean[] zArr = new boolean[1];
        zArr[0] = obj != null;
        writer.writeFlags(zArr);
        if (obj != null) {
            Map<String, Object> asMap = Py.asMap(obj);
            writer.writeLong(Py.lv(asMap.get("id"))).writeString((String) asMap.get("name")).writeInt(Py.lv(asMap.get("badge")));
        }
    }

    static byte[] buildAvatarRanking(Config config) {
        List<Map<String, Object>> rankingRows = rankingRows(config);
        int min = (int) Math.min(200L, rankingRows.size());
        ArrayList arrayList = new ArrayList();
        boolean z = false;
        for (int i = 0; i < min; i++) {
            arrayList.add(Integer.valueOf(i));
            if (Py.lv(rankingRows.get(i).get("id")) == 1) {
                z = true;
            }
        }
        if (!z) {
            for (int i2 = 0; i2 < rankingRows.size(); i2++) {
                if (Py.lv(rankingRows.get(i2).get("id")) == 1) {
                    arrayList.add(Integer.valueOf(i2));
                }
            }
        }
        Cipher.Writer writer = new Cipher.Writer();
        writer.writeInt(arrayList.size());
        Iterator it = arrayList.iterator();
        while (it.hasNext()) {
            int intValue = ((Integer) it.next()).intValue();
            writeRankingEntry(writer, intValue + 1, rankingRows.get(intValue));
        }
        return writer.toBytes();
    }

    static String avatarName(long j, Config config) {
        Map<String, Object> rosterEntry = rosterEntry(j);
        if (rosterEntry != null) {
            return (String) rosterEntry.get("name");
        }
        return config.name;
    }

    static byte[] buildEnemyHome(Map<String, Object> map, Config config, long j) {
        Cipher.Writer writer = new Cipher.Writer();
        long lv = Py.lv(map.get("id"));
        long lv2 = Py.lv(map.get("level"));
        writer.writeInt(0L);
        writer.writeInt(0L).writeLong(lv).writeString((String) map.get("json"));
        writer.writeInt(0L).writeInt(0L).writeInt(0L);
        AvatarOptions avatarOptions = new AvatarOptions();
        avatarOptions.balance = new long[]{Py.lv(map.get("gold")), Py.lv(map.get("elixir")), 0, 0, Py.lv(map.get("gold_cap")), Py.lv(map.get("elixir_cap")), 0};
        avatarOptions.experience = new long[]{4 * lv2, 0};
        avatarOptions.townHall = Long.valueOf(lv2 - 1);
        avatarOptions.heroes = (Map) map.get("heroes");
        Object obj = map.get("score");
        avatarOptions.stats = new long[]{obj != null ? Py.lv(obj) : 0L, 0, 0, 0, 0};
        writeAvatar(writer, lv, (String) map.get("name"), config, Collections.emptyList(), avatarOptions);
        AvatarOptions avatarOptions2 = new AvatarOptions();
        avatarOptions2.units = config.army();
        avatarOptions2.stars = config.starSlots();
        avatarOptions2.loot = config.lootSlots();
        avatarOptions2.achievements = config.achievementRefs();
        writeAvatar(writer, j, config.name, config, config.missions(), avatarOptions2);
        writer.writeInt(3L);
        writer.writeFlags(false);
        return writer.toBytes();
    }

    static synchronized List<Map<String, Object>> dummyClans() {
        synchronized (Builders.class) {
            List<Map<String, Object>> list = DUMMY_CLAN_CACHE;
            if (!list.isEmpty()) {
                return list;
            }
            List<Map<String, Object>> roster = roster();
            ArrayList arrayList = new ArrayList();
            for (Map<String, Object> map : roster) {
                if (map.get("clan") == null && Py.lv(map.get("id")) != 50) {
                    arrayList.add(Long.valueOf(Py.lv(map.get("id"))));
                }
            }
            for (int i = 0; i < DUMMY_CLAN_NAMES.length; i++) {
                long j = i + 700100;
                ArrayList arrayList2 = new ArrayList();
                for (Map<String, Object> map2 : roster) {
                    Object obj = map2.get("clan");
                    if (obj != null && Py.lv(Py.asMap(obj).get("id")) == j) {
                        arrayList2.add(map2.get("id"));
                    }
                }
                while (arrayList2.size() < 6 && !arrayList.isEmpty()) {
                    arrayList2.add(arrayList.remove(arrayList.size() - 1));
                }
                long lv = Py.lv(arrayList2.get(0));
                long lv2 = Py.lv(rosterEntry(lv).get("trophies"));
                for (int i2 = 1; i2 < arrayList2.size(); i2++) {
                    long lv3 = Py.lv(arrayList2.get(i2));
                    long lv4 = Py.lv(rosterEntry(lv3).get("trophies"));
                    if (lv4 > lv2) {
                        lv2 = lv4;
                        lv = lv3;
                    }
                }
                DUMMY_CLAN_CACHE.add(Py.map("id", Long.valueOf(j), "name", DUMMY_CLAN_NAMES[i], "badge", Long.valueOf(DUMMY_CLAN_BADGES[i] + 13000000), "text", Data.DUMMY_CLAN_TEXTS[i % Data.DUMMY_CLAN_TEXTS.length], "kind", 1L, "required", 0L, "members", arrayList2, "leader", Long.valueOf(lv)));
            }
            return DUMMY_CLAN_CACHE;
        }
    }

    static Map<String, Object> dummyClan(long j) {
        for (Map<String, Object> map : dummyClans()) {
            if (Py.lv(map.get("id")) == j) {
                return map;
            }
        }
        return null;
    }

    static Map<String, Object> memberRow(Config config, Map<String, Object> map, long j) {
        if (j == 1) {
            return Py.map("id", Long.valueOf(j), "name", config.name, "role", map.get("role"), "level", Long.valueOf(config.experience()[0]), "trophies", Long.valueOf(config.battleStats()[0]), "donated", 0L, "received", 0L);
        }
        Map<String, Object> rosterEntry = rosterEntry(j);
        if (rosterEntry == null) {
            return null;
        }
        boolean z = Py.truthy(map.get("dummy_id")) && map.get("leader") != null && j == Py.lv(map.get("leader"));
        Object[] objArr = new Object[14];
        objArr[0] = "id";
        objArr[1] = Long.valueOf(j);
        objArr[2] = "name";
        objArr[3] = rosterEntry.get("name");
        objArr[4] = "role";
        objArr[5] = Long.valueOf(z ? 2L : 1L);
        objArr[6] = "level";
        objArr[7] = rosterEntry.get("level");
        objArr[8] = "trophies";
        objArr[9] = rosterEntry.get("trophies");
        objArr[10] = "donated";
        objArr[11] = Long.valueOf(Py.fmod(37 * j, 300L));
        objArr[12] = "received";
        objArr[13] = Long.valueOf(Py.fmod(53 * j, 250L));
        return Py.map(objArr);
    }

    static List<Map<String, Object>> memberRows(Config config, Map<String, Object> map) {
        ArrayList arrayList = new ArrayList();
        arrayList.add(memberRow(config, map, 1L));
        Iterator<Object> it = Py.asList(map.get("members")).iterator();
        while (it.hasNext()) {
            Map<String, Object> memberRow = memberRow(config, map, Py.lv(it.next()));
            if (memberRow != null) {
                arrayList.add(memberRow);
            }
        }
        Collections.sort(arrayList, new Comparator<Map<String, Object>>() { // from class: com.nara.server.Builders.3
            @Override // java.util.Comparator
            public int compare(Map<String, Object> map2, Map<String, Object> map3) {
                return ((-Py.lv(map2.get("trophies"))) > (-Py.lv(map3.get("trophies"))) ? 1 : ((-Py.lv(map2.get("trophies"))) == (-Py.lv(map3.get("trophies"))) ? 0 : -1));
            }
        });
        for (int i = 0; i < arrayList.size(); i++) {
            Map map2 = (Map) arrayList.get(i);
            long j = i + 1;
            map2.put("order", Long.valueOf(j));
            map2.put("previous", Long.valueOf(j));
        }
        return arrayList;
    }

    static void writeMember(Cipher.Writer writer, Map<String, Object> map) {
        long lv = Py.lv(map.get("id"));
        long lv2 = Py.lv(map.get("trophies"));
        writer.writeLong(lv).writeString("").writeString((String) map.get("name"));
        writer.writeInt(Py.lv(map.get("role"))).writeInt(Py.lv(map.get("level"))).writeInt(leagueFor(lv2)).writeInt(lv2);
        writer.writeInt(Py.lv(map.get("donated"))).writeInt(Py.lv(map.get("received"))).writeInt(Py.lv(map.get("order"))).writeInt(Py.lv(map.get("previous")));
        writer.writeFlags(false, true);
        writer.writeLong(lv);
    }

    static void writeHeader(Cipher.Writer writer, Map<String, Object> map) {
        writer.writeLong(Py.lv(map.get("id"))).writeString((String) map.get("name")).writeInt(Py.lv(map.get("badge")));
        writer.writeInt(Py.lv(map.get("kind"))).writeInt(Py.lv(map.get("count"))).writeInt(Py.lv(map.get("score"))).writeInt(Py.lv(map.get("required")));
    }

    static Map<String, Object> clanInfo(Map<String, Object> map, List<Map<String, Object>> list) {
        Iterator<Map<String, Object>> it = list.iterator();
        long j = 0;
        while (it.hasNext()) {
            j += Py.lv(it.next().get("trophies"));
        }
        return Py.map("id", map.get("id"), "name", map.get("name"), "badge", map.get("badge"), "kind", map.get("kind"), "required", map.get("required"), "text", map.get("text"), "count", Long.valueOf(list.size()), "score", Long.valueOf(Py.fdiv(j, 2L)));
    }

    static List<Map<String, Object>> dummyClanRows(Map<String, Object> map) {
        int i;
        long lv = Py.lv(map.get("leader"));
        ArrayList arrayList = new ArrayList();
        Iterator<Object> it = Py.asList(map.get("members")).iterator();
        while (true) {
            long j = 1;
            if (!it.hasNext()) {
                break;
            }
            long lv2 = Py.lv(it.next());
            Map<String, Object> rosterEntry = rosterEntry(lv2);
            Object[] objArr = new Object[14];
            objArr[0] = "id";
            objArr[1] = Long.valueOf(lv2);
            objArr[2] = "name";
            objArr[3] = rosterEntry.get("name");
            objArr[4] = "role";
            if (lv2 == lv) {
                j = 2;
            }
            objArr[5] = Long.valueOf(j);
            objArr[6] = "level";
            objArr[7] = rosterEntry.get("level");
            objArr[8] = "trophies";
            objArr[9] = rosterEntry.get("trophies");
            objArr[10] = "donated";
            objArr[11] = Long.valueOf(Py.fmod(37 * lv2, 300L));
            objArr[12] = "received";
            objArr[13] = Long.valueOf(Py.fmod(lv2 * 53, 250L));
            arrayList.add(Py.map(objArr));
        }
        Collections.sort(arrayList, new Comparator<Map<String, Object>>() { // from class: com.nara.server.Builders.4
            @Override // java.util.Comparator
            public int compare(Map<String, Object> map2, Map<String, Object> map3) {
                return ((-Py.lv(map2.get("trophies"))) > (-Py.lv(map3.get("trophies"))) ? 1 : ((-Py.lv(map2.get("trophies"))) == (-Py.lv(map3.get("trophies"))) ? 0 : -1));
            }
        });
        for (i = 0; i < arrayList.size(); i++) {
            Map map2 = (Map) arrayList.get(i);
            long j2 = i + 1;
            map2.put("order", Long.valueOf(j2));
            map2.put("previous", Long.valueOf(j2));
        }
        return arrayList;
    }

    static byte[] buildFullEntry(Map<String, Object> map, List<Map<String, Object>> list) {
        Cipher.Writer writer = new Cipher.Writer();
        writeHeader(writer, map);
        writer.writeString((String) map.get("text")).writeInt(list.size());
        Iterator<Map<String, Object>> it = list.iterator();
        while (it.hasNext()) {
            writeMember(writer, it.next());
        }
        return writer.toBytes();
    }

    static byte[] buildAllianceData(Config config) {
        Map<String, Object> allianceBlock = config.allianceBlock();
        List<Map<String, Object>> memberRows = memberRows(config, allianceBlock);
        return buildFullEntry(clanInfo(allianceBlock, memberRows), memberRows);
    }

    static byte[] buildDummyAllianceData(Map<String, Object> map) {
        List<Map<String, Object>> dummyClanRows = dummyClanRows(map);
        return buildFullEntry(clanInfo(map, dummyClanRows), dummyClanRows);
    }

    static List<Map<String, Object>> dummyHeaders(String str) {
        String lowerCase = Py.strip(str).toLowerCase(Locale.ROOT);
        ArrayList arrayList = new ArrayList();
        for (Map<String, Object> map : dummyClans()) {
            String lowerCase2 = ((String) map.get("name")).toLowerCase(Locale.ROOT);
            if (lowerCase.isEmpty() || lowerCase2.contains(lowerCase)) {
                arrayList.add(clanInfo(map, dummyClanRows(map)));
            }
        }
        return arrayList;
    }

    static byte[] buildJoinableList() {
        List<Map<String, Object>> dummyHeaders = dummyHeaders("");
        Cipher.Writer writer = new Cipher.Writer();
        writer.writeInt(dummyHeaders.size());
        Iterator<Map<String, Object>> it = dummyHeaders.iterator();
        while (it.hasNext()) {
            writeHeader(writer, it.next());
        }
        return writer.toBytes();
    }

    static byte[] buildSearchResult(String str) {
        List<Map<String, Object>> dummyHeaders = dummyHeaders(str);
        Cipher.Writer writer = new Cipher.Writer();
        writer.writeString(str).writeInt(dummyHeaders.size());
        Iterator<Map<String, Object>> it = dummyHeaders.iterator();
        while (it.hasNext()) {
            writeHeader(writer, it.next());
        }
        return writer.toBytes();
    }

    static byte[] buildAllianceRanking(Config config) {
        List<Map<String, Object>> dummyHeaders = dummyHeaders("");
        Map<String, Object> allianceBlock = config.allianceBlock();
        if (allianceBlock != null && !Py.truthy(allianceBlock.get("dummy_id"))) {
            dummyHeaders.add(clanInfo(allianceBlock, memberRows(config, allianceBlock)));
        }
        Collections.sort(dummyHeaders, new Comparator<Map<String, Object>>() { // from class: com.nara.server.Builders.5
            @Override // java.util.Comparator
            public int compare(Map<String, Object> map, Map<String, Object> map2) {
                return ((-Py.lv(map.get("score"))) > (-Py.lv(map2.get("score"))) ? 1 : ((-Py.lv(map.get("score"))) == (-Py.lv(map2.get("score"))) ? 0 : -1));
            }
        });
        Cipher.Writer writer = new Cipher.Writer();
        writer.writeInt(dummyHeaders.size());
        for (int i = 0; i < dummyHeaders.size(); i++) {
            Map<String, Object> map = dummyHeaders.get(i);
            long j = i + 1;
            writer.writeLong(Py.lv(map.get("id"))).writeString((String) map.get("name"));
            writer.writeInt(j).writeInt(Py.lv(map.get("score"))).writeInt(j);
            writer.writeInt(Py.lv(map.get("badge"))).writeInt(Py.lv(map.get("count")));
        }
        writer.writeInt(0L).writeInt(0L);
        return writer.toBytes();
    }

    static Map<String, Object> streamSender(Config config, Map<String, Object> map, long j) {
        if (j == 1) {
            return Py.map("id", Long.valueOf(j), "name", config.name, "level", Long.valueOf(config.experience()[0]), "league", Long.valueOf(leagueFor(config.battleStats()[0])), "role", map.get("role"));
        }
        Map<String, Object> rosterEntry = rosterEntry(j);
        if (rosterEntry == null) {
            return Py.map("id", Long.valueOf(j), "name", "Nara", "level", 1L, "league", 0L, "role", 1L);
        }
        boolean z = Py.truthy(map.get("dummy_id")) && map.get("leader") != null && j == Py.lv(map.get("leader"));
        Object[] objArr = new Object[10];
        objArr[0] = "id";
        objArr[1] = Long.valueOf(j);
        objArr[2] = "name";
        objArr[3] = rosterEntry.get("name");
        objArr[4] = "level";
        objArr[5] = rosterEntry.get("level");
        objArr[6] = "league";
        objArr[7] = Long.valueOf(leagueFor(Py.lv(rosterEntry.get("trophies"))));
        objArr[8] = "role";
        objArr[9] = Long.valueOf(z ? 2L : 1L);
        return Py.map(objArr);
    }

    static void writeStreamEntry(Cipher.Writer writer, Config config, Map<String, Object> map, Map<String, Object> map2, double d) {
        Map<String, Object> streamSender = streamSender(config, map, Py.lv(map2.get("sender")));
        long lv = Py.lv(map2.get(ServerProtocol.DIALOG_PARAM_TYPE));
        long lv2 = Py.lv(streamSender.get("id"));
        writer.writeInt(lv);
        writer.writeLong(Py.lv(map2.get("id"))).writeLong(lv2).writeLong(lv2).writeString((String) streamSender.get("name"));
        writer.writeInt(Py.lv(streamSender.get("level"))).writeInt(Py.lv(streamSender.get("league"))).writeInt(Py.lv(streamSender.get("role"))).writeInt(Math.max(0L, (long) (d - Py.dv(map2.get("time")))));
        writer.writeFlags(false);
        if (lv == 2) {
            writer.writeString((String) map2.get("text"));
            return;
        }
        if (lv == 4) {
            Map<String, Object> streamSender2 = streamSender(config, map, Py.lv(map2.get("target")));
            writer.writeInt(Py.lv(map2.get("event"))).writeLong(Py.lv(streamSender2.get("id"))).writeString((String) streamSender2.get("name"));
            return;
        }
        List<Object> asList = Py.asList(map2.get("castle"));
        writer.writeInt(Py.lv(asList.get(0))).writeInt(Py.lv(asList.get(1))).writeInt(Py.lv(asList.get(2)));
        List<Object> asList2 = Py.asList(map2.get("donors"));
        writer.writeInt(asList2.size());
        Iterator<Object> it = asList2.iterator();
        while (it.hasNext()) {
            List<Object> asList3 = Py.asList(it.next());
            List<Object> asList4 = Py.asList(asList3.get(1));
            writer.writeLong(Py.lv(asList3.get(0))).writeInt(asList4.size());
            Iterator<Object> it2 = asList4.iterator();
            while (it2.hasNext()) {
                writer.writeInt(Py.lv(it2.next()));
            }
        }
        String str = (String) map2.get("message");
        boolean[] zArr = new boolean[1];
        zArr[0] = (str == null || str.isEmpty()) ? false : true;
        writer.writeFlags(zArr);
        if (str == null || str.isEmpty()) {
            return;
        }
        writer.writeString(str);
    }

    static byte[] buildAttackReport(long j, String str) {
        Cipher.Writer writer = new Cipher.Writer();
        writer.writeInt(1L);
        writer.writeInt(j).writeString(str).writeString("").writeString("");
        return writer.toBytes();
    }

    static byte[] buildStreamEntryMessage(Config config, Map<String, Object> map, Map<String, Object> map2) {
        Cipher.Writer writer = new Cipher.Writer();
        writeStreamEntry(writer, config, map, map2, Py.now());
        return writer.toBytes();
    }

    static byte[] buildStreamMessage(Config config) {
        Map<String, Object> allianceBlock = config.allianceBlock();
        ArrayList arrayList = new ArrayList();
        Iterator<Object> it = Py.asList(allianceBlock.get("stream")).iterator();
        while (it.hasNext()) {
            arrayList.add(Py.asMap(it.next()));
        }
        Collections.sort(arrayList, new Comparator<Map<String, Object>>() { // from class: com.nara.server.Builders.6
            @Override // java.util.Comparator
            public int compare(Map<String, Object> map, Map<String, Object> map2) {
                return Double.compare(Py.dv(map.get("time")), Py.dv(map2.get("time")));
            }
        });
        double now = Py.now();
        Cipher.Writer writer = new Cipher.Writer();
        writer.writeInt(arrayList.size());
        Iterator it2 = arrayList.iterator();
        while (it2.hasNext()) {
            writeStreamEntry(writer, config, allianceBlock, (Map) it2.next(), now);
        }
        return writer.toBytes();
    }

    static byte[] buildMemberMessage(Config config, long j) {
        List<Map<String, Object>> memberRows = memberRows(config, config.allianceBlock());
        Cipher.Writer writer = new Cipher.Writer();
        for (Map<String, Object> map : memberRows) {
            if (Py.lv(map.get("id")) == j) {
                writeMember(writer, map);
                return writer.toBytes();
            }
        }
        return null;
    }

    static byte[] buildUnitReceived(String str, long j, long j2) {
        Cipher.Writer writer = new Cipher.Writer();
        writer.writeInt(5L).writeString(str).writeInt(j).writeInt(j2);
        writer.writeInt(0L).writeInt(0L);
        return writer.toBytes();
    }

    static byte[] buildChangeNameCommand(String str) {
        Cipher.Writer writer = new Cipher.Writer();
        writer.writeInt(3L).writeString(str);
        writer.writeInt(0L).writeInt(0L);
        return writer.toBytes();
    }

    static List<Long> pickDonation(long j, Py.Random random) {
        ArrayList arrayList = new ArrayList();
        while (j > 0) {
            ArrayList arrayList2 = new ArrayList();
            for (long j2 : Data.DONATE_POOL) {
                if (Data.UNIT_SPACE[(int) j2] <= j) {
                    arrayList2.add(Long.valueOf(j2));
                }
            }
            long longValue = ((Long) random.choice(arrayList2)).longValue();
            arrayList.add(Long.valueOf(4000000 + longValue));
            j -= Data.UNIT_SPACE[(int) longValue];
        }
        return arrayList;
    }

    static Map<String, Object> cleanAllianceExtras(Map<String, Object> map) {
        boolean z;
        LinkedHashMap linkedHashMap = new LinkedHashMap();
        Object obj = map.get("dummy_id");
        Map<String, Object> dummyClan = Py.isInt(obj) ? dummyClan(Py.lv(obj)) : null;
        if (dummyClan != null) {
            linkedHashMap.put("dummy_id", obj);
            linkedHashMap.put("leader", dummyClan.get("leader"));
        }
        Object obj2 = map.get("members");
        char c = 1;
        char c2 = 0;
        if (obj2 instanceof List) {
            ArrayList arrayList = new ArrayList();
            for (Object obj3 : Py.asList(obj2)) {
                if (Py.isInt(obj3) && rosterEntry(Py.lv(obj3)) != null) {
                    arrayList.add(obj3);
                    if (arrayList.size() >= 40) {
                        break;
                    }
                }
            }
            linkedHashMap.put("members", arrayList);
        } else {
            linkedHashMap.put("members", dummyClan != null ? new ArrayList(Py.asList(dummyClan.get("members"))) : Py.list(50L));
        }
        ArrayList arrayList2 = new ArrayList();
        Object obj4 = map.get("stream");
        long j = 1;
        if (obj4 instanceof List) {
            for (Object obj5 : Py.asList(obj4)) {
                if (obj5 instanceof Map) {
                    Map<String, Object> asMap = Py.asMap(obj5);
                    Object obj6 = asMap.get("id");
                    Object obj7 = asMap.get(ServerProtocol.DIALOG_PARAM_TYPE);
                    if (Py.isInt(obj6) && Py.isInt(obj7)) {
                        long lv = Py.lv(obj7);
                        if (lv == j || lv == 2 || lv == 4) {
                            Object obj8 = asMap.get("time");
                            Object obj9 = asMap.get("sender");
                            if (Py.isNumber(obj8) && Py.isInt(obj9)) {
                                Object[] objArr = new Object[20];
                                objArr[c2] = "id";
                                objArr[c] = obj6;
                                objArr[2] = ServerProtocol.DIALOG_PARAM_TYPE;
                                objArr[3] = obj7;
                                objArr[4] = "time";
                                objArr[5] = Double.valueOf(Py.dv(obj8));
                                objArr[6] = "sender";
                                objArr[7] = obj9;
                                objArr[8] = "text";
                                objArr[9] = "";
                                objArr[10] = "event";
                                objArr[11] = 0L;
                                objArr[12] = "target";
                                objArr[13] = obj9;
                                objArr[14] = "castle";
                                Object[] objArr2 = new Object[3];
                                objArr2[c2] = 0L;
                                objArr2[c] = 0L;
                                objArr2[2] = 0L;
                                objArr[15] = Py.list(objArr2);
                                objArr[16] = "donors";
                                objArr[17] = new ArrayList();
                                objArr[18] = "message";
                                objArr[19] = "";
                                Map<String, Object> map2 = Py.map(objArr);
                                Object obj10 = asMap.get("text");
                                if (obj10 instanceof String) {
                                    map2.put("text", Py.cpSlice((String) obj10, 600));
                                }
                                if (Py.isInt(asMap.get("event")) && Py.isInt(asMap.get("target"))) {
                                    map2.put("event", asMap.get("event"));
                                    map2.put("target", asMap.get("target"));
                                }
                                Object obj11 = asMap.get("castle");
                                if (obj11 instanceof List) {
                                    List<Object> asList = Py.asList(obj11);
                                    if (asList.size() == 3 && Py.isInt(asList.get(0)) && Py.isInt(asList.get(1)) && Py.isInt(asList.get(2))) {
                                        map2.put("castle", new ArrayList(asList));
                                    }
                                }
                                Object obj12 = asMap.get("donors");
                                if (obj12 instanceof List) {
                                    List<Object> asList2 = Py.asList(map2.get("donors"));
                                    for (Object obj13 : Py.asList(obj12)) {
                                        if (obj13 instanceof List) {
                                            List<Object> asList3 = Py.asList(obj13);
                                            if (asList3.size() == 2 && Py.isInt(asList3.get(0)) && (asList3.get(1) instanceof List)) {
                                                List<Object> asList4 = Py.asList(asList3.get(1));
                                                Iterator<Object> it = asList4.iterator();
                                                while (true) {
                                                    if (!it.hasNext()) {
                                                        z = true;
                                                        break;
                                                    }
                                                    if (!Py.isInt(it.next())) {
                                                        z = false;
                                                        break;
                                                    }
                                                }
                                                if (z) {
                                                    asList2.add(Py.list(asList3.get(0), new ArrayList(asList4.subList(0, Math.min(asList4.size(), 40)))));
                                                }
                                            }
                                        }
                                    }
                                }
                                Object obj14 = asMap.get("message");
                                if (obj14 instanceof String) {
                                    map2.put("message", Py.cpSlice((String) obj14, 120));
                                }
                                arrayList2.add(map2);
                                c = 1;
                                c2 = 0;
                            }
                            j = 1;
                        }
                    }
                }
            }
        }
        ArrayList arrayList3 = new ArrayList(arrayList2.subList(Math.max(0, arrayList2.size() - 60), arrayList2.size()));
        linkedHashMap.put("stream", arrayList3);
        Iterator it2 = arrayList3.iterator();
        long j2 = 0;
        while (it2.hasNext()) {
            long lv2 = Py.lv(Py.asMap(it2.next()).get("id"));
            if (lv2 > j2) {
                j2 = lv2;
            }
        }
        linkedHashMap.put("next_id", Long.valueOf(j2 + 1));
        return linkedHashMap;
    }

    static byte[] buildJoinOk(Config config) {
        Map<String, Object> allianceBlock = config.allianceBlock();
        Cipher.Writer writer = new Cipher.Writer();
        writer.writeLong(Py.lv(allianceBlock.get("id"))).writeString((String) allianceBlock.get("name")).writeInt(Py.lv(allianceBlock.get("badge")));
        writer.writeFlags(true);
        writer.writeInt(0L).writeInt(0L);
        return writer.toBytes();
    }

    static byte[] buildChatLine(String str, Config config) {
        Map<String, Object> allianceBlock = config.allianceBlock();
        long j = config.experience()[0];
        Cipher.Writer writer = new Cipher.Writer();
        writer.writeString(str).writeString(config.name);
        writer.writeInt(j).writeInt(leagueFor(config.battleStats()[0]));
        writer.writeLong(1L).writeLong(1L);
        boolean[] zArr = new boolean[1];
        zArr[0] = allianceBlock != null;
        writer.writeFlags(zArr);
        if (allianceBlock != null) {
            writer.writeLong(Py.lv(allianceBlock.get("id"))).writeString((String) allianceBlock.get("name")).writeInt(Py.lv(allianceBlock.get("badge")));
        }
        return writer.toBytes();
    }

    static byte[] buildBotChatLine(String str, Map<String, Object> map) {
        Object obj = map.get("clan");
        long lv = Py.lv(map.get("id"));
        Cipher.Writer writer = new Cipher.Writer();
        writer.writeString(str).writeString((String) map.get("name"));
        writer.writeInt(Py.lv(map.get("level"))).writeInt(leagueFor(Py.lv(map.get("trophies"))));
        writer.writeLong(lv).writeLong(lv);
        boolean[] zArr = new boolean[1];
        zArr[0] = obj != null;
        writer.writeFlags(zArr);
        if (obj != null) {
            Map map2 = (Map) obj;
            writer.writeLong(Py.lv(map2.get("id"))).writeString((String) map2.get("name")).writeInt(Py.lv(map2.get("badge")));
        }
        return writer.toBytes();
    }

    static byte[] buildAvatarProfile(long j, Config config) {
        Cipher.Writer writer = new Cipher.Writer();
        Map<String, Object> rosterEntry = rosterEntry(j);
        AvatarOptions rosterAvatarOptions = rosterEntry != null ? rosterAvatarOptions(rosterEntry) : new AvatarOptions();
        if (rosterAvatarOptions.achievements == null) {
            rosterAvatarOptions.achievements = config.achievementRefs();
        }
        rosterAvatarOptions.stars = config.starSlots();
        rosterAvatarOptions.loot = config.lootSlots();
        ArrayList arrayList = new ArrayList(Data.MISSIONS.length);
        for (long j2 : Data.MISSIONS) {
            arrayList.add(Long.valueOf(j2));
        }
        writeAvatar(writer, j, avatarName(j, config), config, arrayList, rosterAvatarOptions);
        writer.writeInt(0L).writeInt(0L);
        return writer.toBytes();
    }

    static byte[] buildVisitedHome(long j, Config config, long j2) {
        Map<String, Object> rosterEntry = rosterEntry(j);
        long max = Math.max(j - 100, 0L);
        String loadLevel = loadLevel(config, "townhall" + (rosterEntry != null ? Py.lv(rosterEntry.get("th")) : Py.fmod(max, 10L) + 1) + ".json");
        if (loadLevel == null) {
            loadLevel = npcJson(Py.fmod(max, 40L) + 2, config);
        }
        Cipher.Writer writer = new Cipher.Writer();
        writer.writeInt(0L);
        writer.writeInt(0L).writeLong(j).writeString(loadLevel);
        writer.writeInt(0L).writeInt(0L).writeInt(0L);
        ArrayList arrayList = new ArrayList(Data.MISSIONS.length);
        for (long j3 : Data.MISSIONS) {
            arrayList.add(Long.valueOf(j3));
        }
        writeAvatar(writer, j, avatarName(j, config), config, arrayList, rosterEntry != null ? rosterAvatarOptions(rosterEntry) : new AvatarOptions());
        writer.writeFlags(true);
        AvatarOptions avatarOptions = new AvatarOptions();
        avatarOptions.units = config.army();
        avatarOptions.stars = config.starSlots();
        avatarOptions.loot = config.lootSlots();
        avatarOptions.achievements = config.achievementRefs();
        writeAvatar(writer, j2, config.name, config, config.missions(), avatarOptions);
        return writer.toBytes();
    }

    private static int nextPosAfterString(byte[] bArr, int i) {
        int i2;
        int i3 = i + 4;
        if (i3 > bArr.length) {
            return -1;
        }
        int readIntBE = Cipher.readIntBE(bArr, i);
        if (readIntBE == -1) {
            return i3;
        }
        if (readIntBE < 0 || readIntBE > 1024 || (i2 = i3 + readIntBE) > bArr.length) {
            return -1;
        }
        return i2;
    }

    static ParsedCommand readCommand(byte[] bArr, int i, int i2) {
        String str;
        int i3;
        int nextPosAfterString;
        int i4;
        int i5;
        int readIntBE;
        Command command;
        int readIntBE2;
        int i6 = i + 4;
        Command command2 = null;
        if (i6 <= bArr.length && i2 <= 6) {
            int readIntBE3 = Cipher.readIntBE(bArr, i);
            long j = readIntBE3;
            int i7 = 0;
            if (j == 533) {
                int i8 = i6 + 4;
                if (i8 <= bArr.length && (readIntBE2 = Cipher.readIntBE(bArr, i6)) >= 1 && readIntBE2 <= 300) {
                    long j2 = readIntBE2;
                    if (i8 + (12 * j2) + 4 <= bArr.length) {
                        ArrayList arrayList = new ArrayList((readIntBE2 * 3) + 2);
                        arrayList.add(Long.valueOf(j2));
                        while (i7 < readIntBE2) {
                            arrayList.add(Long.valueOf(Cipher.readIntBE(bArr, i8)));
                            arrayList.add(Long.valueOf(Cipher.readIntBE(bArr, i8 + 4)));
                            arrayList.add(Long.valueOf(Cipher.readIntBE(bArr, i8 + 8)));
                            i8 += 12;
                            i7++;
                        }
                        arrayList.add(Long.valueOf(Cipher.readIntBE(bArr, i8)));
                        return new ParsedCommand(new Command(readIntBE3, arrayList), i8 + 4);
                    }
                }
                return null;
            }
            if (j == 529) {
                int i9 = i6 + 9;
                if (i9 > bArr.length) {
                    return null;
                }
                return new ParsedCommand(new Command(readIntBE3, Py.list(Long.valueOf(Cipher.readIntBE(bArr, i6)), Boolean.valueOf((bArr[i6 + 4] & 1) != 0), Long.valueOf(Cipher.readIntBE(bArr, i6 + 5)))), i9);
            }
            str = "";
            if (readIntBE3 != 537 && readIntBE3 != 540) {
                if (readIntBE3 == 542 || readIntBE3 == 543) {
                    int i10 = i6 + 9;
                    if (i10 <= bArr.length && (nextPosAfterString = nextPosAfterString(bArr, i10)) >= 0 && (i4 = nextPosAfterString + 4) <= bArr.length) {
                        return new ParsedCommand(new Command(readIntBE3, Py.list(Long.valueOf(Cipher.readIntBE(bArr, nextPosAfterString)))), i4);
                    }
                    return null;
                }
                if (j == 521) {
                    int i11 = i6 + 5;
                    if (i11 > bArr.length) {
                        return null;
                    }
                    int readIntBE4 = Cipher.readIntBE(bArr, i6);
                    if ((bArr[i6 + 4] & 255 & 1) != 0) {
                        ParsedCommand readCommand = readCommand(bArr, i11, i2 + 1);
                        if (readCommand == null) {
                            return null;
                        }
                        command2 = readCommand.command;
                        i11 = readCommand.nextPos;
                    }
                    return new ParsedCommand(new Command(readIntBE3, Py.list(Long.valueOf(readIntBE4), command2)), i11);
                }
                if (j == 518) {
                    int i12 = i6 + 9;
                    if (i12 > bArr.length) {
                        return null;
                    }
                    int readIntBE5 = Cipher.readIntBE(bArr, i6);
                    int readIntBE6 = Cipher.readIntBE(bArr, i6 + 4);
                    if ((bArr[i6 + 8] & 255 & 1) != 0) {
                        ParsedCommand readCommand2 = readCommand(bArr, i12, i2 + 1);
                        if (readCommand2 == null) {
                            return null;
                        }
                        command = readCommand2.command;
                        i12 = readCommand2.nextPos;
                    } else {
                        command = null;
                    }
                    int i13 = i12 + 4;
                    if (i13 > bArr.length) {
                        return null;
                    }
                    return new ParsedCommand(new Command(readIntBE3, Py.list(Long.valueOf(readIntBE5), Long.valueOf(readIntBE6), command, Long.valueOf(Cipher.readIntBE(bArr, i12)))), i13);
                }
                if (j == 511) {
                    int i14 = i6 + 5;
                    if (i14 > bArr.length) {
                        return null;
                    }
                    int readIntBE7 = Cipher.readIntBE(bArr, i6);
                    if ((bArr[i6 + 4] & 255 & 1) != 0) {
                        int i15 = i14 + 4;
                        if (i15 > bArr.length || (readIntBE = Cipher.readIntBE(bArr, i14)) < 0 || readIntBE > 256 || i15 + readIntBE > bArr.length) {
                            return null;
                        }
                        str = Py.decode(bArr, i15, readIntBE);
                        i14 += readIntBE + 4;
                    }
                    return new ParsedCommand(new Command(readIntBE3, Py.list(Long.valueOf(readIntBE7), str)), i14);
                }
                int commandSize = commandSize(readIntBE3);
                if (commandSize < 0 || (i5 = (commandSize * 4) + i6) > bArr.length) {
                    return null;
                }
                ArrayList arrayList2 = new ArrayList(commandSize);
                while (i7 < commandSize) {
                    arrayList2.add(Long.valueOf(Cipher.readIntBE(bArr, (i7 * 4) + i6)));
                    i7++;
                }
                return new ParsedCommand(new Command(readIntBE3, arrayList2), i5);
            }
            int nextPosAfterString2 = nextPosAfterString(bArr, i6);
            if (nextPosAfterString2 >= 0 && (i3 = nextPosAfterString2 + 4) <= bArr.length) {
                int readIntBE8 = Cipher.readIntBE(bArr, i6);
                return new ParsedCommand(new Command(readIntBE3, Py.list(readIntBE8 > 0 ? Py.decode(bArr, i6 + 4, readIntBE8) : "", Long.valueOf(Cipher.readIntBE(bArr, nextPosAfterString2)))), i3);
            }
        }
        return null;
    }

    static List<Command> scanCommands(byte[] bArr) {
        int readIntBE;
        ArrayList arrayList = new ArrayList();
        int i = 12;
        if (bArr.length >= 12 && (readIntBE = Cipher.readIntBE(bArr, 8)) >= 0 && readIntBE <= 64) {
            for (int i2 = 0; i2 < readIntBE; i2++) {
                ParsedCommand readCommand = readCommand(bArr, i, 0);
                if (readCommand == null) {
                    break;
                }
                arrayList.add(readCommand.command);
                i = readCommand.nextPos;
            }
        }
        return arrayList;
    }

    static String describeLogin(byte[] bArr) {
        try {
            Cipher.Reader reader = new Cipher.Reader(bArr);
            return String.format(Locale.US, "account=%d token=%s version=%d.%d.%d fingerprint=%s", Long.valueOf(reader.readLong()), Py.repr(reader.readString()), Integer.valueOf(reader.readInt()), Integer.valueOf(reader.readInt()), Integer.valueOf(reader.readInt()), Py.repr(reader.readString()));
        } catch (Exception e) {
            return "login parse failed: " + e.getMessage();
        }
    }
}
