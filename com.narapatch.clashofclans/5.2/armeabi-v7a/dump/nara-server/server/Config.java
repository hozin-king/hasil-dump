package com.nara.server;

import com.facebook.internal.ServerProtocol;
import com.nara.server.Py;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.TreeSet;

/* loaded from: /home/hatch/workspace/rea-clash-of-clans/analysis/../dump-full/classes.dex */
final class Config {
    Map<String, Object> alliance;
    long attackLost;
    long attackWon;
    List<Map<String, Object>> buildings;
    long capFloor;
    long counter;
    long dark;
    List<Map<String, Object>> decos;
    long defenseLost;
    long defenseWon;
    long elixir;
    long gems;
    long gold;
    final Levels levelDir;
    long matchLevel;
    String name;
    List<Map<String, Object>> obstacles;
    long progress;
    double shieldEnd;
    final String stage;
    double stamp;
    final File statePath;
    List<Map<String, Object>> traps;
    long trophies;
    final boolean tutorial;
    long xpPoints;
    TreeMap<Long, Long> units = new TreeMap<>();
    TreeMap<Long, Long> stars = new TreeMap<>();
    TreeMap<Long, Queue> queues = new TreeMap<>();
    TreeMap<Long, long[]> loot = new TreeMap<>();
    TreeMap<Long, Long> spells = new TreeMap<>();
    TreeMap<Long, Long> unitLevels = new TreeMap<>();
    TreeMap<Long, Long> spellLevels = new TreeMap<>();
    TreeMap<Long, Long> heroLevels = new TreeMap<>();
    TreeMap<Long, Long> heroStates = new TreeMap<>();
    TreeMap<Long, Double> heroHealth = new TreeMap<>();
    List<long[]> castleUnits = new ArrayList();
    long xpLevel = 1;
    TreeSet<Long> claimed = new TreeSet<>();
    TreeSet<Long> missionRewards = new TreeSet<>();
    long nextUid = 1;

    static boolean altar(long j) {
        return j == 1000022 || j == 1000025;
    }

    static long altarHero(long j) {
        return j == 1000022 ? 28000000L : 28000001L;
    }

    static boolean isSpell(long j) {
        return 26000000 <= j && j <= 26000005;
    }

    static final class Queue {
        double left;
        boolean leftFloat;
        List<long[]> slots = new ArrayList();

        Queue() {
        }

        void setLeft(long j) {
            this.left = j;
            this.leftFloat = false;
        }

        void subLeft(double d) {
            this.left -= d;
            this.leftFloat = true;
        }

        Object leftValue() {
            return this.leftFloat ? Double.valueOf(this.left) : Long.valueOf((long) this.left);
        }
    }

    Config(long j, long j2, long j3, String str, String str2, boolean z, Levels levels, File file) {
        this.levelDir = levels;
        this.gold = j;
        this.elixir = j2;
        this.gems = j3;
        this.name = str;
        this.stage = str2;
        this.tutorial = z;
        this.statePath = file;
        if (!z) {
            this.units.put(4000000L, 10L);
            this.units.put(4000001L, 10L);
        }
        this.stamp = Py.now();
    }

    static Map<String, Object> obj(Object obj) {
        return Py.asMap(obj);
    }

    static long data(Map<String, Object> map) {
        return Py.lv(map.get("data"));
    }

    static long lvl(Map<String, Object> map) {
        return Py.getLong(map, "lvl", 0L);
    }

    static long levelValue(long[][] jArr, long j, long j2) {
        int i = (int) j;
        if (i < 0) {
            i += jArr.length;
        }
        return jArr[i][(int) Math.max(0L, Math.min(j2, r0.length - 1))];
    }

    synchronized boolean loadState() {
        List<Map<String, Object>> list;
        Iterator<Map.Entry<String, Object>> it;
        String[] strArr;
        String[] strArr2;
        File file = this.statePath;
        if (file == null) {
            return false;
        }
        try {
            if (file.isFile() && this.statePath.length() <= 1048576) {
                Object loads = Py.loads(new String(readAll(this.statePath), Py.UTF8));
                if (!(loads instanceof Map)) {
                    return false;
                }
                Map<String, Object> asMap = Py.asMap(loads);
                Object obj = asMap.get("name");
                if ((obj instanceof String) && Py.cpLen((String) obj) > 0 && Py.cpLen((String) obj) <= 16) {
                    this.name = (String) obj;
                }
                Object obj2 = asMap.get("progress");
                if (Py.isInt(obj2)) {
                    this.progress = Math.max(0L, Math.min(Py.lv(obj2), Data.MISSIONS.length));
                }
                int i = 1;
                String[] strArr3 = {"gold", "elixir", "gems", "dark"};
                int i2 = 0;
                for (int i3 = 4; i2 < i3; i3 = 4) {
                    String str = strArr3[i2];
                    Object obj3 = asMap.get(str);
                    if (Py.isInt(obj3)) {
                        strArr2 = strArr3;
                        long max = Math.max(0L, Math.min(Py.lv(obj3), 1000000000L));
                        if (str.equals("gold")) {
                            this.gold = max;
                        } else if (str.equals("elixir")) {
                            this.elixir = max;
                        } else if (str.equals("gems")) {
                            this.gems = max;
                        } else {
                            this.dark = max;
                        }
                    } else {
                        strArr2 = strArr3;
                    }
                    i2++;
                    strArr3 = strArr2;
                }
                String[] strArr4 = {"trophies", "attack_won", "attack_lost", "defense_won", "defense_lost"};
                int i4 = 0;
                for (int i5 = 5; i4 < i5; i5 = 5) {
                    String str2 = strArr4[i4];
                    Object obj4 = asMap.get(str2);
                    if (Py.isInt(obj4)) {
                        strArr = strArr4;
                        long max2 = Math.max(0L, Math.min(Py.lv(obj4), 99999L));
                        if (str2.equals("trophies")) {
                            this.trophies = max2;
                        } else if (str2.equals("attack_won")) {
                            this.attackWon = max2;
                        } else if (str2.equals("attack_lost")) {
                            this.attackLost = max2;
                        } else if (str2.equals("defense_won")) {
                            this.defenseWon = max2;
                        } else {
                            this.defenseLost = max2;
                        }
                    } else {
                        strArr = strArr4;
                    }
                    i4++;
                    strArr4 = strArr;
                }
                Object obj5 = asMap.get("spells");
                if (obj5 instanceof Map) {
                    this.spells = new TreeMap<>();
                    for (Map.Entry<String, Object> entry : obj(obj5).entrySet()) {
                        if (Py.isDigits(entry.getKey()) && Py.isInt(entry.getValue())) {
                            long parseLong = Long.parseLong(entry.getKey());
                            long lv = Py.lv(entry.getValue());
                            if (26000000 <= parseLong && parseLong <= 26000005 && lv > 0) {
                                this.spells.put(Long.valueOf(parseLong), Long.valueOf(Math.min(lv, 200L)));
                            }
                        }
                    }
                }
                Object obj6 = asMap.get("unit_levels");
                if (obj6 instanceof Map) {
                    this.unitLevels = new TreeMap<>();
                    for (Map.Entry<String, Object> entry2 : obj(obj6).entrySet()) {
                        if (Py.isDigits(entry2.getKey()) && Py.isInt(entry2.getValue())) {
                            long parseLong2 = Long.parseLong(entry2.getKey());
                            long lv2 = Py.lv(entry2.getValue());
                            if (4000000 <= parseLong2 && parseLong2 <= 4000016 && 0 < lv2 && lv2 < 60) {
                                this.unitLevels.put(Long.valueOf(parseLong2), Long.valueOf(lv2));
                            }
                        }
                    }
                }
                Object obj7 = asMap.get("spell_levels");
                if (obj7 instanceof Map) {
                    this.spellLevels = new TreeMap<>();
                    for (Map.Entry<String, Object> entry3 : obj(obj7).entrySet()) {
                        if (Py.isDigits(entry3.getKey()) && Py.isInt(entry3.getValue())) {
                            long parseLong3 = Long.parseLong(entry3.getKey());
                            long lv3 = Py.lv(entry3.getValue());
                            if (26000000 <= parseLong3 && parseLong3 <= 26000005 && 0 < lv3 && lv3 < 20) {
                                this.spellLevels.put(Long.valueOf(parseLong3), Long.valueOf(lv3));
                            }
                        }
                    }
                }
                Object obj8 = asMap.get("hero_levels");
                if (obj8 instanceof Map) {
                    this.heroLevels = new TreeMap<>();
                    for (Map.Entry<String, Object> entry4 : obj(obj8).entrySet()) {
                        if (Py.isDigits(entry4.getKey()) && Py.isInt(entry4.getValue())) {
                            long parseLong4 = Long.parseLong(entry4.getKey());
                            long lv4 = Py.lv(entry4.getValue());
                            long j = parseLong4 - 28000000;
                            if (0 <= j && j < Data.HERO_COST.length && 0 <= lv4 && lv4 < 100) {
                                this.heroLevels.put(Long.valueOf(parseLong4), Long.valueOf(lv4));
                            }
                        }
                    }
                }
                Object obj9 = asMap.get("hero_states");
                if (obj9 instanceof Map) {
                    this.heroStates = new TreeMap<>();
                    for (Map.Entry<String, Object> entry5 : obj(obj9).entrySet()) {
                        if (Py.isDigits(entry5.getKey()) && Py.isInt(entry5.getValue())) {
                            long parseLong5 = Long.parseLong(entry5.getKey());
                            long lv5 = Py.lv(entry5.getValue());
                            long j2 = parseLong5 - 28000000;
                            if (0 <= j2 && j2 < Data.HERO_COST.length && (lv5 == 2 || lv5 == 3)) {
                                this.heroStates.put(Long.valueOf(parseLong5), Long.valueOf(lv5));
                            }
                        }
                    }
                }
                Object obj10 = asMap.get("hero_health");
                double d = 0.0d;
                if (obj10 instanceof Map) {
                    this.heroHealth = new TreeMap<>();
                    Iterator<Map.Entry<String, Object>> it2 = obj(obj10).entrySet().iterator();
                    while (it2.hasNext()) {
                        Map.Entry<String, Object> next = it2.next();
                        if (Py.isDigits(next.getKey()) && Py.isNumber(next.getValue())) {
                            long parseLong6 = Long.parseLong(next.getKey());
                            double dv = Py.dv(next.getValue());
                            long j3 = parseLong6 - 28000000;
                            if (0 <= j3) {
                                it = it2;
                                if (j3 < Data.HERO_COST.length && dv > d) {
                                    this.heroHealth.put(Long.valueOf(parseLong6), Double.valueOf(Math.min(dv, 86400.0d)));
                                }
                                it2 = it;
                                d = 0.0d;
                            }
                        }
                        it = it2;
                        it2 = it;
                        d = 0.0d;
                    }
                }
                Object obj11 = asMap.get("alliance");
                if (obj11 instanceof Map) {
                    Map<String, Object> obj12 = obj(obj11);
                    Object obj13 = obj12.get("name");
                    Object obj14 = obj12.get("text");
                    Object obj15 = obj12.get("badge");
                    Object obj16 = obj12.get("kind");
                    Object obj17 = obj12.get("required");
                    if ((obj13 instanceof String) && Py.cpLen((String) obj13) > 0 && Py.cpLen((String) obj13) <= 16 && (obj14 instanceof String) && Py.cpLen((String) obj14) <= 128 && Py.isInt(obj15) && 0 <= Py.lv(obj15) - 13000000 && Py.lv(obj15) - 13000000 < 50 && Py.isInt(obj16) && Py.isInt(obj17)) {
                        Map<String, Object> map = Py.map("name", obj13, "text", obj14, "badge", obj15, "kind", obj16, "required", obj17);
                        this.alliance = map;
                        map.putAll(Builders.cleanAllianceExtras(obj12));
                    }
                }
                Object obj18 = asMap.get("castle_units");
                if (obj18 instanceof List) {
                    ArrayList arrayList = new ArrayList();
                    for (Object obj19 : Py.asList(obj18)) {
                        if (obj19 instanceof List) {
                            List<Object> asList = Py.asList(obj19);
                            if (asList.size() == 3 && Py.isInt(asList.get(0)) && Py.isInt(asList.get(i)) && Py.isInt(asList.get(2))) {
                                long lv6 = Py.lv(asList.get(0));
                                long lv7 = Py.lv(asList.get(i));
                                long lv8 = Py.lv(asList.get(2));
                                long j4 = lv6 - 4000000;
                                if (0 <= j4 && j4 < Data.UNIT_SPACE.length && 0 <= lv7) {
                                    if (lv7 < 60 && 0 < lv8 && lv8 < 100) {
                                        arrayList.add(new long[]{lv6, lv7, lv8});
                                    }
                                }
                                i = 1;
                            }
                        }
                    }
                    if (arrayList.size() > 40) {
                        arrayList = new ArrayList(arrayList.subList(0, 40));
                    }
                    this.castleUnits = arrayList;
                }
                Object obj20 = asMap.get("xp_level");
                Object obj21 = asMap.get("xp_points");
                if (Py.isInt(obj20) && Py.isInt(obj21) && 1 <= Py.lv(obj20) && Py.lv(obj20) <= Data.XP_THRESHOLDS.length + 1 && Py.lv(obj21) >= 0) {
                    this.xpLevel = Py.lv(obj20);
                    this.xpPoints = Py.lv(obj21);
                }
                Object obj22 = asMap.get("stamp");
                if (Py.isNumber(obj22) && 0.0d < Py.dv(obj22) && Py.dv(obj22) <= Py.now()) {
                    this.stamp = Py.dv(obj22);
                }
                Object obj23 = asMap.get("units");
                if (obj23 instanceof Map) {
                    this.units = new TreeMap<>();
                    for (Map.Entry<String, Object> entry6 : obj(obj23).entrySet()) {
                        if (Py.isDigits(entry6.getKey()) && Py.isInt(entry6.getValue())) {
                            long parseLong7 = Long.parseLong(entry6.getKey());
                            long lv9 = Py.lv(entry6.getValue());
                            if (4000000 <= parseLong7 && parseLong7 <= 4000016 && lv9 > 0) {
                                this.units.put(Long.valueOf(parseLong7), Long.valueOf(Math.min(lv9, 200L)));
                            }
                        }
                    }
                }
                Object obj24 = asMap.get("stars");
                long j5 = 17000000;
                if (obj24 instanceof Map) {
                    this.stars = new TreeMap<>();
                    for (Map.Entry<String, Object> entry7 : obj(obj24).entrySet()) {
                        if (Py.isDigits(entry7.getKey()) && Py.isInt(entry7.getValue())) {
                            long parseLong8 = Long.parseLong(entry7.getKey());
                            long lv10 = Py.lv(entry7.getValue());
                            if (j5 <= parseLong8 && parseLong8 < 17000050 && lv10 > 0) {
                                this.stars.put(Long.valueOf(parseLong8), Long.valueOf(Math.min(lv10, 3L)));
                                j5 = 17000000;
                            }
                        }
                        j5 = 17000000;
                    }
                }
                Object obj25 = asMap.get("buildings");
                if (obj25 instanceof List) {
                    List<Map<String, Object>> cleanSection = Builders.cleanSection(head(Py.asList(obj25)), 1000000L, Data.BUILDING_LEVELS.length, "building");
                    if (!cleanSection.isEmpty()) {
                        this.buildings = tagEntries(cleanSection);
                    }
                }
                Object obj26 = asMap.get("obstacles");
                if (obj26 instanceof List) {
                    this.obstacles = tagEntries(Builders.cleanSection(head(Py.asList(obj26)), 8000000L, 28L, "obstacle"));
                }
                Object obj27 = asMap.get("decos");
                if (obj27 instanceof List) {
                    this.decos = tagEntries(Builders.cleanSection(head(Py.asList(obj27)), 18000000L, Data.DECO_COST.length, "deco"));
                }
                Object obj28 = asMap.get("traps");
                if (obj28 instanceof List) {
                    this.traps = tagEntries(Builders.cleanSection(head(Py.asList(obj28)), 12000000L, Data.TRAP_COST.length, "trap"));
                }
                Object obj29 = asMap.get("shield_end");
                if (Py.isNumber(obj29) && 0.0d <= Py.dv(obj29) && Py.dv(obj29) < Py.now() + 3.456E7d) {
                    this.shieldEnd = Py.dv(obj29);
                }
                Object obj30 = asMap.get("achievements");
                if (obj30 instanceof List) {
                    this.claimed = new TreeSet<>();
                    for (Object obj31 : Py.asList(obj30)) {
                        if (Py.isInt(obj31) && 0 <= Py.lv(obj31) - 23000000 && Py.lv(obj31) - 23000000 < Data.ACHIEVEMENT_GEMS.length) {
                            this.claimed.add(Long.valueOf(Py.lv(obj31)));
                        }
                    }
                }
                Object obj32 = asMap.get("mission_rewards");
                if (obj32 instanceof List) {
                    this.missionRewards = new TreeSet<>();
                    for (Object obj33 : Py.asList(obj32)) {
                        if (Py.isInt(obj33)) {
                            this.missionRewards.add(Long.valueOf(Py.lv(obj33)));
                        }
                    }
                } else if (this.tutorial && this.buildings != null) {
                    this.missionRewards = new TreeSet<>();
                    if (hasFinishedBuilding(1000003L, 0L) || this.progress >= 6) {
                        this.missionRewards.add(21000005L);
                    }
                    if (hasFinishedBuilding(1000005L, 0L) || this.progress >= 7) {
                        this.missionRewards.add(21000006L);
                    }
                    if (hasFinishedBuilding(1000001L, 1L) || this.progress >= 12) {
                        this.missionRewards.add(21000011L);
                    }
                }
                Object obj34 = asMap.get("loot");
                if (obj34 instanceof Map) {
                    this.loot = new TreeMap<>();
                    for (Map.Entry<String, Object> entry8 : obj(obj34).entrySet()) {
                        if (Py.isDigits(entry8.getKey())) {
                            long parseLong9 = Long.parseLong(entry8.getKey());
                            if (17000000 <= parseLong9 && parseLong9 < 17000050) {
                                if (entry8.getValue() instanceof List) {
                                    List<Object> asList2 = Py.asList(entry8.getValue());
                                    if (asList2.size() == 2 && Py.isInt(asList2.get(0)) && Py.lv(asList2.get(0)) >= 0 && Py.isInt(asList2.get(1)) && Py.lv(asList2.get(1)) >= 0) {
                                        this.loot.put(Long.valueOf(parseLong9), new long[]{Math.min(Py.lv(asList2.get(0)), 1000000000L), Math.min(Py.lv(asList2.get(1)), 1000000000L)});
                                    }
                                }
                            }
                        }
                    }
                }
                Object obj35 = asMap.get("queues");
                if ((obj35 instanceof Map) && (list = this.buildings) != null && !list.isEmpty()) {
                    this.queues = new TreeMap<>();
                    for (Map.Entry<String, Object> entry9 : obj(obj35).entrySet()) {
                        if (Py.isDigits(entry9.getKey()) && Long.parseLong(entry9.getKey()) < this.buildings.size()) {
                            if (entry9.getValue() instanceof Map) {
                                Map<String, Object> obj36 = obj(entry9.getValue());
                                Queue queue = new Queue();
                                Object obj37 = obj36.get("slots");
                                if (obj37 instanceof List) {
                                    List<Object> asList3 = Py.asList(obj37);
                                    for (Object obj38 : asList3.subList(0, Math.min(32, asList3.size()))) {
                                        if (obj38 instanceof List) {
                                            List<Object> asList4 = Py.asList(obj38);
                                            if (asList4.size() == 2) {
                                                if (Py.isInt(asList4.get(0)) && Py.isInt(asList4.get(1)) && validItem(Py.lv(asList4.get(0))) && 0 < Py.lv(asList4.get(1)) && Py.lv(asList4.get(1)) <= 400) {
                                                    queue.slots.add(new long[]{Py.lv(asList4.get(0)), Py.lv(asList4.get(1))});
                                                }
                                            }
                                        }
                                    }
                                }
                                Object obj39 = obj36.get("left");
                                if (!queue.slots.isEmpty()) {
                                    queue.setLeft((!Py.isInt(obj39) || Py.lv(obj39) < 0) ? 0L : Py.lv(obj39));
                                    this.queues.put(Long.valueOf(Long.parseLong(entry9.getKey())), queue);
                                }
                            }
                        }
                    }
                }
                return true;
            }
            return false;
        } catch (Py.ValueError unused) {
            return false;
        } catch (IOException unused2) {
            return false;
        }
    }

