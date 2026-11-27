// test_scan.cpp — uji host patterns_v221.h terhadap libil2cpp.so 2.21 asli.
// BUKAN bagian repo injector (tinggal di hasil-dump sebagai bukti pola).
// Build: g++ -O2 -o test_scan test_scan.cpp
// Pakai: ./test_scan <path libil2cpp.so 2.21>
// Sukses = tiap pola cocok TEPAT 1x di seluruh file lib, di file offset
// fungsi yang benar (RVA - 0x4000 untuk segmen R E). Gagal = pola tidak
// ketemu / ambigu / salah alamat.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include "patterns_v221.h"

struct pat {
    const char *label;
    const uint8_t *bytes;
    size_t len;
    size_t expect_off; // file offset = RVA - 0x4000
};

#define P(n) { #n, n, sizeof(n), (size_t)(n##_RVA - 0x4000) }

static const struct pat kPats[] = {
    P(TR_PATTERN_CRASH_V221),
    P(TR_PATTERN_TRIGGER_V221),
    P(TR_PATTERN_SPEED_V221),
    P(TR_PATTERN_MM_FIXEDUPDATE_V221),
    P(TR_PATTERN_MM_UPDATE_V221),
    P(TR_PATTERN_OFFROAD_SHAKE_V221),
    P(TR_PATTERN_TM_FIXEDUPDATE_V221),
    P(TR_PATTERN_GM_FIXEDUPDATE_V221),
    P(TR_PATTERN_CAM_LATE_V221),
    P(TR_PATTERN_GETPOS_V221),
    P(TR_PATTERN_SETPOS_V221),
    P(TR_PATTERN_CAM_MAIN_V221),
    P(TR_PATTERN_W2S_V221),
    P(TR_PATTERN_SCRW_V221),
    P(TR_PATTERN_SCRH_V221),
    P(TR_PATTERN_GETNAME_V221),
    P(TR_PATTERN_BOX_CENTER_V221),
    P(TR_PATTERN_BOX_SIZE_V221),
};

static int count_hits(const uint8_t *buf, size_t n, const uint8_t *pat, size_t len, size_t *first) {
    int c = 0;
    *first = 0;
    for (size_t i = 0; i + len <= n; i++) {
        if (memcmp(buf + i, pat, len) == 0) {
            if (c == 0) *first = i;
            c++;
        }
    }
    return c;
}

int main(int argc, char **argv) {
    if (argc < 2) {
        fprintf(stderr, "pakai: %s libil2cpp.so\n", argv[0]);
        return 2;
    }
    FILE *f = fopen(argv[1], "rb");
    if (!f) { perror("buka lib"); return 2; }
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    uint8_t *buf = (uint8_t *)malloc(n);
    if (fread(buf, 1, n, f) != (size_t)n) { perror("baca lib"); return 2; }
    fclose(f);

    int fail = 0;
    size_t npats = sizeof(kPats) / sizeof(kPats[0]);
    for (size_t i = 0; i < npats; i++) {
        const struct pat *p = &kPats[i];
        size_t first = 0;
        int c = count_hits(buf, n, p->bytes, p->len, &first);
        const char *ok = (c == 1 && first == p->expect_off) ? "OK " : "GAGAL";
        if (c != 1 || first != p->expect_off) fail++;
        printf("%s %-32s cocok=%d off=0x%zx harap=0x%zx len=%zu\n",
               ok, p->label, c, first, p->expect_off, p->len);
    }
    free(buf);
    if (fail) printf("HASIL: GAGAL (%d pola)\n", fail);
    else printf("HASIL: SEMUA POLA OK (%zu pola)\n", npats);
    return fail ? 1 : 0;
}
