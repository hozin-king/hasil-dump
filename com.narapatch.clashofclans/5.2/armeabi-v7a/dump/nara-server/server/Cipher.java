package com.nara.server;

import com.nara.server.Py;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Iterator;
import java.util.List;

/* loaded from: /home/hatch/workspace/rea-clash-of-clans/analysis/../dump-full/classes.dex */
final class Cipher {
    static byte[] packHeader(int i, int i2, int i3) {
        return new byte[]{(byte) ((i >>> 8) & 255), (byte) (i & 255), (byte) ((i2 >>> 16) & 255), (byte) ((i2 >>> 8) & 255), (byte) (i2 & 255), (byte) ((i3 >>> 8) & 255), (byte) (i3 & 255)};
    }

    static boolean plausible(int i, int i2) {
        return 10000 <= i && i < 30000 && ((long) i2) <= 1048576;
    }

    private Cipher() {
    }

    static final class RC4 {
        private int i;
        private int j;
        private final int[] s;

        RC4(byte[] bArr) {
            this.s = new int[256];
            for (int i = 0; i < 256; i++) {
                this.s[i] = i;
            }
            int i2 = 0;
            for (int i3 = 0; i3 < 256; i3++) {
                int[] iArr = this.s;
                int i4 = iArr[i3];
                i2 = (i2 + i4 + (bArr[i3 % bArr.length] & 255)) & 255;
                iArr[i3] = iArr[i2];
                iArr[i2] = i4;
            }
            this.i = 0;
            this.j = 0;
        }

        RC4(RC4 rc4) {
            this.s = (int[]) rc4.s.clone();
            this.i = rc4.i;
            this.j = rc4.j;
        }

        byte[] process(byte[] bArr) {
            byte[] bArr2 = new byte[bArr.length];
            int i = this.i;
            int i2 = this.j;
            for (int i3 = 0; i3 < bArr.length; i3++) {
                i = (i + 1) & 255;
                int[] iArr = this.s;
                int i4 = iArr[i];
                i2 = (i2 + i4) & 255;
                iArr[i] = iArr[i2];
                iArr[i2] = i4;
                bArr2[i3] = (byte) (iArr[(iArr[i] + i4) & 255] ^ (bArr[i3] & 255));
            }
            this.i = i;
            this.j = i2;
            return bArr2;
        }
    }

    static RC4 makeCipher() {
        int length = Data.RC4_KEY.length + Data.RC4_NONCE.length;
        byte[] bArr = new byte[length];
        System.arraycopy(Data.RC4_KEY, 0, bArr, 0, Data.RC4_KEY.length);
        System.arraycopy(Data.RC4_NONCE, 0, bArr, Data.RC4_KEY.length, Data.RC4_NONCE.length);
        RC4 rc4 = new RC4(bArr);
        rc4.process(new byte[length]);
        return rc4;
    }

    static final class Writer {
        private final ByteArrayOutputStream buffer = new ByteArrayOutputStream();

        Writer() {
        }

        Writer writeInt(long j) {
            int i = (int) j;
            this.buffer.write((i >>> 24) & 255);
            this.buffer.write((i >>> 16) & 255);
            this.buffer.write((i >>> 8) & 255);
            this.buffer.write(i & 255);
            return this;
        }

        Writer writeBool(boolean z) {
            this.buffer.write(z ? 1 : 0);
            return this;
        }

        Writer writeFlags(boolean... zArr) {
            int i = 0;
            for (int i2 = 0; i2 < zArr.length; i2++) {
                if (zArr[i2]) {
                    i |= 1 << i2;
                }
            }
            this.buffer.write(i & 255);
            return this;
        }

        Writer writeLong(long j) {
            writeInt((int) (j >> 32));
            writeInt((int) (j & 2147483647L));
            return this;
        }

        Writer writeString(String str) {
            if (str == null) {
                return writeInt(-1L);
            }
            byte[] bytes = str.getBytes(Py.UTF8);
            writeInt(bytes.length);
            this.buffer.write(bytes, 0, bytes.length);
            return this;
        }