    private static List<Object> head(List<Object> list) {
        return ((long) list.size()) > 300 ? list.subList(0, 300) : list;
    }

    static byte[] readAll(File file) throws IOException {
        FileInputStream fileInputStream = new FileInputStream(file);
        try {
            int length = (int) file.length();
            byte[] bArr = new byte[length];
            int i = 0;
            while (i < length) {
                int read = fileInputStream.read(bArr, i, length - i);
                if (read < 0) {
                    break;
                }
                i += read;
            }
            if (i != length) {
                bArr = Arrays.copyOf(bArr, i);
            }
            return bArr;
        } finally {
            fileInputStream.close();
        }
    }

    private static Map<String, Object> sortedLongs(TreeMap<Long, Long> treeMap) {
        LinkedHashMap linkedHashMap = new LinkedHashMap();
        for (Map.Entry<Long, Long> entry : treeMap.entrySet()) {
            linkedHashMap.put(String.valueOf(entry.getKey()), entry.getValue());
        }
        return linkedHashMap;
    }

    private static Map<String, Object> sortedHeroHealth(TreeMap<Long, Double> treeMap) {
        LinkedHashMap linkedHashMap = new LinkedHashMap();
        for (Map.Entry<Long, Double> entry : treeMap.entrySet()) {
            if (entry.getValue().doubleValue() > 0.0d) {
                linkedHashMap.put(String.valueOf(entry.getKey()), Long.valueOf(Math.round(entry.getValue().doubleValue())));
            }
        }
        return linkedHashMap;
    }

    synchronized void save() {
        boolean z;
        if (this.statePath == null) {
            return;
        }
        ArrayList arrayList = new ArrayList();
        Iterator<long[]> it = this.castleUnits.iterator();
        while (true) {
            z = true;
            if (!it.hasNext()) {
                break;
            }
            long[] next = it.next();
            arrayList.add(Py.list(Long.valueOf(next[0]), Long.valueOf(next[1]), Long.valueOf(next[2])));
        }
        LinkedHashMap linkedHashMap = new LinkedHashMap();
        for (Map.Entry<Long, Queue> entry : this.queues.entrySet()) {
            ArrayList arrayList2 = new ArrayList();
            for (long[] jArr : entry.getValue().slots) {
                arrayList2.add(Py.list(Long.valueOf(jArr[0]), Long.valueOf(jArr[1])));
            }
            linkedHashMap.put(String.valueOf(entry.getKey()), Py.map("slots", arrayList2, "left", entry.getValue().leftValue()));
        }
        LinkedHashMap linkedHashMap2 = new LinkedHashMap();
        for (Map.Entry<Long, long[]> entry2 : this.loot.entrySet()) {
            linkedHashMap2.put(String.valueOf(entry2.getKey()), Py.list(Long.valueOf(entry2.getValue()[0]), Long.valueOf(entry2.getValue()[1])));
        }
        byte[] bytes = Py.dumps(Py.map("name", this.name, "progress", Long.valueOf(this.progress), "gold", Long.valueOf(this.gold), "elixir", Long.valueOf(this.elixir), "gems", Long.valueOf(this.gems), "dark", Long.valueOf(this.dark), "trophies", Long.valueOf(this.trophies), "castle_units", arrayList, "attack_won", Long.valueOf(this.attackWon), "attack_lost", Long.valueOf(this.attackLost), "defense_won", Long.valueOf(this.defenseWon), "defense_lost", Long.valueOf(this.defenseLost), "spells", sortedLongs(this.spells), "unit_levels", sortedLongs(this.unitLevels), "spell_levels", sortedLongs(this.spellLevels), "hero_levels", sortedLongs(this.heroLevels), "hero_states", sortedLongs(this.heroStates), "hero_health", sortedHeroHealth(this.heroHealth), "alliance", this.alliance, "xp_level", Long.valueOf(this.xpLevel), "xp_points", Long.valueOf(this.xpPoints), "stamp", Double.valueOf(this.stamp), "units", sortedLongs(this.units), "stars", sortedLongs(this.stars), "buildings", plainEntries(this.buildings), "queues", linkedHashMap, "obstacles", plainEntries(this.obstacles), "decos", plainEntries(this.decos), "traps", plainEntries(this.traps), "shield_end", Double.valueOf(this.shieldEnd), "achievements", new ArrayList(this.claimed), "mission_rewards", new ArrayList(this.missionRewards), "loot", linkedHashMap2)).getBytes(Py.UTF8);
        File parentFile = this.statePath.getParentFile();
        if (parentFile != null && !parentFile.exists()) {
            parentFile.mkdirs();
        }
        File file = new File(this.statePath.getPath() + ".tmp");
        try {
            FileOutputStream fileOutputStream = new FileOutputStream(file);
            try {
                fileOutputStream.write(bytes);
                fileOutputStream.flush();
                fileOutputStream.getFD().sync();
                fileOutputStream.close();
                file.setReadable(false, false);
                file.setReadable(true, true);
                file.setWritable(false, false);
                file.setWritable(true, true);
                if (!file.renameTo(this.statePath)) {
                    File file2 = new File(this.statePath.getPath() + ".bak");
                    file2.delete();
                    if (!this.statePath.exists() || !this.statePath.renameTo(file2)) {
                        z = false;
                    }
                    if (!file.renameTo(this.statePath)) {
                        if (z) {
                            file2.renameTo(this.statePath);
                        }
                        fileOutputStream = new FileOutputStream(this.statePath);
                        try {
                            fileOutputStream.write(bytes);
                            fileOutputStream.flush();
                            fileOutputStream.getFD().sync();
                            fileOutputStream.close();
                            file.delete();
                        } finally {
                        }
                    } else if (z) {
                        file2.delete();
                    }
                }
            } finally {
            }
        } catch (IOException unused) {
        }
    }

