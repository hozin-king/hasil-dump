package com.nara.server;

import com.facebook.AppEventsConstants;
import com.facebook.internal.WorkQueue;
import java.math.BigDecimal;
import java.nio.charset.Charset;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/* loaded from: /home/hatch/workspace/rea-clash-of-clans/analysis/../dump-full/classes.dex */
final class Py {
    static final Charset UTF8 = Charset.forName("UTF-8");
    static volatile double fixedNow = -1.0d;

    static String bool(boolean z) {
        return z ? "True" : "False";
    }

    private Py() {
    }

    static double now() {
        double d = fixedNow;
        if (d >= 0.0d) {
            return d;
        }
        double currentTimeMillis = System.currentTimeMillis();
        Double.isNaN(currentTimeMillis);
        return currentTimeMillis / 1000.0d;
    }

    static final class StructError extends RuntimeException {
        StructError(String str) {
            super(str);
        }
    }

    static final class ValueError extends RuntimeException {
        ValueError(String str) {
            super(str);
        }
    }

    static long fdiv(long j, long j2) {
        long j3 = j / j2;
        if (j % j2 != 0) {
            return ((j > 0L ? 1 : (j == 0L ? 0 : -1)) < 0) != (j2 < 0) ? j3 - 1 : j3;
        }
        return j3;
    }

    static long fmod(long j, long j2) {
        long j3 = j % j2;
        if (j3 != 0) {
            return ((j3 > 0L ? 1 : (j3 == 0L ? 0 : -1)) < 0) != (j2 < 0) ? j3 + j2 : j3;
        }
        return j3;
    }

    static long isqrt(long j) {
        long sqrt = (long) Math.sqrt(j);
        while (sqrt * sqrt > j) {
            sqrt--;
        }
        while (true) {
            long j2 = sqrt + 1;
            if (j2 * j2 > j) {
                return sqrt;
            }
            sqrt = j2;
        }
    }

    static long lv(Object obj) {
        return ((Number) obj).longValue();
    }

    static double dv(Object obj) {
        return ((Number) obj).doubleValue();
    }

    static boolean isInt(Object obj) {
        return obj instanceof Long;
    }

    static boolean isNumber(Object obj) {
        return (obj instanceof Long) || (obj instanceof Double);
    }

    static boolean truthy(Object obj) {
        if (obj == null) {
            return false;
        }
        if (obj instanceof Boolean) {
            return ((Boolean) obj).booleanValue();
        }
        if (obj instanceof Long) {
            return ((Long) obj).longValue() != 0;
        }
        if (obj instanceof Double) {
            return ((Double) obj).doubleValue() != 0.0d;
        }
        if (obj instanceof String) {
            return !((String) obj).isEmpty();
        }
        if (obj instanceof Collection) {
            return !((Collection) obj).isEmpty();
        }
        if (obj instanceof Map) {
            return !((Map) obj).isEmpty();
        }
        return true;
    }

    static long getLong(Map<String, Object> map, String str, long j) {
        Object obj = map.get(str);
        return (obj != null || map.containsKey(str)) ? lv(obj) : j;
    }

    static boolean isDigits(String str) {
        if (str.isEmpty() || str.length() > 18) {
            return false;
        }
        for (int i = 0; i < str.length(); i++) {
            char charAt = str.charAt(i);
            if (charAt < '0' || charAt > '9') {
                return false;
            }
        }
        return true;
    }

    static int cpLen(String str) {
        return str.codePointCount(0, str.length());
    }

    static String cpSlice(String str, int i) {
        return cpLen(str) <= i ? str : str.substring(0, str.offsetByCodePoints(0, i));
    }

    static String cpTail(String str, int i) {
        return str.substring(str.offsetByCodePoints(0, i));
    }

    static boolean isSpace(int i) {
        if (i == 133 || i == 160) {
            return true;
        }
        return (i >= 28 && i <= 31) || Character.isWhitespace(i) || Character.isSpaceChar(i);
    }