        Writer writeSlots(List<long[]> list) {
            writeInt(list.size());
            for (long[] jArr : list) {
                writeInt(jArr[0]);
                writeInt(jArr[1]);
            }
            return this;
        }

        Writer writeRefs(List<Long> list) {
            writeInt(list.size());
            Iterator<Long> it = list.iterator();
            while (it.hasNext()) {
                writeInt(it.next().longValue());
            }
            return this;
        }

        byte[] toBytes() {
            return this.buffer.toByteArray();
        }
    }

    static final class Reader {
        private final byte[] data;
        private int pos = 0;

        Reader(byte[] bArr) {
            this.data = bArr;
        }

        int readInt() {
            int i = this.pos;
            int i2 = i + 4;
            byte[] bArr = this.data;
            if (i2 > bArr.length) {
                throw new Py.StructError("unpack requires a buffer of 4 bytes");
            }
            int i3 = ((bArr[i] & 255) << 24) | ((bArr[i + 1] & 255) << 16) | ((bArr[i + 2] & 255) << 8) | (bArr[i + 3] & 255);
            this.pos = i + 4;
            return i3;
        }

        int readBool() {
            int i = this.pos;
            int i2 = i + 1;
            byte[] bArr = this.data;
            if (i2 > bArr.length) {
                throw new Py.StructError("unpack requires a buffer of 1 byte");
            }
            this.pos = i + 1;
            return bArr[i] & 255;
        }

        boolean[] readFlags(int i) {
            int i2 = this.pos;
            int i3 = i2 + 1;
            byte[] bArr = this.data;
            if (i3 > bArr.length) {
                throw new Py.StructError("unpack requires a buffer of 1 byte");
            }
            this.pos = i2 + 1;
            int i4 = bArr[i2] & 255;
            boolean[] zArr = new boolean[i];
            for (int i5 = 0; i5 < i; i5++) {
                boolean z = true;
                if (((i4 >> i5) & 1) == 0) {
                    z = false;
                }
                zArr[i5] = z;
            }
            return zArr;
        }

        long readLong() {
            return (readInt() << 32) | (readInt() & 4294967295L);
        }

        String readString() {
            int readInt = readInt();
            if (readInt < 0) {
                return null;
            }
            byte[] bArr = this.data;
            int length = bArr.length;
            int i = this.pos;
            if (readInt > length - i) {
                return null;
            }
            String decode = Py.decode(bArr, i, readInt);
            this.pos += readInt;
            return decode;
        }

        boolean atEnd() {
            return this.pos >= this.data.length;
        }
    }

    static int readIntBE(byte[] bArr, int i) {
        return (bArr[i + 3] & 255) | ((bArr[i] & 255) << 24) | ((bArr[i + 1] & 255) << 16) | ((bArr[i + 2] & 255) << 8);
    }

    static int[] unpackHeader(byte[] bArr) {
        return new int[]{((bArr[0] & 255) << 8) | (bArr[1] & 255), ((bArr[2] & 255) << 16) | ((bArr[3] & 255) << 8) | (bArr[4] & 255), (bArr[6] & 255) | ((bArr[5] & 255) << 8)};
    }

    static byte[] recvExact(InputStream inputStream, int i) throws IOException {
        byte[] bArr = new byte[i];
        int i2 = 0;
        while (i2 < i) {
            int read = inputStream.read(bArr, i2, i - i2);
            if (read < 0) {
                return null;
            }
            i2 += read;
        }
        return bArr;
    }

    static String hexdump(byte[] bArr, int i) {
        String hex = Py.hex(bArr, Math.min(bArr.length, i));
        if (bArr.length <= i) {
            return hex;
        }
        return hex + "...(+" + (bArr.length - i) + " bytes)";
    }

    static String hexdump(byte[] bArr) {
        return hexdump(bArr, 512);
    }
}