    List<Map<String, Object>> tagEntries(List<Map<String, Object>> list) {
        ArrayList arrayList = new ArrayList();
        if (list == null) {
            return arrayList;
        }
        Iterator<Map<String, Object>> it = list.iterator();
        while (it.hasNext()) {
            LinkedHashMap linkedHashMap = new LinkedHashMap(it.next());
            if (!linkedHashMap.containsKey("_u")) {
                linkedHashMap.put("_u", Long.valueOf(this.nextUid));
                this.nextUid++;
            }
            arrayList.add(linkedHashMap);
        }
        return arrayList;
    }

    static List<Object> plainEntries(List<Map<String, Object>> list) {
        if (list == null) {
            return null;
        }
        ArrayList arrayList = new ArrayList();
        for (Map<String, Object> map : list) {
            LinkedHashMap linkedHashMap = new LinkedHashMap();
            for (Map.Entry<String, Object> entry : map.entrySet()) {
                if (!entry.getKey().equals("_u")) {
                    Object value = entry.getValue();
                    String key = entry.getKey();
                    if ((value instanceof Map) || (value instanceof List)) {
                        value = Py.deepCopy(value);
                    }
                    linkedHashMap.put(key, value);
                }
            }
            arrayList.add(linkedHashMap);
        }
        return arrayList;
    }

    static List<Long> entryUids(List<Map<String, Object>> list) {
        ArrayList arrayList = new ArrayList();
        if (list != null) {
            Iterator<Map<String, Object>> it = list.iterator();
            while (it.hasNext()) {
                arrayList.add(Long.valueOf(Py.lv(it.next().get("_u"))));
            }
        }
        return arrayList;
    }

    static int findByUid(List<Map<String, Object>> list, long j) {
        if (list != null && j > 0) {
            for (int i = 0; i < list.size(); i++) {
                if (Py.lv(list.get(i).get("_u")) == j) {
                    return i;
                }
            }
        }
        return -1;
    }

    synchronized List<Long> buildingUids() {
        return entryUids(this.buildings);
    }

    synchronized List<Long> trapUids() {
        return entryUids(this.traps);
    }

    synchronized List<Long> decoUids() {
        return entryUids(this.decos);
    }

    synchronized List<Object> villageObstacles(Object obj) {
        if (this.obstacles == null) {
            this.obstacles = tagEntries(Builders.cleanSection(obj, 8000000L, 28L, "obstacle"));
        }
        settle(null);
        return plainEntries(this.obstacles);
    }

    synchronized List<Long> obstacleUids() {
        return entryUids(this.obstacles);
    }

    synchronized boolean clearObstacle(long j) {
        settle(null);
        int findByUid = findByUid(this.obstacles, j);
        if (findByUid < 0) {
            return false;
        }
        Map<String, Object> map = this.obstacles.get(findByUid);
        if (Py.getLong(map, "clear_t", 0L) <= 0 && hasWorkerSlot()) {
            int data = (int) (data(map) - 8000000);
            if (!trySpend(Data.OBSTACLE_RES[data], Data.OBSTACLE_COST[data])) {
                return false;
            }
            long j2 = Data.OBSTACLE_SECONDS[data];
            if (j2 > 0) {
                map.put("clear_t", Long.valueOf(j2));
            } else {
                addXp(Py.isqrt(j2));
                this.obstacles.remove(findByUid);
            }
            return true;
        }
        return false;
    }

    synchronized boolean speedUpClearing(long j) {
        settle(null);
        int findByUid = findByUid(this.obstacles, j);
        if (findByUid < 0) {
            return false;
        }
        Map<String, Object> map = this.obstacles.get(findByUid);
        if (Py.getLong(map, "clear_t", 0L) <= 0) {
            return false;
        }
        spendSpeedUpGems(Builders.speedCost(r4));
        addXp(Py.isqrt(Data.OBSTACLE_SECONDS[(int) (data(map) - 8000000)]));
        this.obstacles.remove(findByUid);
        return true;
    }

    void gain(long j, double d) {
        long max = Math.max(0L, (long) d);
        if (max <= 0) {
            return;
        }
        long[] caps = caps();
        synchronized (this) {
            try {
                if (j == 0) {
                    long j2 = this.gold;
                    this.gold = Math.max(j2, Math.min(max + j2, caps[0]));
                } else if (j == 1) {
                    long j3 = this.elixir;
                    this.elixir = Math.max(j3, Math.min(max + j3, caps[1]));
                } else if (j == 2) {
                    long max2 = Math.max(caps[2], this.capFloor);
                    if (max2 > 0) {
                        long j4 = this.dark;
                        this.dark = Math.max(j4, Math.min(max + j4, max2));
                    }
                } else if (j == 3) {
                    this.gems = Math.min(this.gems + max, 1000000000L);
                }
            } catch (Throwable th) {
                throw th;
            }
        }
    }

    boolean cancelTraining(long j, long j2, long j3) {
        long j4 = j2;
        if (!validItem(j2)) {
            return false;
        }
        long max = Math.max(1L, Math.min(j3, 50L));
        synchronized (this) {
            long[] jArr = null;
            settle(null);
            Queue queue = this.queues.get(Long.valueOf(j));
            if (queue == null) {
                return false;
            }
            if (!queue.slots.isEmpty()) {
                jArr = queue.slots.get(0);
            }
            int size = queue.slots.size() - 1;
            long j5 = 0;
            while (size >= 0) {
                long[] jArr2 = queue.slots.get(size);
                if (jArr2[0] == j4 && j5 < max) {
                    long min = Math.min(jArr2[1], max - j5);
                    jArr2[1] = jArr2[1] - min;
                    j5 += min;
                }
                size--;
                j4 = j2;
            }
            ArrayList arrayList = new ArrayList();
            for (long[] jArr3 : queue.slots) {
                if (jArr3[1] > 0) {
                    arrayList.add(jArr3);
                }
            }
            queue.slots = arrayList;
            if (queue.slots.isEmpty()) {
                this.queues.remove(Long.valueOf(j));
            } else if (jArr != queue.slots.get(0)) {
                queue.setLeft(itemTime(queue.slots.get(0)[0]));
            }
            if (j5 != 0) {
                gain(itemResource(j2), itemCost(j2) * j5);
            }
            return j5 > 0;
        }
    }

    void awardLoot(long j, double d) {
        long[] jArr = Data.NPC_LOOT[(int) (j - 17000000)];
        double d2 = jArr[0];
        Double.isNaN(d2);
        double d3 = jArr[1];
        Double.isNaN(d3);
        long[] jArr2 = {(long) (d2 * d), (long) (d3 * d)};
        synchronized (this) {
            long[] jArr3 = this.loot.containsKey(Long.valueOf(j)) ? this.loot.get(Long.valueOf(j)) : new long[]{0, 0};
            gain(0L, Math.max(0L, jArr2[0] - jArr3[0]));
            gain(1L, Math.max(0L, jArr2[1] - jArr3[1]));
            this.loot.put(Long.valueOf(j), new long[]{Math.max(jArr3[0], jArr2[0]), Math.max(jArr3[1], jArr2[1])});
        }
    }

    synchronized Object villageDecos(Object obj) {
        if (this.decos == null) {
            this.decos = tagEntries(Builders.cleanSection(obj, 18000000L, Data.DECO_COST.length, "deco"));
        }
        return plainEntries(this.decos);
    }

    synchronized Long addDeco(long j, long j2, long j3) {
        long j4 = j3 - 18000000;
        if (this.decos != null && 0 <= j4 && j4 < Data.DECO_COST.length && this.decos.size() < 300) {
            if (0 <= j && j < 50 && 0 <= j2 && j2 < 50) {
                int i = (int) j4;
                if (this.xpLevel >= Data.DECO_REQ_EXP[i]) {
                    long j5 = Data.DECO_MAX_COUNT[i];
                    if (j5 > 0 && countByData(this.decos, j3) < j5) {
                        if (!trySpend(Data.DECO_RES[i], Data.DECO_COST[i])) {
                            return null;
                        }
                        long j6 = this.nextUid;
                        this.nextUid = 1 + j6;
                        this.decos.add(Py.map("data", Long.valueOf(j3), "x", Long.valueOf(j), "y", Long.valueOf(j2), "_u", Long.valueOf(j6)));
                        return Long.valueOf(j6);
                    }
                    return null;
                }
            }
            return null;
        }
        return null;
    }

    synchronized boolean moveDeco(long j, long j2, long j3) {
        int findByUid = findByUid(this.decos, j);
        if (findByUid < 0) {
            return false;
        }
        if (0 > j2 || j2 >= 50 || 0 > j3 || j3 >= 50) {
            return false;
        }
        this.decos.get(findByUid).put("x", Long.valueOf(j2));
        this.decos.get(findByUid).put("y", Long.valueOf(j3));
        return true;
    }

    synchronized Object villageTraps(Object obj) {
        if (this.traps == null) {
            this.traps = tagEntries(Builders.cleanSection(obj, 12000000L, Data.TRAP_COST.length, "trap"));
        }
        return plainEntries(this.traps);
    }

    synchronized Long addTrap(long j, long j2, long j3) {
        long j4 = j3 - 12000000;
        if (this.traps != null && 0 <= j4 && j4 < Data.TRAP_COST.length && this.traps.size() < 300) {
            if (0 <= j && j < 50 && 0 <= j2 && j2 < 50) {
                int i = (int) j4;
                if (countByData(this.traps, j3) >= Data.TH_TRAP_CAPS[(int) Math.max(0L, Math.min(townHallLevel() - 1, Data.TH_TRAP_CAPS.length - 1))][i]) {
                    return null;
                }
                if (!trySpend(Data.TRAP_RES[i], Data.TRAP_COST[i])) {
                    return null;
                }
                long j5 = this.nextUid;
                this.nextUid = 1 + j5;
                this.traps.add(Py.map("data", Long.valueOf(j3), "lvl", 0L, "x", Long.valueOf(j), "y", Long.valueOf(j2), "_u", Long.valueOf(j5)));
                return Long.valueOf(j5);
            }
            return null;
        }
        return null;
    }

    synchronized boolean moveTrap(long j, long j2, long j3) {
        int findByUid = findByUid(this.traps, j);
        if (findByUid < 0) {
            return false;
        }
        if (0 > j2 || j2 >= 50 || 0 > j3 || j3 >= 50) {
            return false;
        }
        this.traps.get(findByUid).put("x", Long.valueOf(j2));
        this.traps.get(findByUid).put("y", Long.valueOf(j3));
        return true;
    }

    synchronized boolean buyShield(long j) {
        long j2 = j - 20000000;
        double now = Py.now();
        if (0 <= j2 && j2 < Data.SHIELD_GEMS.length) {
            int i = (int) j2;
            if (!trySpend(3L, Data.SHIELD_GEMS[i])) {
                return false;
            }
            double max = Math.max(now, this.shieldEnd);
            double d = Data.SHIELD_SECONDS[i];
            Double.isNaN(d);
            this.shieldEnd = max + d;
            return true;
        }
        return false;
    }

    synchronized long shieldSeconds() {
        return Math.max(0L, (long) (this.shieldEnd - Py.now()));
    }

    synchronized boolean claimAchievement(long j) {
        long j2 = j - 23000000;
        if (0 <= j2) {
            if (j2 < Data.ACHIEVEMENT_GEMS.length && !this.claimed.contains(Long.valueOf(j))) {
                this.claimed.add(Long.valueOf(j));
                int i = (int) j2;
                this.gems = Math.min(this.gems + Data.ACHIEVEMENT_GEMS[i], 1000000000L);
                addXp(Data.ACHIEVEMENT_XP[i]);
                return true;
            }
        }
        return false;
    }

    synchronized List<Long> achievementRefs() {
        return new ArrayList(this.claimed);
    }

    synchronized List<long[]>[] lootSlots() {
        ArrayList arrayList;
        ArrayList arrayList2;
        arrayList = new ArrayList();
        arrayList2 = new ArrayList();
        for (Map.Entry<Long, long[]> entry : this.loot.entrySet()) {
            if (entry.getValue()[0] > 0) {
                arrayList.add(new long[]{entry.getKey().longValue(), entry.getValue()[0]});
            }
        }
        for (Map.Entry<Long, long[]> entry2 : this.loot.entrySet()) {
            if (entry2.getValue()[1] > 0) {
                arrayList2.add(new long[]{entry2.getKey().longValue(), entry2.getValue()[1]});
            }
        }
        return new List[]{arrayList, arrayList2};
    }

    synchronized long[] caps() {
        List<Map<String, Object>> list = this.buildings;
        if (list != null && !list.isEmpty()) {
            long j = 0;
            long j2 = 0;
            long j3 = 0;
            long j4 = 0;
            for (Map<String, Object> map : this.buildings) {
                long lvl = lvl(map);
                if (lvl >= j) {
                    long data = data(map) - 1000000;
                    j2 += levelValue(Data.STORE_GOLD, data, lvl);
                    j3 += levelValue(Data.STORE_ELIXIR, data, lvl);
                    j4 += levelValue(Data.STORE_DARK, data, lvl);
                    j = 0;
                }
            }
            return new long[]{Math.max(j2, this.capFloor), Math.max(j3, this.capFloor), Math.max(j4, this.capFloor)};
        }
        return new long[]{Math.max(1000L, this.capFloor), Math.max(1000L, this.capFloor), this.capFloor};
    }