    static String strip(String str) {
        int length = str.length();
        int i = 0;
        while (i < length) {
            int codePointAt = str.codePointAt(i);
            if (!isSpace(codePointAt)) {
                break;
            }
            i += Character.charCount(codePointAt);
        }
        while (length > i) {
            int codePointBefore = str.codePointBefore(length);
            if (!isSpace(codePointBefore)) {
                break;
            }
            length -= Character.charCount(codePointBefore);
        }
        return str.substring(i, length);
    }

    static boolean isPrintable(int i) {
        if (i == 32) {
            return true;
        }
        int type = Character.getType(i);
        if (type == 0 || type == 18 || type == 19) {
            return false;
        }
        switch (type) {
        }
        return true;
    }

    static String printable(String str) {
        StringBuilder sb = new StringBuilder();
        int i = 0;
        while (i < str.length()) {
            int codePointAt = str.codePointAt(i);
            if (isPrintable(codePointAt)) {
                sb.appendCodePoint(codePointAt);
            }
            i += Character.charCount(codePointAt);
        }
        return sb.toString();
    }

    static String decode(byte[] bArr, int i, int i2) {
        return new String(bArr, i, i2, UTF8);
    }

    static String hex(byte[] bArr, int i) {
        char[] charArray = "0123456789abcdef".toCharArray();
        StringBuilder sb = new StringBuilder(i * 2);
        for (int i2 = 0; i2 < i; i2++) {
            sb.append(charArray[(bArr[i2] >> 4) & 15]);
            sb.append(charArray[bArr[i2] & 15]);
        }
        return sb.toString();
    }

    static String repr(String str) {
        if (str == null) {
            return "None";
        }
        return "'" + str.replace("\\", "\\\\").replace("'", "\\'") + "'";
    }

    static List<Object> list(Object... objArr) {
        ArrayList arrayList = new ArrayList();
        for (Object obj : objArr) {
            arrayList.add(obj);
        }
        return arrayList;
    }

    static Map<String, Object> map(Object... objArr) {
        LinkedHashMap linkedHashMap = new LinkedHashMap();
        for (int i = 0; i < objArr.length; i += 2) {
            linkedHashMap.put((String) objArr[i], objArr[i + 1]);
        }
        return linkedHashMap;
    }

    static Object deepCopy(Object obj) {
        if (obj instanceof Map) {
            LinkedHashMap linkedHashMap = new LinkedHashMap();
            for (Map.Entry entry : ((Map) obj).entrySet()) {
                linkedHashMap.put((String) entry.getKey(), deepCopy(entry.getValue()));
            }
            return linkedHashMap;
        }
        if (!(obj instanceof List)) {
            return obj;
        }
        ArrayList arrayList = new ArrayList();
        Iterator it = ((List) obj).iterator();
        while (it.hasNext()) {
            arrayList.add(deepCopy(it.next()));
        }
        return arrayList;
    }

    static Map<String, Object> asMap(Object obj) {
        return (Map) obj;
    }

    static List<Object> asList(Object obj) {
        return (List) obj;
    }