    long[] balance() {
        long[] jArr;
        long[] caps = caps();
        synchronized (this) {
            jArr = new long[]{this.gold, this.elixir, this.dark, this.gems, caps[0], caps[1], caps[2]};
        }
        return jArr;
    }

    synchronized void setResources(long j) {
        this.dark = j;
        this.gems = j;
        this.elixir = j;
        this.gold = j;
        this.capFloor = j;
    }

    synchronized long townHallLevel() {
        List<Map<String, Object>> list = this.buildings;
        if (list != null) {
            for (Map<String, Object> map : list) {
                if (data(map) == 1000001) {
                    return Math.max(0L, lvl(map)) + 1;
                }
            }
        }
        return 1L;
    }

    synchronized void addXp(long j) {
        if (j <= 0) {
            return;
        }
        long j2 = this.xpPoints + j;
        long j3 = this.xpLevel;
        while (true) {
            long j4 = j3 - 1;
            if (j4 >= Data.XP_THRESHOLDS.length) {
                break;
            }
            int i = (int) j4;
            if (j2 < Data.XP_THRESHOLDS[i]) {
                break;
            }
            j2 -= Data.XP_THRESHOLDS[i];
            j3++;
        }
        this.xpLevel = j3;
        this.xpPoints = j2;
    }

    synchronized long[] experience() {
        return new long[]{this.xpLevel, this.xpPoints};
    }

    synchronized boolean trySpend(long j, double d) {
        long max = Math.max(0L, (long) d);
        if (max <= 0) {
            return true;
        }
        if (j == 0) {
            long j2 = this.gold;
            if (5 + j2 < max) {
                return false;
            }
            this.gold = Math.max(0L, j2 - max);
            return true;
        }
        if (j == 1) {
            long j3 = this.elixir;
            if (5 + j3 < max) {
                return false;
            }
            this.elixir = Math.max(0L, j3 - max);
            return true;
        }
        if (j == 2) {
            long j4 = this.dark;
            if (5 + j4 < max) {
                return false;
            }
            this.dark = Math.max(0L, j4 - max);
            return true;
        }
        if (j != 3) {
            return false;
        }
        long j5 = this.gems;
        if (j5 < max) {
            return false;
        }
        this.gems = j5 - max;
        return true;
    }

    synchronized void spendSpeedUpGems(double d) {
        this.gems = Math.max(0L, this.gems - Math.max(0L, (long) d));
    }

    synchronized void spend(long j, double d) {
        long max = Math.max(0L, (long) d);
        if (j == 0) {
            this.gold = Math.max(0L, this.gold - max);
        } else if (j == 1) {
            this.elixir = Math.max(0L, this.elixir - max);
        } else if (j == 2) {
            this.dark = Math.max(0L, this.dark - max);
        } else if (j == 3) {
            this.gems = Math.max(0L, this.gems - max);
        }
    }

    long campSpace() {
        List<Map<String, Object>> list = this.buildings;
        if (list == null) {
            return 0L;
        }
        long j = 0;
        for (Map<String, Object> map : list) {
            if (data(map) == 1000000 && lvl(map) >= 0) {
                j += levelValue(new long[][]{Data.CAMP_SPACE}, 0L, lvl(map));
            }
        }
        return j;
    }

    long usedSpace() {
        long j = 0;
        for (Map.Entry<Long, Long> entry : this.units.entrySet()) {
            j += entry.getValue().longValue() * Data.UNIT_SPACE[(int) (entry.getKey().longValue() - 4000000)];
        }
        return j;
    }

    long spellSpace() {
        List<Map<String, Object>> list = this.buildings;
        if (list == null) {
            return 0L;
        }
        long j = 0;
        for (Map<String, Object> map : list) {
            if (data(map) == 1000020 && lvl(map) >= 0) {
                j += levelValue(new long[][]{Data.SPELL_CAPACITY}, 0L, lvl(map));
            }
        }
        return j;
    }

    long spellUsed() {
        long j = 0;
        for (Map.Entry<Long, Long> entry : this.spells.entrySet()) {
            j += entry.getValue().longValue() * Data.SPELL_SPACE[(int) (entry.getKey().longValue() - 26000000)];
        }
        return j;
    }

    static boolean validItem(long j) {
        return isSpell(j) || (4000000 <= j && j <= 4000016);
    }

    static long itemSpace(long j) {
        return isSpell(j) ? Data.SPELL_SPACE[(int) (j - 26000000)] : Data.UNIT_SPACE[(int) (j - 4000000)];
    }

    static long itemTime(long j) {
        return isSpell(j) ? Data.SPELL_TIME[(int) (j - 26000000)] : Data.UNIT_TIME[(int) (j - 4000000)];
    }

    static long itemResource(long j) {
        return isSpell(j) ? Data.SPELL_RES[(int) (j - 26000000)] : Data.UNIT_RES[(int) (j - 4000000)];
    }

    long itemCost(long j) {
        return isSpell(j) ? Data.SPELL_COST[(int) (j - 26000000)] : trainingCost(j);
    }

    long[][] room() {
        return new long[][]{new long[]{campSpace(), usedSpace()}, new long[]{spellSpace(), spellUsed()}};
    }

    boolean deliver(long[][] jArr, long j) {
        boolean isSpell = isSpell(j);
        long itemSpace = itemSpace(j);
        long[] jArr2 = jArr[isSpell ? 1 : 0];
        if (jArr2[1] + itemSpace > jArr2[0]) {
            return false;
        }
        TreeMap<Long, Long> treeMap = isSpell ? this.spells : this.units;
        treeMap.put(Long.valueOf(j), Long.valueOf(Math.min((treeMap.containsKey(Long.valueOf(j)) ? treeMap.get(Long.valueOf(j)).longValue() : 0L) + 1, 200L)));
        long[] jArr3 = jArr[isSpell ? 1 : 0];
        jArr3[1] = jArr3[1] + itemSpace;
        return true;
    }

    synchronized List<long[]> spellSlots() {
        ArrayList arrayList;
        arrayList = new ArrayList();
        for (Map.Entry<Long, Long> entry : this.spells.entrySet()) {
            if (entry.getValue().longValue() > 0) {
                arrayList.add(new long[]{entry.getKey().longValue(), entry.getValue().longValue()});
            }
        }
        return arrayList;
    }

    synchronized void consumeSpells(Map<Long, Long> map) {
        for (Map.Entry<Long, Long> entry : map.entrySet()) {
            long max = Math.max(0L, (this.spells.containsKey(entry.getKey()) ? this.spells.get(entry.getKey()).longValue() : 0L) - entry.getValue().longValue());
            if (max != 0) {
                this.spells.put(entry.getKey(), Long.valueOf(max));
            } else {
                this.spells.remove(entry.getKey());
            }
        }
    }

    synchronized List<long[]> heroStateSlots() {
        TreeMap treeMap;
        treeMap = new TreeMap();
        List<Map<String, Object>> list = this.buildings;
        if (list != null) {
            for (Map<String, Object> map : list) {
                if (altar(data(map)) && lvl(map) >= 0) {
                    long altarHero = altarHero(data(map));
                    treeMap.put(Long.valueOf(altarHero), Long.valueOf(this.heroStates.containsKey(Long.valueOf(altarHero)) ? this.heroStates.get(Long.valueOf(altarHero)).longValue() : 3L));
                }
            }
        }
        return pairs(treeMap);
    }

    synchronized List<long[]> heroHealthSlots() {
        TreeMap treeMap;
        treeMap = new TreeMap();
        List<Map<String, Object>> list = this.buildings;
        if (list != null) {
            for (Map<String, Object> map : list) {
                if (altar(data(map)) && lvl(map) >= 0) {
                    long altarHero = altarHero(data(map));
                    Double d = this.heroHealth.get(Long.valueOf(altarHero));
                    if (d != null && d.doubleValue() > 0.0d) {
                        treeMap.put(Long.valueOf(altarHero), Long.valueOf(Math.max(1L, (long) Math.ceil(d.doubleValue()))));
                    }
                }
            }
        }
        return pairs(treeMap);
    }

    synchronized List<long[]> heroLevelAll() {
        TreeMap treeMap;
        treeMap = new TreeMap();
        List<Map<String, Object>> list = this.buildings;
        if (list != null) {
            for (Map<String, Object> map : list) {
                if (altar(data(map))) {
                    if (lvl(map) >= 0) {
                        long altarHero = altarHero(data(map));
                        treeMap.put(Long.valueOf(altarHero), Long.valueOf(this.heroLevels.containsKey(Long.valueOf(altarHero)) ? this.heroLevels.get(Long.valueOf(altarHero)).longValue() : 0L));
                    }
                }
            }
        }
        return pairs(treeMap);
    }

    synchronized List<long[]> spellLevelSlots() {
        return pairs(this.spellLevels);
    }

    static List<long[]> pairs(Map<Long, Long> map) {
        ArrayList arrayList = new ArrayList();
        for (Map.Entry<Long, Long> entry : map.entrySet()) {
            arrayList.add(new long[]{entry.getKey().longValue(), entry.getValue().longValue()});
        }
        return arrayList;
    }

    synchronized void settle(Double d) {
        settleTimers(d);
    }

    private long producerMaxSeconds(long j, long j2) {
        long[][] producer = Builders.producer(j - 1000000);
        if (producer == null || j2 < 0) {
            return 0L;
        }
        int min = (int) Math.min(j2, producer[1].length - 1);
        long j3 = producer[1][min];
        long j4 = producer[2][min];
        if (j3 <= 0) {
            return 0L;
        }
        return Py.fdiv(j4 * 3600, j3);
    }

    private void resetProducerTimer(Map<String, Object> map) {
        long producerMaxSeconds = producerMaxSeconds(data(map), lvl(map));
        if (producerMaxSeconds > 0) {
            map.put("res_time", Long.valueOf(producerMaxSeconds));
        }
    }

    private void collectProducerEntry(Map<String, Object> map) {
        long[][] producer;
        int i;
        long j;
        long lvl = lvl(map);
        if (lvl >= 0 && (producer = Builders.producer(data(map) - 1000000)) != null && (i = (int) producer[0][0]) >= 0 && i <= 2) {
            int min = (int) Math.min(lvl, producer[1].length - 1);
            long j2 = producer[1][min];
            long j3 = producer[2][min];
            if (j2 <= 0) {
                return;
            }
            long fdiv = Py.fdiv(j3 * 3600, j2);
            long max = map.containsKey("res_time") ? Math.max(0L, Math.min(fdiv, Py.getLong(map, "res_time", fdiv))) : fdiv;
            long min2 = Math.min(j3, Py.fdiv(Math.max(0L, fdiv - max) * j2, 3600L));
            long[] caps = caps();
            if (i == 0) {
                j = this.gold;
            } else {
                j = i == 1 ? this.elixir : this.dark;
            }
            long max2 = Math.max(0L, Math.min(min2, caps[i] - j));
            if (i == 0) {
                this.gold += max2;
            } else if (i == 1) {
                this.elixir += max2;
            } else {
                this.dark += max2;
            }
            if (max2 < min2) {
                fdiv = Math.min(fdiv, max + Py.fdiv(max2 * 3600, j2));
            }
            map.put("res_time", Long.valueOf(fdiv));
        }
    }

    private boolean hasFinishedBuilding(long j, long j2) {
        List<Map<String, Object>> list = this.buildings;
        if (list == null) {
            return false;
        }
        for (Map<String, Object> map : list) {
            if (data(map) == j && lvl(map) >= j2 && Py.getLong(map, "const_t", 0L) <= 0) {
                return true;
            }
        }
        return false;
    }

    synchronized void syncTutorialRewards() {
        if (this.tutorial && this.buildings != null) {
            if (!this.missionRewards.contains(21000005L) && hasFinishedBuilding(1000002L, 0L) && hasFinishedBuilding(1000003L, 0L)) {
                this.missionRewards.add(21000005L);
                gain(1L, 1500.0d);
            }
            if (this.missionRewards.contains(21000005L) && !this.missionRewards.contains(21000006L) && hasFinishedBuilding(1000005L, 0L)) {
                this.missionRewards.add(21000006L);
                gain(0L, 1500.0d);
            }
            if (!this.missionRewards.contains(21000011L) && this.progress >= 10 && townHallLevel() >= 2 && hasFinishedBuilding(1000001L, 1L)) {
                this.missionRewards.add(21000011L);
                gain(0L, 1000.0d);
            }
        }
    }

    private void completeBuildingUpgrade(Map<String, Object> map) {
        long data = data(map) - 1000000;
        long lvl = lvl(map);
        long j = lvl < 0 ? 0L : lvl + 1;
        if (0 <= data && data < Data.BUILDING_LEVELS.length) {
            j = Math.min(j, Data.BUILDING_LEVELS[(int) data] - 1);
            addXp(Py.isqrt(levelValue(Data.BUILD_SECS, data, j)));
        }
        map.put("lvl", Long.valueOf(j));
        map.remove("const_t");
        resetProducerTimer(map);
        if (altar(data(map))) {
            long altarHero = altarHero(data(map));
            if (!this.heroLevels.containsKey(Long.valueOf(altarHero))) {
                this.heroLevels.put(Long.valueOf(altarHero), 0L);
            }
            if (!this.heroStates.containsKey(Long.valueOf(altarHero))) {
                this.heroStates.put(Long.valueOf(altarHero), 3L);
            }
        }
        syncTutorialRewards();
    }

    private boolean completeLabUpgrade(Map<String, Object> map) {
        long longValue;
        Object obj = map.get("unit_upg");
        if (!(obj instanceof Map)) {
            return false;
        }
        long lv = Py.lv(((Map) obj).get("id"));
        if (isSpell(lv)) {
            int i = (int) (lv - 26000000);
            longValue = this.spellLevels.containsKey(Long.valueOf(lv)) ? this.spellLevels.get(Long.valueOf(lv)).longValue() : 0L;
            if (i >= 0 && i < Data.SPELL_UPGRADE_SECONDS.length) {
                addXp(Py.isqrt(levelValue(Data.SPELL_UPGRADE_SECONDS, i, longValue)));
            }
            this.spellLevels.put(Long.valueOf(lv), Long.valueOf(longValue + 1));
        } else if (4000000 <= lv && lv <= 4000016) {
            int i2 = (int) (lv - 4000000);
            longValue = this.unitLevels.containsKey(Long.valueOf(lv)) ? this.unitLevels.get(Long.valueOf(lv)).longValue() : 0L;
            if (i2 >= 0 && i2 < Data.UNIT_UPGRADE_SECONDS.length) {
                addXp(Py.isqrt(levelValue(Data.UNIT_UPGRADE_SECONDS, i2, longValue)));
            }
            this.unitLevels.put(Long.valueOf(lv), Long.valueOf(longValue + 1));
        }
        map.remove("unit_upg");
        return true;
    }

    private boolean completeHeroUpgrade(Map<String, Object> map) {
        Object obj = map.get("hero_upg");
        if (!(obj instanceof Map) || !altar(data(map))) {
            return false;
        }
        Map map2 = (Map) obj;
        long altarHero = altarHero(data(map));
        int i = (int) (altarHero - 28000000);
        long longValue = this.heroLevels.containsKey(Long.valueOf(altarHero)) ? this.heroLevels.get(Long.valueOf(altarHero)).longValue() : 0L;
        this.heroLevels.put(Long.valueOf(altarHero), Long.valueOf(Math.max(longValue, Math.min(Py.isInt(map2.get("level")) ? Py.lv(map2.get("level")) : longValue + 1, Data.HERO_COST[i].length - 1))));
        this.heroStates.put(Long.valueOf(altarHero), 3L);
        this.heroHealth.remove(Long.valueOf(altarHero));
        addXp(Py.isqrt(Data.HERO_SECONDS[i][(int) Math.max(0L, Math.min(longValue, Data.HERO_SECONDS[i].length - 1))]));
        map.remove("hero_upg");
        return true;
    }

    /* JADX WARN: Removed duplicated region for block: B:45:0x00d7 A[Catch: all -> 0x0264, TryCatch #1 {all -> 0x0264, blocks: (B:38:0x0099, B:43:0x00c9, B:45:0x00d7, B:47:0x00df, B:48:0x00f9, B:49:0x0113, B:51:0x011d, B:54:0x0132, B:55:0x0137, B:56:0x0145, B:58:0x014f, B:61:0x0164, B:64:0x0169, B:63:0x0177, B:67:0x00f5, B:70:0x00a7, B:75:0x018d, B:77:0x0191, B:78:0x01a2, B:80:0x01a8, B:91:0x01c5, B:86:0x01db, B:87:0x01e9, B:95:0x01ed, B:96:0x01ef, B:98:0x01f7, B:99:0x0206, B:101:0x020c, B:108:0x0223, B:104:0x022e, B:111:0x0236, B:112:0x023a, B:114:0x0240, B:116:0x024c, B:118:0x0254), top: B:37:0x0099 }] */
    /* JADX WARN: Removed duplicated region for block: B:51:0x011d A[Catch: all -> 0x0264, TRY_LEAVE, TryCatch #1 {all -> 0x0264, blocks: (B:38:0x0099, B:43:0x00c9, B:45:0x00d7, B:47:0x00df, B:48:0x00f9, B:49:0x0113, B:51:0x011d, B:54:0x0132, B:55:0x0137, B:56:0x0145, B:58:0x014f, B:61:0x0164, B:64:0x0169, B:63:0x0177, B:67:0x00f5, B:70:0x00a7, B:75:0x018d, B:77:0x0191, B:78:0x01a2, B:80:0x01a8, B:91:0x01c5, B:86:0x01db, B:87:0x01e9, B:95:0x01ed, B:96:0x01ef, B:98:0x01f7, B:99:0x0206, B:101:0x020c, B:108:0x0223, B:104:0x022e, B:111:0x0236, B:112:0x023a, B:114:0x0240, B:116:0x024c, B:118:0x0254), top: B:37:0x0099 }] */
    /* JADX WARN: Removed duplicated region for block: B:58:0x014f A[Catch: all -> 0x0264, TRY_LEAVE, TryCatch #1 {all -> 0x0264, blocks: (B:38:0x0099, B:43:0x00c9, B:45:0x00d7, B:47:0x00df, B:48:0x00f9, B:49:0x0113, B:51:0x011d, B:54:0x0132, B:55:0x0137, B:56:0x0145, B:58:0x014f, B:61:0x0164, B:64:0x0169, B:63:0x0177, B:67:0x00f5, B:70:0x00a7, B:75:0x018d, B:77:0x0191, B:78:0x01a2, B:80:0x01a8, B:91:0x01c5, B:86:0x01db, B:87:0x01e9, B:95:0x01ed, B:96:0x01ef, B:98:0x01f7, B:99:0x0206, B:101:0x020c, B:108:0x0223, B:104:0x022e, B:111:0x0236, B:112:0x023a, B:114:0x0240, B:116:0x024c, B:118:0x0254), top: B:37:0x0099 }] */
    /* JADX WARN: Removed duplicated region for block: B:66:0x0177 A[SYNTHETIC] */
    /*
        Code decompiled incorrectly, please refer to instructions dump.
        To view partially-correct add '--show-bad-code' argument
    */
    synchronized boolean settleTimers(java.lang.Double r22) {
        /*
            Method dump skipped, instructions count: 620
            To view this dump add '--comments-level debug' option
        */
        throw new UnsupportedOperationException("Method not decompiled: com.nara.server.Config.settleTimers(java.lang.Double):boolean");
    }

    boolean advanceQueues(double d, Map<Long, Double> map) {
        long[][] room = room();
        boolean z = false;
        for (Map.Entry<Long, Queue> entry : this.queues.entrySet()) {
            Queue value = entry.getValue();
            double doubleValue = d + ((map.containsKey(entry.getKey()) ? map.get(entry.getKey()).doubleValue() : 0.0d) * 3.0d);
            while (true) {
                if (!value.slots.isEmpty() && doubleValue > 0.0d) {
                    if (doubleValue < value.left) {
                        value.subLeft(doubleValue);
                        break;
                    }
                    doubleValue -= value.left;
                    long j = 0;
                    if (!deliver(room, value.slots.get(0)[0])) {
                        value.setLeft(0L);
                        break;
                    }
                    long[] jArr = value.slots.get(0);
                    jArr[1] = jArr[1] - 1;
                    if (value.slots.get(0)[1] <= 0) {
                        value.slots.remove(0);
                    }
                    if (!value.slots.isEmpty()) {
                        j = itemTime(value.slots.get(0)[0]);
                    }
                    value.setLeft(j);
                    z = true;
                }
            }
        }
        ArrayList arrayList = new ArrayList();
        for (Map.Entry<Long, Queue> entry2 : this.queues.entrySet()) {
            if (entry2.getValue().slots.isEmpty()) {
                arrayList.add(entry2.getKey());
            }
        }
        Iterator it = arrayList.iterator();
        while (it.hasNext()) {
            this.queues.remove((Long) it.next());
        }
        return z;
    }

    long trainingCost(long j) {
        return levelValue(Data.UNIT_TRAIN_COST, j - 4000000, this.unitLevels.containsKey(Long.valueOf(j)) ? this.unitLevels.get(Long.valueOf(j)).longValue() : 0L);
    }

    synchronized Long upgradeUnit(long j, long j2) {
        settleTimers(null);
        if (this.buildings != null && 0 <= j && j < r4.size()) {
            Map<String, Object> map = this.buildings.get((int) j);
            if (data(map) == 1000007 && lvl(map) >= 0 && !map.containsKey("unit_upg")) {
                if (isSpell(j2)) {
                    int i = (int) (j2 - 26000000);
                    long longValue = this.spellLevels.containsKey(Long.valueOf(j2)) ? this.spellLevels.get(Long.valueOf(j2)).longValue() : 0L;
                    long[] jArr = Data.SPELL_UPGRADE_COST[i];
                    if (longValue < jArr.length - 1) {
                        int i2 = (int) longValue;
                        if (jArr[i2] > 0) {
                            if (!trySpend(Data.SPELL_UPGRADE_RES[i], jArr[i2])) {
                                return null;
                            }
                            long j3 = Data.SPELL_UPGRADE_SECONDS[i][i2];
                            if (j3 > 0) {
                                map.put("unit_upg", Py.map("unit_type", 1L, "t", Long.valueOf(j3), "id", Long.valueOf(j2)));
                            } else {
                                this.spellLevels.put(Long.valueOf(j2), Long.valueOf(longValue + 1));
                            }
                            return Long.valueOf(j3);
                        }
                    }
                    return null;
                }
                if (4000000 > j2 || j2 > 4000016) {
                    return null;
                }
                int i3 = (int) (j2 - 4000000);
                long longValue2 = this.unitLevels.containsKey(Long.valueOf(j2)) ? this.unitLevels.get(Long.valueOf(j2)).longValue() : 0L;
                long[] jArr2 = Data.UNIT_UPGRADE_COST[i3];
                if (longValue2 < jArr2.length - 1) {
                    int i4 = (int) longValue2;
                    if (jArr2[i4] > 0) {
                        if (!trySpend(Data.UNIT_UPGRADE_RES[i3], jArr2[i4])) {
                            return null;
                        }
                        long j4 = Data.UNIT_UPGRADE_SECONDS[i3][i4];
                        if (j4 > 0) {
                            map.put("unit_upg", Py.map("unit_type", 0L, "t", Long.valueOf(j4), "id", Long.valueOf(j2)));
                        } else {
                            this.unitLevels.put(Long.valueOf(j2), Long.valueOf(longValue2 + 1));
                        }
                        return Long.valueOf(j4);
                    }
                }
                return null;
            }
            return null;
        }
        return null;
    }

    synchronized boolean speedUpUpgradeUnit(long j) {
        settleTimers(null);
        if (this.buildings != null && 0 <= j && j < r0.size()) {
            Map<String, Object> map = this.buildings.get((int) j);
            if (!(map.get("unit_upg") instanceof Map)) {
                return false;
            }
            spendSpeedUpGems(Builders.speedCost(Math.max(0L, Py.getLong((Map) r8, "t", 0L))));
            return completeLabUpgrade(map);
        }
        return false;
    }

    synchronized boolean cancelUpgradeUnit(long j) {
        long longValue;
        settleTimers(null);
        if (this.buildings != null) {
            if (0 <= j && j < r0.size()) {
                Map<String, Object> map = this.buildings.get((int) j);
                Object obj = map.get("unit_upg");
                if (!(obj instanceof Map)) {
                    return false;
                }
                long lv = Py.lv(((Map) obj).get("id"));
                if (isSpell(lv)) {
                    int i = (int) (lv - 26000000);
                    longValue = this.spellLevels.containsKey(Long.valueOf(lv)) ? this.spellLevels.get(Long.valueOf(lv)).longValue() : 0L;
                    if (i >= 0 && i < Data.SPELL_UPGRADE_COST.length && longValue < Data.SPELL_UPGRADE_COST[i].length) {
                        long j2 = Data.SPELL_UPGRADE_RES[i];
                        double d = Data.SPELL_UPGRADE_COST[i][(int) longValue] * 50;
                        Double.isNaN(d);
                        gain(j2, d / 100.0d);
                    }
                } else if (4000000 <= lv && lv <= 4000016) {
                    int i2 = (int) (lv - 4000000);
                    longValue = this.unitLevels.containsKey(Long.valueOf(lv)) ? this.unitLevels.get(Long.valueOf(lv)).longValue() : 0L;
                    if (i2 >= 0 && i2 < Data.UNIT_UPGRADE_COST.length && longValue < Data.UNIT_UPGRADE_COST[i2].length) {
                        long j3 = Data.UNIT_UPGRADE_RES[i2];
                        double d2 = Data.UNIT_UPGRADE_COST[i2][(int) longValue] * 50;
                        Double.isNaN(d2);
                        gain(j3, d2 / 100.0d);
                    }
                }
                map.remove("unit_upg");
                return true;
            }
        }
        return false;
    }