    static String floatRepr(double d) {
        if (Double.isNaN(d)) {
            return "NaN";
        }
        if (Double.isInfinite(d)) {
            return d > 0.0d ? "Infinity" : "-Infinity";
        }
        if (d == 0.0d) {
            return 1.0d / d < 0.0d ? "-0.0" : "0.0";
        }
        BigDecimal bigDecimal = new BigDecimal(Double.toString(d));
        double abs = Math.abs(d);
        if (abs >= 1.0E16d || abs < 1.0E-4d) {
            String replaceAll = bigDecimal.unscaledValue().abs().toString().replaceAll("0+$", "");
            if (replaceAll.isEmpty()) {
                replaceAll = AppEventsConstants.EVENT_PARAM_VALUE_NO;
            }
            int precision = (bigDecimal.precision() - bigDecimal.scale()) - 1;
            StringBuilder sb = new StringBuilder();
            if (d < 0.0d) {
                sb.append('-');
            }
            sb.append(replaceAll.charAt(0));
            if (replaceAll.length() > 1) {
                sb.append('.');
                sb.append(replaceAll.substring(1));
            }
            sb.append('e');
            sb.append(precision >= 0 ? '+' : '-');
            int abs2 = Math.abs(precision);
            if (abs2 < 10) {
                sb.append('0');
            }
            sb.append(abs2);
            return sb.toString();
        }
        String plainString = bigDecimal.stripTrailingZeros().toPlainString();
        if (plainString.indexOf(46) >= 0) {
            return plainString;
        }
        return plainString + ".0";
    }

    static String dumps(Object obj) {
        StringBuilder sb = new StringBuilder();
        dump(sb, obj);
        return sb.toString();
    }

    private static void dump(StringBuilder sb, Object obj) {
        if (obj == null) {
            sb.append("null");
            return;
        }
        if (obj instanceof Boolean) {
            sb.append(((Boolean) obj).booleanValue() ? "true" : "false");
            return;
        }
        if ((obj instanceof Long) || (obj instanceof Integer)) {
            sb.append(((Number) obj).longValue());
            return;
        }
        if (obj instanceof Double) {
            sb.append(floatRepr(((Double) obj).doubleValue()));
            return;
        }
        if (obj instanceof String) {
            dumpString(sb, (String) obj);
            return;
        }
        boolean z = true;
        if (obj instanceof Map) {
            sb.append('{');
            for (Map.Entry entry : ((Map) obj).entrySet()) {
                if (!z) {
                    sb.append(',');
                }
                dumpString(sb, (String) entry.getKey());
                sb.append(':');
                dump(sb, entry.getValue());
                z = false;
            }
            sb.append('}');
            return;
        }
        if (obj instanceof List) {
            sb.append('[');
            for (Object obj2 : (List) obj) {
                if (!z) {
                    sb.append(',');
                }
                dump(sb, obj2);
                z = false;
            }
            sb.append(']');
            return;
        }
        throw new IllegalArgumentException("not serializable: " + obj.getClass());
    }

    private static void dumpString(StringBuilder sb, String str) {
        sb.append('\"');
        for (int i = 0; i < str.length(); i++) {
            char charAt = str.charAt(i);
            if (charAt != '\f') {
                if (charAt != '\r') {
                    if (charAt != '\"') {
                        if (charAt == '\\') {
                            sb.append("\\\\");
                        } else {
                            switch (charAt) {
                                case WorkQueue.DEFAULT_MAX_CONCURRENT /* 8 */:
                                    sb.append("\\b");
                                    break;
                                case '\t':
                                    sb.append("\\t");
                                    break;
                                case '\n':
                                    sb.append("\\n");
                                    break;
                                default:
                                    if (charAt < ' ' || (charAt > '~' && charAt != 127)) {
                                        sb.append(String.format("\\u%04x", Integer.valueOf(charAt)));
                                        break;
                                    } else {
                                        sb.append(charAt);
                                        break;
                                    }
                                    break;
                            }
                        }
                    } else {
                        sb.append("\\\"");
                    }
                } else {
                    sb.append("\\r");
                }
            } else {
                sb.append("\\f");
            }
        }
        sb.append('\"');
    }

    static Object loads(String str) {
        JsonParser jsonParser = new JsonParser(str);
        jsonParser.skip();
        Object value = jsonParser.value();
        jsonParser.skip();
        if (jsonParser.pos == str.length()) {
            return value;
        }
        throw new ValueError("Extra data");
    }

    private static final class JsonParser {
        int pos;
        final String s;

        boolean isAsciiDigit(char c) {
            return c >= '0' && c <= '9';
        }