    synchronized Long upgradeHero(long j) {
        settleTimers(null);
        if (this.buildings != null && 0 <= j && j < r4.size()) {
            Map<String, Object> map = this.buildings.get((int) j);
            long data = data(map);
            if (altar(data) && lvl(map) >= 0 && !map.containsKey("hero_upg") && hasWorkerSlot()) {
                long altarHero = altarHero(data);
                int i = (int) (altarHero - 28000000);
                long longValue = this.heroLevels.containsKey(Long.valueOf(altarHero)) ? this.heroLevels.get(Long.valueOf(altarHero)).longValue() : 0L;
                long[] jArr = Data.HERO_COST[i];
                if (longValue < jArr.length - 1) {
                    int i2 = (int) longValue;
                    if (jArr[i2] > 0) {
                        if (townHallLevel() - 1 < Data.HERO_REQUIRED_TH[i][i2]) {
                            return null;
                        }
                        if (!trySpend(2L, jArr[i2])) {
                            return null;
                        }
                        long j2 = Data.HERO_SECONDS[i][i2];
                        if (j2 > 0) {
                            map.put("hero_upg", Py.map("level", Long.valueOf(longValue + 1), "t", Long.valueOf(j2)));
                        } else {
                            this.heroLevels.put(Long.valueOf(altarHero), Long.valueOf(longValue + 1));
                        }
                        return Long.valueOf(j2);
                    }
                }
                return null;
            }
            return null;
        }
        return null;
    }

    synchronized boolean speedUpHero(long j) {
        settleTimers(null);
        if (this.buildings != null && 0 <= j && j < r0.size()) {
            Map<String, Object> map = this.buildings.get((int) j);
            if (!(map.get("hero_upg") instanceof Map)) {
                return false;
            }
            spendSpeedUpGems(Builders.speedCost(Math.max(0L, Py.getLong(Py.asMap(r8), "t", 0L))));
            return completeHeroUpgrade(map);
        }
        return false;
    }

    synchronized boolean cancelHeroUpgrade(long j) {
        settleTimers(null);
        if (this.buildings != null) {
            if (0 <= j && j < r0.size()) {
                Map<String, Object> map = this.buildings.get((int) j);
                if (altar(data(map)) && map.containsKey("hero_upg")) {
                    long altarHero = altarHero(data(map));
                    int i = (int) (altarHero - 28000000);
                    long longValue = this.heroLevels.containsKey(Long.valueOf(altarHero)) ? this.heroLevels.get(Long.valueOf(altarHero)).longValue() : 0L;
                    if (longValue < Data.HERO_COST[i].length) {
                        double d = Data.HERO_COST[i][(int) longValue] * 50;
                        Double.isNaN(d);
                        gain(2L, d / 100.0d);
                    }
                    map.remove("hero_upg");
                    return true;
                }
                return false;
            }
        }
        return false;
    }

    synchronized boolean toggleHeroSleep(long j, boolean z) {
        if (this.buildings != null && 0 <= j && j < r0.size()) {
            long data = data(this.buildings.get((int) j));
            if (!altar(data)) {
                return false;
            }
            this.heroStates.put(Long.valueOf(altarHero(data)), Long.valueOf(z ? 2L : 3L));
            return true;
        }
        return false;
    }

    synchronized boolean speedUpHeroHealth(long j) {
        settleTimers(null);
        if (this.buildings != null && 0 <= j && j < r0.size()) {
            long data = data(this.buildings.get((int) j));
            if (!altar(data)) {
                return false;
            }
            Double remove = this.heroHealth.remove(Long.valueOf(altarHero(data)));
            if (remove != null && remove.doubleValue() > 0.0d) {
                spendSpeedUpGems(Math.max(1L, Math.min(Builders.speedCost((long) Math.ceil(remove.doubleValue())), 300L)));
            }
            return true;
        }
        return false;
    }

    synchronized List<long[]> unitLevelSlots() {
        return pairs(this.unitLevels);
    }

    synchronized long[] battleStats() {
        return new long[]{this.trophies, this.attackWon, this.attackLost, this.defenseWon, this.defenseLost};
    }

    synchronized long recordBattle(long j) {
        long randint;
        long j2;
        try {
            if (j <= 0) {
                randint = -Builders.RANDOM.randint(12L, 24L);
                this.attackLost++;
            } else {
                randint = Builders.RANDOM.randint(j == 1 ? 8L : j == 2 ? 18L : 32L, j == 1 ? 16L : j == 2 ? 28L : 44L);
                this.attackWon++;
            }
            long max = Math.max(0L, this.trophies + randint);
            j2 = max - this.trophies;
            this.trophies = max;
        } catch (Throwable th) {
            throw th;
        }
        return j2;
    }

    synchronized Map<String, Object> appendEntry(Map<String, Object> map, double d) {
        Map<String, Object> map2 = this.alliance;
        if (map2 == null) {
            return null;
        }
        Object[] objArr = new Object[20];
        objArr[0] = "id";
        objArr[1] = map2.containsKey("next_id") ? this.alliance.get("next_id") : 1L;
        objArr[2] = ServerProtocol.DIALOG_PARAM_TYPE;
        objArr[3] = 2L;
        objArr[4] = "time";
        objArr[5] = Double.valueOf(Py.now() - d);
        objArr[6] = "sender";
        objArr[7] = 1L;
        objArr[8] = "text";
        objArr[9] = "";
        objArr[10] = "event";
        objArr[11] = 0L;
        objArr[12] = "target";
        objArr[13] = 1L;
        objArr[14] = "castle";
        objArr[15] = Py.list(0L, 0L, 0L);
        objArr[16] = "donors";
        objArr[17] = new ArrayList();
        objArr[18] = "message";
        objArr[19] = "";
        Map<String, Object> map3 = Py.map(objArr);
        map3.putAll(map);
        this.alliance.put("next_id", Long.valueOf(Py.lv(map3.get("id")) + 1));
        if (!this.alliance.containsKey("stream")) {
            this.alliance.put("stream", new ArrayList());
        }
        List<Object> asList = Py.asList(this.alliance.get("stream"));
        asList.add(map3);
        while (asList.size() > 60) {
            asList.remove(0);
        }
        return Py.asMap(Py.deepCopy(map3));
    }

    synchronized Map<String, Object> updateEntry(long j, Map<String, Object> map) {
        Map<String, Object> map2 = this.alliance;
        if (map2 == null) {
            return null;
        }
        Object obj = map2.get("stream");
        if (obj != null) {
            Iterator<Object> it = Py.asList(obj).iterator();
            while (it.hasNext()) {
                Map<String, Object> asMap = Py.asMap(it.next());
                if (Py.lv(asMap.get("id")) == j) {
                    asMap.putAll(map);
                    return Py.asMap(Py.deepCopy(asMap));
                }
            }
        }
        return null;
    }

    synchronized boolean changeMembers(Long l, Long l2) {
        Map<String, Object> map = this.alliance;
        if (map == null) {
            return false;
        }
        if (!map.containsKey("members")) {
            this.alliance.put("members", new ArrayList());
        }
        List<Object> asList = Py.asList(this.alliance.get("members"));
        if (l != null && !asList.contains(l)) {
            asList.add(l);
        }
        if (l2 != null && asList.contains(l2)) {
            asList.remove(l2);
        }
        return true;
    }

    boolean createAlliance(String str, String str2, long j, long j2, long j3) {
        String strip = Py.strip(str);
        if (Py.cpLen(strip) > 0 && Py.cpLen(strip) <= 16 && Py.cpLen(str2) <= 128) {
            long j4 = j - 13000000;
            if (0 <= j4 && j4 < 50) {
                synchronized (this) {
                    if (this.alliance != null) {
                        return false;
                    }
                    this.alliance = Py.map("name", strip, "text", str2, "badge", Long.valueOf(j), "kind", Long.valueOf(j2), "required", Long.valueOf(Math.max(0L, j3)), "members", Py.list(50L), "stream", new ArrayList(), "next_id", 1L);
                    appendEntry(Py.map(ServerProtocol.DIALOG_PARAM_TYPE, 4L, "sender", 50L, "event", 3L, "target", 50L), 7.0d);
                    double[] dArr = {5.0d, 4.0d, 3.0d};
                    for (int i = 0; i < 3; i++) {
                        appendEntry(Py.map(ServerProtocol.DIALOG_PARAM_TYPE, 2L, "sender", 50L, "text", Data.WELCOME_PARTS[i].replace("{name}", this.name)), dArr[i]);
                    }
                    return true;
                }
            }
        }
        return false;
    }

    synchronized boolean joinDummyAlliance(Map<String, Object> map, Py.Random random) {
        if (this.alliance != null) {
            return false;
        }
        List<Object> asList = Py.asList(map.get("members"));
        char c = 2;
        this.alliance = Py.map("name", map.get("name"), "text", map.get("text"), "badge", map.get("badge"), "kind", map.get("kind"), "required", map.get("required"), "dummy_id", map.get("id"), "leader", map.get("leader"), "members", new ArrayList(asList), "stream", new ArrayList(), "next_id", 1L);
        ArrayList arrayList = new ArrayList();
        for (Object obj : asList) {
            if (Py.lv(obj) != Py.lv(map.get("leader"))) {
                arrayList.add(obj);
            }
        }
        if (arrayList.isEmpty()) {
            arrayList = new ArrayList(asList);
        }
        ArrayList arrayList2 = new ArrayList();
        int i = 0;
        for (int i2 = 4; i < i2; i2 = 4) {
            arrayList2.add(Double.valueOf(random.uniform(300.0d, 3600.0d)));
            i++;
        }
        Collections.sort(arrayList2, Collections.reverseOrder());
        Iterator it = arrayList2.iterator();
        while (it.hasNext()) {
            appendEntry(Py.map(ServerProtocol.DIALOG_PARAM_TYPE, 2L, "sender", random.choice(arrayList), "text", random.choice(Data.CLAN_CHAT_LINES)), ((Double) it.next()).doubleValue());
        }
        appendEntry(Py.map(ServerProtocol.DIALOG_PARAM_TYPE, 4L, "sender", 1L, "event", 3L, "target", 1L), 6.0d);
        int i3 = 3;
        double[] dArr = {4.0d, 3.0d, 2.0d};
        int i4 = 0;
        while (i4 < i3) {
            Object[] objArr = new Object[6];
            objArr[0] = ServerProtocol.DIALOG_PARAM_TYPE;
            objArr[1] = 2L;
            objArr[c] = "sender";
            objArr[3] = map.get("leader");
            objArr[4] = "text";
            objArr[5] = Data.WELCOME_PARTS[i4].replace("{name}", this.name);
            appendEntry(Py.map(objArr), dArr[i4]);
            i4++;
            i3 = 3;
            c = 2;
        }
        return true;
    }

    synchronized long[] applyRaid(Py.Random random) {
        long min;
        long min2;
        long j;
        long max;
        double d = this.gold;
        double uniform = random.uniform(Data.RAID_LOOT_RANGE[0], Data.RAID_LOOT_RANGE[1]);
        Double.isNaN(d);
        min = Math.min((long) (d * uniform), 400000L);
        double d2 = this.elixir;
        double uniform2 = random.uniform(Data.RAID_LOOT_RANGE[0], Data.RAID_LOOT_RANGE[1]);
        Double.isNaN(d2);
        min2 = Math.min((long) (d2 * uniform2), 400000L);
        this.gold -= min;
        this.elixir -= min2;
        j = this.trophies;
        max = Math.max(0L, j - random.randint(Data.RAID_TROPHY_LOSS[0], Data.RAID_TROPHY_LOSS[1]));
        this.trophies = max;
        this.defenseLost++;
        return new long[]{min, min2, j - max};
    }

    synchronized boolean leaveAlliance() {
        boolean z;
        z = this.alliance != null;
        this.alliance = null;
        this.castleUnits = new ArrayList();
        return z;
    }

    synchronized Map<String, Object> allianceBlock() {
        if (this.alliance == null) {
            return null;
        }
        LinkedHashMap linkedHashMap = new LinkedHashMap(this.alliance);
        Object obj = this.alliance.get("dummy_id");
        linkedHashMap.put("id", Py.truthy(obj) ? obj : 700001L);
        linkedHashMap.put("role", Long.valueOf(Py.truthy(obj) ? 1L : 2L));
        Object obj2 = this.alliance.get("members");
        linkedHashMap.put("members", obj2 == null ? new ArrayList() : new ArrayList(Py.asList(obj2)));
        Object obj3 = this.alliance.get("stream");
        linkedHashMap.put("stream", obj3 == null ? new ArrayList() : Py.deepCopy(obj3));
        return linkedHashMap;
    }

    synchronized long[] castleInfo() {
        List<Map<String, Object>> list = this.buildings;
        if (list != null) {
            for (Map<String, Object> map : list) {
                Object obj = map.get("data");
                if (obj != null && Py.lv(obj) == 1000014) {
                    long j = 0;
                    if (lvl(map) >= 0 && !Py.truthy(map.get("locked"))) {
                        int max = (int) Math.max(0L, Math.min(lvl(map), Data.CASTLE_CAPACITY.length - 1));
                        for (long[] jArr : this.castleUnits) {
                            long j2 = jArr[2];
                            long j3 = Data.UNIT_SPACE[(int) (jArr[0] - 4000000)];
                            Long.signum(j2);
                            j += j2 * j3;
                        }
                        return new long[]{max, Data.CASTLE_CAPACITY[max], j};
                    }
                }
            }
        }
        return new long[]{0, 0, 0};
    }

    synchronized List<long[]> castleSlots() {
        ArrayList arrayList;
        arrayList = new ArrayList();
        for (long[] jArr : this.castleUnits) {
            arrayList.add(new long[]{jArr[0], jArr[1], jArr[2]});
        }
        return arrayList;
    }