        JsonParser(String str) {
            this.s = str;
        }

        void skip() {
            while (this.pos < this.s.length()) {
                char charAt = this.s.charAt(this.pos);
                if (charAt != ' ' && charAt != '\t' && charAt != '\n' && charAt != '\r') {
                    return;
                } else {
                    this.pos++;
                }
            }
        }

        ValueError error(String str) {
            return new ValueError(str + " at " + this.pos);
        }

        Object value() {
            if (this.pos >= this.s.length()) {
                throw error("Expecting value");
            }
            char charAt = this.s.charAt(this.pos);
            if (charAt == '{') {
                return object();
            }
            if (charAt == '[') {
                return array();
            }
            if (charAt == '\"') {
                return string();
            }
            if (this.s.startsWith("true", this.pos)) {
                this.pos += 4;
                return Boolean.TRUE;
            }
            if (this.s.startsWith("false", this.pos)) {
                this.pos += 5;
                return Boolean.FALSE;
            }
            if (this.s.startsWith("null", this.pos)) {
                this.pos += 4;
                return null;
            }
            if (this.s.startsWith("NaN", this.pos)) {
                this.pos += 3;
                return Double.valueOf(Double.NaN);
            }
            if (this.s.startsWith("Infinity", this.pos)) {
                this.pos += 8;
                return Double.valueOf(Double.POSITIVE_INFINITY);
            }
            if (this.s.startsWith("-Infinity", this.pos)) {
                this.pos += 9;
                return Double.valueOf(Double.NEGATIVE_INFINITY);
            }
            return number();
        }

        /* JADX WARN: Removed duplicated region for block: B:54:0x0136  */
        /* JADX WARN: Removed duplicated region for block: B:57:0x013f A[EXC_TOP_SPLITTER, SYNTHETIC] */
        /*
            Code decompiled incorrectly, please refer to instructions dump.
            To view partially-correct add '--show-bad-code' argument
        */
        java.lang.Object number() {
            /*
                Method dump skipped, instructions count: 348
                To view this dump add '--comments-level debug' option
            */
            throw new UnsupportedOperationException("Method not decompiled: com.nara.server.Py.JsonParser.number():java.lang.Object");
        }

        String string() {
            this.pos++;
            StringBuilder sb = new StringBuilder();
            while (this.pos < this.s.length()) {
                String str = this.s;
                int i = this.pos;
                this.pos = i + 1;
                char charAt = str.charAt(i);
                if (charAt == '\"') {
                    return sb.toString();
                }
                if (charAt == '\\') {
                    if (this.pos >= this.s.length()) {
                        throw error("Unterminated string");
                    }
                    String str2 = this.s;
                    int i2 = this.pos;
                    this.pos = i2 + 1;
                    char charAt2 = str2.charAt(i2);
                    if (charAt2 == '\"') {
                        sb.append('\"');
                    } else if (charAt2 == '/') {
                        sb.append('/');
                    } else if (charAt2 == '\\') {
                        sb.append('\\');
                    } else if (charAt2 == 'b') {
                        sb.append('\b');
                    } else if (charAt2 == 'f') {
                        sb.append('\f');
                    } else if (charAt2 == 'n') {
                        sb.append('\n');
                    } else if (charAt2 == 'r') {
                        sb.append('\r');
                    } else if (charAt2 == 't') {
                        sb.append('\t');
                    } else if (charAt2 == 'u') {
                        if (this.pos + 4 > this.s.length()) {
                            throw error("Invalid \\u escape");
                        }
                        try {
                            String str3 = this.s;
                            int i3 = this.pos;
                            sb.append((char) Integer.parseInt(str3.substring(i3, i3 + 4), 16));
                            this.pos += 4;
                        } catch (NumberFormatException unused) {
                            throw error("Invalid \\u escape");
                        }
                    } else {
                        throw error("Invalid escape");
                    }
                } else {
                    if (charAt < ' ') {
                        throw error("Invalid control character");
                    }
                    sb.append(charAt);
                }
            }
            throw error("Unterminated string");
        }