    synchronized void addCastleUnit(long j, long j2) {
        for (long[] jArr : this.castleUnits) {
            if (jArr[0] == j && jArr[1] == j2) {
                jArr[2] = jArr[2] + 1;
                return;
            }
        }
        this.castleUnits.add(new long[]{j, j2, 1});
    }

    boolean train(long j, long j2, long j3) {
        long j4;
        long j5;
        if (!validItem(j2)) {
            return false;
        }
        long max = Math.max(1L, Math.min(j3, 100L));
        synchronized (this) {
            List<Map<String, Object>> list = this.buildings;
            if (list != null && !list.isEmpty() && 0 <= j && j < this.buildings.size()) {
                if (lvl(this.buildings.get((int) j)) < 0) {
                    return false;
                }
                settleTimers(null);
                long itemResource = itemResource(j2);
                long itemCost = itemCost(j2);
                Queue queue = this.queues.get(Long.valueOf(j));
                if (queue == null || queue.slots.isEmpty()) {
                    j4 = 0;
                } else {
                    Iterator<long[]> it = queue.slots.iterator();
                    j4 = 0;
                    while (it.hasNext()) {
                        j4 += it.next()[1];
                    }
                }
                long j6 = 0;
                int i = 0;
                while (j6 < max && j4 < 400) {
                    long j7 = max;
                    if (!trySpend(itemResource, itemCost)) {
                        break;
                    }
                    if (queue == null) {
                        queue = new Queue();
                        this.queues.put(Long.valueOf(j), queue);
                    }
                    if (queue.slots.isEmpty()) {
                        queue.setLeft(itemTime(j2));
                    }
                    if (!queue.slots.isEmpty() && queue.slots.get(queue.slots.size() - 1)[0] == j2) {
                        long[] jArr = queue.slots.get(queue.slots.size() - 1);
                        jArr[1] = jArr[1] + 1;
                        j5 = 1;
                    } else {
                        j5 = 1;
                        queue.slots.add(new long[]{j2, 1});
                    }
                    j4 += j5;
                    i++;
                    j6 += j5;
                    max = j7;
                }
                return i > 0;
            }
            return false;
        }
    }

    double queueSeconds(Queue queue) {
        double d = queue.left;
        int i = 0;
        while (i < queue.slots.size()) {
            long[] jArr = queue.slots.get(i);
            double itemTime = itemTime(jArr[0]) * (i == 0 ? jArr[1] - 1 : jArr[1]);
            Double.isNaN(itemTime);
            d += itemTime;
            i++;
        }
        return d;
    }

    synchronized boolean speedUpTraining(long j) {
        long j2;
        settle(null);
        Queue queue = this.queues.get(Long.valueOf(j));
        if (queue != null && !queue.slots.isEmpty()) {
            spend(3L, Builders.speedCost((long) queueSeconds(queue)));
            long[][] room = room();
            while (true) {
                j2 = 0;
                if (queue.slots.isEmpty() || !deliver(room, queue.slots.get(0)[0])) {
                    break;
                }
                long[] jArr = queue.slots.get(0);
                jArr[1] = jArr[1] - 1;
                if (queue.slots.get(0)[1] <= 0) {
                    queue.slots.remove(0);
                }
            }
            if (!queue.slots.isEmpty()) {
                j2 = itemTime(queue.slots.get(0)[0]);
            }
            queue.setLeft(j2);
            if (queue.slots.isEmpty()) {
                this.queues.remove(Long.valueOf(j));
            }
            return true;
        }
        return false;
    }

    synchronized boolean collect(long j) {
        List<Map<String, Object>> list = this.buildings;
        if (list != null && !list.isEmpty() && 0 <= j && j < this.buildings.size()) {
            settleTimers(null);
            Map<String, Object> map = this.buildings.get((int) j);
            if (lvl(map) < 0) {
                return false;
            }
            long[][] producer = Builders.producer(data(map) - 1000000);
            if (producer == null) {
                return false;
            }
            int i = (int) producer[0][0];
            if (i >= 0 && i <= 2) {
                if (producer[1][(int) Math.min(lvl(map), producer[1].length - 1)] <= 0) {
                    return false;
                }
                collectProducerEntry(map);
                return true;
            }
            return false;
        }
        return false;
    }

    static long countByData(List<Map<String, Object>> list, long j) {
        long j2 = 0;
        if (list == null) {
            return 0L;
        }
        Iterator<Map<String, Object>> it = list.iterator();
        while (it.hasNext()) {
            if (data(it.next()) == j) {
                j2++;
            }
        }
        return j2;
    }

    private long shortestWorkerTaskSeconds() {
        List<Map<String, Object>> list = this.buildings;
        long j = Long.MAX_VALUE;
        if (list != null) {
            for (Map<String, Object> map : list) {
                long j2 = Py.getLong(map, "const_t", 0L);
                if (j2 > 0 && j2 < j) {
                    j = j2;
                }
                Object obj = map.get("hero_upg");
                if (obj instanceof Map) {
                    long j3 = Py.getLong(Py.asMap(obj), "t", 0L);
                    if (j3 > 0 && j3 < j) {
                        j = j3;
                    }
                }
            }
        }
        List<Map<String, Object>> list2 = this.obstacles;
        if (list2 != null) {
            Iterator<Map<String, Object>> it = list2.iterator();
            while (it.hasNext()) {
                long j4 = Py.getLong(it.next(), "clear_t", 0L);
                if (j4 > 0 && j4 < j) {
                    j = j4;
                }
            }
        }
        return j;
    }

    private long activeWorkerCount() {
        long j;
        List<Map<String, Object>> list = this.buildings;
        if (list != null) {
            j = 0;
            for (Map<String, Object> map : list) {
                if (Py.getLong(map, "const_t", 0L) > 0 || (map.get("hero_upg") instanceof Map)) {
                    j++;
                }
            }
        } else {
            j = 0;
        }
        List<Map<String, Object>> list2 = this.obstacles;
        if (list2 != null) {
            Iterator<Map<String, Object>> it = list2.iterator();
            while (it.hasNext()) {
                if (Py.getLong(it.next(), "clear_t", 0L) > 0) {
                    j++;
                }
            }
        }
        return j;
    }

    synchronized boolean hasWorkerSlot() {
        if (activeWorkerCount() < Math.max(1L, countByData(this.buildings, 1000015L))) {
            return true;
        }
        if (shortestWorkerTaskSeconds() > 5) {
            return false;
        }
        return finishShortestWorkerTask(true);
    }

    synchronized boolean freeWorker() {
        settleTimers(null);
        return finishShortestWorkerTask(false);
    }

    private boolean finishShortestWorkerTask(boolean z) {
        char c;
        int i = -1;
        long j = Long.MAX_VALUE;
        if (this.buildings != null) {
            c = 0;
            for (int i2 = 0; i2 < this.buildings.size(); i2++) {
                Map<String, Object> map = this.buildings.get(i2);
                long j2 = Py.getLong(map, "const_t", 0L);
                if (j2 > 0 && j2 < j) {
                    i = i2;
                    j = j2;
                    c = 1;
                }
                Object obj = map.get("hero_upg");
                if (obj instanceof Map) {
                    long j3 = Py.getLong(Py.asMap(obj), "t", 0L);
                    if (j3 > 0 && j3 < j) {
                        i = i2;
                        j = j3;
                        c = 2;
                    }
                }
            }
        } else {
            c = 0;
        }
        if (this.obstacles != null) {
            for (int i3 = 0; i3 < this.obstacles.size(); i3++) {
                long j4 = Py.getLong(this.obstacles.get(i3), "clear_t", 0L);
                if (j4 > 0 && j4 < j) {
                    c = 3;
                    i = i3;
                    j = j4;
                }
            }
        }
        if (i < 0) {
            return true;
        }
        if (!z) {
            spendSpeedUpGems(Builders.speedCost(j));
        }
        if (c == 1) {
            completeBuildingUpgrade(this.buildings.get(i));
            return true;
        }
        if (c == 2) {
            return completeHeroUpgrade(this.buildings.get(i));
        }
        addXp(Py.isqrt(Data.OBSTACLE_SECONDS[(int) (data(this.obstacles.remove(i)) - 8000000)]));
        return true;
    }

    private boolean hasOverlap(long j, long j2, long j3, long j4, int i) {
        if (this.buildings == null) {
            return false;
        }
        for (int i2 = 0; i2 < this.buildings.size(); i2++) {
            if (i2 != i) {
                Map<String, Object> map = this.buildings.get(i2);
                int data = (int) (data(map) - 1000000);
                if (data >= 0 && data < Data.BUILDING_W.length) {
                    long lv = Py.lv(map.get("x"));
                    long lv2 = Py.lv(map.get("y"));
                    long j5 = Data.BUILDING_W[data];
                    long j6 = Data.BUILDING_H[data];
                    if (j < j5 + lv && j + j3 > lv && j2 < j6 + lv2 && j2 + j4 > lv2) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private void removeBuildingAt(int i) {
        this.buildings.remove(i);
        if (this.queues.isEmpty()) {
            return;
        }
        TreeMap<Long, Queue> treeMap = new TreeMap<>();
        for (Map.Entry<Long, Queue> entry : this.queues.entrySet()) {
            long longValue = entry.getKey().longValue();
            long j = i;
            if (longValue < j) {
                treeMap.put(Long.valueOf(longValue), entry.getValue());
            } else if (longValue > j) {
                treeMap.put(Long.valueOf(longValue - 1), entry.getValue());
            }
        }
        this.queues = treeMap;
    }

    long[] buildingCost(long j, long j2) {
        long j3 = j - 1000000;
        return j == 1000015 ? new long[]{3, Data.WORKER_COSTS[(int) Math.min(countByData(this.buildings, 1000015L), Data.WORKER_COSTS.length - 1)]} : new long[]{Data.BUILD_RES[(int) j3], levelValue(Data.BUILD_COST, j3, j2)};
    }

    synchronized long[] addBuilding(long j, long j2, long j3) {
        long j4;
        long levelValue;
        settleTimers(null);
        long j5 = j3 - 1000000;
        if (this.buildings != null && 0 <= j5 && j5 < Data.BUILDING_LEVELS.length && this.buildings.size() < 300) {
            if (0 <= j && j < 50 && 0 <= j2 && j2 < 50) {
                int i = (int) j5;
                if (countByData(this.buildings, j3) >= Data.TH_BUILDING_CAPS[(int) Math.max(0L, Math.min(townHallLevel() - 1, Data.TH_BUILDING_CAPS.length - 1))][i]) {
                    return null;
                }
                if (hasOverlap(j, j2, Data.BUILDING_W[i], Data.BUILDING_H[i], -1)) {
                    return null;
                }
                if (j3 == 1000015) {
                    j4 = 0;
                    levelValue = 0;
                } else {
                    j4 = 0;
                    levelValue = levelValue(Data.BUILD_SECS, j5, 0L);
                }
                if (j3 != 1000015 && levelValue > j4 && !hasWorkerSlot()) {
                    return null;
                }
                if (!trySpend(buildingCost(j3, j4)[0], r1[1])) {
                    return null;
                }
                long j6 = this.nextUid;
                this.nextUid = j6 + 1;
                Object[] objArr = new Object[10];
                objArr[0] = "data";
                objArr[1] = Long.valueOf(j3);
                objArr[2] = "lvl";
                objArr[3] = Long.valueOf(levelValue > j4 ? -1L : j4);
                objArr[4] = "x";
                objArr[5] = Long.valueOf(j);
                objArr[6] = "y";
                objArr[7] = Long.valueOf(j2);
                objArr[8] = "_u";
                objArr[9] = Long.valueOf(j6);
                Map<String, Object> map = Py.map(objArr);
                if (levelValue > j4) {
                    map.put("const_t", Long.valueOf(levelValue));
                } else {
                    addXp(Py.isqrt(levelValue));
                    resetProducerTimer(map);
                    if (altar(j3)) {
                        long altarHero = altarHero(j3);
                        if (!this.heroLevels.containsKey(Long.valueOf(altarHero))) {
                            this.heroLevels.put(Long.valueOf(altarHero), Long.valueOf(j4));
                        }
                        if (!this.heroStates.containsKey(Long.valueOf(altarHero))) {
                            this.heroStates.put(Long.valueOf(altarHero), 3L);
                        }
                    }
                }
                this.buildings.add(map);
                if (levelValue <= j4) {
                    syncTutorialRewards();
                }
                return new long[]{j6, levelValue};
            }
            return null;
        }
        return null;
    }

    synchronized boolean moveBuilding(long j, long j2, long j3) {
        if (this.buildings != null && 0 <= j && j < r0.size()) {
            if (0 <= j2 && j2 < 50 && 0 <= j3 && j3 < 50) {
                int i = (int) j;
                this.buildings.get(i).put("x", Long.valueOf(j2));
                this.buildings.get(i).put("y", Long.valueOf(j3));
                return true;
            }
            return false;
        }
        return false;
    }

    synchronized boolean moveBuildingByUid(long j, long j2, long j3) {
        boolean z;
        int findByUid = findByUid(this.buildings, j);
        if (findByUid >= 0) {
            z = moveBuilding((long) findByUid, j2, j3);
        }
        return z;
    }

    synchronized Long upgradeBuilding(long j) {
        settleTimers(null);
        if (this.buildings != null && 0 <= j && j < r1.size()) {
            Map<String, Object> map = this.buildings.get((int) j);
            if (lvl(map) >= 0 && Py.getLong(map, "const_t", 0L) <= 0 && hasWorkerSlot()) {
                long data = data(map) - 1000000;
                long lvl = lvl(map) + 1;
                int i = (int) data;
                if (lvl >= Data.BUILDING_LEVELS[i]) {
                    return null;
                }
                if (data != 1 && townHallLevel() - 1 < Data.BUILDING_REQUIRED_TH[i][(int) lvl]) {
                    return null;
                }
                if (!trySpend(buildingCost(data(map), lvl)[0], r14[1])) {
                    return null;
                }
                collectProducerEntry(map);
                long levelValue = levelValue(Data.BUILD_SECS, data, lvl);
                if (levelValue > 0) {
                    map.put("const_t", Long.valueOf(levelValue));
                } else {
                    map.put("lvl", Long.valueOf(lvl));
                    addXp(Py.isqrt(levelValue));
                    resetProducerTimer(map);
                    syncTutorialRewards();
                }
                return Long.valueOf(levelValue);
            }
            return null;
        }
        return null;
    }

    synchronized Long unlockBuilding(long j) {
        settleTimers(null);
        if (this.buildings != null && 0 <= j && j < r1.size()) {
            Map<String, Object> map = this.buildings.get((int) j);
            if (!Py.truthy(map.get("locked"))) {
                return null;
            }
            long levelValue = levelValue(Data.BUILD_SECS, data(map) - 1000000, 0L);
            if (levelValue > 0 && !hasWorkerSlot()) {
                return null;
            }
            if (!trySpend(buildingCost(data(map), 0L)[0], r12[1])) {
                return null;
            }
            map.remove("locked");
            if (levelValue > 0) {
                map.put("const_t", Long.valueOf(levelValue));
            } else {
                addXp(Py.isqrt(levelValue));
            }
            return Long.valueOf(levelValue);
        }
        return null;
    }

    synchronized boolean cancelConstruction(long j) {
        settleTimers(null);
        if (this.buildings != null && 0 <= j && j < r0.size()) {
            int i = (int) j;
            Map<String, Object> map = this.buildings.get(i);
            if (Py.getLong(map, "const_t", 0L) <= 0) {
                return false;
            }
            long lvl = lvl(map);
            long[] buildingCost = buildingCost(data(map), Math.max(0L, 1 + lvl));
            long j2 = buildingCost[0];
            double d = buildingCost[1] * 50;
            Double.isNaN(d);
            gain(j2, d / 100.0d);
            if (lvl < 0) {
                removeBuildingAt(i);
            } else {
                map.remove("const_t");
            }
            return true;
        }
        return false;
    }

    synchronized boolean speedUpConstruction(long j) {
        settleTimers(null);
        if (this.buildings != null && 0 <= j && j < r0.size()) {
            Map<String, Object> map = this.buildings.get((int) j);
            if (Py.getLong(map, "const_t", 0L) <= 0) {
                return false;
            }
            spendSpeedUpGems(Builders.speedCost(r4));
            completeBuildingUpgrade(map);
            return true;
        }
        return false;
    }

    synchronized boolean sellObjectByUid(long j, long j2) {
        settleTimers(null);
        if (j == 506) {
            int findByUid = findByUid(this.decos, j2);
            if (findByUid < 0) {
                return false;
            }
            int data = (int) (data(this.decos.remove(findByUid)) - 18000000);
            if (data >= 0 && data < Data.DECO_COST.length) {
                long j3 = Data.DECO_RES[data];
                double d = Data.DECO_COST[data];
                Double.isNaN(d);
                gain(j3, d / 10.0d);
            }
            return true;
        }
        if (j == 504) {
            int findByUid2 = findByUid(this.traps, j2);
            if (findByUid2 < 0) {
                return false;
            }
            int data2 = (int) (data(this.traps.remove(findByUid2)) - 12000000);
            if (data2 >= 0 && data2 < Data.TRAP_COST.length) {
                long j4 = Data.TRAP_RES[data2];
                double d2 = Data.TRAP_COST[data2];
                Double.isNaN(d2);
                gain(j4, d2 / 5.0d);
            }
            return true;
        }
        int findByUid3 = findByUid(this.buildings, j2);
        if (findByUid3 < 0) {
            return false;
        }
        Map<String, Object> map = this.buildings.get(findByUid3);
        int data3 = (int) (data(map) - 1000000);
        if (data3 >= 0 && data3 < Data.BUILDING_CANNOT_SELL_LAST.length) {
            if (Data.BUILDING_CANNOT_SELL_LAST[data3] && countByData(this.buildings, data(map)) <= 1) {
                return false;
            }
            long[] buildingCost = buildingCost(data(map), Math.max(0L, lvl(map)));
            long j5 = buildingCost[0];
            double d3 = buildingCost[1];
            Double.isNaN(d3);
            gain(j5, d3 / 5.0d);
            removeBuildingAt(findByUid3);
            return true;
        }
        return false;
    }

    synchronized boolean toggleAttackMode(long j) {
        if (this.buildings != null && 0 <= j && j < r0.size()) {
            Map<String, Object> map = this.buildings.get((int) j);
            int data = (int) (data(map) - 1000000);
            if (data >= 0 && data < Data.BUILDING_ALT_MODE.length && Data.BUILDING_ALT_MODE[data]) {
                map.put("attack_mode", Boolean.valueOf(Py.truthy(map.get("attack_mode")) ? false : true));
                return true;
            }
            return false;
        }
        return false;
    }

    synchronized boolean loadAmmo(long j) {
        settleTimers(null);
        if (this.buildings != null && 0 <= j && j < r0.size()) {
            Map<String, Object> map = this.buildings.get((int) j);
            long lvl = lvl(map);
            int data = (int) (data(map) - 1000000);
            if (lvl >= 0 && data >= 0 && data < Data.BUILDING_AMMO.length) {
                long levelValue = levelValue(Data.BUILDING_AMMO, data, lvl);
                long j2 = Data.BUILDING_AMMO_RES[data];
                long j3 = Data.BUILDING_AMMO_COST[data];
                if (levelValue > 0 && j2 >= 0 && j3 > 0) {
                    long j4 = Py.getLong(map, "ammo", levelValue);
                    if (j4 >= levelValue) {
                        map.put("ammo", Long.valueOf(levelValue));
                        return true;
                    }
                    double d = j3 * (levelValue - j4);
                    Double.isNaN(d);
                    Double.isNaN(levelValue);
                    if (!trySpend(j2, Math.max(1L, (long) Math.ceil(d / r8)))) {
                        return false;
                    }
                    map.put("ammo", Long.valueOf(levelValue));
                    return true;
                }
                return false;
            }
            return false;
        }
        return false;
    }

    synchronized boolean boostBuilding(long j) {
        settleTimers(null);
        if (this.buildings != null && 0 <= j && j < r0.size()) {
            Map<String, Object> map = this.buildings.get((int) j);
            long lvl = lvl(map);
            int data = (int) (data(map) - 1000000);
            if (lvl >= 0 && data >= 0 && data < Data.BOOST_SECONDS.length && Data.BOOST_SECONDS[data] > 0) {
                if (Py.getLong(map, "const_t", 0L) <= 0 && Py.getLong(map, "boost_t", 0L) <= 0) {
                    long levelValue = levelValue(Data.BOOST_COST, data, lvl);
                    if (levelValue > 0 && trySpend(3L, levelValue)) {
                        map.put("boost_t", Long.valueOf(Data.BOOST_SECONDS[data]));
                        return true;
                    }
                    return false;
                }
                return false;
            }
            return false;
        }
        return false;
    }

    synchronized void recordHeroBattleResult(long j, double d) {
        long j2 = j - 28000000;
        if (0 <= j2) {
            if (j2 < Data.HERO_REGEN_SECONDS.length) {
                if (d <= 0.05d) {
                    return;
                }
                double levelValue = levelValue(Data.HERO_REGEN_SECONDS, (int) j2, this.heroLevels.containsKey(Long.valueOf(j)) ? this.heroLevels.get(Long.valueOf(j)).longValue() : 0L);
                double min = Math.min(1.0d, d);
                Double.isNaN(levelValue);
                double d2 = levelValue * min;
                if (d2 >= 1.0d) {
                    this.heroHealth.put(Long.valueOf(j), Double.valueOf(Math.max(this.heroHealth.containsKey(Long.valueOf(j)) ? this.heroHealth.get(Long.valueOf(j)).doubleValue() : 0.0d, d2)));
                }
            }
        }
    }

    synchronized List<long[]> army() {
        ArrayList arrayList;
        arrayList = new ArrayList();
        for (Map.Entry<Long, Long> entry : this.units.entrySet()) {
            if (entry.getValue().longValue() > 0) {
                arrayList.add(new long[]{entry.getKey().longValue(), entry.getValue().longValue()});
            }
        }
        return arrayList;
    }

    List<long[]> grants(long j) {
        if (this.tutorial && !this.stars.containsKey(Long.valueOf(17000000 + j)) && (j == 0 || j == 1)) {
            ArrayList arrayList = new ArrayList();
            arrayList.add(new long[]{4000006, 5});
            return arrayList;
        }
        return new ArrayList();
    }

    List<long[]> attackUnits(long j) {
        settle(null);
        TreeMap treeMap = new TreeMap();
        for (long[] jArr : army()) {
            treeMap.put(Long.valueOf(jArr[0]), Long.valueOf(jArr[1]));
        }
        for (long[] jArr2 : grants(j)) {
            treeMap.put(Long.valueOf(jArr2[0]), Long.valueOf((treeMap.containsKey(Long.valueOf(jArr2[0])) ? ((Long) treeMap.get(Long.valueOf(jArr2[0]))).longValue() : 0L) + jArr2[1]));
        }
        return pairs(treeMap);
    }

    synchronized void consume(Map<Long, Long> map, Map<Long, Long> map2) {
        for (Map.Entry<Long, Long> entry : map.entrySet()) {
            long max = Math.max(0L, (this.units.containsKey(entry.getKey()) ? this.units.get(entry.getKey()).longValue() : 0L) - Math.max(0L, entry.getValue().longValue() - (map2.containsKey(entry.getKey()) ? map2.get(entry.getKey()).longValue() : 0L)));
            if (max != 0) {
                this.units.put(entry.getKey(), Long.valueOf(max));
            } else {
                this.units.remove(entry.getKey());
            }
        }
    }

    void award(long j, long j2) {
        if (j2 > 0) {
            synchronized (this) {
                this.stars.put(Long.valueOf(j), Long.valueOf(Math.max(this.stars.containsKey(Long.valueOf(j)) ? this.stars.get(Long.valueOf(j)).longValue() : 0L, Math.min(j2, 3L))));
            }
        }
    }

    synchronized List<long[]> starSlots() {
        return pairs(this.stars);
    }

    synchronized List<Object> villageBuildings(Object obj) {
        List<Object> plainEntries;
        if (this.buildings == null) {
            this.buildings = tagEntries((List) Py.deepCopy(obj));
        }
        settleTimers(null);
        plainEntries = plainEntries(this.buildings);
        Iterator<Object> it = plainEntries.iterator();
        while (it.hasNext()) {
            Map<String, Object> asMap = Py.asMap(it.next());
            if (lvl(asMap) >= 0) {
                Builders.completeBuilding(asMap);
            }
        }
        for (Map.Entry<Long, Queue> entry : this.queues.entrySet()) {
            long longValue = entry.getKey().longValue();
            if (0 <= longValue && longValue < plainEntries.size()) {
                Map<String, Object> asMap2 = Py.asMap(plainEntries.get((int) longValue));
                if (lvl(asMap2) >= 0) {
                    ArrayList arrayList = new ArrayList();
                    for (long[] jArr : entry.getValue().slots) {
                        arrayList.add(Py.map("id", Long.valueOf(jArr[0]), "cnt", Long.valueOf(jArr[1])));
                    }
                    Object[] objArr = new Object[6];
                    objArr[0] = "unit_type";
                    objArr[1] = Long.valueOf(data(asMap2) == 1000020 ? 1L : 0L);
                    objArr[2] = "t";
                    objArr[3] = Long.valueOf((long) entry.getValue().left);
                    objArr[4] = "slots";
                    objArr[5] = arrayList;
                    asMap2.put("unit_prod", Py.map(objArr));
                }
            }
        }
        return plainEntries;
    }

    List<Long> missions() {
        ArrayList arrayList = new ArrayList();
        long length = this.tutorial ? this.progress : Data.MISSIONS.length;
        for (int i = 0; i < length && i < Data.MISSIONS.length; i++) {
            arrayList.add(Long.valueOf(Data.MISSIONS[i]));
        }
        return arrayList;
    }

    boolean advance(long j) {
        boolean z;
        if (!this.tutorial) {
            return false;
        }
        synchronized (this) {
            long j2 = this.progress;
            this.progress = Math.min(Math.max(j2, j), Data.MISSIONS.length);
            syncTutorialRewards();
            z = this.progress != j2;
        }
        return z;
    }

    String pickStage() {
        if (!this.stage.equals("auto")) {
            return this.stage;
        }
        synchronized (this) {
            this.counter++;
        }
        return "full";
    }
}