        /* JADX WARN: Code restructure failed: missing block: B:24:0x0099, code lost:
        
            if (r5.pos >= r5.s.length()) goto L27;
         */
        /* JADX WARN: Code restructure failed: missing block: B:26:0x00a3, code lost:
        
            if (r5.s.charAt(r5.pos) != '}') goto L27;
         */
        /* JADX WARN: Code restructure failed: missing block: B:27:0x00a5, code lost:
        
            r5.pos++;
         */
        /* JADX WARN: Code restructure failed: missing block: B:28:0x00ab, code lost:
        
            return r0;
         */
        /* JADX WARN: Code restructure failed: missing block: B:30:0x00b2, code lost:
        
            throw error("Expecting ',' delimiter");
         */
        /* JADX WARN: Code restructure failed: missing block: B:38:0x00c1, code lost:
        
            throw error("Expecting property name");
         */
        /*
            Code decompiled incorrectly, please refer to instructions dump.
            To view partially-correct add '--show-bad-code' argument
        */
        java.util.Map<java.lang.String, java.lang.Object> object() {
            /*
                r5 = this;
                int r0 = r5.pos
                int r0 = r0 + 1
                r5.pos = r0
                java.util.LinkedHashMap r0 = new java.util.LinkedHashMap
                r0.<init>()
                r5.skip()
                int r1 = r5.pos
                java.lang.String r2 = r5.s
                int r2 = r2.length()
                r3 = 125(0x7d, float:1.75E-43)
                if (r1 >= r2) goto L2b
                java.lang.String r1 = r5.s
                int r2 = r5.pos
                char r1 = r1.charAt(r2)
                if (r1 != r3) goto L2b
                int r1 = r5.pos
                int r1 = r1 + 1
                r5.pos = r1
                return r0
            L2b:
                r5.skip()
                int r1 = r5.pos
                java.lang.String r2 = r5.s
                int r2 = r2.length()
                if (r1 >= r2) goto Lba
                java.lang.String r1 = r5.s
                int r2 = r5.pos
                char r1 = r1.charAt(r2)
                r2 = 34
                if (r1 != r2) goto Lba
                java.lang.String r1 = r5.string()
                r5.skip()
                int r2 = r5.pos
                java.lang.String r4 = r5.s
                int r4 = r4.length()
                if (r2 >= r4) goto Lb3
                java.lang.String r2 = r5.s
                int r4 = r5.pos
                char r2 = r2.charAt(r4)
                r4 = 58
                if (r2 != r4) goto Lb3
                int r2 = r5.pos
                int r2 = r2 + 1
                r5.pos = r2
                r5.skip()
                java.lang.Object r2 = r5.value()
                r0.put(r1, r2)
                r5.skip()
                int r1 = r5.pos
                java.lang.String r2 = r5.s
                int r2 = r2.length()
                if (r1 >= r2) goto L91
                java.lang.String r1 = r5.s
                int r2 = r5.pos
                char r1 = r1.charAt(r2)
                r2 = 44
                if (r1 != r2) goto L91
                int r1 = r5.pos
                int r1 = r1 + 1
                r5.pos = r1
                goto L2b
            L91:
                int r1 = r5.pos
                java.lang.String r2 = r5.s
                int r2 = r2.length()
                if (r1 >= r2) goto Lac
                java.lang.String r1 = r5.s
                int r2 = r5.pos
                char r1 = r1.charAt(r2)
                if (r1 != r3) goto Lac
                int r1 = r5.pos
                int r1 = r1 + 1
                r5.pos = r1
                return r0
            Lac:
                java.lang.String r0 = "Expecting ',' delimiter"
                com.nara.server.Py$ValueError r0 = r5.error(r0)
                throw r0
            Lb3:
                java.lang.String r0 = "Expecting ':'"
                com.nara.server.Py$ValueError r0 = r5.error(r0)
                throw r0
            Lba:
                java.lang.String r0 = "Expecting property name"
                com.nara.server.Py$ValueError r0 = r5.error(r0)
                goto Lc2
            Lc1:
                throw r0
            Lc2:
                goto Lc1
            */
            throw new UnsupportedOperationException("Method not decompiled: com.nara.server.Py.JsonParser.object():java.util.Map");
        }

        List<Object> array() {
            this.pos++;
            ArrayList arrayList = new ArrayList();
            skip();
            if (this.pos < this.s.length() && this.s.charAt(this.pos) == ']') {
                this.pos++;
                return arrayList;
            }
            while (true) {
                skip();
                arrayList.add(value());
                skip();
                if (this.pos >= this.s.length() || this.s.charAt(this.pos) != ',') {
                    break;
                }
                this.pos++;
            }
            if (this.pos < this.s.length() && this.s.charAt(this.pos) == ']') {
                this.pos++;
                return arrayList;
            }
            throw error("Expecting ',' delimiter");
        }
    }

    static final class Random {
        private int index;
        private final int[] mt;

        Random() {
            this.mt = new int[624];
            this.index = 625;
            SecureRandom secureRandom = new SecureRandom();
            int[] iArr = new int[4];
            for (int i = 0; i < 4; i++) {
                iArr[i] = secureRandom.nextInt();
            }
            initByArray(iArr);
        }

        Random(long j) {
            this.mt = new int[624];
            this.index = 625;
            seed(j);
        }

        synchronized void seed(long j) {
            long abs = Math.abs(j);
            ArrayList arrayList = new ArrayList();
            do {
                arrayList.add(Integer.valueOf((int) (4294967295L & abs)));
                abs >>>= 32;
            } while (abs != 0);
            int size = arrayList.size();
            int[] iArr = new int[size];
            for (int i = 0; i < size; i++) {
                iArr[i] = ((Integer) arrayList.get(i)).intValue();
            }
            initByArray(iArr);
        }

        private void initGenrand(int i) {
            this.mt[0] = i;
            int i2 = 1;
            while (true) {
                this.index = i2;
                int i3 = this.index;
                if (i3 >= 624) {
                    return;
                }
                int[] iArr = this.mt;
                iArr[i3] = ((iArr[i3 - 1] ^ (iArr[i3 - 1] >>> 30)) * 1812433253) + i3;
                i2 = i3 + 1;
            }
        }

        private void initByArray(int[] iArr) {
            initGenrand(19650218);
            int i = 1;
            int i2 = 0;
            for (int max = Math.max(624, iArr.length); max > 0; max--) {
                int[] iArr2 = this.mt;
                int i3 = iArr2[i];
                int i4 = iArr2[i - 1];
                iArr2[i] = (i3 ^ ((i4 ^ (i4 >>> 30)) * 1664525)) + iArr[i2] + i2;
                i++;
                i2++;
                if (i >= 624) {
                    iArr2[0] = iArr2[623];
                    i = 1;
                }
                if (i2 >= iArr.length) {
                    i2 = 0;
                }
            }
            for (int i5 = 623; i5 > 0; i5--) {
                int[] iArr3 = this.mt;
                int i6 = iArr3[i];
                int i7 = iArr3[i - 1];
                iArr3[i] = (i6 ^ ((i7 ^ (i7 >>> 30)) * 1566083941)) - i;
                i++;
                if (i >= 624) {
                    iArr3[0] = iArr3[623];
                    i = 1;
                }
            }
            this.mt[0] = Integer.MIN_VALUE;
            this.index = 624;
        }

        private long genrand() {
            if (this.index >= 624) {
                int i = 0;
                while (true) {
                    if (i >= 227) {
                        break;
                    }
                    int[] iArr = this.mt;
                    int i2 = i + 1;
                    int i3 = (Integer.MAX_VALUE & iArr[i2]) | (Integer.MIN_VALUE & iArr[i]);
                    int i4 = iArr[i + 397] ^ (i3 >>> 1);
                    if ((i3 & 1) == 0) {
                        r3 = 0;
                    }
                    iArr[i] = r3 ^ i4;
                    i = i2;
                }
                while (i < 623) {
                    int[] iArr2 = this.mt;
                    int i5 = i + 1;
                    int i6 = (iArr2[i] & Integer.MIN_VALUE) | (iArr2[i5] & Integer.MAX_VALUE);
                    iArr2[i] = ((i6 & 1) != 0 ? -1727483681 : 0) ^ (iArr2[i - 227] ^ (i6 >>> 1));
                    i = i5;
                }
                int[] iArr3 = this.mt;
                int i7 = (Integer.MAX_VALUE & iArr3[0]) | (Integer.MIN_VALUE & iArr3[623]);
                iArr3[623] = ((i7 & 1) == 0 ? 0 : -1727483681) ^ (iArr3[396] ^ (i7 >>> 1));
                this.index = 0;
            }
            int[] iArr4 = this.mt;
            int i8 = this.index;
            this.index = i8 + 1;
            int i9 = iArr4[i8];
            int i10 = i9 ^ (i9 >>> 11);
            int i11 = i10 ^ ((i10 << 7) & (-1658038656));
            int i12 = i11 ^ ((i11 << 15) & (-272236544));
            return (i12 ^ (i12 >>> 18)) & 4294967295L;
        }

        synchronized double random() {
            double d;
            double d2;
            long genrand = genrand() >>> 5;
            long genrand2 = genrand() >>> 6;
            d = genrand;
            Double.isNaN(d);
            d2 = genrand2;
            Double.isNaN(d2);
            return ((d * 6.7108864E7d) + d2) * 1.1102230246251565E-16d;
        }

        private long getrandbits(int i) {
            if (i == 0) {
                return 0L;
            }
            return genrand() >>> (32 - i);
        }

        synchronized long randbelow(long j) {
            long j2;
            try {
                if (j <= 0) {
                    throw new ValueError("empty range");
                }
                int numberOfLeadingZeros = 64 - Long.numberOfLeadingZeros(j);
                if (numberOfLeadingZeros > 32) {
                    throw new ValueError("range too large");
                }
                j2 = getrandbits(numberOfLeadingZeros);
                while (j2 >= j) {
                    j2 = getrandbits(numberOfLeadingZeros);
                }
            } catch (Throwable th) {
                throw th;
            }
            return j2;
        }

        long randrange(long j) {
            return randbelow(j);
        }

        long randrange(long j, long j2) {
            return j + randbelow(j2 - j);
        }

        long randint(long j, long j2) {
            return randrange(j, j2 + 1);
        }

        double uniform(double d, double d2) {
            return d + ((d2 - d) * random());
        }

        <T> T choice(List<T> list) {
            if (list.isEmpty()) {
                throw new IndexOutOfBoundsException("Cannot choose from an empty sequence");
            }
            return list.get((int) randbelow(list.size()));
        }

        long choice(long[] jArr) {
            if (jArr.length == 0) {
                throw new IndexOutOfBoundsException("Cannot choose from an empty sequence");
            }
            return jArr[(int) randbelow(jArr.length)];
        }

        String choice(String[] strArr) {
            if (strArr.length == 0) {
                throw new IndexOutOfBoundsException("Cannot choose from an empty sequence");
            }
            return strArr[(int) randbelow(strArr.length)];
        }

        synchronized <T> void shuffle(List<T> list) {
            for (int size = list.size() - 1; size > 0; size--) {
                int randbelow = (int) randbelow(size + 1);
                T t = list.get(size);
                list.set(size, list.get(randbelow));
                list.set(randbelow, t);
            }
        }
    }
}
